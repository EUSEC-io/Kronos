# description: Install Kronos external dependencies
function __kronos_install --description "Install Kronos external dependencies"
    set -l script_path (status dirname)/../scripts/install_kronos_deps.sh
    if test -f "$script_path"
        bash "$script_path"
    else
        echo "error: installer script not found at $script_path" >&2
        return 1
    end
end
