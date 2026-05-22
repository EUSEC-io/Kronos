# description: Query domain info and password policy
function __kronos_dominfo --description "Query domain info and password policy"
    argparse h/help q/quiet P/pass-policy u/username= p/password= N/NULL k/kerberos X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos dominfo [TARGET] [OPTIONS]"
        echo ""
        echo "Query domain info and password policy using rpcclient (null session) or nxc (credentialed)."
        echo ""
        echo "Options:"
        echo "  -P, --pass-policy   Also query password policy"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -N, --NULL          Force NULL session enumeration"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l pass_pol 0
    if set -q _flag_pass_policy; set pass_pol 1; end

    # Load defaults
    if test -z "$target"
        set target $__KRONOS_CACHE_DOMINFO_TARGET
        if test -z "$target"; set target $TGT_HOSTS[1]; end
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end

    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_DOMINFO_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"
        set auth_pass $__KRONOS_CACHE_DOMINFO_AUTH_PASS
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    # Interactive Wizard
    if not set -q _flag_quiet
        if test (count $argv) -eq 0; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting DomInfo wizard..."; set_color normal

            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_DOMINFO_TARGET "$target"

            set -l mode "NULL Session"
            if set -q _flag_kerberos; set mode "Kerberos"; end
            if test -n "$auth_user"; and test -n "$auth_pass"; set mode "Credentials"; end
            
            set mode (__kronos_ask_choice "Authentication Mode" "$mode" "NULL Session" "Credentials" "Kerberos"); or return 1
            
            if test "$mode" = "Credentials"
                set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
                set -U __KRONOS_CACHE_DOMINFO_AUTH_USER "$auth_user"
                set auth_pass (__kronos_ask "Auth Password" "$auth_pass"); or return 1
                set -U __KRONOS_CACHE_DOMINFO_AUTH_PASS "$auth_pass"
                set -e _flag_NULL
                set -e _flag_kerberos
            else if test "$mode" = "Kerberos"
                set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
                set -U __KRONOS_CACHE_DOMINFO_AUTH_USER "$auth_user"
                set _flag_kerberos 1
                set -e _flag_NULL
            else
                set _flag_NULL 1
                set -e _flag_kerberos
            end

            set -l pol_choice (__kronos_ask_confirm "Query password policy?" (test "$pass_pol" -eq 1; and echo "y"; or echo "n")); or return 1
            if test "$pol_choice" = "yes"
                set pass_pol 1
            else
                set pass_pol 0
            end
        end
    end

    if test -z "$target"; echo "error: target is required" >&2; return 1; end

    set -l has_creds 0
    if test -n "$auth_user"; and test -n "$auth_pass"; set has_creds 1; end
    if set -q _flag_kerberos; set has_creds 1; end
    if set -q _flag_NULL; set has_creds 0; end

    if test "$has_creds" -eq 1
        __kronos_check_dep nxc; or return 1
        set -l nxc_cmd "nxc smb $target"
        if test -n "$TGT_DC_DOMAIN"; set nxc_cmd "$nxc_cmd -d $TGT_DC_DOMAIN"; end
        
        if set -q _flag_kerberos
            set nxc_cmd "$nxc_cmd -k -u \"$auth_user\" -p \"\""
        else
            set nxc_cmd "$nxc_cmd -u \"$auth_user\" -p \"$auth_pass\""
        end

        if test "$pass_pol" -eq 1
            set nxc_cmd "$nxc_cmd --pass-pol"
        end
        
        if set -q _flag_edit_cmd
            set nxc_cmd (__kronos_edit_cmd "$nxc_cmd"); or return 1
        end

        echo "[*] Querying dominfo via nxc smb..."
        eval $nxc_cmd
    else
        __kronos_check_dep rpcclient; or return 1
        set -l rpc_cmds "querydominfo"
        if test "$pass_pol" -eq 1
            set rpc_cmds "$rpc_cmds; getdompwinfo"
        end
        
        set -l rpc_cmd "rpcclient -U \"\" -N \"$target\" -c \"$rpc_cmds\""
        
        if set -q _flag_edit_cmd
            set rpc_cmd (__kronos_edit_cmd "$rpc_cmd"); or return 1
        end

        echo "[*] Querying dominfo via rpcclient (null session)..."
        eval $rpc_cmd
    end
end
