# description: Remote command execution via psexec.py
function __kronos_psexec --description "Remote command execution via psexec.py"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet u/username= p/password= H/hash= d/domain= k/kerberos X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos psexec [OPTIONS]"
        echo ""
        echo "Remote command execution using impacket's psexec.py."
        echo "NOTE: This is a very loud technique (creates a service and uploads a binary)."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target IP or Hostname"
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

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l domain $_flag_domain
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting PsExec wizard..."; set_color normal

            set -l def_target "$__KRONOS_CACHE_PSEXEC_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target IP or FQDN" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_PSEXEC_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_PSEXEC_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"; if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_PSEXEC_DOMAIN "$domain"

            set -l def_auth_user "$__KRONOS_CACHE_PSEXEC_AUTH_USER"
            set -l src_user "Cache"
            if test -z "$def_auth_user"
                set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
            end
            if test -n "$auth_user"; set def_auth_user "$auth_user"; set src_user "CLI Arg"; end
            set auth_user (__kronos_ask "Auth Username" "$def_auth_user" "$src_user"); or return 1
            set -U __KRONOS_CACHE_PSEXEC_AUTH_USER "$auth_user"

            if not set -q _flag_kerberos
                set -l use_krb (__kronos_ask_confirm "Use Kerberos authentication?" n); or return 1
                if test "$use_krb" = "yes"
                    set _flag_kerberos 1
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
    else
        # Quiet mode fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_PSEXEC_TARGET"; end
        if test -z "$target"; set target $TGT_HOSTS[1]; end
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end

        if test -z "$domain"; set domain "$__KRONOS_CACHE_PSEXEC_DOMAIN"; end
        if test -z "$domain"; set domain "$TGT_DC_DOMAIN"; end

        if test -z "$auth_user"; set auth_user "$__KRONOS_CACHE_PSEXEC_AUTH_USER"; end
        if test -z "$auth_user"; set auth_user "$TGT_USERNAME"; end
        if test -z "$auth_user"; set auth_user "$TGT_CRED_USERNAME"; end
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
        set -a psexec_args -k "$domain/$auth_user@$target"
    else
        if test -n "$TGT_DC_IP"; set -a psexec_args -dc-ip "$TGT_DC_IP"
        else if test -n "$TGT_DC"; set -a psexec_args -dc-ip "$TGT_DC"; end

        if test -n "$auth_hash"
            set -a psexec_args -hashes "$auth_hash" "$domain/$auth_user@$target"
        else
            if test -z "$auth_pass"; echo "error: password or hash required"; return 1; end
            set -a psexec_args "$domain/$auth_user:$auth_pass@$target"
        end

    set -l full_cmd "$impacket_cmd "(string join ' ' -- $psexec_args)
    if set -q _flag_edit_cmd
        set full_cmd (__kronos_edit_cmd "$full_cmd"); or return 1
    end

    __kronos_check_dep $impacket_cmd; or return 1
    echo "[*] Executing PsExec via $impacket_cmd..."
    eval $full_cmd
end