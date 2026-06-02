# description: Private helper to execute commands with optional faketime prefix
function __kronos_exec --argument-names cmd_str
    set -l final_cmd "$cmd_str"
    
    if test -n "$__KRONOS_FAKETIME"
        if not command -v faketime >/dev/null
            set_color red; echo "error: faketime is not installed but __KRONOS_FAKETIME is set." >&2; set_color normal >&2
            echo "Please run 'kronos install' or install 'libfaketime' manually." >&2
            return 1
        end
        set final_cmd "faketime -f \"$__KRONOS_FAKETIME\" $final_cmd"
    end

    eval $final_cmd
end
