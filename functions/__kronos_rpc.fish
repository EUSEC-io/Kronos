# description: Connect to target using rpcclient (RPC)
function __kronos_rpc --description "Connect to target using rpcclient (RPC)"
    argparse h/help u/username= p/password= H/hash= d/domain= k/kerberos N/null -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos rpc [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via RPC using rpcclient."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -d, --domain DOMAIN Provide domain (falls back to \$TGT_DC_DOMAIN)"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -N, --null          Use a null session"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"
        set target $TGT
    end

    if test -z "$target"
        echo "error: target is required (pass as argument or set \$TGT)" >&2
        return 1
    end

    if not command -v rpcclient >/dev/null
        echo "error: rpcclient not found in PATH" >&2
        return 1
    end

    set -l rpc_args $target
    
    if set -q _flag_null
        set -a rpc_args -U "" -N
    else if set -q _flag_kerberos
        set -a rpc_args -k
    else
        set -l user $_flag_username
        if test -z "$user"
            set user $TGT_CRED_USERNAME
        end
        if test -n "$user"
            set -a rpc_args -U "$user"
        end

        set -l domain $_flag_domain
        if test -z "$domain"
            set domain $TGT_DC_DOMAIN
        end
        if test -n "$domain"
            set -a rpc_args -W "$domain"
        end

        if set -q _flag_hash
            set -a rpc_args --pw-nt-hash $_flag_hash
        end
    end

    echo "[*] Connecting to $target via RPC..."
    command rpcclient $rpc_args
end
