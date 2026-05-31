# description: Connect to target using evil-winrm (WinRM)
function __kronos_winrm --description "Connect to target using evil-winrm (WinRM)"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse h/help X/edit-cmd u/username= p/password= H/hash= k/kerberos q/quiet t/target= w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect winrm [OPTIONS]"
        echo ""
        echo "Connect to a target via WinRM using evil-winrm."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target IP or Hostname"
        echo "  -u, --username USER Provide username"
        echo "  -p, --password PASS Provide password"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -X, --edit-cmd      Edit command before execution"
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l user $_flag_username
    set -l pass $_flag_password
    set -l hash $_flag_hash

    if not set -q _flag_quiet
        if set -q _flag_wizard; or test -z "$target"
            set_color cyan; echo "[*] Starting WinRM connection wizard..."; set_color normal
            
            set -l def_target "$__KRONOS_CACHE_WINRM_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_WINRM_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_WINRM_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_WINRM_DOMAIN "$domain"

            set -l def_user "$__KRONOS_CACHE_WINRM_USER"
            set -l src_user "Cache"
            if test -z "$def_user"
                set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
            end
            if test -n "$user"; set def_user "$user"; set src_user "CLI Arg"; end
            set user (__kronos_ask "Username" "$def_user" "$src_user"); or return 1
            set -U __KRONOS_CACHE_WINRM_USER "$user"

            if not set -q _flag_kerberos
                set -l def_auth_val "$pass"
                if test -n "$hash"; set def_auth_val "$hash"; end
                if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; end
                set -l auth_input (__kronos_ask "Password or Hash" "$def_auth_val"); or return 1
                set -U __KRONOS_CACHE_WINRM_AUTH_VAL "$auth_input"
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set hash "$auth_input"; set pass ""
                else
                    set pass "$auth_input"; set hash ""
                end
            end
        end
    else
        # Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_WINRM_TARGET"; end
        if test -z "$target"; set target "$TGT"; end
        if test -z "$user"; set user "$__KRONOS_CACHE_WINRM_USER"; end
        if test -z "$user"; set user "$TGT_USERNAME"; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end

    __kronos_check_dep evil-winrm; or return 1

    set -l cmd_list evil-winrm -i "$target"
    if test -n "$user"; set -a cmd_list -u "$user"; end

    if set -q _flag_kerberos
        set -a cmd_list -k
        if test -n "$TGT_DC_REALM"; set -a cmd_list -r "$TGT_DC_REALM"; end
        if test -n "$TGT"; set -a cmd_list -ip "$TGT"
        else if test -n "$TGT_DC_IP"; set -a cmd_list -ip "$TGT_DC_IP"; end
    else if test -n "$hash"
        set -a cmd_list -H "$hash"
    else
        if test -n "$pass"; set -a cmd_list -p "$pass"; end
    end

    set -l cmd_str (string escape -- $cmd_list | string join " ")
    if set -q _flag_edit_cmd; set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1; end

    echo "[*] Connecting to $target via WinRM (evil-winrm)..."
    eval $cmd_str
end
