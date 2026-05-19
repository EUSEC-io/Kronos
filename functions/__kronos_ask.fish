# description: Private helper to ask for text input (gum or read fallback)
function __kronos_ask --argument-names label default
    if command -q gum
        set_color cyan >&2; echo "  $label" >&2; set_color normal >&2
        if test -n "$default"
            set_color brblack >&2; echo "    [press Enter to keep: $default]" >&2; set_color normal >&2
        else
            set_color brblack >&2; echo "    [optional — Enter to skip]" >&2; set_color normal >&2
        end
        echo "" >&2
        set -l value (command gum input --placeholder "Type something..." --value "$default")
        set -l rc $status
        echo "" >&2
        if test $rc -ne 0; return $rc; end
        if test -z "$value"; set value "$default"; end
        echo "$value"
        return 0
    end

    if test -n "$default"
        read -P "  $label [$default]: " value
    else
        read -P "  $label (optional): " value
    end
    set -l rc $status
    if test $rc -ne 0; return $rc; end
    if test -z "$value"; set value "$default"; end
    echo "$value"
    return 0
end
