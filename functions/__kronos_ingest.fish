# description: Ingest Active Directory data using bloodhound-python
function __kronos_ingest --description "Ingest Active Directory data using bloodhound-python"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet u/username= p/password= H/hash= o/output= d/domain= k/kerberos X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos ingest [TARGET] [OPTIONS]"
        echo ""
        echo "Ingest Active Directory data using bloodhound-python."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target IP or Hostname"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -H, --hash HASH     Auth NTLM hash"
        echo "  -o, --output FILE   Output zip filename"
        echo "  -d, --domain DOMAIN Target domain"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l domain $_flag_domain
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash
    set -l outfile $_flag_output

    # Load defaults
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
    if test -z "$auth_pass"; and test -z "$auth_hash"
        set -l cached_auth "$__KRONOS_CACHE_INGEST_AUTH_VAL"
        if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$cached_auth"
            set auth_hash "$cached_auth"
        else
            set auth_pass "$cached_auth"
        end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting Ingest wizard..."; set_color normal

            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_INGEST_TARGET "$target"

            set domain (__kronos_ask "Domain Name" "$domain"); or return 1
            set -U __KRONOS_CACHE_INGEST_DOMAIN "$domain"

            if not set -q _flag_kerberos
                set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
                set -U __KRONOS_CACHE_INGEST_AUTH_USER "$auth_user"

                set -l def_auth_val "$auth_pass"
                if test -n "$auth_hash"; set def_auth_val "$auth_hash"; end
                set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val"); or return 1
                set -U __KRONOS_CACHE_INGEST_AUTH_VAL "$auth_input"
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set auth_hash "$auth_input"; set auth_pass ""
                else
                    set auth_pass "$auth_input"; set auth_hash ""
                end
            end

            set -l def_out "$domain-bloodhound.zip"
            if test -n "$outfile"; set def_out "$outfile"; end
            set outfile (__kronos_ask "Output Zip Name" "$def_out"); or return 1
        end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$domain"; echo "error: domain is required"; return 1; end
    if test -z "$outfile"; set outfile "$domain-bloodhound.zip"; end

    set -l bh_cmd "bloodhound-python -d \"$domain\" -ns \"$target\" -c All"
    if set -q _flag_kerberos
        set bh_cmd "$bh_cmd -k"
    else
        if test -z "$auth_user"
            echo "error: username is required"; return 1
        end
        set bh_cmd "$bh_cmd -u \"$auth_user\""
        if test -n "$auth_hash"
            set bh_cmd "$bh_cmd --hashes \"$auth_hash\""
        else
            set bh_cmd "$bh_cmd -p \"$auth_pass\""
        end
    end

    if set -q _flag_edit_cmd
        set bh_cmd (__kronos_edit_cmd "$bh_cmd"); or return 1
    end

    __kronos_check_dep bloodhound-python; or return 1

    echo "[*] Running bloodhound-python against $target ($domain)..."
    eval $bh_cmd
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
