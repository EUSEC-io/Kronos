# description: Create a new AD user using bloodyAD
function __kronos_add_user --description "Create a new AD user using bloodyAD"
    argparse h/help u/username= p/password= k/kerberos U/new-user= P/new-password= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos add-user [TARGET] [OPTIONS]"
        echo ""
        echo "Create a new Active Directory user using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -U, --new-user NAME     The username of the new user"
        echo "  -P, --new-password PASS The password for the new user"
        echo "  -u, --username USER     Auth username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS     Auth password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -k, --kerberos          Use Kerberos authentication"
        echo "  -h, --help              Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"; set target $TGT_DC_IP; end
    if test -z "$target"; set target $TGT_DC; end
    if test -z "$target"; set target $TGT; end
    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    if not set -q _flag_new_user; or not set -q _flag_new_password
        echo "error: --new-user and --new-password are required" >&2
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
        set -l auth_user $_flag_username; if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end

        set -l auth_pass $_flag_password; if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end

        if test -z "$auth_user"
            echo "error: auth credentials required" >&2
            return 1
        end
        set -a cmd_str -u "$auth_user" -p "$auth_pass"
    end

    set -a cmd_str add user "$_flag_new_user" "$_flag_new_password"

    echo "[*] Creating user $_flag_new_user via bloodyAD..."
    command $cmd_str
end
