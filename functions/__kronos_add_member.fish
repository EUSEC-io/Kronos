# description: Add a user to an AD group using bloodyAD
function __kronos_add_member --description "Add a user to an AD group using bloodyAD"
    argparse h/help u/username= p/password= k/kerberos g/group= m/member= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos add-member [TARGET] [OPTIONS]"
        echo ""
        echo "Add a user to an Active Directory group using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -g, --group NAME        The target group name"
        echo "  -m, --member NAME       The user to add to the group"
        echo "  -u, --username USER     Auth username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS     Auth password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -k, --kerberos          Use Kerberos authentication"
        echo "  -h, --help              Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"; set target $TGT_DC_IP; end
    if test -z "$target"; set target $TGT_DC; end
    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    if not set -q _flag_group; or not set -q _flag_member
        echo "error: --group and --member are required" >&2
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

    set -a cmd_str add groupMember "$_flag_group" "$_flag_member"

    echo "[*] Adding $_flag_member to group $_flag_group via bloodyAD..."
    command $cmd_str
end
