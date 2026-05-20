# description: Create a new AD user using bloodyAD
function __kronos_add_user --description "Create a new AD user using bloodyAD"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse h/help u/username= p/password= k/kerberos U/new-user= P/new-password= w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos add-user [TARGET] [OPTIONS]"
        echo ""
        echo "Create a new Active Directory user using bloodyAD."
        echo ""
        echo "Options:"
        echo "  -U, --new-user NAME     The username of the new user"
        echo "  -P, --new-password PASS The password for the new user"
        echo "  -u, --username USER     Auth username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS     Auth password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -k, --kerberos          Use Kerberos authentication"
        echo "  -h, --help              Show this help message"
        return 0
    end

    set -l target $argv[1]
    set -l new_user $_flag_new_user
    set -l new_pass $_flag_new_password
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password

    if test "$wizard" -eq 1; or set -q _flag_wizard
        set_color cyan; echo "[*] Starting Add User wizard..."; set_color normal

        set -l def_target "$__KRONOS_CACHE_ADDUSER_TARGET"
        if test -z "$def_target"; set def_target "$TGT_DC_IP"; end
        if test -z "$def_target"; set def_target "$TGT_DC"; end
        if test -z "$def_target"; set def_target "$TGT"; end
        if test -n "$target"; set def_target "$target"; end
        set target (__kronos_ask "Target DC IP/Hostname" "$def_target"); or return 1
        set -U __KRONOS_CACHE_ADDUSER_TARGET "$target"

        set -l def_new_user "$__KRONOS_CACHE_ADDUSER_NEW_USER"
        if test -n "$new_user"; set def_new_user "$new_user"; end
        set new_user (__kronos_ask "New Username" "$def_new_user"); or return 1
        set -U __KRONOS_CACHE_ADDUSER_NEW_USER "$new_user"

        set -l def_new_pass "$__KRONOS_CACHE_ADDUSER_NEW_PASS"
        if test -n "$new_pass"; set def_new_pass "$new_pass"; end
        set new_pass (__kronos_ask "New Password" "$def_new_pass"); or return 1
        set -U __KRONOS_CACHE_ADDUSER_NEW_PASS "$new_pass"

        if not set -q _flag_kerberos
            set -l def_auth_user "$__KRONOS_CACHE_ADDUSER_AUTH_USER"
            if test -z "$def_auth_user"; set def_auth_user "$TGT_USERNAME"; end
            if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; end
            if test -n "$auth_user"; set def_auth_user "$auth_user"; end
            set auth_user (__kronos_ask "Auth Username" "$def_auth_user"); or return 1
            set -U __KRONOS_CACHE_ADDUSER_AUTH_USER "$auth_user"

            set -l def_auth_pass "$__KRONOS_CACHE_ADDUSER_AUTH_PASS"
            if test -z "$def_auth_pass"; set def_auth_pass "$TGT_PASSWORD"; end
            if test -z "$def_auth_pass"; set def_auth_pass "$TGT_CRED_PASSWORD"; end
            if test -n "$auth_pass"; set def_auth_pass "$auth_pass"; end
            set auth_pass (__kronos_ask "Auth Password" "$def_auth_pass"); or return 1
            set -U __KRONOS_CACHE_ADDUSER_AUTH_PASS "$auth_pass"
        end
    else
        # Standard Fallbacks
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
        
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
        if test -z "$auth_pass"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$new_user"; echo "error: --new-user is required"; return 1; end
    if test -z "$new_pass"; echo "error: --new-password is required"; return 1; end

    set -l domain $TGT_DC_DOMAIN
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN is not set" >&2
        return 1
    end

    set -l cmd_str bloodyAD --host "$target" -d "$domain"
    if set -q _flag_kerberos
        set -a cmd_str -k
    else
        if test -z "$auth_user"
            echo "error: auth credentials required" >&2
            return 1
        end
        set -a cmd_str -u "$auth_user" -p "$auth_pass"
    end

    set -a cmd_str add user "$new_user" "$new_pass"

    __kronos_check_dep bloodyAD; or return 1

    echo "[*] Creating user $new_user via bloodyAD..."
    command $cmd_str
end
