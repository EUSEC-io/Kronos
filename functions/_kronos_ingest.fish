# description: Ingest Active Directory data using bloodhound-python
function _kronos_ingest --description "Ingest Active Directory data using bloodhound-python"
    argparse h/help u/username= p/password= o/output= d/domain= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ingest [TARGET] [OPTIONS]"
        echo ""
        echo "Ingest Active Directory data using bloodhound-python."
        echo ""
        echo "Arguments:"
        echo "  TARGET              DC IP, hostname, or nameserver (falls back to \$TGT_DC or \$TGT)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username for ingestion"
        echo "  -p, --password PASS Provide password for ingestion"
        echo "  -o, --output FILE   Output zip filename (default: <domain>-bloodhound.zip)"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_AD_DOMAIN)"
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
            echo "Usage: kronos ingest [TARGET] [OPTIONS]" >&2
            return 1
        end
    end

    set -l domain ""
    if set -q _flag_domain
        set domain $_flag_domain
    else if test -n "$TGT_AD_DOMAIN"
        set domain $TGT_AD_DOMAIN
    else
        echo "Error: Domain is required. Provide it via -d/--domain or ensure TGT_AD_DOMAIN is set." >&2
        return 1
    end

    set -l has_creds 0
    set -l bh_user ""
    set -l bh_pass ""

    if set -q _flag_username; and set -q _flag_password
        set has_creds 1
        set bh_user $_flag_username
        set bh_pass $_flag_password
    else if set -q _flag_username; or set -q _flag_password
        echo "Error: Both -u/--username and -p/--password must be provided for credentialed ingestion." >&2
        return 1
    else if test -n "$TGT_USERNAME"; and test -n "$TGT_PASSWORD"
        # Fall back to active tgt credentials
        set has_creds 1
        set bh_user $TGT_USERNAME
        set bh_pass $TGT_PASSWORD
    end

    if test "$has_creds" -eq 0
        echo "Error: Credentials are required. Provide them via -u/-p or ensure tgt credentials are active." >&2
        return 1
    end

    set -l outfile "$domain-bloodhound.zip"
    if set -q _flag_output
        set outfile $_flag_output
    end

    if not command -s bloodhound-python >/dev/null
        echo "Error: bloodhound-python not found in PATH." >&2
        return 1
    end

    echo "Running bloodhound-python against $target for domain $domain..."
    bloodhound-python -u "$bh_user" -p "$bh_pass" -d "$domain" -ns "$target" -c All
    set -l bh_status $status

    if test $bh_status -eq 0
        set -l json_files (ls *.json 2>/dev/null)
        if test (count $json_files) -gt 0
            echo "Zipping results into $outfile..."
            zip -m -q "$outfile" *.json
            echo "Successfully created $outfile in "(pwd)
        else
            echo "No JSON files generated."
        end
    else
        echo "bloodhound-python encountered an error."
        return 1
    end
end
