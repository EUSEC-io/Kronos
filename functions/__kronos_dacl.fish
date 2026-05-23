# description: Manipulate AD object DACLs using bloodyAD
function __kronos_dacl --description "Manipulate AD object DACLs using bloodyAD"
    argparse h/help u/username= p/password= k/kerberos t/target-object= m/member= a/action= p/permission= q/quiet w/wizard X/edit-cmd -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos dacl [TARGET_DC] [OPTIONS]"
        echo ""
        echo "Manipulate Active Directory DACLs using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -t, --target-object NAME Target AD object (e.g. 'DC=dante,DC=local' or 'p.user')"
        echo "  -m, --member NAME        The user/group to grant/revoke permissions to"
        echo "  -a, --action ACTION      Action to perform (add, remove, set) - default: add"
        echo "  -p, --permission PERM    Permission (genericAll, dcsync, owner, all) - default: genericAll"
        echo "  -u, --username USER      Auth username"
        echo "  -p, --password PASS      Auth password"
        echo "  -k, --kerberos           Use Kerberos authentication"
        echo "  -X, --edit-cmd           Edit the command before execution"
        echo "  -q, --quiet              Skip prompts and use fallbacks"
        echo "  -h, --help               Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l target_obj $_flag_target_object
    set -l member $_flag_member
    set -l action "add"
    if set -q _flag_action; set action $_flag_action; end
    set -l permission "genericAll"
    if set -q _flag_permission; set permission $_flag_permission; end

    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    # Load defaults
    if test -z "$target"
        set target $__KRONOS_CACHE_DACL_TARGET
        if test -z "$target"; set target $TGT_HOSTS[1]; end
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end
    if test -z "$target_obj"; set target_obj $__KRONOS_CACHE_DACL_TARGET_OBJ; end
    if test -z "$member"; set member $__KRONOS_CACHE_DACL_MEMBER; end

    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_DACL_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"
        set auth_pass $__KRONOS_CACHE_DACL_AUTH_PASS
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    # Interactive Fallback
    if not set -q _flag_quiet
        if test (count $argv) -eq 0; or set -q _flag_wizard
            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_DACL_TARGET "$target"

            set target_obj (__kronos_ask "Target AD Object" "$def_target_obj" "$src_target_obj"); or return 1
            set -U __KRONOS_CACHE_DACL_TARGET_OBJ "$target_obj"

            set member (__kronos_ask "Member to grant/revoke" "$member"); or return 1
            set -U __KRONOS_CACHE_DACL_MEMBER "$member"

            set action (__kronos_ask "Action (add, remove, set)" "$action"); or return 1
            set permission (__kronos_ask "Permission (genericAll, dcsync, owner, all)" "$permission"); or return 1
        end

    if test -z "$target"; echo "error: target DC is required" >&2; return 1; end
    if test -z "$target_obj"; echo "error: --target-object is required" >&2; return 1; end
    if test -z "$member"; echo "error: --member is required" >&2; return 1; end

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

    set -a cmd_list $action dacl "$target_obj" "$member" "$permission"

    __kronos_check_dep bloodyAD; or return 1

    set -l cmd_str ""
    for part in $cmd_list
        set cmd_str "$cmd_str "(string escape -- $part)
    end
    set cmd_str (string trim $cmd_str)

    if set -q _flag_edit_cmd
        set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1
    end

    echo "[*] Performing DACL $action ($permission) on $target_obj for $member..."
    eval $cmd_str
end