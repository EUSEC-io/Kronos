# description: Connect to target using mssqlclient.py (MSSQL)
function __kronos_mssql --description "Connect to target using mssqlclient.py (MSSQL)"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse h/help X/edit-cmd u/username= p/password= H/hash= d/domain= k/kerberos q/quiet t/target= w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect mssql [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via MSSQL using impacket's mssqlclient.py."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target IP or Hostname"
        echo "  -u, --username USER Provide username"
        echo "  -p, --password PASS Provide password"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -d, --domain DOMAIN Provide domain"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -X, --edit-cmd      Edit command before execution"
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
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
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_MSSQL_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_MSSQL_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_MSSQL_DOMAIN "$domain"

            if not set -q _flag_kerberos
                set -l def_user "$__KRONOS_CACHE_MSSQL_USER"
                set -l src_user "Cache"
                if test -z "$def_user"
                    set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                end
                set user (__kronos_ask "Username" "$def_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_MSSQL_USER "$user"

                set -l def_domain "$__KRONOS_CACHE_MSSQL_DOMAIN"
                set -l src_domain "Cache"
                if test -z "$def_domain"
                    set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                    if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
                end
                set domain (__kronos_ask "Domain" "$def_domain" "$src_domain"); or return 1
                set -U __KRONOS_CACHE_MSSQL_DOMAIN "$domain"

                set -l def_auth_val "$pass"
                if test -n "$hash"; set def_auth_val "$hash"; end
                if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; end
                set -l auth_input (__kronos_ask "Password or Hash" "$def_auth_val"); or return 1
                set -U __KRONOS_CACHE_MSSQL_AUTH_VAL "$auth_input"
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set hash "$auth_input"; set pass ""
                else
                    set pass "$auth_input"; set hash ""
                end
            end
        end
    else
        # Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_MSSQL_TARGET"; end
        if test -z "$target"; set target "$TGT"; end
        if test -z "$user"; set user "$__KRONOS_CACHE_MSSQL_USER"; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end

    set -l impacket_cmd ""
    if command -v mssqlclient.py >/dev/null; set impacket_cmd mssqlclient.py
    else if command -v impacket-mssqlclient >/dev/null; set impacket_cmd impacket-mssqlclient
    else; echo "error: mssqlclient not found."; return 1; end

    set -l cmd_list $impacket_cmd
    if test -n "$domain"; set -a cmd_list -windows-auth; end

    if set -q _flag_kerberos
        set -a cmd_list -k -no-pass "$domain/$user@$target"
    else if test -n "$hash"
        set -a cmd_list -hashes "$hash" "$domain/$user@$target"
    else
        set -a cmd_list "$domain/$user:$pass@$target"
    end

    set -l cmd_str (string join " " -- $cmd_list)
    if set -q _flag_edit_cmd; set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1; end

    __kronos_check_dep $impacket_cmd; or return 1
    echo "[*] Connecting to $target via MSSQL..."
    __kronos_exec "$cmd_str"
end
