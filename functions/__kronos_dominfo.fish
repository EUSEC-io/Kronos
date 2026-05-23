# description: Query domain info, users, groups, and shares
function __kronos_dominfo --description "Query domain info, users, groups, and shares"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet P/pass-policy U/users G/groups L/loggedon S/shares u/username= p/password= N/NULL k/kerberos X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos dominfo [OPTIONS] [COMMANDS...]"
        echo ""
        echo "Query domain info and enumerate objects using rpcclient or nxc."
        echo ""
        echo "Commands/Options:"
        echo "  -P, --pass-policy, policy     Query password policy"
        echo "  -U, --users, users            List domain users"
        echo "  -G, --groups, groups          List domain groups"
        echo "  -L, --loggedon, loggedon      List logged on users"
        echo "  -S, --shares, shares          List shares"
        echo ""
        echo "General Options:"
        echo "  -t, --target IP               Target DC IP or Hostname"
        echo "  -u, --username USER           Auth username"
        echo "  -p, --password PASS           Auth password"
        echo "  -N, --NULL                    Force NULL session enumeration"
        echo "  -k, --kerberos                Use Kerberos authentication"
        echo "  -X, --edit-cmd                Inspect and edit the command before execution"
        echo "  -q, --quiet                   Skip prompts and use fallbacks"
        echo "  -h, --help                    Show this help message"
        return 0
    end

    set -l target $_flag_target
    # Handle positional target if not provided via -t
    if test -z "$target"; and test (count $argv) -gt 0; and not contains -- "$argv[1]" users groups shares policy loggedon
        set target $argv[1]
        set -e argv[1]
    end

    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    
    # Flags or Positional Commands
    set -l pass_pol 0
    if set -q _flag_pass_policy; or contains policy $argv; set pass_pol 1; end
    set -l list_users 0
    if set -q _flag_users; or contains users $argv; set list_users 1; end
    set -l list_groups 0
    if set -q _flag_groups; or contains groups $argv; set list_groups 1; end
    set -l list_loggedon 0
    if set -q _flag_loggedon; or contains loggedon $argv; set list_loggedon 1; end
    set -l list_shares 0
    if set -q _flag_shares; or contains shares $argv; set list_shares 1; end

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

            # Differential Multi-Select Prompt
            echo "" >&2
            set_color cyan >&2; echo "  Pick Enumeration Sections" >&2; set_color normal >&2
            set_color brblack >&2; echo "    [Space to select/deselect, Enter to confirm]" >&2; set_color normal >&2
            echo "" >&2
            
            set -l enum_choices "Password Policy" "Users" "Groups" "Logged-on Users" "Shares"
            set -l preselected
            if test "$pass_pol" -eq 1; set -a preselected "Password Policy"; end
            if test "$list_users" -eq 1; set -a preselected "Users"; end
            if test "$list_groups" -eq 1; set -a preselected "Groups"; end
            if test "$list_loggedon" -eq 1; set -a preselected "Logged-on Users"; end
            if test "$list_shares" -eq 1; set -a preselected "Shares"; end
            if test (count $preselected) -eq 0; set preselected "Password Policy"; end

            set -l selected (command gum choose --no-limit --selected (string join ',' -- $preselected) $enum_choices)
            set -l rc $status
            if test $rc -ne 0; return $rc; end

            set pass_pol 0; set list_users 0; set list_groups 0; set list_loggedon 0; set list_shares 0
            if contains "Password Policy" $selected; set pass_pol 1; end
            if contains "Users" $selected; set list_users 1; end
            if contains "Groups" $selected; set list_groups 1; end
            if contains "Logged-on Users" $selected; set list_loggedon 1; end
            if contains "Shares" $selected; set list_shares 1; end
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
        
        # Define common base for NXC commands
        set -l nxc_base "nxc smb $target"
        if test -n "$TGT_DC_DOMAIN"; set nxc_base "$nxc_base -d $TGT_DC_DOMAIN"; end
        if set -q _flag_kerberos
            set nxc_base "$nxc_base -k -u \"$auth_user\" -p \"\""
        else
            set nxc_base "$nxc_base -u \"$auth_user\" -p \"$auth_pass\""
        end

        echo ""
        set_color -o yellow; echo ">>> [ SECTION: DOMAIN ENUMERATION ] <<<"; set_color normal

        # Individual Modules with descriptive lines
        if test "$list_shares" -eq 1
            echo ""; set_color cyan; echo "[*] Enumerating Shares Now ...."; set_color normal
            set -l cmd "$nxc_base --shares"
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            eval $cmd
        end

        if test "$list_users" -eq 1
            echo ""; set_color cyan; echo "[*] Enumerating Domain Users Now ...."; set_color normal
            set -l cmd "$nxc_base --users"
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            eval $cmd
        end

        if test "$pass_pol" -eq 1
            echo ""; set_color cyan; echo "[*] Enumerating Password Policy Now ...."; set_color normal
            set -l cmd "$nxc_base --pass-pol"
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            eval $cmd
        end

        if test "$list_loggedon" -eq 1
            echo ""; set_color cyan; echo "[*] Enumerating Logged-on Users Now ...."; set_color normal
            set -l cmd "$nxc_base --loggedon-users"
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            eval $cmd
        end

        if test "$list_groups" -eq 1
            echo ""; set_color cyan; echo "[*] Enumerating Domain Groups Now ...."; set_color normal
            # Groups is better over LDAP
            set -l ldap_base "nxc ldap $target"
            if test -n "$TGT_DC_DOMAIN"; set ldap_base "$ldap_base -d $TGT_DC_DOMAIN"; end
            if set -q _flag_kerberos
                set ldap_base "$ldap_base -k -u \"$auth_user\" -p \"\""
            else
                set ldap_base "$ldap_base -u \"$auth_user\" -p \"$auth_pass\""
            end
            set -l cmd "$ldap_base --groups"
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            eval $cmd
        end
    else
        __kronos_check_dep rpcclient; or return 1
        echo ""
        set_color -o yellow; echo ">>> [ SECTION: RPC NULL SESSION ENUMERATION ] <<<"; set_color normal

        if test "$pass_pol" -eq 1
            echo ""; set_color cyan; echo "[*] Enumerating Password Policy Now ...."; set_color normal
            set -l cmd "rpcclient -U \"\" -N \"$target\" -c \"querydominfo; getdompwinfo\""
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            eval $cmd
        end

        if test "$list_users" -eq 1
            echo ""; set_color cyan; echo "[*] Enumerating Domain Users Now ...."; set_color normal
            set -l cmd "rpcclient -U \"\" -N \"$target\" -c \"enumdomusers\""
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            eval $cmd
        end

        if test "$list_groups" -eq 1
            echo ""; set_color cyan; echo "[*] Enumerating Domain Groups Now ...."; set_color normal
            set -l cmd "rpcclient -U \"\" -N \"$target\" -c \"enumdomgroups\""
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            eval $cmd
        end

        if test "$list_shares" -eq 1
            echo ""; set_color cyan; echo "[*] Enumerating Shares Now ...."; set_color normal
            set -l cmd "rpcclient -U \"\" -N \"$target\" -c \"netshareenum\""
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            eval $cmd
        end
    end
end
