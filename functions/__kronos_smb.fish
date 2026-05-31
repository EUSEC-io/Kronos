# description: Connect to target using smbclient (SMB)
function __kronos_smb --description "Connect to target using smbclient (SMB)"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help X/edit-cmd u/username= p/password= H/hash= d/domain= k/kerberos s/share= q/quiet w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect smb [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via SMB using smbclient."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target DC IP or Hostname"
        echo "  -u, --username USER Provide username"
        echo "  -p, --password PASS Provide password"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -d, --domain DOMAIN Provide domain"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -s, --share SHARE   Target share (default: C\$)"
        echo "  -X, --edit-cmd      Edit command before execution"
        echo "  -q, --quiet         Skip prompts and use cached/default values"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l user $_flag_username
    set -l domain $_flag_domain
    set -l pass $_flag_password
    set -l hash $_flag_hash
    set -l share $_flag_share

    if not set -q _flag_quiet
        if test (count $argv) -eq 0 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting SMB connection wizard..."; set_color normal
            
            set -l def_target "$__KRONOS_CACHE_SMB_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_SMB_TARGET "$target"

            set -l def_domain "$__KRONOS_CACHE_SMB_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_SMB_DOMAIN "$domain"

            set -l def_share "$__KRONOS_CACHE_SMB_SHARE"
            if test -z "$def_share"; set def_share "C\$"; end
            set share (__kronos_ask "Target Share" "$def_share"); or return 1
            set -U __KRONOS_CACHE_SMB_SHARE "$share"

            if not set -q _flag_kerberos
                set -l def_user "$__KRONOS_CACHE_SMB_USER"
                set -l src_user "Cache"
                if test -z "$def_user"
                    set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                end
                set user (__kronos_ask "Username" "$def_user" "$src_user"); or return 1
                set -U __KRONOS_CACHE_SMB_USER "$user"

                set -l def_domain "$__KRONOS_CACHE_SMB_DOMAIN"
                set -l src_domain "Cache"
                if test -z "$def_domain"
                    set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                    if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
                end
                set domain (__kronos_ask "Domain/Workgroup" "$def_domain" "$src_domain"); or return 1
                set -U __KRONOS_CACHE_SMB_DOMAIN "$domain"

                set -l def_auth_val "$pass"
                if test -n "$hash"; set def_auth_val "$hash"; end
                if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; end
                set -l auth_input (__kronos_ask "Password or Hash" "$def_auth_val"); or return 1
                set -U __KRONOS_CACHE_SMB_AUTH_VAL "$auth_input"
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set hash "$auth_input"; set pass ""
                else
                    set pass "$auth_input"; set hash ""
                end
            end
        end
    else
        # Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_SMB_TARGET"; end
        if test -z "$target"; set target "$TGT"; end
        if test -z "$share"; set share "C\$"; end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end

    __kronos_check_dep smbclient; or return 1

    set -l cmd_list smbclient "//$target/$share"
    if set -q _flag_kerberos
        set -a cmd_list -k
    else
        if test -n "$user"; set -a cmd_list -U "$user" ; end
        if test -n "$domain"; set -a cmd_list -W "$domain"; end
        if test -n "$hash"
            set -a cmd_list --pw-nt-hash "$hash"
        end
    end

    set -l cmd_str (string escape -- $cmd_list | string join " ")
    if set -q _flag_edit_cmd; set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1; end

    echo "[*] Connecting to //$target/$share via SMB..."
    eval $cmd_str
end
