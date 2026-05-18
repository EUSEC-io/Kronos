# description: Run kerbrute userenum
function _kronos_userenum --description "Run kerbrute userenum"
    argparse h/help w/wordlist= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos userenum [TARGET] [-w/--wordlist FILE]"
        echo ""
        echo "Run kerbrute userenum against the specified target."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT or \$TGT_DC)"
        echo ""
        echo "Options:"
        echo "  -w, --wordlist FILE Path to a custom wordlist"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    
    if test -z "$target"
        if test -n "$TGT"
            set target $TGT
        else if test -n "$TGT_DC"
            set target $TGT_DC
        else
            echo "Error: Target IP/hostname/nameserver is required." >&2
            echo "Usage: kronos userenum [TARGET] [-w/--wordlist FILE]" >&2
            return 1
        end
    end

    set -l domain ""
    if test -n "$TGT_AD_DOMAIN"
        set domain $TGT_AD_DOMAIN
    else
        echo "Error: TGT_AD_DOMAIN is not set. Please set it or run within a configured tgt environment." >&2
        return 1
    end

    set -l userlist ""
    if set -q _flag_wordlist
        set userlist $_flag_wordlist
        if not test -f "$userlist"
            echo "Error: Custom wordlist not found at $userlist" >&2
            return 1
        end
    else if test -n "$KRONOS_USERLIST"
        set userlist $KRONOS_USERLIST
        if not test -f "$userlist"
            echo "Error: KRONOS_USERLIST not found at $userlist" >&2
            return 1
        end
    else
        # Default fallback to common SecLists location
        set userlist "/usr/share/seclists/Usernames/xato-net-10-million-usernames.txt"
        if not test -f "$userlist"
            echo "Error: Default userlist not found at $userlist." >&2
            echo "Please provide a wordlist with -w/--wordlist or set KRONOS_USERLIST." >&2
            return 1
        end
    end

    if not command -s kerbrute >/dev/null
        echo "Error: kerbrute not found in PATH." >&2
        echo "Please run 'make install' in the Kronos directory and ensure ~/go/bin is in your PATH." >&2
        return 1
    end

    echo "Running kerbrute userenum against $target for domain $domain..."
    kerbrute userenum --dc $target -d $domain $userlist
end
