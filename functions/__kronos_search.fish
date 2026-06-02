# description: Search and enumerate AD objects using bloodyAD
function __kronos_search --description "Search and enumerate AD objects using bloodyAD"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet u/username= p/password= k/kerberos query= a/attr= w/wizard X/edit-cmd -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos search [OPTIONS]"
        echo ""
        echo "Search and enumerate Active Directory objects using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target DC IP or Hostname"
        echo "  --query TEXT        Search query (e.g. '(&(objectClass=user)(sAMAccountName=admin))')"
        echo "  -a, --attr TEXT     Attribute to fetch (default: all)"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -X, --edit-cmd      Edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l query $_flag_query
    set -l attr $_flag_attr
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting Search wizard..."; set_color normal

            set -l def_target "$__KRONOS_CACHE_SEARCH_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_SEARCH_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_SEARCH_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_SEARCH_DOMAIN "$domain"

            set -l def_query "$__KRONOS_CACHE_SEARCH_QUERY"
            if test -z "$def_query"; set def_query "(&(objectClass=user)(sAMAccountName=Administrator))"; end
            set query (__kronos_ask "LDAP Query" "$def_query"); or return 1
            set -U __KRONOS_CACHE_SEARCH_QUERY "$query"

            if not set -q _flag_kerberos
                set -l def_auth_user "$__KRONOS_CACHE_SEARCH_AUTH_USER"
                set -l src_user "Cache"
                if test -z "$def_auth_user"
                    set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                end
                set auth_user (__kronos_ask "Auth Username" "$def_auth_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_SEARCH_AUTH_USER "$auth_user"

                set -l def_auth_val "$__KRONOS_CACHE_SEARCH_AUTH_VAL"
                set -l src_auth_val "Cache"
                if test -z "$def_auth_val"
                    set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"
                    if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; set src_auth_val "TGT_CRED_PASSWORD"; end
                end
                if test -n "$auth_pass"; set def_auth_val "$auth_pass"; set src_auth_val "CLI Pass"; end
                if test -n "$auth_hash"; set def_auth_val "$auth_hash"; set src_auth_val "CLI Hash"; end
                set auth_pass (__kronos_ask "Auth Password" "$def_auth_val" "$src_auth_val"); or return 1
                set -U __KRONOS_CACHE_SEARCH_AUTH_PASS "$auth_pass"
            end
        end
    else
        # Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_SEARCH_TARGET"; end
        if test -z "$target"; set target "$TGT"; end
        if test -z "$auth_user"; set auth_user "$TGT_USERNAME"; end
    end

    if test -z "$target"; echo "error: target DC is required"; return 1; end

    if test -z "$domain"
        set domain $TGT_DC_DOMAIN
        if test -z "$domain"; set domain $TGT_HOSTS[1]; end
    end
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN or \$TGT_HOSTS is not set" >&2
        return 1
    end

    set -l cmd_list bloodyAD --host "$target" -d "$domain"
    if set -q _flag_kerberos
        set -a cmd_list -k
    else
        if test -z "$auth_user"; or test -z "$auth_pass"
            echo "error: auth credentials required"; return 1
        end
        set -a cmd_list -u "$auth_user" -p "$auth_pass"
    end

    set -a cmd_list get search --searchFilter "$query"
    if test -n "$attr"
        set -a cmd_list --searchAttribute "$attr"
    end

    __kronos_check_dep bloodyAD; or return 1

    set -l cmd_str ""
    for part in $cmd_list
        set cmd_str "$cmd_str "(string escape -- $part)
    end
    set cmd_str (string trim $cmd_str)

    if set -q _flag_edit_cmd; set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1; end

    echo "[*] Searching for '$query' in AD via bloodyAD..."
    __kronos_exec "$cmd_str"
end
