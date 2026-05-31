# description: Add a user to an AD group using bloodyAD
function __kronos_add_member --description "Add a user to an AD group using bloodyAD"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet u/username= p/password= k/kerberos g/group= m/member= X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos add-member [OPTIONS]"
        echo ""
        echo "Add a user to an Active Directory group using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -t, --target IP         Target DC IP or Hostname"
        echo "  -g, --group NAME        The target group name"
        echo "  -m, --member NAME       The user to add to the group"
        echo "  -u, --username USER     Auth username"
        echo "  -p, --password PASS     Auth password"
        echo "  -k, --kerberos          Use Kerberos authentication"
        echo "  -X, --edit-cmd          Edit the command before execution"
        echo "  -q, --quiet             Skip all prompts and use fallbacks/cached values"
        echo "  -h, --help              Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l group $_flag_group
    set -l member $_flag_member
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting Add Member wizard..."; set_color normal
            
            set -l def_target "$__KRONOS_CACHE_ADDMEMBER_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_ADDMEMBER_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_ADDMEMBER_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_ADDMEMBER_DOMAIN "$domain"

            set group (__kronos_ask "Target Group" "$group"); or return 1
            set -U __KRONOS_CACHE_ADDMEMBER_GROUP "$group"

            set member (__kronos_ask "Member to Add" "$member"); or return 1
            set -U __KRONOS_CACHE_ADDMEMBER_MEMBER "$member"

            if not set -q _flag_kerberos
                set -l def_auth_user "$__KRONOS_CACHE_ADDMEMBER_AUTH_USER"
                set -l src_user "Cache"
                if test -z "$def_auth_user"
                    set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                    if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
                end
                set auth_user (__kronos_ask "Auth Username" "$def_auth_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_ADDMEMBER_AUTH_USER "$auth_user"

                set auth_pass (__kronos_ask "Auth Password" "$auth_pass"); or return 1
                set -U __KRONOS_CACHE_ADDMEMBER_AUTH_PASS "$auth_pass"
            end

            # Confirmation
            echo ""
            echo "Configuration:"
            echo "  Target:   $target"
            echo "  Group:    $group"
            echo "  Member:   $member"
            echo "  Auth:     "(set -q _flag_kerberos; and echo "Kerberos"; or echo "$auth_user")
            echo ""
            if test (__kronos_ask_confirm "Add $member to $group on $target?" n) != "yes"
                echo "Aborted."
                return 1
            end
        end
    else
        # Quiet mode fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_ADDMEMBER_TARGET"; end
        if test -z "$target"; set target $TGT; end
        if test -z "$target"; set target $TGT_HOSTS[1]; end
        if test -z "$target"; set target $TGT_DC_IP; end

        if test -z "$auth_user"
            set auth_user "$TGT_USERNAME"
            if test -z "$auth_user"; set auth_user "$TGT_CRED_USERNAME"; end
        end
        if test -z "$auth_pass"
            set auth_pass "$TGT_PASSWORD"
            if test -z "$auth_pass"; set auth_pass "$TGT_CRED_PASSWORD"; end
        end
    end

    # Validation
    if test -z "$target"; echo "error: target is required" >&2; return 1; end
    if test -z "$group"; echo "error: --group is required" >&2; return 1; end
    if test -z "$member"; echo "error: --member is required" >&2; return 1; end

    set -l domain $TGT_DC_DOMAIN
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN is not set" >&2
        return 1
    end

    set -l cmd_str "bloodyAD --host \"$target\" -d \"$domain\""
    if set -q _flag_kerberos
        set cmd_str "$cmd_str -k"
    else
        if test -z "$auth_user"
            echo "error: auth credentials required"; return 1
        end
        set cmd_str "$cmd_str -u \"$auth_user\" -p \"$auth_pass\""
    end

    set cmd_str "$cmd_str add groupMember \"$group\" \"$member\""

    if set -q _flag_edit_cmd
        set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1
    end

    __kronos_check_dep bloodyAD; or return 1

    echo "[*] Adding $member to group $group via bloodyAD..."
    command eval $cmd_str
end
