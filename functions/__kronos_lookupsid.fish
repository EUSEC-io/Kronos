# description: Enumerate SIDs for AD objects using lookupsid.py
function __kronos_lookupsid --description "Enumerate SIDs for AD objects using lookupsid.py"
    argparse t/target= h/help q/quiet u/username= p/password= H/hash= d/domain= k/kerberos f/filter= D/domain-sid X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos lookupsid [OPTIONS]"
        echo ""
        echo "Enumerate SIDs for AD objects using impacket's lookupsid.py."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target DC IP or Hostname"
        echo "  -u, --username USER Auth username"
        echo "  -p, --password PASS Auth password"
        echo "  -H, --hash HASH     Auth NTLM hash"
        echo "  -d, --domain DOMAIN Target domain Name"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -f, --filter TEXT   Filter the output"
        echo "  -D, --domain-sid    Only extract Domain SID"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target "$_flag_target"
    set -l domain "$_flag_domain"
    set -l auth_user "$_flag_username"
    set -l auth_pass "$_flag_password"
    set -l auth_hash "$_flag_hash"

    if not set -q _flag_quiet
        set_color cyan; echo "[*] Starting LookupSID wizard..."; set_color normal

        # Target IP Priority
        set -l def_target "$__KRONOS_CACHE_LOOKUPSID_TARGET"
        set -l src_target "Cache"
        if test -z "$def_target"
            set def_target "$TGT"; set src_target "TGT"
            if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
            if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
            if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
        end
        if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
        set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
        set -U __KRONOS_CACHE_LOOKUPSID_TARGET "$target"

        # Domain Name Priority
        set -l def_domain "$__KRONOS_CACHE_LOOKUPSID_DOMAIN"
        set -l src_domain "Cache"
        if test -z "$def_domain"
            set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
            if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
        end
        if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
        set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
        set -U __KRONOS_CACHE_LOOKUPSID_DOMAIN "$domain"

        if not set -q _flag_kerberos
            set -l def_auth_user "$__KRONOS_CACHE_LOOKUPSID_AUTH_USER"
            set -l src_user "Cache"
            if test -z "$def_auth_user"
                set def_auth_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                if test -z "$def_auth_user"; set def_auth_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
            end
            if test -n "$auth_user"; set def_auth_user "$auth_user"; set src_user "CLI Arg"; end
            set auth_user (__kronos_ask "Auth Username" "$def_auth_user" "$src_user"); or return 1
            set -U __KRONOS_CACHE_LOOKUPSID_AUTH_USER "$auth_user"

            set -l def_auth_val "$auth_pass"
            if test -n "$auth_hash"; set def_auth_val "$auth_hash"; end
            if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; end
            set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val"); or return 1
            set -U __KRONOS_CACHE_LOOKUPSID_AUTH_VAL "$auth_input"
            
            if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                set auth_hash "$auth_input"; set auth_pass ""
            else
                set auth_pass "$auth_input"; set auth_hash ""
            end
        end
    else
        # Quiet mode fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_LOOKUPSID_TARGET"; end
        if test -z "$target"; set target "$TGT"; end
        if test -z "$target"; set target "$TGT_DC_IP"; end
        if test -z "$target"; set target "$TGT_DC"; end
        if test -z "$target"; set target "$TGT_HOSTS[1]"; end

        if test -z "$domain"; set domain "$__KRONOS_CACHE_LOOKUPSID_DOMAIN"; end
        if test -z "$domain"; set domain "$TGT_HOSTS[1]"; end
        if test -z "$domain"; set domain "$TGT_DC_DOMAIN"; end

        if test -z "$auth_user"
            set auth_user "$TGT_USERNAME"
            if test -z "$auth_user"; set auth_user "$TGT_CRED_USERNAME"; end
        end
        if test -z "$auth_pass"; and test -z "$auth_hash"
            set auth_pass "$TGT_PASSWORD"
            if test -z "$auth_pass"; set auth_pass "$TGT_CRED_PASSWORD"; end
        end
    end

    if test -z "$target"; echo "error: target is required" >&2; return 1; end
    if test -z "$domain"; echo "error: domain is required" >&2; return 1; end

    set -l impacket_cmd ""
    if command -v lookupsid.py >/dev/null; set impacket_cmd lookupsid.py
    else if command -v impacket-lookupsid >/dev/null; set impacket_cmd impacket-lookupsid
    else; echo "error: lookupsid not found. run 'kronos install'." >&2; return 1; end

    set -l cmd_args
    if test -n "$TGT_DC_IP"; set -a cmd_args -dc-ip "$TGT_DC_IP"
    else if test -n "$TGT_DC"; set -a cmd_args -dc-ip "$TGT_DC"; end

    if set -q _flag_kerberos
        set -a cmd_args -k -no-pass "$domain/$auth_user@$target"
    else if test -n "$auth_hash"
        set -a cmd_args -hashes "$auth_hash" "$domain/$auth_user@$target"
    else
        if test -z "$auth_user"; or test -z "$auth_pass"
             echo "error: credentials or kerberos flag required" >&2; return 1
        end
        set -a cmd_args "$domain/$auth_user:$auth_pass@$target"
    end

    set -l full_cmd "$impacket_cmd "(string join ' ' -- $cmd_args)
    
    if set -q _flag_domain_sid
        set full_cmd "$full_cmd | grep -i 'Domain SID'"
    else if set -q _flag_filter
        set full_cmd "$full_cmd | grep -i \"$_flag_filter\""
    end

    if set -q _flag_edit_cmd
        set full_cmd (__kronos_edit_cmd "$full_cmd"); or return 1
    end

    __kronos_check_dep $impacket_cmd; or return 1
    
    echo "[*] Enumerating SIDs on $target..."
    eval $full_cmd
end
