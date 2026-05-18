# description: Query domain info and password policy
function __kronos_dominfo --description "Query domain info and password policy"
    argparse h/help P/pass-policy u/username= p/password= N/NULL k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos dominfo [TARGET] [OPTIONS]"
        echo ""
        echo "Query domain info and password policy using rpcclient (null session) or nxc (credentialed)."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC_IP or \$TGT_DC)"
        echo ""
        echo "Options:"
        echo "  -P, --pass-policy   Also query password policy"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -N, --NULL          Force NULL session enumeration"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
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

    set -l user $_flag_username
    if test -z "$user"; set user $TGT_CRED_USERNAME; end

    set -l pass $_flag_password
    if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end

    set -l domain $TGT_DC_DOMAIN

    if not set -q _flag_NULL; and test -n "$user"
        if not command -v nxc >/dev/null
            echo "error: nxc not found. run 'kronos install'." >&2
            return 1
        end

        set -l nxc_cmd nxc smb $target
        if test -n "$domain"; set -a nxc_cmd -d $domain; end
        
        if set -q _flag_kerberos
            set -a nxc_cmd -k -u $user -p ''
        else
            set -a nxc_cmd -u $user -p $pass
        end

        if set -q _flag_pass_policy
            set -a nxc_cmd --pass-pol
        end
        
        echo "[*] Querying dominfo via nxc smb..."
        command $nxc_cmd
    else
        if not command -v rpcclient >/dev/null
            echo "error: rpcclient not found." >&2
            return 1
        end

        set -l rpc_cmds "querydominfo"
        if set -q _flag_pass_policy
            set rpc_cmds "$rpc_cmds; getdompwinfo"
        end
        
        echo "[*] Querying dominfo via rpcclient (null session)..."
        command rpcclient -U "" -N $target -c "$rpc_cmds"
    end
end
