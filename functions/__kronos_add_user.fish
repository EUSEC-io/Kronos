# description: Create a new AD user using bloodyAD
function __kronos_add_user --description "Create a new AD user using bloodyAD"
    argparse t/target= h/help q/quiet u/username= p/password= k/kerberos U/new-user= P/new-password= X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos add-user [OPTIONS]"
        echo ""
        echo "Create a new Active Directory user using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -t, --target IP         Target DC IP or Hostname"
        echo "  -U, --new-user NAME     The username of the new user"
        echo "  -P, --new-password PASS The password for the new user"
        echo "  -A, --auth-user USER    Auth username"
        echo "  -X, --edit-cmd          Edit the command before execution"
        echo "  -q, --quiet             Skip prompts and use cached/default values"
        echo "  -h, --help              Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l new_user $_flag_new_user
    set -l new_pass $_flag_new_password
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    if not set -q _flag_quiet
        if test (count $argv) -eq 0 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting Add User wizard..."; set_color normal

            set -l def_target "$__KRONOS_CACHE_ADDUSER_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_ADDUSER_TARGET "$target"

            set new_user (__kronos_ask "New Username" "$new_user"); or return 1
            set -U __KRONOS_CACHE_ADDUSER_NEW_USER "$new_user"

            set new_pass (__kronos_ask "New Password" "$new_pass"); or return 1
            set -U __KRONOS_CACHE_ADDUSER_NEW_PASS "$new_pass"

            if not set -q _flag_kerberos
                set -l def_auth_user "$__KRONOS_CACHE_ADDUSER_AUTH_USER"
                set -l src_user "Cache"
                if test -z "$def_auth_user"
                    set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                    if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
                end
                set auth_user (__kronos_ask "Auth Username" "$def_auth_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_ADDUSER_AUTH_USER "$auth_user"

                set auth_pass (__kronos_ask "Auth Password" "$auth_pass"); or return 1
                set -U __KRONOS_CACHE_ADDUSER_AUTH_PASS "$auth_pass"
            end

            # Confirmation
            echo ""
            echo "Configuration:"
            echo "  Target:   $target"
            echo "  New User: $new_user"
            echo "  Auth:     "(set -q _flag_kerberos; and echo "Kerberos"; or echo "$auth_user")
            echo ""
            if test (__kronos_ask_confirm "Create user '$new_user' on $target?" n) != "yes"
                echo "Aborted."
                return 1
            end
        end
    else
        # Quiet mode fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_ADDUSER_TARGET"; end
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

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$new_user"; echo "error: new user is required"; return 1; end
    if test -z "$new_pass"; echo "error: new password is required"; return 1; end

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

    set cmd_str "$cmd_str add user \"$new_user\" \"$new_pass\""

    if set -q _flag_edit_cmd
        set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1
    end

    __kronos_check_dep bloodyAD; or return 1

    echo "[*] Creating user $new_user via bloodyAD..."
    command eval $cmd_str
end
