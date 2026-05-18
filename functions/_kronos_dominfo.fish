# description: Query domain info and password policy
function _kronos_dominfo --description "Query domain info and password policy"
    argparse h/help P/pass-policy u/username= p/password= N/NULL -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos dominfo [TARGET] [OPTIONS]"
        echo ""
        echo "Query domain info and password policy using rpcclient (null session) or nxc (credentialed)."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT or \$TGT_DC)"
        echo ""
        echo "Options:"
        echo "  -P, --pass-policy   Also query password policy"
        echo "  -u, --username USER Provide username for credentialed check (uses nxc)"
        echo "  -p, --password PASS Provide password for credentialed check (uses nxc)"
        echo "  -N, --NULL          Force NULL session enumeration (disables tgt credentials)"
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
            echo "Usage: kronos dominfo [TARGET] [OPTIONS]" >&2
            return 1
        end
    end

    set -l has_creds 0
    if set -q _flag_NULL
        # Explicitly requested NULL session
        set has_creds 0
    else if set -q _flag_username; and set -q _flag_password
        set has_creds 1
    else if set -q _flag_username; or set -q _flag_password
        echo "Error: Both -u/--username and -p/--password must be provided for credentialed enumeration." >&2
        return 1
    else if test -n "$TGT_USERNAME"; and test -n "$TGT_PASSWORD"
        # Fall back to active tgt credentials
        set has_creds 1
        set _flag_username $TGT_USERNAME
        set _flag_password $TGT_PASSWORD
    end

    if test "$has_creds" -eq 1
        if not command -s nxc >/dev/null
            echo "Error: nxc (NetExec) not found in PATH." >&2
            return 1
        end
        echo "Using nxc smb for credentialed enumeration against $target..."
        set -l nxc_cmd nxc smb $target -u $_flag_username -p $_flag_password
        
        # Add domain if available, otherwise nxc defaults to local/target name sometimes
        if test -n "$TGT_AD_DOMAIN"
            set nxc_cmd $nxc_cmd -d $TGT_AD_DOMAIN
        end

        if set -q _flag_pass_policy
            set nxc_cmd $nxc_cmd --pass-pol
        end
        
        eval $nxc_cmd
    else
        if not command -s rpcclient >/dev/null
            echo "Error: rpcclient not found in PATH." >&2
            return 1
        end
        echo "Using rpcclient with null session against $target..."
        set -l rpc_cmds "querydominfo"
        if set -q _flag_pass_policy
            set rpc_cmds "$rpc_cmds; getdompwinfo"
        end
        
        rpcclient -U "" -N $target -c "$rpc_cmds"
    end
end
