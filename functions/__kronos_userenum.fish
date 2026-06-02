# description: Enumerate AD users (Wordlist, NULL Session, or Credentials)
function __kronos_userenum --description "Enumerate AD users (Wordlist, NULL Session, or Credentials)"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet w/wordlist= u/username= p/password= H/hash= d/domain= k/kerberos N/null X/edit-cmd W/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos userenum [TARGET] [OPTIONS]"
        echo ""
        echo "Enumerate Active Directory users using various methods."
        echo ""
        echo "Options:"
        echo "  -t, --target IP      Target DC IP or Hostname"
        echo "  -w, --wordlist FILE  Path to custom wordlist (for Wordlist mode)"
        echo "  -d, --domain NAME    Target domain name"
        echo "  -u, --username USER  Auth username (for Credentials mode)"
        echo "  -p, --password PASS  Auth password"
        echo "  -H, --hash HASH      Auth NTLM hash"
        echo "  -k, --kerberos       Use Kerberos authentication"
        echo "  -N, --null           Use NULL session (nxc -u 'Guest' -p '')"
        echo "  -X, --edit-cmd       Inspect and edit the command before execution"
        echo "  -q, --quiet          Skip prompts and use fallbacks"
        echo "  -h, --help           Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; and test (count $argv) -gt 0
        set target $argv[1]
    end
    set -l domain $_flag_domain
    set -l userlist $_flag_wordlist
    set -l auth_user $_flag_username
    set -l auth_pass $_flag_password
    set -l auth_hash $_flag_hash
    set -l mode ""

    # Determine mode from flags
    if set -q _flag_wordlist; set mode "Wordlist"; end
    if set -q _flag_null; set mode "NULL Session"; end
    if set -q _flag_username; or set -q _flag_kerberos; set mode "Credentials"; end

    # 1. Target Resolution
    set -l def_target "$__KRONOS_CACHE_USERENUM_TARGET"
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
            set_color cyan; echo "[*] Starting UserEnum wizard..."; set_color normal
            
            # Target Prompt
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_USERENUM_TARGET "$target"

            # Domain Prompt
            set -l def_domain "$__KRONOS_CACHE_USERENUM_DOMAIN"
            set -l src_domain "Cache"
            if test -z "$def_domain"
                set def_domain "$TGT_HOSTS[1]"; set src_domain "TGT_HOSTS"
                if test -z "$def_domain"; set def_domain "$TGT_DC_DOMAIN"; set src_domain "TGT_DC_DOMAIN"; end
            end
            if test -n "$domain"; set def_domain "$domain"; set src_domain "CLI Arg"; end
            set domain (__kronos_ask "Domain Name" "$def_domain" "$src_domain"); or return 1
            set -U __KRONOS_CACHE_USERENUM_DOMAIN "$domain"

            # Mode Selection
            if test -z "$mode"
                set mode (__kronos_ask_choice "Enumeration Mode" "Wordlist" "Wordlist" "NULL Session" "Credentials"); or return 1
            end

            if test "$mode" = "Wordlist"
                set -l def_userlist "$__KRONOS_CACHE_USERENUM_USERLIST"
                set -l src_userlist "Cache"
                if test -z "$def_userlist"; set def_userlist "/usr/share/seclists/Usernames/xato-net-10-million-usernames.txt"; set src_userlist "Default"; end
                if test -n "$userlist"; set def_userlist "$userlist"; set src_userlist "CLI Arg"; end
                set userlist (__kronos_ask "User List Path" "$def_userlist" "$src_userlist"); or return 1
                set -U __KRONOS_CACHE_USERENUM_USERLIST "$userlist"
            else if test "$mode" = "Credentials"
                # Auth Prompts
                if not set -q _flag_kerberos; and test -z "$auth_user"
                    set -l def_user "$__KRONOS_CACHE_USERENUM_AUTH_USER"
                    set -l src_user "Cache"
                    if test -z "$def_user"
                        set def_user "$TGT_USERNAME"; set src_user "TGT_USERNAME"
                        if test -z "$def_user"; set def_user "$TGT_CRED_USERNAME"; set src_user "TGT_CRED_USERNAME"; end
                    end
                    if test -n "$auth_user"; set def_user "$auth_user"; set src_user "CLI Arg"; end
                    set auth_user (__kronos_ask "Auth Username" "$def_user" "$src_user"); or return 1
                    set -U __KRONOS_CACHE_USERENUM_AUTH_USER "$auth_user"

                    set -l def_auth_val "$__KRONOS_CACHE_USERENUM_AUTH_VAL"
                    set -l src_auth_val "Cache"
                    if test -z "$def_auth_val"
                        set def_auth_val "$TGT_PASSWORD"; set src_auth_val "TGT_PASSWORD"
                        if test -z "$def_auth_val"; set def_auth_val "$TGT_CRED_PASSWORD"; set src_auth_val "TGT_CRED_PASSWORD"; end
                    end
                    if test -n "$auth_pass"; set def_auth_val "$auth_pass"; set src_auth_val "CLI Pass"; end
                    if test -n "$auth_hash"; set def_auth_val "$auth_hash"; set src_auth_val "CLI Hash"; end
                    set -l auth_input (__kronos_ask "Auth Password or Hash" "$def_auth_val" "$src_auth_val"); or return 1
                    set -U __KRONOS_CACHE_USERENUM_AUTH_VAL "$auth_input"
                    
                    if string match -rq '^[a-fA-F0-9]{32}:[a-fA-F0-9]{32}$|^[a-fA-F0-9]{32}$' -- "$auth_input"
                        set auth_hash "$auth_input"; set auth_pass ""
                    else
                        set auth_pass "$auth_input"; set auth_hash ""
                    end
                end
            end
        end
    else
        # Quiet fallbacks
        if test -z "$target"; set target "$def_target"; end
        if test -z "$domain"
            set domain "$__KRONOS_CACHE_USERENUM_DOMAIN"
            if test -z "$domain"; set domain $TGT_HOSTS[1]; end
            if test -z "$domain"; set domain $TGT_DC_DOMAIN; end
        end
        if test -z "$mode"; set mode "Wordlist"; end
        if test "$mode" = "Wordlist" -a -z "$userlist"
            set userlist "$__KRONOS_CACHE_USERENUM_USERLIST"
            if test -z "$userlist"; set userlist "/usr/share/seclists/Usernames/xato-net-10-million-usernames.txt"; end
        end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end
    if test -z "$domain"; echo "error: domain is required"; return 1; end

    if test "$mode" = "Wordlist"
        if not test -f "$userlist"
            echo "error: userlist not found at $userlist" >&2
            return 1
        end

        set -l kerbrute_bin kerbrute
        if not command -v kerbrute >/dev/null
            if command -v kerbrute.py >/dev/null; set kerbrute_bin kerbrute.py
            else; echo "error: kerbrute not found. run 'kronos install'."; return 1; end
        end

        __kronos_check_dep $kerbrute_bin; or return 1
        set -l cmd_str "$kerbrute_bin userenum --dc \"$target\" -d \"$domain\" -o .kerbrute_out.txt \"$userlist\""
        if set -q _flag_edit_cmd; set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1; end

        echo "[*] Running kerbrute userenum against $target ($domain)..."
        __kronos_exec "$cmd_str"
        
        if test -f .kerbrute_out.txt
            echo "[*] Extracting valid users to valid_users.txt..."
            command grep "\[+\] VALID USERNAME" .kerbrute_out.txt | command awk '{print $NF}' | command cut -d'@' -f1 > valid_users.txt
            echo "[+] Saved "(cat valid_users.txt | wc -l)" valid users to valid_users.txt"
            rm -f .kerbrute_out.txt
        end
    else
        # NULL Session (Guest) or Credentials via NXC
        __kronos_check_dep nxc; or return 1
        set -l nxc_cmd "nxc smb \"$target\""
        if test -n "$domain"; set nxc_cmd "$nxc_cmd -d \"$domain\""; end
        
        if test "$mode" = "NULL Session"
            set nxc_cmd "$nxc_cmd -u 'Guest' -p ''"
        else
            if set -q _flag_kerberos
                set nxc_cmd "$nxc_cmd -k -u \"$auth_user\" -p ''"
            else if test -n "$auth_hash"
                set nxc_cmd "$nxc_cmd -u \"$auth_user\" -H \"$auth_hash\""
            else
                set nxc_cmd "$nxc_cmd -u \"$auth_user\" -p \"$auth_pass\""
            end
        end
        
        set nxc_cmd "$nxc_cmd --users"
        if set -q _flag_edit_cmd; set nxc_cmd (__kronos_edit_cmd "$nxc_cmd"); or return 1; end

        echo "[*] Running NetExec user enumeration ($mode) against $target ($domain)..."
        __kronos_exec "$nxc_cmd"
    end
end
