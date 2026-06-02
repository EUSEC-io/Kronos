# description: Read GMSA passwords using ldeep
function __kronos_gmsa --description "Read GMSA passwords using ldeep"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet u/username= p/password= H/hash= d/domain= k/kerberos X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos gmsa [OPTIONS]"
        echo ""
        echo "Read GMSA passwords using ldeep."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target DC IP or Hostname"
        echo "  -u, --username USER Auth username (Required for both mode)"
        echo "  -p, --password PASS Auth password"
        echo "  -H, --hash HASH     Auth NTLM hash"
        echo "  -d, --domain DOMAIN Target domain name"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash
    set -l domain $_flag_domain

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting GMSA wizard..."; set_color normal

            # 1. Target
            set -l def_target "$__KRONOS_CACHE_GMSA_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_GMSA_TARGET "$target"

            # 2. Domain
            set -l def_domain "$__KRONOS_CACHE_GMSA_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_GMSA_DOMAIN "$domain"

            # 3. Username (Required for both modes in ldeep)
            set -l def_user "$__KRONOS_CACHE_GMSA_AUTH_USER"
            set -l src_user "Cache"
            if test -z "$def_user"
                set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
            end
            if test -n "$auth_user"; set def_user "$auth_user"; set src_user "CLI Arg"; end
            set auth_user (__kronos_ask "Auth Username" "$def_user" "$src_user"); or return 1
            set -U __KRONOS_CACHE_GMSA_AUTH_USER "$auth_user"

            # 4. Auth Mode
            set -l mode "Credentials"
            if set -q _flag_kerberos; set mode "Kerberos"; end
            
            if not set -q _flag_kerberos; and test -z "$auth_pass"; and test -z "$auth_hash"
                set mode (__kronos_ask_choice "Authentication Mode" "$mode" "Credentials" "Kerberos"); or return 1
            end

            if test "$mode" = "Kerberos"
                set _flag_kerberos 1
            else
                # 5. Credentials (if not Kerberos)
                set -l def_auth_val "$auth_pass"
                set -l src_auth_val "Cache"
                if test -n "$auth_hash"; set def_auth_val "$auth_hash"; set src_auth_val "CLI Hash"; end
                if test -z "$def_auth_val"
                    set def_auth_val "$__KRONOS_CACHE_GMSA_AUTH_VAL"
                    set src_auth_val "Cache"
                    if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"; end
                end
                
                set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val" "$src_auth_val"); or return 1
                set -U __KRONOS_CACHE_GMSA_AUTH_VAL "$auth_input"
                
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set auth_hash "$auth_input"; set auth_pass ""
                else
                    set auth_pass "$auth_input"; set auth_hash ""
                end
            end
        end
    else
        # Quiet fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_GMSA_TARGET"; end
        if test -z "$target"; set target $TGT; end
        if test -z "$domain"
            set domain "$__KRONOS_CACHE_GMSA_DOMAIN"
            if test -z "$domain"; set domain $TGT_HOSTS[1]; end
            if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
        end
        if test -z "$auth_user"
            set auth_user "$__KRONOS_CACHE_GMSA_AUTH_USER"
            if test -z "$auth_user"; set auth_user "$TGT_USERNAME"; end
        end
        if test -z "$auth_pass"; and test -z "$auth_hash"; and not set -q _flag_kerberos
            set auth_pass "$__KRONOS_CACHE_GMSA_AUTH_VAL"
            if test -z "$auth_pass"; set auth_pass "$TGT_PASSWORD"; end
        end
    end

    if test -z "$target"; echo "error: target is required" >&2; return 1; end
    if test -z "$domain"; echo "error: domain is required" >&2; return 1; end
    if test -z "$auth_user"; echo "error: username is required" >&2; return 1; end

    __kronos_check_dep ldeep; or return 1

    set -l gmsa_cmd "ldeep ldap -u \"$auth_user\" -d \"$domain\" -s \"ldap://$target\""
    if set -q _flag_kerberos
        set gmsa_cmd "$gmsa_cmd -k"
        # ldeep help says $KRB5NAME, but standard is $KRB5CCNAME. Let's provide both if possible.
        if test -n "$KRB5CCNAME"; and test -z "$KRB5NAME"
            set -gx KRB5NAME "$KRB5CCNAME"
        end
    else if test -n "$auth_hash"
        set gmsa_cmd "$gmsa_cmd -H \"$auth_hash\""
    else
        set gmsa_cmd "$gmsa_cmd -p \"$auth_pass\""
    end
    
    set gmsa_cmd "$gmsa_cmd gmsa"

    if set -q _flag_edit_cmd
        set gmsa_cmd (__kronos_edit_cmd "$gmsa_cmd"); or return 1
    end

    echo "[*] Reading GMSA passwords via ldeep..."
    __kronos_exec "$gmsa_cmd"
end
