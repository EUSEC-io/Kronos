# description: Search and enumerate AD objects using bloodyAD
function __kronos_search --description "Search and enumerate AD objects using bloodyAD"
    argparse h/help q/quiet u/username= p/password= k/kerberos query= a/attr= w/wizard X/edit-cmd -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos search [TARGET] [OPTIONS]"
        echo ""
        echo "Search and enumerate Active Directory objects using bloodyAD."
        echo ""
        echo "Options:"
        echo "  --query TEXT          Search query (e.g. '*' or LDAP filter)"
        echo "  -a, --attr NAME       Specific attribute to retrieve"
        echo "  -u, --username USER   Auth username"
        echo "  -p, --password PASS   Auth password"
        echo "  -k, --kerberos        Use Kerberos authentication"
        echo "  -X, --edit-cmd        Edit the command before execution"
        echo "  -q, --quiet           Skip prompts and use fallbacks"
        echo "  -h, --help            Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l query $_flag_query
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    # Standard Fallbacks & Cache
    if test -z "$target"
        set target $__KRONOS_CACHE_SEARCH_TARGET
        if test -z "$target"; set target $TGT_HOSTS[1]; end
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end

    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_SEARCH_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"
        set auth_pass $__KRONOS_CACHE_SEARCH_AUTH_PASS
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    # Interactive Fallback
    if not set -q _flag_quiet
        if test (count $argv) -eq 0; or set -q _flag_wizard
            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_SEARCH_TARGET "$target"
            
            if test -z "$query"
                 set query (__kronos_ask "Search Query" "*"); or return 1
            end

    if test -z "$target"; echo "error: target is required" >&2; return 1; end

    set -l domain $TGT_DC_DOMAIN
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN is not set" >&2
        return 1
    end

    set -l cmd_list bloodyAD --host "$target" -d "$domain"
    if set -q _flag_kerberos
        set -a cmd_list -k
    else
        if test -z "$auth_user"
            echo "error: auth credentials required" >&2
            return 1
        end
        set -a cmd_list -u "$auth_user" -p "$auth_pass"
    end

    if test -z "$query"; set query "*"; end

    set -a cmd_list get object "$query"
    if set -q _flag_attr
        set -a cmd_list --attr "$_flag_attr"
    end

    __kronos_check_dep bloodyAD; or return 1

    set -l cmd_str ""
    for part in $cmd_list
        set cmd_str "$cmd_str "(string escape -- $part)
    end
    set cmd_str (string trim $cmd_str)

    if set -q _flag_edit_cmd
        set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1
    end

    echo "[*] Searching for '$query' in AD..."
    eval $cmd_str
end