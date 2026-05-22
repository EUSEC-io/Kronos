# description: Enumerate SIDs for AD objects using lookupsid.py
function __kronos_lookupsid --description "Enumerate SIDs for AD objects using lookupsid.py"
    argparse h/help q/quiet u/username= p/password= H/hash= d/domain= k/kerberos f/filter= D/domain-sid X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos lookupsid [TARGET] [OPTIONS]"
        echo ""
        echo "Enumerate SIDs for AD objects using impacket's lookupsid.py."
        echo ""
        echo "Options:"
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

    set -l target $argv[1]
    set -l domain $_flag_domain
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash

    # Standard Fallbacks & Cache
    if test -z "$target"
        set target $__KRONOS_CACHE_LOOKUPSID_TARGET
        if test -z "$target"; set target $TGT_HOSTS[1]; end
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end

    if test -z "$domain"
        set domain $__KRONOS_CACHE_LOOKUPSID_DOMAIN
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    end

    if test -z "$auth_user"
        set auth_user $__KRONOS_CACHE_LOOKUPSID_AUTH_USER
        if test -z "$auth_user"; set auth_user $TGT_USERNAME; end
        if test -z "$auth_user"; set auth_user $TGT_CRED_USERNAME; end
    end
    if test -z "$auth_pass"; and test -z "$auth_hash"
        set -l cached_auth "$__KRONOS_CACHE_LOOKUPSID_AUTH_VAL"
        if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$cached_auth"
            set auth_hash "$cached_auth"
        else
            set auth_pass "$cached_auth"
        end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass $TGT_CRED_PASSWORD; end
    end

    # Interactive Wizard
    if not set -q _flag_quiet
        if test (count $argv) -eq 0; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting LookupSID wizard..."; set_color normal

            set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
            set -U __KRONOS_CACHE_LOOKUPSID_TARGET "$target"

            set domain (__kronos_ask "Domain Name" "$domain"); or return 1
            set -U __KRONOS_CACHE_LOOKUPSID_DOMAIN "$domain"

            if not set -q _flag_kerberos
                set auth_user (__kronos_ask "Auth Username" "$auth_user"); or return 1
                set -U __KRONOS_CACHE_LOOKUPSID_AUTH_USER "$auth_user"

                set -l def_auth_val "$auth_pass"
                if test -n "$auth_hash"; set def_auth_val "$auth_hash"; end
                set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val"); or return 1
                set -U __KRONOS_CACHE_LOOKUPSID_AUTH_VAL "$auth_input"
                
                if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                    set auth_hash "$auth_input"; set auth_pass ""
                else
                    set auth_pass "$auth_input"; set auth_hash ""
                end
            end
        end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$domain"; echo "error: domain is required"; return 1; end

    set -l impacket_cmd ""
    if command -v lookupsid.py >/dev/null; set impacket_cmd lookupsid.py
    else if command -v impacket-lookupsid >/dev/null; set impacket_cmd impacket-lookupsid
    else; echo "error: lookupsid not found. run 'kronos install'."; return 1; end

    set -l cmd_args
    if test -n "$TGT_DC_IP"; set -a cmd_args -dc-ip "$TGT_DC_IP"
    else if test -n "$TGT_DC"; set -a cmd_args -dc-ip "$TGT_DC"; end

    if set -q _flag_kerberos
        set -a cmd_args -k -no-pass "$domain/$auth_user@$target"
    else if test -n "$auth_hash"
        set -a cmd_args -hashes "$auth_hash" "$domain/$auth_user@$target"
    else
        if test -z "$auth_user"; or test -z "$auth_pass"
             echo "error: credentials or kerberos flag required"; return 1
        end
        set -a cmd_args "$domain/$auth_user:$auth_pass@$target"
    end

    set -l full_cmd "$impacket_cmd "(string join ' ' -- $cmd_args)
    
    # Handle piping/filtering in the string for eval
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
