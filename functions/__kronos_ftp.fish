# description: Connect to target using ftp (FTP)
function __kronos_ftp --description "Connect to target using ftp (FTP)"
    argparse h/help u/username= p/password= w/wizard q/quiet X/edit-cmd -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect ftp [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via FTP."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -X, --edit-cmd      Edit the command before execution"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l user $_flag_username

    if not set -q _flag_quiet
        if set -q _flag_wizard; or test -z "$target"
            set_color cyan; echo "[*] Starting FTP connection wizard..."; set_color normal
            
            set -l def_target "$__KRONOS_CACHE_FTP_TARGET"
            if test -z "$def_target"; set def_target "$TGT"; end
            if test -n "$target"; set def_target "$target"; end
            set target (__kronos_ask "Target IP/Hostname" "$def_target"); or return 1
            set -U __KRONOS_CACHE_FTP_TARGET "$target"

            set -l def_user "$__KRONOS_CACHE_FTP_USER"
            if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; end
            if test -n "$user"; set def_user "$user"; end
            set user (__kronos_ask "Username" "$def_user"); or return 1
            set -U __KRONOS_CACHE_FTP_USER "$user"
        end
    else
        # Standard Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_FTP_TARGET"; end
        if test -z "$target"; set target $TGT; end

        if test -z "$user"; set user "$__KRONOS_CACHE_FTP_USER"; end
        if test -z "$user"; set user $TGT_CRED_USERNAME; end
    end

    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    if not command -v ftp >/dev/null
        echo "error: ftp client not found in PATH" >&2
        return 1
    end

    set -l cmd_str (string join " " -- command ftp (string escape -- $target))

    if set -q _flag_edit_cmd
        set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1
    end

    if not set -q _flag_quiet
        echo "[*] Connecting to $target via FTP..."
        if test -n "$user"
            echo "Note: Use the provided credentials if prompted."
            echo "User: $user"
        end
    
    eval $cmd_str
end