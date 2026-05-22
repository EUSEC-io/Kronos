# description: Remote command execution via psexec.py
function __kronos_psexec --description "Remote command execution via psexec.py"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse h/help q/quiet u/username= p/password= H/hash= d/domain= k/kerberos X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos psexec [TARGET] [OPTIONS]"
        echo ""
        echo "Remote command execution using impacket's psexec.py."
        echo "NOTE: This is a very loud technique (creates a service and uploads a binary)."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -H, --hash HASH     Auth NTLM hash"
        echo "  -d, --domain DOMAIN Target domain name"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l domain $_flag_domain
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash

    # Load defaults
    if test -z "$target"
        set target $__KRONOS_CACHE_PSEXEC_TARGET
        if test -z "$target"; set target $TGT; end
        if test -z "$target"; set target $TGT_DC_HOST; end
        if test -z "$target"; set target $TGT_HOSTS[1]; end
        if test -z "$target"; set target $TGT_DC_IP; end
    end
    if test -z "$domain"
        set domain $__KRONOS_CACHE_PSEXEC_DOMAIN
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    end
    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_PSEXEC_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"; and test -z "$auth_hash"
        set -l cached_auth "$__KRONOS_CACHE_PSEXEC_AUTH_VAL"
        if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$cached_auth"
            set auth_hash "$cached_auth"
        else
            set auth_pass "$cached_auth"
        end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    if not set -q _flag_quiet
        set_color cyan; echo "[*] Starting PsExec wizard..."; set_color normal

        set target (__kronos_ask "Target IP or FQDN" "$def_target" "$src_target"); or return 1
        set -U __KRONOS_CACHE_PSEXEC_TARGET "$target"

        set domain (__kronos_ask "Domain Name" "$domain"); or return 1
        set -U __KRONOS_CACHE_PSEXEC_DOMAIN "$domain"

        set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
        set -U __KRONOS_CACHE_PSEXEC_AUTH_USER "$auth_user"

        if not set -q _flag_kerberos
            set -l use_krb (__kronos_ask_confirm "Use Kerberos authentication?" n); or return 1
            if test "$use_krb" = "yes"
                set _flag_kerberos 1
            end
        end

        if not set -q _flag_kerberos
            set -l def_auth_val "$auth_pass"
            if test -n "$auth_hash"; set def_auth_val "$auth_hash"; end
            set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val"); or return 1
            set -U __KRONOS_CACHE_PSEXEC_AUTH_VAL "$auth_input"
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set auth_hash "$auth_input"; set auth_pass ""
            else
                set auth_pass "$auth_input"; set auth_hash ""
            end
        end

        # Safety Confirmation
        echo ""
        set_color yellow; echo "WARNING: PsExec is a VERY LOUD technique."; set_color normal
        echo "It will create a service and upload a binary to the target filesystem."
        echo ""
        echo "Configuration:"
        echo "  Target: $target"
        echo "  Domain: $domain"
        echo "  User:   $auth_user"
        echo "  Auth:   "(set -q _flag_kerberos; and echo "Kerberos"; or echo "Password/Hash")
        echo ""
        if test (__kronos_ask_confirm "Proceed with PsExec on $target?" n) != "yes"
            echo "Aborted."
            return 1
        end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$domain"; echo "error: domain is required"; return 1; end
    if test -z "$auth_user"; echo "error: username is required"; return 1; end

    set -l impacket_cmd ""
    if command -v psexec.py >/dev/null; set impacket_cmd psexec.py
    else if command -v impacket-psexec >/dev/null; set impacket_cmd impacket-psexec
    else; echo "error: psexec not found. run 'kronos install'."; return 1; end

    set -l psexec_args -no-pass

    if set -q _flag_kerberos
        # Kerberos mode: avoid dc-ip to prevent realm resolution issues if DNS/TGT context is mixed
        set -a psexec_args -k "$domain/$auth_user@$target"
    else
        # Credentialed mode: dc-ip is helpful
        if test -n "$TGT_DC_IP"; set -a psexec_args -dc-ip "$TGT_DC_IP"
        else if test -n "$TGT_DC"; set -a psexec_args -dc-ip "$TGT_DC"; end

        if test -n "$auth_hash"
            set -a psexec_args -hashes "$auth_hash" "$domain/$auth_user@$target"
        else
            if test -z "$auth_pass"; echo "error: password or hash required"; return 1; end
            set -a psexec_args "$domain/$auth_user:$auth_pass@$target"
        end
    end

    set -l full_cmd "$impacket_cmd "(string join ' ' -- $psexec_args)
    if set -q _flag_edit_cmd
        set full_cmd (__kronos_edit_cmd "$full_cmd"); or return 1
    end

    __kronos_check_dep $impacket_cmd; or return 1
    echo "[*] Executing PsExec via $impacket_cmd..."
    eval $full_cmd
end
