# description: Connect to target using rpcclient (RPC)
function __kronos_rpc --description "Connect to target using rpcclient (RPC)"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet X/edit-cmd u/username= p/password= H/hash= d/domain= k/kerberos N/null w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect rpc [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via RPC using rpcclient."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target DC IP or Hostname"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -H, --hash HASH     Auth NTLM hash"
        echo "  -d, --domain DOMAIN Target domain"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -N, --null          Use a null session"
        echo "  -X, --edit-cmd      Edit command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l auth_user $_flag_username
    set -l domain $_flag_domain
    set -l auth_pass $_flag_password
    set -l hash $_flag_hash

    if not set -q _flag_quiet
        if test (count $argv) -eq 0 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting RPC connection wizard..."; set_color normal
            
            set -l def_target "$__KRONOS_CACHE_RPC_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_RPC_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_RPC_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_RPC_DOMAIN "$domain"

            if not set -q _flag_null; and not set -q _flag_kerberos
                set -l def_user "$__KRONOS_CACHE_RPC_AUTH_USER"
                set -l src_user "Cache"
                if test -z "$def_user"
                    set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                end
                set auth_user (__kronos_ask "Auth Username" "$def_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_RPC_AUTH_USER "$auth_user"

                set -l def_pass "$__KRONOS_CACHE_RPC_AUTH_PASS"
                if test -z "$def_pass"; set def_pass "$TGT_PASSWORD"; end
                set auth_pass (__kronos_ask "Auth Password" "$def_pass"); or return 1
                set -U __KRONOS_CACHE_RPC_AUTH_PASS "$auth_pass"
            end

            set -l def_domain "$__KRONOS_CACHE_RPC_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            set domain (__kronos_ask "Domain" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_RPC_DOMAIN "$domain"
        end
    else
        # Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_RPC_TARGET"; end
        if test -z "$target"; set target "$TGT"; end
        if test -z "$auth_user"; set auth_user "$TGT_USERNAME"; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end

    set -l cmd_list rpcclient "$target"
    if set -q _flag_null
        set -a cmd_list -U "" -N
    else if set -q _flag_kerberos
        set -a cmd_list -k
    else
        if test -n "$hash"
            if test -n "$auth_user"; set -a cmd_list -U "$auth_user"; end
            if test -n "$domain"; set -a cmd_list -W "$domain"; end
            set -a cmd_list --pw-nt-hash "$hash"
        else
            set -l rpc_user "$auth_user"
            if test -n "$auth_pass"; set rpc_user "$auth_user%$auth_pass"; end
            set -a cmd_list -U "$rpc_user"
            if test -n "$domain"; set -a cmd_list -W "$domain"; end
        end
    end

    __kronos_check_dep rpcclient; or return 1
    
    set -l cmd_str (string escape -- $cmd_list | string join " ")
    if set -q _flag_edit_cmd; set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1; end

    echo "[*] Connecting to $target via RPC..."
    eval $cmd_str
end
