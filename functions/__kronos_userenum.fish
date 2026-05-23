# description: Run kerbrute userenum
function __kronos_userenum --description "Run kerbrute userenum"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse t/target= h/help q/quiet w/wordlist= X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos userenum [TARGET] [-w/--wordlist FILE]"
        echo ""
        echo "Run kerbrute userenum against the specified target."
        echo ""
        echo "Options:"
        echo "  -t, --target IP     Target DC IP or Hostname"
        echo "  -w, --wordlist FILE Path to a custom wordlist"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $_flag_target
    if test -z "$target"; set target $argv[1]; end
    set -l userlist $_flag_wordlist

    if not set -q _flag_quiet
        if test (count $argv) -eq 0 -o -z "$target"; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting UserEnum wizard..."; set_color normal

            set -l def_target "$__KRONOS_CACHE_USERENUM_TARGET"
            set -l src_target "Cache"
            if test -z "$def_target"
                set def_target "$TGT"; set src_target "TGT"
                if test -z "$def_target"; set def_target "$TGT_DC_IP"; set src_target "TGT_DC_IP"; end
                if test -z "$def_target"; set def_target "$TGT_DC"; set src_target "TGT_DC"; end
                if test -z "$def_target"; set def_target "$TGT_HOSTS[1]"; set src_target "TGT_HOSTS"; end
            end
            if test -n "$target"; set def_target "$target"; set src_target "CLI Arg"; end
            set target (__kronos_ask "Target DC IP/Hostname" "$def_target" "$src_target"); or return 1
            set -U __KRONOS_CACHE_USERENUM_TARGET "$target"

            set -l def_userlist "$__KRONOS_CACHE_USERENUM_USERLIST"
            set -l src_userlist "Cache"
            if test -z "$def_userlist"; set def_userlist "/usr/share/seclists/Usernames/xato-net-10-million-usernames.txt"; set src_userlist "Default"; end
            if test -n "$userlist"; set def_userlist "$userlist"; set src_userlist "CLI Arg"; end
            set userlist (__kronos_ask "User List Path" "$def_userlist" "$src_userlist"); or return 1
            set -U __KRONOS_CACHE_USERENUM_USERLIST "$userlist"
        end
    else
        # Fallbacks
        if test -z "$target"; set target "$__KRONOS_CACHE_USERENUM_TARGET"; end
        if test -z "$target"; set target "$TGT"; end
        if test -z "$userlist"
            set userlist "$__KRONOS_CACHE_USERENUM_USERLIST"
            if test -z "$userlist"; set userlist "/usr/share/seclists/Usernames/xato-net-10-million-usernames.txt"; end
        end
    end

    if test -z "$target"; echo "error: target is required"; return 1; end

    set -l domain $TGT_DC_DOMAIN
    if test -z "$domain"; set domain $TGT_HOSTS[1]; end
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN or \$TGT_HOSTS is not set" >&2
        return 1
    end

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
    eval $cmd_str
    
    if test -f .kerbrute_out.txt
        echo "[*] Extracting valid users to valid_users.txt..."
        command grep "\[+\] VALID USERNAME" .kerbrute_out.txt | command awk '{print $NF}' | command cut -d'@' -f1 > valid_users.txt
        echo "[+] Saved "(cat valid_users.txt | wc -l)" valid users to valid_users.txt"
        rm -f .kerbrute_out.txt
    end
end
