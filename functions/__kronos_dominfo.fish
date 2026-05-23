# description: Query domain info, users, groups, and shares
function __kronos_dominfo --description "Query domain info, users, groups, and shares"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet P/pass-policy U/users G/groups L/loggedon S/shares u/username= p/password= N/NULL k/kerberos X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos dominfo [OPTIONS]"
        echo ""
        echo "Query domain info and enumerate objects using rpcclient or nxc."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target DC IP or Hostname"
        echo "  -P, --pass-policy   Query password policy"
        echo "  -U, --users         List domain users"
        echo "  -G, --groups        List domain groups"
        echo "  -L, --loggedon      List logged on users"
        echo "  -S, --shares        List shares"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -N, --NULL          Force NULL session enumeration"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    
    set -l pass_pol 0
    if set -q _flag_pass_policy; set pass_pol 1; end
    set -l list_users 0
    if set -q _flag_users; set list_users 1; end
    set -l list_groups 0
    if set -q _flag_groups; set list_groups 1; end
    set -l list_loggedon 0
    if set -q _flag_loggedon; set list_loggedon 1; end
    set -l list_shares 0
    if set -q _flag_shares; set list_shares 1; end

    # Load defaults
    if test -z "$target"
        set -l def_target "$__KRONOS_CACHE_DOMINFO_TARGET"
        set -l src_target "Cache"
        if test -z "$def_target"
            set def_target "$TGT"; set src_target "TGT"
            if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
            if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
            if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
        end
        if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
        
        if not set -q _flag_quiet
            if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
                set_color cyan; echo "[*] Starting DomInfo wizard..."; set_color normal
                set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
                set -U __KRONOS_CACHE_DOMINFO_TARGET "$target"
            else
                set target "$def_target"
            end
        else
            set target "$def_target"
        end
    end

    if not set -q _flag_quiet
        if test "$wizard" -eq 1; or set -q _flag_wizard
            set -l mode "NULL Session"
            if set -q _flag_kerberos; set mode "Kerberos"; end
            if test -n "$auth_user"; and test -n "$auth_pass"; set mode "Credentials"; end
            
            set mode (__kronos_ask_choice "Authentication Mode" "$mode" "NULL Session" "Credentials" "Kerberos"); or return 1
            
            if test "$mode" = "Credentials"
                set -l def_auth_user "$__KRONOS_CACHE_DOMINFO_AUTH_USER"
                set -l src_user "Cache"
                if test -z "$def_auth_user"
                    set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                    if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
                end
                set auth_user (__kronos_ask "Auth Username" "$def_auth_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_DOMINFO_AUTH_USER "$auth_user"

                set -l def_auth_val "$__KRONOS_CACHE_DOMINFO_AUTH_PASS"
                set -l src_auth_val "Cache"
                if test -z "$def_auth_val"
                    set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"
                    if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; set src_auth_val "TGT_CRED_PASSWORD"; end
                end
                if test -n "$auth_pass"; set def_auth_val "$auth_pass"; set src_auth_val "CLI Pass"; end
                set auth_pass (__kronos_ask "Auth Password" "$def_auth_val" "$src_auth_val")
                set -U __KRONOS_CACHE_DOMINFO_AUTH_PASS "$auth_pass"
                set -e _flag_NULL
                set -e _flag_kerberos
            else if test "$mode" = "Kerberos"
                set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
                set _flag_kerberos 1
                set -e _flag_NULL
            else
                set _flag_NULL 1
                set -e _flag_kerberos
            end

            if test (__kronos_ask_confirm "Query password policy?" (test "$pass_pol" -eq 1; and echo "y"; or echo "n")) = "yes"
                set pass_pol 1; end
            if test (__kronos_ask_confirm "List domain users?" (test "$list_users" -eq 1; and echo "y"; or echo "n")) = "yes"
                set list_users 1; end
            if test (__kronos_ask_confirm "List domain groups?" (test "$list_groups" -eq 1; and echo "y"; or echo "n")) = "yes"
                set list_groups 1; end
            if test (__kronos_ask_confirm "List logged on users?" (test "$list_loggedon" -eq 1; and echo "y"; or echo "n")) = "yes"
                set list_loggedon 1; end
            if test (__kronos_ask_confirm "List shares?" (test "$list_shares" -eq 1; and echo "y"; or echo "n")) = "yes"
                set list_shares 1; end
        end
    else
        # Quiet mode fallbacks
        if test -z "$auth_user"
            set auth_user "$TGT_USERNAME"
            if test -z "$auth_user"; set auth_user "$TGT_CRED_USERNAME"; end
        end
        if test -z "$auth_pass"
            set auth_pass "$TGT_PASSWORD"
            if test -z "$auth_pass"; set auth_pass "$TGT_CRED_PASSWORD"; end
        end
    end

    if test -z "$target"; echo "error: target is required" >&2; return 1; end

    set -l has_creds 0
    if test -n "$auth_user"; and test -n "$auth_pass"; set has_creds 1; end
    if set -q _flag_kerberos; set has_creds 1; end
    if set -q _flag_NULL; set has_creds 0; end

    if test "$has_creds" -eq 1
        __kronos_check_dep nxc; or return 1
        
        # 1. SMB related enumeration
        if test "$pass_pol" -eq 1 -o "$list_users" -eq 1 -o "$list_loggedon" -eq 1 -o "$list_shares" -eq 1
            set_color yellow; echo "--- [ SECTION: SMB ENUMERATION ] ---"; set_color normal
            set -l nxc_smb_cmd "nxc smb $target"
            if test -n "$TGT_DC_DOMAIN"; set nxc_smb_cmd "$nxc_smb_cmd -d $TGT_DC_DOMAIN"; end
            
            if set -q _flag_kerberos
                set nxc_smb_cmd "$nxc_smb_cmd -k -u \"$auth_user\" -p \"\""
            else
                set nxc_smb_cmd "$nxc_smb_cmd -u \"$auth_user\" -p \"$auth_pass\""
            end

            if test "$pass_pol" -eq 1; set nxc_smb_cmd "$nxc_smb_cmd --pass-pol"; end
            if test "$list_users" -eq 1; set nxc_smb_cmd "$nxc_smb_cmd --users"; end
            if test "$list_loggedon" -eq 1; set nxc_smb_cmd "$nxc_smb_cmd --loggedon-users"; end
            if test "$list_shares" -eq 1; set nxc_smb_cmd "$nxc_smb_cmd --shares"; end
            
            if set -q _flag_edit_cmd
                set nxc_smb_cmd (__kronos_edit_cmd "$nxc_smb_cmd"); or return 1
            end
            eval $nxc_smb_cmd
            echo ""
        end

        # 2. LDAP related enumeration (Groups)
        if test "$list_groups" -eq 1
            set_color yellow; echo "--- [ SECTION: LDAP ENUMERATION (Groups) ] ---"; set_color normal
            set -l nxc_ldap_cmd "nxc ldap $target"
            if test -n "$TGT_DC_DOMAIN"; set nxc_ldap_cmd "$nxc_ldap_cmd -d $TGT_DC_DOMAIN"; end
            
            if set -q _flag_kerberos
                set nxc_ldap_cmd "$nxc_ldap_cmd -k -u \"$auth_user\" -p \"\""
            else
                set nxc_ldap_cmd "$nxc_ldap_cmd -u \"$auth_user\" -p \"$auth_pass\""
            end

            set nxc_ldap_cmd "$nxc_ldap_cmd --groups"

            if set -q _flag_edit_cmd
                set nxc_ldap_cmd (__kronos_edit_cmd "$nxc_ldap_cmd"); or return 1
            end
            eval $nxc_ldap_cmd
            echo ""
        end
    else
        __kronos_check_dep rpcclient; or return 1
        set_color yellow; echo "--- [ SECTION: RPC NULL SESSION ENUMERATION ] ---"; set_color normal
        set -l rpc_cmds "querydominfo"
        if test "$pass_pol" -eq 1; set rpc_cmds "$rpc_cmds; getdompwinfo"; end
        if test "$list_users" -eq 1; set rpc_cmds "$rpc_cmds; enumdomusers"; end
        if test "$list_groups" -eq 1; set rpc_cmds "$rpc_cmds; enumdomgroups"; end
        if test "$list_shares" -eq 1; set rpc_cmds "$rpc_cmds; netshareenum"; end
        
        set -l rpc_cmd "rpcclient -U \"\" -N \"$target\" -c \"$rpc_cmds\""
        
        if set -q _flag_edit_cmd
            set rpc_cmd (__kronos_edit_cmd "$rpc_cmd"); or return 1
        end

        echo "[*] Querying domain info via rpcclient..."
        eval $rpc_cmd
    end
end
