# description: Enumerate SIDs for AD objects using lookupsid.py
function __kronos_lookupsid --description "Enumerate SIDs for AD objects using lookupsid.py"
    argparse h/help q/quiet u/username= p/password= H/hash= d/domain= k/kerberos f/filter= D/domain-sid w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos lookupsid [TARGET] [OPTIONS]"
        echo ""
        echo "Enumerate SIDs for AD objects using impacket's lookupsid.py."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -H, --hash HASH     Auth NTLM hash"
        echo "  -d, --domain DOMAIN Target domain"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -f, --filter TEXT   Filter the output"
        echo "  -D, --domain-sid    Only extract Domain SID"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l domain $_flag_domain
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    # Standard Fallbacks & Cache
    if test -z "$target"
        set target $__KRONOS_CACHE_LOOKUPSID_TARGET
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end

    if test -z "$domain"
        set domain $__KRONOS_CACHE_LOOKUPSID_DOMAIN
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    end

    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_LOOKUPSID_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"
        set auth_pass $__KRONOS_CACHE_LOOKUPSID_AUTH_PASS
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    # Interactive Fallback
    if not set -q _flag_quiet
        if test -z "$target"; or test -z "$domain"; or set -q _flag_wizard
            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_LOOKUPSID_TARGET "$target"

            set domain (__kronos_ask "Target Domain" "$domain"); or return 1
            set -U __KRONOS_CACHE_LOOKUPSID_DOMAIN "$domain"
        end
        if test -z "$auth_user"; and not set -q _flag_kerberos
            set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
            set -U __KRONOS_CACHE_LOOKUPSID_AUTH_USER "$auth_user"
        end
    end

    if test -z "$target"; echo "error: target is required" >&2; return 1; end
    if test -z "$domain"; echo "error: domain is required" >&2; return 1; end

    set -l impacket_cmd ""
    if command -v lookupsid.py >/dev/null
        set impacket_cmd lookupsid.py
    else if command -v impacket-lookupsid >/dev/null
        set impacket_cmd impacket-lookupsid
    else
        echo "error: lookupsid not found. run 'kronos install'." >&2
        return 1
    end

    set -l cmd_str "$impacket_cmd"
    if set -q _flag_kerberos
        set cmd_str "$cmd_str -k -no-pass \"$domain/$auth_user\""
    else if set -q _flag_hash
        set cmd_str "$cmd_str -hashes \"$_flag_hash\" \"$domain/$auth_user\""
    else
        if test -z "$auth_user"; or test -z "$auth_pass"
             echo "error: credentials or kerberos flag required" >&2
             return 1
        end
        set cmd_str "$cmd_str \"$domain/$auth_user:$auth_pass\""
    end
    set cmd_str "$cmd_str@$target"

    __kronos_check_dep $impacket_cmd; or return 1

    if set -q _flag_domain_sid
        echo "[*] Retrieving Domain SID from $target..."
        eval "$cmd_str | grep -i 'Domain SID'"
    else if set -q _flag_filter
        echo "[*] Enumerating SIDs and filtering for '$_flag_filter'..."
        eval "$cmd_str | grep -i \"$_flag_filter\""
    else
        echo "[*] Enumerating all SIDs on $target..."
        eval $cmd_str
    end
end
