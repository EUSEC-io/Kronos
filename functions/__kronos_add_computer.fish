# description: Create a new AD computer account using addcomputer.py
function __kronos_add_computer --description "Create a new AD computer account using addcomputer.py"
    argparse h/help u/username= p/password= H/hash= k/kerberos C/computer= P/computer-pass= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos add-computer [TARGET] [OPTIONS]"
        echo ""
        echo "Create a new Active Directory computer account using impacket's addcomputer.py."
        echo ""
        echo "Options:"
        echo "  -C, --computer NAME     The name of the new computer account"
        echo "  -P, --computer-pass PASS The password for the new computer"
        echo "  -u, --username USER     Auth username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS     Auth password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH         Auth NTLM hash"
        echo "  -k, --kerberos          Use Kerberos authentication"
        echo "  -h, --help              Show this help message"
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

    if not set -q _flag_computer
        echo "error: --computer name is required" >&2
        return 1
    end

    set -l domain $TGT_DC_DOMAIN
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN is not set" >&2
        return 1
    end

    set -l impacket_cmd ""
    if command -v addcomputer.py >/dev/null
        set impacket_cmd addcomputer.py
    else if command -v impacket-addcomputer >/dev/null
        set impacket_cmd impacket-addcomputer
    else
        echo "error: addcomputer.py not found. run 'kronos install'." >&2
        return 1
    end

    set -l add_args -dc-ip "$target"
    if set -q _flag_computer_pass
        set -a add_args -computer-pass "$_flag_computer_pass"
    end
    set -a add_args -computer-name "$_flag_computer"

    if set -q _flag_kerberos
        set -a add_args -k -no-pass "$domain/$TGT_CRED_USERNAME"
    else
        set -l auth_user $_flag_username; if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end

        set -l auth_pass $_flag_password; if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end

        if set -q _flag_hash
            set -a add_args -hashes "$_flag_hash" "$domain/$auth_user"
        else
            set -a add_args "$domain/$auth_user:$auth_pass"
        end
    end

    echo "[*] Creating computer account $_flag_computer via $impacket_cmd..."
    command $impacket_cmd $add_args
end
