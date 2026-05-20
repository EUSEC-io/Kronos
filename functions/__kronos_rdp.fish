# description: Connect to target using xfreerdp3 (RDP)
function __kronos_rdp --description "Connect to target using xfreerdp3 (RDP)"
    argparse h/help u/username= p/password= H/hash= d/domain= q/quiet w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect rdp [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via RDP using xfreerdp3."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash for PTH"
        echo "  -d, --domain DOMAIN Provide domain (falls back to \$TGT_DC_DOMAIN)"
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l user $_flag_username
    set -l pass $_flag_password
    set -l hash $_flag_hash
    set -l domain $_flag_domain

    if not set -q _flag_quiet
        if set -q _flag_wizard; or test -z "$target"
            set_color cyan; echo "[*] Starting RDP connection wizard..."; set_color normal
            
            set -l def_target "$__KRONOS_CACHE_RDP_TARGET"
            if test -z "$def_target"; set def_target "$TGT"; end
            if test -n "$target"; set def_target "$target"; end
            set target (__kronos_ask "Target IP/Hostname" "$def_target"); or return 1
            set -U __KRONOS_CACHE_RDP_TARGET "$target"

            set -l def_user "$__KRONOS_CACHE_RDP_USER"
            if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; end
            if test -n "$user"; set def_user "$user"; end
            set user (__kronos_ask "Username" "$def_user"); or return 1
            set -U __KRONOS_CACHE_RDP_USER "$user"

            set -l def_domain "$__KRONOS_CACHE_RDP_DOMAIN"
            if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; end
            if test -n "$domain"; set def_domain "$domain"; end
            set domain (__kronos_ask "Domain" "$def_domain"); or return 1
            set -U __KRONOS_CACHE_RDP_DOMAIN "$domain"

            set -l def_auth_val "$__KRONOS_CACHE_RDP_AUTH_VAL"
            if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; end
            if test -n "$pass"; set def_auth_val "$pass"; end
            if test -n "$hash"; set def_auth_val "$hash"; end
            set -l auth_input (__kronos_ask "Password or Hash" "$def_auth_val"); or return 1
            set -U __KRONOS_CACHE_RDP_AUTH_VAL "$auth_input"
            
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set hash "$auth_input"; set pass ""
            else
                set pass "$auth_input"; set hash ""
            end

            set -l def_size "$__KRONOS_CACHE_RDP_SIZE"
            if test -z "$def_size"; set def_size "1920x1080"; end
            set -g _rdp_size (__kronos_ask "Screen Size" "$def_size"); or return 1
            set -U __KRONOS_CACHE_RDP_SIZE "$_rdp_size"

            set -l def_fs "$__KRONOS_CACHE_RDP_FS"
            if test -z "$def_fs"; set def_fs "y"; end
            set -l do_fs (__kronos_ask_confirm "Enable Fullscreen?" "$def_fs"); or return 1
            set -U __KRONOS_CACHE_RDP_FS (string sub -l 1 -- "$do_fs")
            if test "$do_fs" = "yes"; set -g _rdp_fs 1; else; set -g _rdp_fs 0; end

            set -l def_share "$__KRONOS_CACHE_RDP_SHARE"
            if test -z "$def_share"; set def_share "y"; end
            set -l do_share (__kronos_ask_confirm "Share a drive/folder?" "$def_share"); or return 1
            set -U __KRONOS_CACHE_RDP_SHARE (string sub -l 1 -- "$do_share")
            
            if test "$do_share" = "yes"
                set -l def_path "$__KRONOS_CACHE_RDP_PATH"
                if test -z "$def_path"; set def_path "$PWD"; end
                set -g _rdp_path (__kronos_ask "Path to share" "$def_path"); or return 1
                if test "$_rdp_path" = "pwd"; set _rdp_path "$PWD"; end
                set -U __KRONOS_CACHE_RDP_PATH "$_rdp_path"
            else
                set -e _rdp_path
            end
        end
    else
        # Standard Fallbacks from cache/tgt
        if test -z "$target"; set target "$__KRONOS_CACHE_RDP_TARGET"; end
        if test -z "$target"; set target $TGT; end

        if test -z "$user"; set user "$__KRONOS_CACHE_RDP_USER"; end
        if test -z "$user"; set user $TGT_CRED_USERNAME; end

        if test -z "$domain"; set domain "$__KRONOS_CACHE_RDP_DOMAIN"; end
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end

        if test -z "$pass"; and test -z "$hash"
            set -l cached_auth "$__KRONOS_CACHE_RDP_AUTH_VAL"
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$cached_auth"
                set hash "$cached_auth"
            else
                set pass "$cached_auth"
            end
        end
        if test -z "$pass"; and test -z "$hash"; set pass $TGT_CRED_PASSWORD; end

        set -l size "$__KRONOS_CACHE_RDP_SIZE"
        if test -z "$size"; set size "1920x1080"; end
        set -g _rdp_size "$size"

        set -l fs "$__KRONOS_CACHE_RDP_FS"
        if test "$fs" = "n"; set -g _rdp_fs 0; else; set -g _rdp_fs 1; end

        set -l share "$__KRONOS_CACHE_RDP_SHARE"
        if test "$share" = "y"
            set -l p "$__KRONOS_CACHE_RDP_PATH"; if test -z "$p"; set p "$PWD"; end
            set -g _rdp_path "$p"
        else
            set -e _rdp_path
        end
    end

    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    set -l rdp_bin xfreerdp3
    if not command -v xfreerdp3 >/dev/null
        if command -v xfreerdp >/dev/null; set rdp_bin xfreerdp
        else; echo "error: xfreerdp3 not found. run 'kronos install'."; return 1; end
    end

    set -l rdp_args /v:$target /cert:ignore
    if test "$_rdp_fs" -eq 1; set -a rdp_args /f; end
    if test -n "$_rdp_size"; set -a rdp_args /size:$_rdp_size; end
    if test -n "$_rdp_path"; set -a rdp_args /drive:share,$_rdp_path; end
    
    if test -n "$user"; set -a rdp_args /u:$user; end
    if test -n "$domain"; set -a rdp_args /d:$domain; end

    if test -n "$hash"
        set -a rdp_args /pth:$hash
    else if test -n "$pass"
        set -a rdp_args /p:$pass
    end

    echo "[*] Connecting to $target via RDP ($rdp_bin)..."
    __kronos_check_dep $rdp_bin; or return 1
    command $rdp_bin $rdp_args
end
