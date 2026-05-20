# description: Ingest Active Directory data using bloodhound-python
function __kronos_ingest --description "Ingest Active Directory data using bloodhound-python"
    argparse h/help q/quiet u/username= p/password= o/output= d/domain= k/kerberos w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ingest [TARGET] [OPTIONS]"
        echo ""
        echo "Ingest Active Directory data using bloodhound-python."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -o, --output FILE   Output zip filename"
        echo "  -d, --domain DOMAIN Target domain"
        echo "  -k, --kerberos      Use Kerberos authentication"
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
        set target $__KRONOS_CACHE_INGEST_TARGET
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end

    if test -z "$domain"
        set domain $__KRONOS_CACHE_INGEST_DOMAIN
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    end

    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_INGEST_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"
        set auth_pass $__KRONOS_CACHE_INGEST_AUTH_PASS
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    # Interactive Fallback
    if not set -q _flag_quiet
        if test -z "$target"; or test -z "$domain"; or set -q _flag_wizard
            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_INGEST_TARGET "$target"

            set domain (__kronos_ask "Target Domain" "$domain"); or return 1
            set -U __KRONOS_CACHE_INGEST_DOMAIN "$domain"
        end
        if test -z "$auth_user"; and not set -q _flag_kerberos
            set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
            set -U __KRONOS_CACHE_INGEST_AUTH_USER "$auth_user"
        end
    end

    if test -z "$target"; echo "error: target is required" >&2; return 1; end
    if test -z "$domain"; echo "error: domain is required" >&2; return 1; end

    set -l bh_args -d "$domain" -ns "$target" -c All
    if set -q _flag_kerberos
        set -a bh_args -k
    else
        if test -z "$auth_user"
            echo "error: credentials or kerberos flag required" >&2
            return 1
        end
        set -a bh_args -u "$auth_user" -p "$auth_pass"
    end

    set -l outfile "$domain-bloodhound.zip"
    if set -q _flag_output
        set outfile $_flag_output
    end

    __kronos_check_dep bloodhound-python; or return 1

    echo "[*] Running bloodhound-python against $target ($domain)..."
    command bloodhound-python $bh_args
    set -l bh_status $status

    if test $bh_status -eq 0
        set -l json_files (ls *.json 2>/dev/null)
        if test (count $json_files) -gt 0
            echo "[*] Zipping results into $outfile..."
            zip -m -q "$outfile" *.json
            echo "[+] Successfully created $outfile in "(pwd)
        else
            echo "[!] No JSON files generated."
        end
    else
        echo "error: bloodhound-python encountered an error." >&2
        return 1
    end
end
