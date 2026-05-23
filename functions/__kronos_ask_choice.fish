# description: Private helper to pick one of $choices
function __kronos_ask_choice --description "Pick one of $choices using gum or read"
    set -l label $argv[1]
    set -l default $argv[2]
    set -l choices $argv[3..]

    if command -q gum
        set_color cyan >&2; echo "  $label" >&2; set_color normal >&2
        set_color brblack >&2; echo "    [↑/↓ to select, Enter to confirm; current: $default]" >&2; set_color normal >&2
        echo "" >&2
        set -l value (command gum choose --selected "$default" $choices)
        set -l rc $status
        echo "" >&2
        if test $rc -ne 0; return $rc; end
        if test -z "$value"; set value "$default"; end
        echo "$value"
        return 0
    end

    set -l joined (string join '/' -- $choices)
    while true
        read -P "  $label, $joined [$default]: " value
        set -l rc $status
        if test $rc -ne 0; return $rc; end
        if test -z "$value"; set value "$default"; end
        if contains -- "$value" $choices
            echo "$value"
            return 0
        end
        echo "    invalid; expected one of: $joined" >&2
    end