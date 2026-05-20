# description: Connect to target using rpcclient (RPC)
function __kronos_rpc --description "Connect to target using rpcclient (RPC)"
    argparse h/help q/quiet u/username= p/password= H/hash= d/domain= k/kerberos N/null w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect rpc [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via RPC using rpcclient."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -H, --hash HASH     Auth NTLM hash"
        echo "  -d, --domain DOMAIN Target domain"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -N, --null          Use a null session"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l auth_user $_flag_username
    set -l domain $_flag_domain
    set -l auth_pass $_flag_password
    set -l hash $_flag_hash

    # Standard Fallbacks & Cache
    if test -z "$target"
        set target $__KRONOS_CACHE_RPC_TARGET
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end

    if test -z "$domain"
        set domain $__KRONOS_CACHE_RPC_DOMAIN
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    end

    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_RPC_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"; and test -z "$hash"
        set auth_pass $__KRONOS_CACHE_RPC_AUTH_PASS
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    # Interactive Fallback
    if not set -q _flag_quiet
        if test -z "$target"; or set -q _flag_wizard
            set target (__kronos_ask "Target IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_RPC_TARGET "$target"
        end
        if not set -q _flag_null; and not set -q _flag_kerberos
             if test -z "$auth_user"; or test -z "$auth_pass"
                set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
                set -U __KRONOS_CACHE_RPC_AUTH_USER "$auth_user"

                set auth_pass (__kronos_ask "Auth Password" "$auth_pass"); or return 1
                set -U __KRONOS_CACHE_RPC_AUTH_PASS "$auth_pass"
             end
        end
    end

    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    set -l rpc_args $target
    
    if set -q _flag_null
        set -a rpc_args -U "" -N
    else if set -q _flag_kerberos
        set -a rpc_args -k
    else
        if test -n "$auth_user"; set -a rpc_args -U "$auth_user"; end
        if test -n "$domain"; set -a rpc_args -W "$domain"; end
        if test -n "$hash"; set -a rpc_args --pw-nt-hash $hash; end
        if test -n "$auth_pass"; and test -z "$hash"
            # rpcclient doesn't have a -p flag easily, it prompts if not provided
            # but we can try to pass it in the -U user%pass format
            set -l rpc_user "$auth_user"
            if test -n "$auth_pass"; set rpc_user "$auth_user%$auth_pass"; end
            # Re-set rpc_args to use this format
            set rpc_args $target -U "$rpc_user"
            if test -n "$domain"; set -a rpc_args -W "$domain"; end
        end
    end

    __kronos_check_dep rpcclient; or return 1

    echo "[*] Connecting to $target via RPC..."
    command rpcclient $rpc_args
end
