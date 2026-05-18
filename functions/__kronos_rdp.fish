# description: Connect to target using xfreerdp3 (RDP)
function __kronos_rdp --description "Connect to target using xfreerdp3 (RDP)"
    argparse h/help u/username= p/password= H/hash= d/domain= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos rdp [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via RDP using xfreerdp3."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash for PTH"
        echo "  -d, --domain DOMAIN Provide domain (falls back to \$TGT_DC_DOMAIN)"
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

    set -l user $_flag_username
    if test -z "$user"
        set user $TGT_CRED_USERNAME
    end

    set -l domain $_flag_domain
    if test -z "$domain"
        set domain $TGT_DC_DOMAIN
    end

    set -l rdp_bin xfreerdp3
    if not command -v xfreerdp3 >/dev/null
        if command -v xfreerdp >/dev/null
            set rdp_bin xfreerdp
        else
            echo "error: xfreerdp3 or xfreerdp not found in PATH" >&2
            return 1
        end
    end

    set -l rdp_args /v:$target /f /drive:share,$PWD
    if test -n "$user"
        set -a rdp_args /u:$user
    end
    if test -n "$domain"
        set -a rdp_args /d:$domain
    end

    if set -q _flag_hash
        set -a rdp_args /pth:$_flag_hash
    else
        set -l pass $_flag_password
        if test -z "$pass"
            set pass $TGT_CRED_PASSWORD
        end
        if test -n "$pass"
            set -a rdp_args /p:$pass
        end
    end

    echo "[*] Connecting to $target via RDP ($rdp_bin)..."
    command $rdp_bin $rdp_args
end
