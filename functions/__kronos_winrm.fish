# description: Connect to target using evil-winrm (WinRM)
function __kronos_winrm --description "Connect to target using evil-winrm (WinRM)"
    argparse h/help u/username= p/password= H/hash= k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos winrm [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via WinRM using evil-winrm."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"; set target $TGT; end

    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    set -l user $_flag_username
    if test -z "$user"; set user $TGT_CRED_USERNAME; end

    if not command -v evil-winrm >/dev/null
        echo "error: evil-winrm not found. run 'kronos install'." >&2
        return 1
    end

    set -l winrm_args -i $target
    if test -n "$user"; set -a winrm_args -u $user; end

    if set -q _flag_kerberos
        set -a winrm_args -k
        if test -n "$TGT_DC_REALM"; set -a winrm_args -r "$TGT_DC_REALM"; end
        
        # Support DC targeting
        if test -n "$TGT_DC_IP"; set -a winrm_args -ip "$TGT_DC_IP"
        else if test -n "$TGT_DC"; set -a winrm_args -ip "$TGT_DC"; end
    else if set -q _flag_hash
        set -a winrm_args -H $_flag_hash
    else
        set -l pass $_flag_password
        if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end
        if test -n "$pass"; set -a winrm_args -p $pass; end
    end

    echo "[*] Connecting to $target via WinRM (evil-winrm)..."
    command evil-winrm $winrm_args
end
