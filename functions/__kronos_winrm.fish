# description: Connect to target using evil-winrm (WinRM)
function __kronos_winrm --description "Connect to target using evil-winrm (WinRM)"
    argparse h/help u/username= p/password= H/hash= k/kerberos w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect winrm [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via WinRM using evil-winrm."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l user $_flag_username
    set -l pass $_flag_password
    set -l hash $_flag_hash

    if set -q _flag_wizard
        set_color cyan; echo "[*] Starting WinRM connection wizard..."; set_color normal
        
        set -l def_target "$__KRONOS_CACHE_WINRM_TARGET"
        if test -z "$def_target"; set def_target $TGT_DC_IP; end
        if test -z "$def_target"; set def_target $TGT_DC; end
        if test -z "$def_target"; set def_target "$TGT"; end
        if test -n "$target"; set def_target "$target"; end
        set target (__kronos_ask "Target IP/Hostname" "$def_target"); or return 1
        set -U __KRONOS_CACHE_WINRM_TARGET "$target"

        set -l def_user "$__KRONOS_CACHE_WINRM_USER"
        if test -z "$def_user"; set def_user $TGT_USERNAME; end
        if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; end
        if test -n "$user"; set def_user "$user"; end
        set user (__kronos_ask "Username" "$def_user"); or return 1
        set -U __KRONOS_CACHE_WINRM_USER "$user"

        if not set -q _flag_kerberos
            set -l def_auth_val "$__KRONOS_CACHE_WINRM_AUTH_VAL"
            if test -z "$def_auth_val"; set def_auth_val $TGT_PASSWORD; end
            if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; end
            if test -n "$pass"; set def_auth_val "$pass"; end
            if test -n "$hash"; set def_auth_val "$hash"; end
            set -l auth_input (__kronos_ask "Password or Hash" "$def_auth_val"); or return 1
            set -U __KRONOS_CACHE_WINRM_AUTH_VAL "$auth_input"
            
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set hash "$auth_input"; set pass ""
            else
                set pass "$auth_input"; set hash ""
            end
        end
    else
        # Standard Fallbacks
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
        
        if test -z "$user"; set user $TGT_USERNAME; end
        if test -z "$user"; set user $TGT_CRED_USERNAME; end
    end

    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    if not command -v evil-winrm >/dev/null
        echo "error: evil-winrm not found. run 'kronos install'." >&2
        return 1
    end

    set -l winrm_args -i $target
    if test -n "$user"; set -a winrm_args -u $user; end

    if set -q _flag_kerberos
        set -a winrm_args -k
        if test -n "$TGT_DC_REALM"; set -a winrm_args -r "$TGT_DC_REALM"; end
        if test -n "$TGT_DC_IP"; set -a winrm_args -ip "$TGT_DC_IP"
        else if test -n "$TGT_DC"; set -a winrm_args -ip "$TGT_DC"; end
    else if test -n "$hash"
        set -a winrm_args -H $hash
    else
        if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end
        if test -n "$pass"; set -a winrm_args -p $pass; end
    end

    echo "[*] Connecting to $target via WinRM (evil-winrm)..."
    __kronos_check_dep evil-winrm; or return 1
    command evil-winrm $winrm_args
end
