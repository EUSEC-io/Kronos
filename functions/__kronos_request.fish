# description: Request TGT or ST and export KRB5CCNAME
function __kronos_request --description "Request TGT or ST and export KRB5CCNAME"
    argparse h/help u/username= p/password= H/hash= s/spn= d/domain= t/target= X/edit-cmd q/quiet w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos request [OPTIONS]"
        echo ""
        echo "Request a TGT or ST using impacket's getTGT.py or getST.py."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username"
        echo "  -p, --password PASS Provide password"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -s, --spn SPN       Target SPN (for ST request)"
        echo "  -d, --domain DOMAIN Target domain Name"
        echo "  -t, --target DC_IP  DC IP or hostname"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    set -l domain $_flag_domain
    set -l user $_flag_username
    set -l pass $_flag_password
    set -l hash $_flag_hash
    set -l spn $_flag_spn

    # Load defaults
    if test -z "$target"
        set target $__KRONOS_CACHE_REQUEST_TARGET
        if test -z "$target"; set target $TGT_DC_IP; end
        if test -z "$target"; set target $TGT_DC; end
        if test -z "$target"; set target $TGT; end
    end
    if test -z "$domain"
        set domain $__KRONOS_CACHE_REQUEST_DOMAIN
        if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
    end
    if test -z "$user"
        set user $__KRONOS_CACHE_REQUEST_USER
        if test -z "$user"; set user $TGT_USERNAME; end
        if test -z "$user"; set user $TGT_CRED_USERNAME; end
    end
    if test -z "$pass"; and test -z "$hash"
        set -l cached_auth "$__KRONOS_CACHE_REQUEST_AUTH_VAL"
        if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$cached_auth"
            set hash "$cached_auth"
        else
            set pass "$cached_auth"
        end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set pass $TGT_PASSWORD; end
        if test -z "$auth_pass"; and test -z "$auth_hash"; set pass $TGT_CRED_PASSWORD; end
    end
    if test -z "$spn"; set spn $__KRONOS_CACHE_REQUEST_SPN; end

    if not set -q _flag_quiet
        set_color cyan; echo "[*] Starting Ticket Request wizard..."; set_color normal

        set target (__kronos_ask "Target DC IP/Hostname" "$target"); or return 1
        set -U __KRONOS_CACHE_REQUEST_TARGET "$target"

        set domain (__kronos_ask "Domain Name" "$domain"); or return 1
        set -U __KRONOS_CACHE_REQUEST_DOMAIN "$domain"

        set user (__kronos_ask "Auth Username" "$user"); or return 1
        set -U __KRONOS_CACHE_REQUEST_USER "$user"

        set -l def_auth_val "$pass"
        if test -n "$hash"; set def_auth_val "$hash"; end
        set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val"); or return 1
        set -U __KRONOS_CACHE_REQUEST_AUTH_VAL "$auth_input"
        if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
            set hash "$auth_input"; set pass ""
        else
            set pass "$auth_input"; set hash ""
        end

        set -l req_type (__kronos_ask_choice "Ticket Type" "TGT" TGT ST); or return 1
        if test "$req_type" = "ST"
            set spn (__kronos_ask "Target SPN (e.g. cifs/ms01.contoso.local)" "$spn"); or return 1
            set -U __KRONOS_CACHE_REQUEST_SPN "$spn"
        else
            set spn ""
        end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$domain"; echo "error: domain is required"; return 1; end
    if test -z "$user"; echo "error: username is required"; return 1; end

    set -l req_args
    set -l impacket_cmd

    if test -n "$spn"
        if command -v getST.py >/dev/null; set impacket_cmd getST.py
        else if command -v impacket-getST >/dev/null; set impacket_cmd impacket-getST
        else; echo "error: getST not found. run 'kronos install'."; return 1; end

        echo "[*] Requesting Service Ticket for $spn..."
        set -a req_args -spn "$spn" -dc-ip "$target"
    else
        if command -v getTGT.py >/dev/null; set impacket_cmd getTGT.py
        else if command -v impacket-getTGT >/dev/null; set impacket_cmd impacket-getTGT
        else; echo "error: getTGT not found. run 'kronos install'."; return 1; end

        echo "[*] Requesting Ticket Granting Ticket for $user..."
        set -a req_args -dc-ip "$target"
    end

    if test -n "$hash"
        set -a req_args -hashes "$hash" "$domain/$user"
    else
        set -a req_args "$domain/$user:$pass"
    end

    set -l full_cmd "$impacket_cmd "(string join ' ' -- $req_args)
    if set -q _flag_edit_cmd
        set full_cmd (__kronos_edit_cmd "$full_cmd"); or return 1
    end

    __kronos_check_dep $impacket_cmd; or return 1
    command eval $full_cmd

    if test -f "$user.ccache"
        set -gx KRB5CCNAME "$PWD/$user.ccache"
        echo "[+] Ticket saved and exported to KRB5CCNAME=$KRB5CCNAME"
    end
end
