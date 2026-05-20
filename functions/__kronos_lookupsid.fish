# description: Enumerate SIDs for AD objects using lookupsid.py
function __kronos_lookupsid --description "Enumerate SIDs for AD objects using lookupsid.py"
    argparse h/help u/username= p/password= H/hash= d/domain= k/kerberos f/filter= D/domain-sid -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos lookupsid [TARGET] [OPTIONS]"
        echo ""
        echo "Enumerate SIDs for AD objects using impacket's lookupsid.py."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC_IP or \$TGT_DC)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username for authentication (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password for authentication (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash for authentication"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_DC_DOMAIN)"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -f, --filter TEXT   Filter the output for a specific object/text"
        echo "  -D, --domain-sid    Only extract and display the Domain SID"
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
        echo "error: domain is required (-d)" >&2
        return 1
    end

    set -l user $_flag_username; if test -z "$user"; set user $TGT_USERNAME; end
    if test -z "$user"; set user $TGT_CRED_USERNAME; end
    
    set -l pass $_flag_password; if test -z "$pass"; set pass $TGT_PASSWORD; end
    if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end

    set -l impacket_cmd ""
    if command -v lookupsid.py >/dev/null
        set impacket_cmd lookupsid.py
    else if command -v impacket-lookupsid >/dev/null
        set impacket_cmd impacket-lookupsid
    else
        echo "error: lookupsid not found. run 'kronos install'." >&2
        return 1
    end

    set -l cmd_str "$impacket_cmd"
    if set -q _flag_kerberos
        set cmd_str "$cmd_str -k -no-pass \"$domain/$user\""
    else if set -q _flag_hash
        set cmd_str "$cmd_str -hashes \"$_flag_hash\" \"$domain/$user\""
    else
        if test -z "$user"; or test -z "$pass"
             echo "error: credentials or kerberos flag required" >&2
             return 1
        end
        set cmd_str "$cmd_str \"$domain/$user:$pass\""
    end
    set cmd_str "$cmd_str@$target"

    if set -q _flag_domain_sid
        echo "[*] Retrieving Domain SID from $target..."
        eval "$cmd_str | grep -i 'Domain SID'"
    else if set -q _flag_filter
        echo "[*] Enumerating SIDs and filtering for '$_flag_filter'..."
        eval "$cmd_str | grep -i \"$_flag_filter\""
    else
        echo "[*] Enumerating all SIDs on $target..."
        eval $cmd_str
    end
end
