# description: Create a new AD computer account using addcomputer.py
function __kronos_add_computer --description "Create a new AD computer account using addcomputer.py"
    argparse h/help u/username= p/password= H/hash= k/kerberos C/computer= P/computer-pass= q/quiet w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos add-computer [TARGET] [OPTIONS]"
        echo ""
        echo "Create a new Active Directory computer account using impacket's addcomputer.py."
        echo ""
        echo "Options:"
        echo "  -C, --computer NAME     The name of the new computer account"
        echo "  -P, --computer-pass PASS The password for the new computer"
        echo "  -u, --username USER     Auth username"
        echo "  -p, --password PASS     Auth password"
        echo "  -H, --hash HASH         Auth NTLM hash"
        echo "  -k, --kerberos          Use Kerberos authentication"
        echo "  -q, --quiet             Skip all prompts and use fallbacks/cached values"
        echo "  -h, --help              Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l computer $_flag_computer
    set -l computer_pass $_flag_computer_pass
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash

    # Load defaults
    if test -z "$target"
        set target $__KRONOS_CACHE_ADDCOMP_TARGET
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end
    if test -z "$computer"; set computer $__KRONOS_CACHE_ADDCOMP_NAME; end
    if test -z "$computer_pass"; set computer_pass $__KRONOS_CACHE_ADDCOMP_PASS; end
    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_ADDCOMP_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"; and test -z "$auth_hash"
        set -l cached_auth "$__KRONOS_CACHE_ADDCOMP_AUTH_VAL"
        if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$cached_auth"
            set auth_hash "$cached_auth"
        else
            set auth_pass "$cached_auth"
        end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    if not set -q _flag_quiet
        set_color cyan; echo "[*] Starting Add Computer wizard..."; set_color normal

        set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
        set -U __KRONOS_CACHE_ADDCOMP_TARGET "$target"

        set computer (__kronos_ask "Computer Name" "$computer"); or return 1
        set -U __KRONOS_CACHE_ADDCOMP_NAME "$computer"

        set computer_pass (__kronos_ask "Computer Password (optional)" "$computer_pass")
        set -U __KRONOS_CACHE_ADDCOMP_PASS "$computer_pass"

        if not set -q _flag_kerberos
            set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
            set -U __KRONOS_CACHE_ADDCOMP_AUTH_USER "$auth_user"

            set -l def_auth_val "$auth_pass"
            if test -n "$auth_hash"; set def_auth_val "$auth_hash"; end
            set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val"); or return 1
            set -U __KRONOS_CACHE_ADDCOMP_AUTH_VAL "$auth_input"
            
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set auth_hash "$auth_input"; set auth_pass ""
            else
                set auth_pass "$auth_input"; set auth_hash ""
            end
        end

        # Confirmation
        echo ""
        echo "Configuration:"
        echo "  Target:   $target"
        echo "  Computer: $computer"
        echo "  Auth:     "(set -q _flag_kerberos; and echo "Kerberos"; or echo "$auth_user")
        echo ""
        if test (__kronos_ask_confirm "Create computer account '$computer' on $target?" n) != "yes"
            echo "Aborted."
            return 1
        end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$computer"; echo "error: computer name is required"; return 1; end

    set -l domain $TGT_DC_DOMAIN
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN is not set" >&2
        return 1
    end

    set -l impacket_cmd ""
    if command -v addcomputer.py >/dev/null; set impacket_cmd addcomputer.py
    else if command -v impacket-addcomputer >/dev/null; set impacket_cmd impacket-addcomputer
    else; echo "error: addcomputer.py not found. run 'kronos install'."; return 1; end

    set -l add_args -dc-ip "$target" -computer-name "$computer"
    if test -n "$computer_pass"; set -a add_args -computer-pass "$computer_pass"; end

    if set -q _flag_kerberos
        set -a add_args -k -no-pass "$domain/$auth_user"
    else
        if test -n "$auth_hash"
            set -a add_args -hashes "$auth_hash" "$domain/$auth_user"
        else
            set -a add_args "$domain/$auth_user:$auth_pass"
        end
    end

    __kronos_check_dep $impacket_cmd; or return 1

    echo "[*] Creating computer account $computer via $impacket_cmd..."
    command $impacket_cmd $add_args
end
