# description: Create a new AD computer account using addcomputer.py
function __kronos_add_computer --description "Create a new AD computer account using addcomputer.py"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet u/username= p/password= H/hash= C/computer= P/computer-pass= k/kerberos X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos add-computer [OPTIONS]"
        echo ""
        echo "Create a new Active Directory computer account using impacket's addcomputer.py."
        echo ""
        echo "Options:"
        echo "  -t, --target IP         Target DC IP or Hostname"
        echo "  -C, --computer NAME     The name of the new computer account"
        echo "  -P, --computer-pass PASS The password for the new computer"
        echo "  -u, --username USER     Auth username"
        echo "  -p, --password PASS     Auth password"
        echo "  -H, --hash HASH         Auth NTLM hash"
        echo "  -k, --kerberos          Use Kerberos authentication"
        echo "  -X, --edit-cmd          Edit the command before execution"
        echo "  -q, --quiet             Skip prompts and use cached/default values"
        echo "  -h, --help              Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l computer $_flag_computer
    set -l computer_pass $_flag_computer_pass
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting Add Computer wizard..."; set_color normal

            set -l def_target "$__KRONOS_CACHE_ADDCOMP_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_ADDCOMP_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_ADDCOMP_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_ADDCOMP_DOMAIN "$domain"

            set computer (__kronos_ask "Computer Name" "$computer"); or return 1
            set -U __KRONOS_CACHE_ADDCOMP_NAME "$computer"

            set computer_pass (__kronos_ask "Computer Password (optional)" "$computer_pass")
            set -U __KRONOS_CACHE_ADDCOMP_PASS "$computer_pass"

            if not set -q _flag_kerberos
                set -l def_auth_user "$__KRONOS_CACHE_ADDCOMP_AUTH_USER"
                set -l src_user "Cache"
                if test -z "$def_auth_user"
                    set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                    if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
                end
                set auth_user (__kronos_ask "Auth Username" "$def_auth_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_ADDCOMP_AUTH_USER "$auth_user"

                set -l def_auth_val "$auth_pass"
                if test -n "$auth_hash"; set def_auth_val "$auth_hash"; end
                if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; end
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
    else
        # Quiet mode fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_ADDCOMP_TARGET"; end
        if test -z "$target"; set target $TGT; end
        if test -z "$target"; set target $TGT_HOSTS[1]; end
        if test -z "$target"; set target $TGT_DC_IP; end

        if test -z "$auth_user"
            set auth_user "$TGT_USERNAME"
            if test -z "$auth_user"; set auth_user "$TGT_CRED_USERNAME"; end
        end
        if test -z "$auth_pass"; and test -z "$auth_hash"
            set auth_pass "$TGT_PASSWORD"
            if test -z "$auth_pass"; set auth_pass "$TGT_CRED_PASSWORD"; end
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

    set -l cmd_str "$impacket_cmd"
    for arg in $add_args
        set cmd_str "$cmd_str "(string escape -- $arg)
    end

    if set -q _flag_edit_cmd
        set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1
    end

    echo "[*] Creating computer account $computer via $impacket_cmd..."
    eval $cmd_str
end
