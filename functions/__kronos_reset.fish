# description: Reset all cached Kronos universal variables
function __kronos_reset --description "Reset all cached Kronos universal variables"
    argparse h/help y/yes -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos reset [OPTIONS]"
        echo ""
        echo "Clear all persistent variables saved by Kronos wizards."
        echo ""
        echo "Options:"
        echo "  -y, --yes    Skip confirmation prompt"
        echo "  -h, --help   Show this help message"
        return 0
    end

    if not set -q _flag_yes
        set -l conf (__kronos_ask_confirm "Are you sure you want to clear all Kronos cached data?" n)
        if test "$conf" != "yes"
            echo "Aborted."
            return 1
        end

    echo "[*] Clearing Kronos cache variables..."
    set -l count 0
    for var in (set -U | grep "^__KRONOS_CACHE_" | awk '{print $1}')
        set -eU $var
        set count (math $count + 1)
    end

    set_color green; echo "[+] Successfully cleared $count cache variables."; set_color normal
end