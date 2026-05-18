# description: Run kerbrute userenum
function __kronos_userenum --description "Run kerbrute userenum"
    argparse h/help w/wordlist= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos userenum [TARGET] [-w/--wordlist FILE]"
        echo ""
        echo "Run kerbrute userenum against the specified target."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC_IP or \$TGT_DC)"
        echo ""
        echo "Options:"
        echo "  -w, --wordlist FILE Path to a custom wordlist"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"
        set target $TGT_DC_IP
    end
    if test -z "$target"
        set target $TGT_DC
    end
    if test -z "$target"
        set target $TGT
    end
    
    if test -z "$target"
        echo "error: target is required (pass as argument or set \$TGT_DC_IP / \$TGT)" >&2
        return 1
    end

    set -l domain $TGT_DC_DOMAIN
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN is not set" >&2
        return 1
    end

    set -l userlist ""
    if set -q _flag_wordlist
        set userlist $_flag_wordlist
    else if test -n "$KRONOS_USERLIST"
        set userlist $KRONOS_USERLIST
    else
        set userlist "/usr/share/seclists/Usernames/xato-net-10-million-usernames.txt"
    end

    if not test -f "$userlist"
        echo "error: userlist not found at $userlist" >&2
        return 1
    end

    set -l kerbrute_bin kerbrute
    if not command -v kerbrute >/dev/null
        if command -v kerbrute.py >/dev/null
            set kerbrute_bin kerbrute.py
        else
            echo "error: kerbrute not found. run 'kronos install'." >&2
            return 1
        end
    end

    echo "[*] Running $kerbrute_bin userenum against $target ($domain)..."
    command $kerbrute_bin userenum --dc $target -d $domain -o .kerbrute_out.txt $userlist
    
    if test -f .kerbrute_out.txt
        echo "[*] Extracting valid users to valid_users.txt..."
        command grep "\[+\] VALID USERNAME" .kerbrute_out.txt | command awk '{print $NF}' | command cut -d'@' -f1 > valid_users.txt
        echo "[+] Saved "(cat valid_users.txt | wc -l)" valid users to valid_users.txt"
        rm -f .kerbrute_out.txt
    end
end
