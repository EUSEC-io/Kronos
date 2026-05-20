# description: Add a user to an AD group using bloodyAD
function __kronos_add_member --description "Add a user to an AD group using bloodyAD"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse h/help u/username= p/password= k/kerberos g/group= m/member= w/wizard -- $argv
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
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l group $_flag_group
    set -l member $_flag_member
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    if test "$wizard" -eq 1; or set -q _flag_wizard
        set_color cyan; echo "[*] Starting Add Member wizard..."; set_color normal

        set -l def_target "$__KRONOS_CACHE_ADDMEMBER_TARGET"
        if test -z "$def_target"; set def_target "$TGT_DC_IP"; end
        if test -z "$def_target"; set def_target "$TGT_DC"; end
        if test -z "$def_target"; set def_target "$TGT"; end
        if test -n "$target"; set def_target "$target"; end
        set target (__kronos_ask "Target DC IP/Hostname" "$def_target"); or return 1
        set -U __KRONOS_CACHE_ADDMEMBER_TARGET "$target"

        set -l def_group "$__KRONOS_CACHE_ADDMEMBER_GROUP"
        if test -z "$def_group"; set def_group "Domain Admins"; end
        if test -n "$group"; set def_group "$group"; end
        set group (__kronos_ask "Target Group" "$def_group"); or return 1
        set -U __KRONOS_CACHE_ADDMEMBER_GROUP "$group"

        set -l def_member "$__KRONOS_CACHE_ADDMEMBER_MEMBER"
        if test -n "$member"; set def_member "$member"; end
        set member (__kronos_ask "Member to Add" "$def_member"); or return 1
        set -U __KRONOS_CACHE_ADDMEMBER_MEMBER "$member"

        if not set -q _flag_kerberos
            set -l def_auth_user "$__KRONOS_CACHE_ADDMEMBER_AUTH_USER"
            if test -z "$def_auth_user"; set def_auth_user "$TGT_USERNAME"; end
            if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; end
            if test -n "$auth_user"; set def_auth_user "$auth_user"; end
            set auth_user (__kronos_ask "Auth Username" "$def_auth_user"); or return 1
            set -U __KRONOS_CACHE_ADDMEMBER_AUTH_USER "$auth_user"

            set -l def_auth_pass "$__KRONOS_CACHE_ADDMEMBER_AUTH_PASS"
            if test -z "$def_auth_pass"; set def_auth_pass "$TGT_PASSWORD"; end
            if test -z "$def_auth_pass"; set def_auth_pass "$TGT_CRED_PASSWORD"; end
            if test -n "$auth_pass"; set def_auth_pass "$auth_pass"; end
            set auth_pass (__kronos_ask "Auth Password" "$def_auth_pass"); or return 1
            set -U __KRONOS_CACHE_ADDMEMBER_AUTH_PASS "$auth_pass"
        end
    else
        # Standard Fallbacks
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
        
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$group"; echo "error: --group is required"; return 1; end
    if test -z "$member"; echo "error: --member is required"; return 1; end

    set -l domain $TGT_DC_DOMAIN
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN is not set" >&2
        return 1
    end

    set -l cmd_str bloodyAD --host "$target" -d "$domain"
    if set -q _flag_kerberos
        set -a cmd_str -k
    else
        if test -z "$auth_user"
            echo "error: auth credentials required" >&2
            return 1
        end
        set -a cmd_str -u "$auth_user" -p "$auth_pass"
    end

    set -a cmd_str add groupMember "$group" "$member"

    __kronos_check_dep bloodyAD; or return 1

    echo "[*] Adding $member to group $group via bloodyAD..."
    command $cmd_str
end
