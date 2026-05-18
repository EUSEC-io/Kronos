# description: Enumerate SIDs for AD objects using impacket-lookupsid
function _kronos_lookupsid --description "Enumerate SIDs for AD objects using impacket-lookupsid"
    argparse h/help u/username= p/password= H/hash= d/domain= k/kerberos f/filter= D/domain-sid -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos lookupsid [TARGET] [OPTIONS]"
        echo ""
        echo "Enumerate SIDs for AD objects using impacket-lookupsid."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC or \$TGT)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username for authentication"
        echo "  -p, --password PASS Provide password for authentication"
        echo "  -H, --hash HASH     Provide NTLM hash for authentication"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_AD_DOMAIN)"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -f, --filter TEXT   Filter the output for a specific object/text"
        echo "  -D, --domain-sid    Only extract and display the Domain SID"
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
            echo "Usage: kronos lookupsid [TARGET] [OPTIONS]" >&2
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

    if not command -s impacket-lookupsid >/dev/null
        echo "Error: impacket-lookupsid not found in PATH." >&2
        return 1
    end

    set -l cmd_str "impacket-lookupsid \"$domain/$auth_user"
    if set -q _flag_kerberos
        set cmd_str "$cmd_str\" -k -no-pass"
    else if test -n "$auth_hash"
        set cmd_str "$cmd_str\" -hashes \"$auth_hash\""
    else
        set cmd_str "$cmd_str:$auth_pass\""
    end
    set cmd_str "$cmd_str@$target"

    if set -q _flag_domain_sid
        echo "Retrieving Domain SID from $target..."
        set cmd_str "$cmd_str | grep -i 'Domain SID'"
    else if set -q _flag_filter
        echo "Enumerating SIDs on $target and filtering for '$_flag_filter'..."
        set cmd_str "$cmd_str | grep -i \"$_flag_filter\""
    else
        echo "Enumerating all SIDs on $target..."
    end

    eval $cmd_str
end
