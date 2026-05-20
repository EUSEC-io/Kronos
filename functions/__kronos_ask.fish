# description: Private helper to ask for text input (gum or read fallback)
function __kronos_ask --argument-names label default
    if command -q gum
        set_color cyan >&2; echo "  $label" >&2; set_color normal >&2
        if test -n "$default"
            set_color brblack >&2; echo "    [Enter to keep default, or delete and type '.' to clear]" >&2; set_color normal >&2
        else
            set_color brblack >&2; echo "    [optional — Enter to skip]" >&2; set_color normal >&2
        end
        echo "" >&2
        set -l value (command gum input --placeholder "Type something..." --value "$default")
        set -l rc $status
        echo "" >&2
        if test $rc -ne 0; return $rc; end
        
        # If user typed just a dot, return an empty string to signal "clear"
        if test "$value" = "."
            echo ""
            return 0
        end

        # If Enter was pressed without changing anything, it returns the default.
        # If they deleted everything and hit enter, gum returns empty.
        echo "$value"
        return 0
    end

    read -P "  $label [$default]: " value
    set -l rc $status
    if test $rc -ne 0; return $rc; end
    if test "$value" = "."
        echo ""
        return 0
    end
    if test -z "$value"; set value "$default"; end
    echo "$value"
    return 0
end
