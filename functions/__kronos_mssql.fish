# description: Connect to target using mssqlclient.py (MSSQL)
function __kronos_mssql --description "Connect to target using mssqlclient.py (MSSQL)"
    argparse h/help u/username= p/password= H/hash= d/domain= k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect mssql [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via MSSQL using impacket's mssqlclient.py."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -d, --domain DOMAIN Provide domain (falls back to \$TGT_DC_DOMAIN)"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"; set target $TGT; end
    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    set -l user $_flag_username
    if test -z "$user"; set user $TGT_CRED_USERNAME; end

    set -l domain $_flag_domain
    if test -z "$domain"; set domain $TGT_DC_DOMAIN; end

    set -l impacket_cmd ""
    if command -v mssqlclient.py >/dev/null
        set impacket_cmd mssqlclient.py
    else if command -v impacket-mssqlclient >/dev/null
        set impacket_cmd impacket-mssqlclient
    else
        echo "error: mssqlclient not found. run 'kronos install'." >&2
        return 1
    end

    set -l mssql_args ""
    if set -q _flag_kerberos
        set -a mssql_args -k -no-pass "$domain/$user@$target"
    else if set -q _flag_hash
        set -a mssql_args -hashes "$_flag_hash" "$domain/$user@$target"
    else
        set -l pass $_flag_password
        if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end
        if test -z "$user"; or test -z "$pass"
             echo "error: credentials or kerberos flag required" >&2
             return 1
        end
        set -a mssql_args "$domain/$user:$pass@$target"
    end

    echo "[*] Connecting to $target via MSSQL ($impacket_cmd)..."
    command $impacket_cmd $mssql_args
end
