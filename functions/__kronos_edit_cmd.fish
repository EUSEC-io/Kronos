# description: Private helper to inspect and edit a constructed command before execution
function __kronos_edit_cmd --argument-names cmd_str
    if not command -q gum
        echo "" >&2
        set_color yellow >&2; echo "[!] Final command to be executed:" >&2; set_color normal >&2
        echo "    $cmd_str" >&2
        echo "" >&2
        read -P "  Edit command (Enter to run as is): " edited_cmd
        if test -n "$edited_cmd"
            echo "$edited_cmd"
        else
            echo "$cmd_str"
        end
        return 0
    end

    echo "" >&2
    set_color yellow >&2; echo "[!] Inspect/Edit constructed command:" >&2; set_color normal >&2
    set_color brblack >&2; echo "    [Press Enter to execute, or modify the string below]" >&2; set_color normal >&2
    echo "" >&2
    
    # Use gum input for interactive editing
    set -l result (command gum input --value "$cmd_str" --width (math $COLUMNS - 10))
    set -l rc $status
    echo "" >&2
    
    if test $rc -ne 0
        echo "Aborted." >&2
        return 1
    end
    
    if test -z "$result"
        echo "$cmd_str"
    else
        echo "$result"
    end
    return 0
end
