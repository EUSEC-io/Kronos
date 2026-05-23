# description: Connect to target using mssqlclient.py (MSSQL)
function __kronos_mssql --description "Connect to target using mssqlclient.py (MSSQL)"
    argparse h/help u/username= p/password= H/hash= d/domain= q/quiet w/wizard X/edit-cmd k/kerberos -- $argv
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
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -X, --edit-cmd      Edit the command before execution"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l user $_flag_username
    set -l domain $_flag_domain
    set -l pass $_flag_password
    set -l hash $_flag_hash

    if not set -q _flag_quiet
        if set -q _flag_wizard; or test -z "$target"
            set_color cyan; echo "[*] Starting MSSQL connection wizard..."; set_color normal
            
            set -l def_target "$__KRONOS_CACHE_MSSQL_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT"; set src_target "TGT"; end
            end
                if test -z "$def_target"; set def_target "$TGT"; set src_target "TGT"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_MSSQL_TARGET "$target"

            if not set -q _flag_kerberos
                set -l def_user "$__KRONOS_CACHE_MSSQL_USER"
            set -l src_user "Cache"
            if test -z "$def_user"
                set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
            end
            if test -n "$user"; set def_user "$user"; set src_user "CLI Arg"; end
                set user (__kronos_ask "Username" "$def_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_MSSQL_USER "$user"

                set -l def_domain "$__KRONOS_CACHE_MSSQL_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
                set domain (__kronos_ask "Domain" "$def_domain" "$src_domain"); or return 1
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
    else
        # Standard Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_MSSQL_TARGET"; end
        if test -z "$target"; set target $TGT; end

        if test -z "$user"; set user "$__KRONOS_CACHE_MSSQL_USER"; end
        if test -z "$user"; set user $TGT_CRED_USERNAME; end

        if test -z "$domain"; set domain "$__KRONOS_CACHE_MSSQL_DOMAIN"; end
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end

        if test -z "$pass"; and test -z "$hash"
            set -l cached_auth "$__KRONOS_CACHE_MSSQL_AUTH_VAL"
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$cached_auth"
                set hash "$cached_auth"
            else
                set pass "$cached_auth"
            end
        if test -z "$pass"; and test -z "$hash"; set pass $TGT_CRED_PASSWORD; end
    end

    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    set -l impacket_cmd ""
    if command -v mssqlclient.py >/dev/null; set impacket_cmd mssqlclient.py
    else if command -v impacket-mssqlclient >/dev/null; set impacket_cmd impacket-mssqlclient
    else; echo "error: mssqlclient not found. run 'kronos install'."; return 1; end

    __kronos_check_dep $impacket_cmd; or return 1

    set -l mssql_args
    if set -q _flag_kerberos
        set -a mssql_args -k -no-pass "$target"
    else
        if test -n "$TGT_DC_IP"; set -a mssql_args -dc-ip "$TGT_DC_IP"
        else if test -n "$TGT_DC"; set -a mssql_args -dc-ip "$TGT_DC"; end

        if test -n "$hash"
            set -a mssql_args -hashes "$hash" "$domain/$user@$target"
        else
            if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end
            if test -z "$user"; or test -z "$pass"
                 echo "error: credentials or kerberos flag required" >&2
                 return 1
            end
            set -a mssql_args "$domain/$user:$pass@$target"
        end

    set -l cmd_str (string join " " -- command $impacket_cmd (string escape -- $mssql_args))

    if set -q _flag_edit_cmd
        set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1
    end

    if not set -q _flag_quiet
        echo "[*] Connecting to $target via MSSQL ($impacket_cmd)..."
    end

    eval $cmd_str
end