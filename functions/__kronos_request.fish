# description: Request TGT or ST and export KRB5CCNAME
function __kronos_request --description "Request TGT or ST and export KRB5CCNAME"
    argparse h/help u/username= p/password= H/hash= s/spn= d/domain= t/target= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos request [OPTIONS]"
        echo ""
        echo "Request a TGT or ST using impacket's getTGT.py or getST.py."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -s, --spn SPN       Target SPN (for ST request)"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_DC_DOMAIN)"
        echo "  -t, --target DC_IP  DC IP or hostname (falls back to \$TGT_DC_IP or \$TGT_DC)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $TGT_DC_IP; end
    if test -z "$target"; set target $TGT_DC; end
    if test -z "$target"; set target $TGT; end
    if test -z "$target"
        echo "error: target is required (-t)" >&2
        return 1
    end

    set -l domain $_flag_domain
    if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    if test -z "$domain"
        echo "error: domain is required (-d)" >&2
        return 1
    end

    set -l user $_flag_username; if test -z "$user"; set user $TGT_USERNAME; end
    if test -z "$user"; set user $TGT_CRED_USERNAME; end
    
    set -l pass $_flag_password; if test -z "$pass"; set pass $TGT_PASSWORD; end
    if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end

    set -l req_args
    set -l impacket_cmd

    if set -q _flag_spn
        if command -v getST.py >/dev/null
            set impacket_cmd getST.py
        else if command -v impacket-getST >/dev/null
            set impacket_cmd impacket-getST
        else
            echo "error: getST not found. run 'kronos install'." >&2
            return 1
        end

        echo "[*] Requesting Service Ticket for $_flag_spn..."
        set -a req_args -spn "$_flag_spn" -dc-ip "$target"
    else
        if command -v getTGT.py >/dev/null
            set impacket_cmd getTGT.py
        else if command -v impacket-getTGT >/dev/null
            set impacket_cmd impacket-getTGT
        else
            echo "error: getTGT not found. run 'kronos install'." >&2
            return 1
        end

        echo "[*] Requesting Ticket Granting Ticket for $user..."
        set -a req_args -dc-ip "$target"
    end

    if set -q _flag_hash
        set -a req_args -hashes "$_flag_hash" "$domain/$user"
    else
        set -a req_args "$domain/$user:$pass"
    end

    __kronos_check_dep $impacket_cmd; or return 1

    command $impacket_cmd $req_args

    if test -f "$user.ccache"
        set -gx KRB5CCNAME "$PWD/$user.ccache"
        echo "[+] Ticket saved and exported to KRB5CCNAME=$KRB5CCNAME"
    end
end
