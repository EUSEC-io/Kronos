# description: Search and enumerate AD objects using bloodyAD
function __kronos_search --description "Search and enumerate AD objects using bloodyAD"
    argparse h/help u/username= p/password= k/kerberos q/query= a/attr= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos search [TARGET] [OPTIONS]"
        echo ""
        echo "Search and enumerate Active Directory objects using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -q, --query TEXT      Search query (e.g. 'Administrator' or LDAP filter)"
        echo "  -a, --attr NAME       Specific attribute to retrieve"
        echo "  -u, --username USER   Auth username"
        echo "  -p, --password PASS   Auth password"
        echo "  -k, --kerberos        Use Kerberos authentication"
        echo "  -h, --help            Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"; set target $TGT_DC_IP; end
    if test -z "$target"; set target $TGT_DC; end
    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    set -l domain $TGT_DC_DOMAIN
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN is not set" >&2
        return 1
    end

    set -l cmd_str bloodyAD --host "$target" -d "$domain"
    if set -q _flag_kerberos
        set -a cmd_str -k
    else
        set -l auth_user $_flag_username; if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
        set -l auth_pass $_flag_password; if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
        if test -z "$auth_user"
            echo "error: auth credentials required" >&2
            return 1
        end
        set -a cmd_str -u "$auth_user" -p "$auth_pass"
    end

    set -l query "*"
    if set -q _flag_query; set query $_flag_query; end

    set -a cmd_str get object "$query"
    if set -q _flag_attr
        set -a cmd_str --attr "$_flag_attr"
    end

    echo "[*] Searching for '$query' in AD..."
    command $cmd_str
end
