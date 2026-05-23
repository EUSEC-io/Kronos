# description: Connect to target using ftp (FTP)
function __kronos_ftp --description "Connect to target using ftp (FTP)"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help X/edit-cmd u/username= p/password= q/quiet w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect ftp [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via FTP."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target IP or Hostname"
        echo "  -u, --username USER Provide username"
        echo "  -p, --password PASS Provide password"
        echo "  -X, --edit-cmd      Edit command before execution"
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l user $_flag_username
    set -l pass $_flag_password

    if not set -q _flag_quiet
        if set -q _flag_wizard; or test -z "$target"
            set_color cyan; echo "[*] Starting FTP connection wizard..."; set_color normal
            
            set -l def_target "$__KRONOS_CACHE_FTP_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_FTP_TARGET "$target"

            set -l def_user "$__KRONOS_CACHE_FTP_USER"
            set -l src_user "Cache"
            if test -z "$def_user"; set def_user "anonymous"; set src_user "Default"; end
            if test -n "$user"; set def_user "$user"; set src_user "CLI Arg"; end
            set user (__kronos_ask "Username" "$def_user" "$src_user"); or return 1
            set -U __KRONOS_CACHE_FTP_USER "$user"

            set -l def_pass "$__KRONOS_CACHE_FTP_PASS"
            if test -z "$def_pass"; set def_pass "anonymous"; end
            if test -n "$pass"; set def_pass "$pass"; end
            set pass (__kronos_ask "Password" "$def_pass"); or return 1
            set -U __KRONOS_CACHE_FTP_PASS "$pass"
        end
    else
        # Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_FTP_TARGET"; end
        if test -z "$target"; set target "$TGT"; end
        if test -z "$user"; set user "$__KRONOS_CACHE_FTP_USER"; end
        if test -z "$user"; set user "anonymous"; end
        if test -z "$pass"; set pass "$__KRONOS_CACHE_FTP_PASS"; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end

    __kronos_check_dep ftp; or return 1

    set -l cmd_str "ftp $target"
    if set -q _flag_edit_cmd; set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1; end

    echo "[*] Connecting to $target via FTP..."
    echo "Note: Use user '$user' and password '$pass'"
    eval $cmd_str
end
