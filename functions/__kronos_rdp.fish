# description: Connect to target using xfreerdp3 (RDP)
function __kronos_rdp --description "Connect to target using xfreerdp3 (RDP)"
    argparse t/target= h/help X/edit-cmd u/username= p/password= H/hash= d/domain= q/quiet w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect rdp [OPTIONS]"
        echo ""
        echo "Connect to a target via RDP using xfreerdp3."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target IP or Hostname"
        echo "  -u, --username USER Provide username"
        echo "  -p, --password PASS Provide password"
        echo "  -H, --hash HASH     Provide NTLM hash for PTH"
        echo "  -d, --domain DOMAIN Provide domain"
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
    set -l domain $_flag_domain

    if not set -q _flag_quiet
        if set -q _flag_wizard; or test -z "$target"
            set_color cyan; echo "[*] Starting RDP connection wizard..."; set_color normal
            
            set -l def_target "$__KRONOS_CACHE_RDP_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_RDP_TARGET "$target"

            set -l def_user "$__KRONOS_CACHE_RDP_USER"
            set -l src_user "Cache"
            if test -z "$def_user"
                set def_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"
            end
            if test -n "$user"; set def_user "$user"; set src_user "CLI Arg"; end
            set user (__kronos_ask "Username" "$def_user" "$src_user"); or return 1
            set -U __KRONOS_CACHE_RDP_USER "$user"

            set -l def_domain "$__KRONOS_CACHE_RDP_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_RDP_DOMAIN "$domain"

            set -l def_auth_val "$__KRONOS_CACHE_RDP_AUTH_VAL"
            if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; end
            set -l auth_input (__kronos_ask "Password or Hash" "$def_auth_val"); or return 1
            set -U __KRONOS_CACHE_RDP_AUTH_VAL "$auth_input"
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set hash "$auth_input"; set pass ""
            else
                set pass "$auth_input"; set hash ""
            end
        end
    else
        # Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_RDP_TARGET"; end
        if test -z "$target"; set target "$TGT"; end
        if test -z "$user"; set user "$__KRONOS_CACHE_RDP_USER"; end
        if test -z "$user"; set user "$TGT_CRED_USERNAME"; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end

    set -l rdp_bin xfreerdp3
    if not command -v xfreerdp3 >/dev/null
        if command -v xfreerdp >/dev/null; set rdp_bin xfreerdp
        else; echo "error: xfreerdp3 not found."; return 1; end
    end

    set -l cmd_list $rdp_bin /v:"$target" /cert:ignore /size:1920x1080 /f /drive:share,"$PWD"
    if test -n "$user"; set -a cmd_list /u:"$user"; end
    if test -n "$domain"; set -a cmd_list /d:"$domain"; end
    if test -n "$hash"
        set -a cmd_list /pth:"$hash"
    else if test -n "$pass"
        set -a cmd_list /p:"$pass"
    end

    set -l cmd_str (string escape -- $cmd_list | string join " ")
    if set -q _flag_edit_cmd; set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1; end

    echo "[*] Connecting to $target via RDP ($rdp_bin)..."
    __kronos_check_dep $rdp_bin; or return 1
    eval $cmd_str
end
