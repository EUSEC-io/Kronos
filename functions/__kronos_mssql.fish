# description: Connect to target using mssqlclient.py (MSSQL)
function __kronos_mssql --description "Connect to target using mssqlclient.py (MSSQL)"
    argparse h/help u/username= p/password= H/hash= d/domain= k/kerberos w/wizard -- $argv
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
    set -l user $_flag_username
    set -l domain $_flag_domain
    set -l pass $_flag_password
    set -l hash $_flag_hash

    if set -q _flag_wizard
        set_color cyan; echo "[*] Starting MSSQL connection wizard..."; set_color normal
        
        set -l def_target "$__KRONOS_CACHE_MSSQL_TARGET"
        if test -z "$def_target"; set def_target "$TGT"; end
        if test -n "$target"; set def_target "$target"; end
        set target (__kronos_ask "Target IP/Hostname" "$def_target"); or return 1
        set -U __KRONOS_CACHE_MSSQL_TARGET "$target"

        if not set -q _flag_kerberos
            set -l def_user "$__KRONOS_CACHE_MSSQL_USER"
            if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; end
            if test -n "$user"; set def_user "$user"; end
            set user (__kronos_ask "Username" "$def_user"); or return 1
            set -U __KRONOS_CACHE_MSSQL_USER "$user"

            set -l def_domain "$__KRONOS_CACHE_MSSQL_DOMAIN"
            if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; end
            if test -n "$domain"; set def_domain "$domain"; end
            set domain (__kronos_ask "Domain" "$def_domain"); or return 1
            set -U __KRONOS_CACHE_MSSQL_DOMAIN "$domain"

            set -l def_auth_val "$__KRONOS_CACHE_MSSQL_AUTH_VAL"
            if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; end
            if test -n "$pass"; set def_auth_val "$pass"; end
            if test -n "$hash"; set def_auth_val "$hash"; end
            set -l auth_input (__kronos_ask "Password or Hash" "$def_auth_val"); or return 1
            set -U __KRONOS_CACHE_MSSQL_AUTH_VAL "$auth_input"
            
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set hash "$auth_input"; set pass ""
            else
                set pass "$auth_input"; set hash ""
            end
        end
    else
        # Standard Fallbacks
        if test -z "$target"; set target $TGT; end
        if test -z "$user"; set user $TGT_CRED_USERNAME; end
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    end

    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    set -l impacket_cmd ""
    if command -v mssqlclient.py >/dev/null; set impacket_cmd mssqlclient.py
    else if command -v impacket-mssqlclient >/dev/null; set impacket_cmd impacket-mssqlclient
    else; echo "error: mssqlclient not found. run 'kronos install'."; return 1; end

    set -l mssql_args
    if set -q _flag_kerberos
        set -a mssql_args -k -no-pass "$target"
    else
        if test -n "$TGT_DC_IP"; set -a mssql_args -dc-ip "$TGT_DC_IP"
        else if test -n "$TGT_DC"; set -a mssql_args -dc-ip "$TGT_DC"; end

        if test -n "$hash"
            set -a mssql_args -hashes "$hash" "$domain/$user@$target"
        else
            if test -z "$pass"; set pass $TGT_PASSWORD; end
            if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end
            if test -z "$user"; or test -z "$pass"
                 echo "error: credentials or kerberos flag required" >&2
                 return 1
            end
            set -a mssql_args "$domain/$user:$pass@$target"
        end
    end

    echo "[*] Connecting to $target via MSSQL ($impacket_cmd)..."
    command $impacket_cmd $mssql_args
end
$pass"; set pass $TGT_CRED_PASSWORD; end
            if test -z "$user"; or test -z "$pass"
                 echo "error: credentials or kerberos flag required" >&2
                 return 1
            end
            set -a mssql_args "$domain/$user:$pass@$target"
        end
    end

    echo "[*] Connecting to $target via MSSQL ($impacket_cmd)..."
    command $impacket_cmd $mssql_args
end
