# description: Private helper to check for a command dependency
function __kronos_check_dep --argument-names cmd
    if not command -v "$cmd" >/dev/null
        set_color red; echo "error: $cmd is not installed." >&2; set_color normal >&2
        echo "Please run 'kronos install' to automatically set up all required tools." >&2
        return 1
    end
    return 0
end
