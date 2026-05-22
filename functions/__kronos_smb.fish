# description: Connect to target using smbclient (SMB)
function __kronos_smb --description "Connect to target using smbclient (SMB)"
    argparse h/help X/edit-cmd u/username= p/password= H/hash= d/domain= k/kerberos s/share= q/quiet w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect smb [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via SMB using smbclient."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash (requires -u)"
        echo "  -d, --domain DOMAIN Provide domain (falls back to \$TGT_DC_DOMAIN)"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -s, --share SHARE   Target share (default: C\$)"
        echo "  -X, --edit-cmd      Edit command in your editor before execution"
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l user $_flag_username
    set -l domain $_flag_domain
    set -l pass $_flag_password
    set -l hash $_flag_hash
    set -l share $_flag_share

    if not set -q _flag_quiet
        if set -q _flag_wizard; or test -z "$target"
            set_color cyan; echo "[*] Starting SMB connection wizard..."; set_color normal
            
            set -l def_target "$__KRONOS_CACHE_SMB_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT"; set src_target "TGT"; end
            end
                if test -z "$def_target"; set def_target "$TGT"; set src_target "TGT"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_SMB_TARGET "$target"

            set -l def_share "$__KRONOS_CACHE_SMB_SHARE"
            set -l src_share "Cache"
            if test -z "$def_share"
                
            end
            if test -n "$share"; set def_share "$share"; set src_share "CLI Arg"; end
            set share (__kronos_ask "Target Share" "$def_share" "$src_share"); or return 1
            set -U __KRONOS_CACHE_SMB_SHARE "$share"

            if not set -q _flag_kerberos
                set -l def_user "$__KRONOS_CACHE_SMB_USER"
            set -l src_user "Cache"
            if test -z "$def_user"
                set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
            end
            if test -n "$user"; set def_user "$user"; set src_user "CLI Arg"; end
                set user (__kronos_ask "Username" "$def_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_SMB_USER "$user"

                set -l def_domain "$__KRONOS_CACHE_SMB_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
                set domain (__kronos_ask "Domain/Workgroup" "$def_domain" "$src_domain"); or return 1
                set -U __KRONOS_CACHE_SMB_DOMAIN "$domain"

                set -l def_auth_val "$__KRONOS_CACHE_SMB_AUTH_VAL"
                if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; end
                if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; end
                if test -n "$pass"; set def_auth_val "$pass"; end
                if test -n "$hash"; set def_auth_val "$hash"; end
                set -l auth_input (__kronos_ask "Password or Hash" "$def_auth_val"); or return 1
                set -U __KRONOS_CACHE_SMB_AUTH_VAL "$auth_input"
                
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set hash "$auth_input"; set pass ""
                else
                    set pass "$auth_input"; set hash ""
                end
            end
        end
    end

    # Standard Fallbacks
    if test -z "$target"; set target "$__KRONOS_CACHE_SMB_TARGET"; end
    if test -z "$target"; set target $TGT; end

    if test -z "$share"; set share "$__KRONOS_CACHE_SMB_SHARE"; end
    if test -z "$share"; set share "C\$"; end

    if not set -q _flag_kerberos
        if test -z "$user"; set user "$__KRONOS_CACHE_SMB_USER"; end
        if test -z "$user"; set user $TGT_USERNAME; end
        if test -z "$user"; set user $TGT_CRED_USERNAME; end

        if test -z "$domain"; set domain "$__KRONOS_CACHE_SMB_DOMAIN"; end
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end

        if test -z "$pass"; and test -z "$hash"
            set -l cached_auth "$__KRONOS_CACHE_SMB_AUTH_VAL"
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$cached_auth"
                set hash "$cached_auth"
            else
                set pass "$cached_auth"
            end
        end
        if test -z "$pass"; and test -z "$hash"; set pass $TGT_PASSWORD; end
        if test -z "$pass"; and test -z "$hash"; set pass $TGT_CRED_PASSWORD; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end

    __kronos_check_dep smbclient; or return 1

    set -l cmd_list smbclient "//$target/$share"
    if set -q _flag_kerberos
        set -a cmd_list -k
    else
        if test -n "$user"; set -a cmd_list -U "$user" ; end
        if test -n "$domain"; set -a cmd_list -W "$domain"; end
        if test -n "$hash"
            set -a cmd_list --pw-nt-hash "$hash"
        end
        # Note: smbclient prompts for password if not provided in -U user%pass
    end

    set -l cmd_str (string escape -- $cmd_list | string join " ")

    if set -q _flag_edit_cmd
        set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1
    end

    echo "[*] Connecting to //$target/$share via SMB..."
    eval $cmd_str
end
