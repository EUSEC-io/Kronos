# description: Private helper to ask a yes/no question
function __kronos_ask_confirm --description "Ask a yes/no question using gum or read" --argument-names label default_yn
    if command -q gum
        echo "" >&2
        if test "$default_yn" = y
            command gum confirm "$label"
        else
            command gum confirm --default=false "$label"
        end
        set -l rc $status
        echo "" >&2
        switch $rc
            case 0
                echo yes
                return 0
            case 1
                echo no
                return 0
            case '*'
                return $rc
        end

    set -l prompt "  $label "
    if test "$default_yn" = y; set prompt "$prompt(Y/n): "; else; set prompt "$prompt(y/N): "; end
    
    while true
        read -P "$prompt" value
        set -l rc $status
        if test $rc -ne 0; return $rc; end
        if test -z "$value"
            test "$default_yn" = y; and echo yes; or echo no
            return 0
        end
        switch (string lower -- $value)
            case y yes
                echo yes
                return 0
            case n no
                echo no
                return 0
        end
        echo "    invalid; expected yes/no" >&2
    end