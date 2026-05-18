# description: Connect to target using ftp (FTP)
function __kronos_ftp --description "Connect to target using ftp (FTP)"
    argparse h/help u/username= p/password= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ftp [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via FTP."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"
        set target $TGT
    end

    if test -z "$target"
        echo "error: target is required (pass as argument or set \$TGT)" >&2
        return 1
    end

    if not command -v ftp >/dev/null
        echo "error: ftp client not found in PATH" >&2
        return 1
    end

    set -l user $_flag_username
    if test -z "$user"
        set user $TGT_CRED_USERNAME
    end

    echo "[*] Connecting to $target via FTP..."
    if test -n "$user"
        echo "Note: Use the provided credentials if prompted."
        echo "User: $user"
    end
    
    command ftp $target
end
