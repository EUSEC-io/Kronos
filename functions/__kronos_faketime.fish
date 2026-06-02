# description: Set or clear a global faketime offset for all Kronos commands
function __kronos_faketime --description "Set/Clear global faketime (e.g. +8h)"
    set -l offset $argv[1]

    if not set -q _flag_quiet; and test -z "$offset"
        set_color cyan; echo "[*] Starting Faketime wizard..."; set_color normal
        set -l def "."
        if test -n "$__KRONOS_FAKETIME"; set def "$__KRONOS_FAKETIME"; end
        
        set offset (__kronos_ask "Time Offset (e.g. +8h, -2h, or '.' to clear)" "$def")
        if test $status -ne 0; return 1; end
    end

    if test -z "$offset" -o "$offset" = "-h" -o "$offset" = "--help"
        echo "Usage: kronos faketime [OFFSET | .]"
        echo ""
        echo "Set a global time offset for Kerberos authentication."
        echo "Examples: +8h, -2h, '2023-12-25 12:00:00'"
        echo ""
        echo "To clear, type '.' or 'clear'."
        echo ""
        echo "Current Offset: "(test -n "$__KRONOS_FAKETIME"; and echo "$__KRONOS_FAKETIME"; or echo "None")
        return 0
    end

    if test "$offset" = "." -o "$offset" = "clear" -o "$offset" = "reset"
        set -eU __KRONOS_FAKETIME
        set_color green; echo "[+] Global faketime cleared."; set_color normal
        return 0
    end

    set -U __KRONOS_FAKETIME "$offset"
    set_color green; echo "[+] Global faketime set to: $offset"; set_color normal
    echo "[*] All subsequent Kronos commands will be prefixed with 'faketime -f \"$offset\"'."
end
