# description: Force change a user's password using bloodyAD
function __kronos_forcechange --description "Force change a user's password using bloodyAD"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse h/help u/username= p/password= H/hash= t/target-user= P/new-password= k/kerberos q/quiet target= w/wizard X/edit-cmd -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos forcechange [OPTIONS]"
        echo ""
        echo "Force change a user's password using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target DC IP or Hostname"
        echo "  -u, --target-user U Target user whose password will be changed"
        echo "  -P, --new-password  The new password to set"
        echo "  -A, --auth-user     Auth username"
        echo "  -X, --edit-cmd      Edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l target_user $_flag_target_user
    set -l new_pass $_flag_new_password
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting Force Password Change wizard..."; set_color normal

            set -l def_target "$__KRONOS_CACHE_FORCEPASS_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_FORCEPASS_TARGET "$target"

            set target_user (__kronos_ask "User to Reset" "$target_user"); or return 1
            set -U __KRONOS_CACHE_FORCEPASS_USER "$target_user"

            set new_pass (__kronos_ask "New Password" "$new_pass"); or return 1
            set -U __KRONOS_CACHE_FORCEPASS_NEW_PASS "$new_pass"

            if not set -q _flag_kerberos
                set -l def_auth_user "$__KRONOS_CACHE_FORCEPASS_AUTH_USER"
                set -l src_user "Cache"
                if test -z "$def_auth_user"
                    set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                    if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
                end
                set auth_user (__kronos_ask "Auth Username" "$def_auth_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_FORCEPASS_AUTH_USER "$auth_user"

                set -l def_auth_val "$auth_pass"
                if test -n "$auth_hash"; set def_auth_val "$auth_hash"; end
                if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; end
                set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val"); or return 1
                set -U __KRONOS_CACHE_FORCEPASS_AUTH_VAL "$auth_input"
                
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set auth_hash "$auth_input"; set auth_pass ""
                else
                    set auth_pass "$auth_input"; set auth_hash ""
                end
            end

            # Confirmation
            echo ""
            echo "Configuration:"
            echo "  Target:   $target"
            echo "  Reset:    $target_user"
            echo "  Auth:     "(set -q _flag_kerberos; and echo "Kerberos"; or echo "$auth_user")
            echo ""
            if test (__kronos_ask_confirm "Force reset password for '$target_user' on $target?" n) != "yes"
                echo "Aborted."
                return 1
            end
        end
    else
        # Quiet mode fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_FORCEPASS_TARGET"; end
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
    if test -z "$target_user"; echo "error: target user is required"; return 1; end
    if test -z "$new_pass"; echo "error: new password is required"; return 1; end

    if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
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
        set -a cmd_list -u "$auth_user"
        if test -n "$auth_hash"
            set -a cmd_list -p ":$auth_hash"
        else
            set -a cmd_list -p "$auth_pass"
        end
    end

    set -a cmd_list set password "$target_user" "$new_pass"

    __kronos_check_dep bloodyAD; or return 1

    set -l cmd_str ""
    for part in $cmd_list
        set cmd_str "$cmd_str "(string escape -- $part)
    end
    set cmd_str (string trim $cmd_str)

    if set -q _flag_edit_cmd
        set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1
    end

    echo "[*] Force-changing password for $target_user via bloodyAD..."
    eval $cmd_str
end
