# description: Ingest Active Directory data using bloodhound-python
function __kronos_ingest --description "Ingest Active Directory data using bloodhound-python"
    argparse h/help u/username= p/password= o/output= d/domain= k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ingest [TARGET] [OPTIONS]"
        echo ""
        echo "Ingest Active Directory data using bloodhound-python."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC_IP or \$TGT_DC)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -o, --output FILE   Output zip filename (default: <domain>-bloodhound.zip)"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_DC_DOMAIN)"
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

    set -l domain $_flag_domain
    if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    
    if test -z "$domain"
        echo "error: domain is required (pass -d or set \$TGT_DC_DOMAIN)" >&2
        return 1
    end

    set -l user $_flag_username; if test -z "$user"; set user $TGT_USERNAME; end
    if test -z "$user"; set user $TGT_CRED_USERNAME; end
    
    set -l pass $_flag_password; if test -z "$pass"; set pass $TGT_PASSWORD; end
    if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end

    if not command -v bloodhound-python >/dev/null
        echo "error: bloodhound-python not found. run 'kronos install'." >&2
        return 1
    end

    set -l bh_args -d "$domain" -ns "$target" -c All
    if set -q _flag_kerberos
        set -a bh_args -k
    else
        if test -z "$user"
            echo "error: credentials or kerberos flag required" >&2
            return 1
        end
        set -a bh_args -u "$user" -p "$pass"
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
