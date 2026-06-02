# description: Dump all DNS records from AD using adidnsdump
function __kronos_dnsdump --description "Dump all DNS records from AD using adidnsdump"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet u/username= p/password= H/hash= d/domain= k/kerberos r/resolve X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos dnsdump [OPTIONS]"
        echo ""
        echo "Dump all DNS records from Active Directory using adidnsdump."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target DC IP or Hostname"
        echo "  -r, --resolve       Resolve all found records"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -H, --hash HASH     Auth NTLM hash"
        echo "  -d, --domain DOMAIN Target domain name"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; and test (count $argv) -gt 0
        set target $argv[1]
    end
    set -l domain $_flag_domain
    set -l user $_flag_username
    set -l pass $_flag_password
    set -l hash $_flag_hash
    set -l resolve 0
    if set -q _flag_resolve; set resolve 1; end

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting DNSDump wizard..."; set_color normal

            set -l def_target "$__KRONOS_CACHE_DNSDUMP_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_DNSDUMP_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_DNSDUMP_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_DNSDUMP_DOMAIN "$domain"

            if not set -q _flag_kerberos
                set -l def_auth_user "$__KRONOS_CACHE_DNSDUMP_AUTH_USER"
                set -l src_user "Cache"
                if test -z "$def_auth_user"
                    set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                    if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
                end
                if test -n "$user"; set def_auth_user "$user"; set src_user "CLI Arg"; end
                set user (__kronos_ask "Auth Username" "$def_auth_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_DNSDUMP_AUTH_USER "$user"

                set -l def_auth_val "$__KRONOS_CACHE_DNSDUMP_AUTH_VAL"
                set -l src_auth_val "Cache"
                if test -z "$def_auth_val"
                    set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"
                    if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; set src_auth_val "TGT_CRED_PASSWORD"; end
                end
                if test -n "$pass"; set def_auth_val "$pass"; set src_auth_val "CLI Pass"; end
                if test -n "$hash"; set def_auth_val "$hash"; set src_auth_val "CLI Hash"; end
                set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val" "$src_auth_val"); or return 1
                set -U __KRONOS_CACHE_DNSDUMP_AUTH_VAL "$auth_input"
                
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set hash "$auth_input"; set pass ""
                else
                    set pass "$auth_input"; set hash ""
                end
            end

            if test (__kronos_ask_confirm "Resolve found records?" (test "$resolve" -eq 1; and echo "y"; or echo "n")) = "yes"
                set resolve 1
            else
                set resolve 0
            end
        end
    else
        # Quiet mode fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_DNSDUMP_TARGET"; end
        if test -z "$target"; set target $TGT; end
        if test -z "$domain"; set domain "$__KRONOS_CACHE_DNSDUMP_DOMAIN"; end
        if test -z "$domain"; set domain $TGT_HOSTS[1]; end
        if test -z "$user"; set user "$__KRONOS_CACHE_DNSDUMP_AUTH_USER"; end
        if test -z "$user"; set user "$TGT_USERNAME"; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$domain"; echo "error: domain is required"; return 1; end

    __kronos_check_dep adidnsdump; or return 1

    set -l cmd_args
    if set -q _flag_kerberos
        set -a cmd_args -k
    else if test -n "$hash"
        set -a cmd_args -u "$domain\\$user" -p "" -H "$hash"
    else
        set -a cmd_args -u "$domain\\$user" -p "$pass"
    end

    if test "$resolve" -eq 1; set -a cmd_args -r; end
    
    set -a cmd_args "ldap://$target"

    set -l full_cmd "adidnsdump "(string join ' ' -- $cmd_args)
    if set -q _flag_edit_cmd
        set full_cmd (__kronos_edit_cmd "$full_cmd"); or return 1
    end

    echo "[*] Dumping DNS records via adidnsdump..."
    __kronos_exec "$full_cmd"
end
