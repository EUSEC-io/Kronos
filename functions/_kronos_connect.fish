# description: Connect to target using evil-winrm or xfreerdp3
function _kronos_connect --description "Connect to target using evil-winrm or xfreerdp3"
    argparse h/help u/username= p/password= H/hash= g/gui -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to the target using evil-winrm (CLI) or xfreerdp3 (GUI)."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC or \$TGT)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username"
        echo "  -p, --password PASS Provide password"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -g, --gui           Use xfreerdp3 for a GUI session instead of evil-winrm"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    
    if test -z "$target"
        if test -n "$TGT_DC"
            set target $TGT_DC
        else if test -n "$TGT"
            set target $TGT
        else
            echo "Error: Target IP/hostname/nameserver is required." >&2
            echo "Usage: kronos connect [TARGET] [OPTIONS]" >&2
            return 1
        end
    end

    set -l auth_user ""
    set -l auth_pass ""
    set -l auth_hash ""
    set -l has_creds 0

    if set -q _flag_username
        set auth_user $_flag_username
        if set -q _flag_password
            set auth_pass $_flag_password
            set has_creds 1
        else if set -q _flag_hash
            set auth_hash $_flag_hash
            set has_creds 1
        else
            echo "Error: Username provided but no password (-p) or hash (-H) supplied." >&2
            return 1
        end
    else if test -n "$TGT_USERNAME"
        if test -n "$TGT_PASSWORD"
            set auth_user $TGT_USERNAME
            set auth_pass $TGT_PASSWORD
            set has_creds 1
        else if test -n "$TGT_HASH"
            set auth_user $TGT_USERNAME
            set auth_hash $TGT_HASH
            set has_creds 1
        end
    end

    if test "$has_creds" -eq 0
        echo "Error: Credentials are required. Provide them via -u with -p/-H, or ensure tgt credentials are active." >&2
        return 1
    end

    if set -q _flag_gui
        if not command -s xfreerdp3 >/dev/null
            # Fallback to xfreerdp if xfreerdp3 is not found, or just show error.
            if command -s xfreerdp >/dev/null
                echo "Warning: xfreerdp3 not found, falling back to xfreerdp." >&2
                set -g _rdp_cmd xfreerdp
            else
                echo "Error: xfreerdp3 (or xfreerdp) not found in PATH." >&2
                return 1
            end
        else
            set -g _rdp_cmd xfreerdp3
        end

        echo "Starting GUI session with $_rdp_cmd against $target..."
        set -l rdp_args /v:$target /u:$auth_user /f /drive:share,$PWD
        
        if test -n "$auth_hash"
            set rdp_args $rdp_args /pth:$auth_hash
        else
            set rdp_args $rdp_args /p:$auth_pass
        end

        eval $_rdp_cmd $rdp_args
    else
        if not command -s evil-winrm >/dev/null
            echo "Error: evil-winrm not found in PATH." >&2
            return 1
        end

        echo "Starting CLI session with evil-winrm against $target..."
        set -l winrm_args -i $target -u $auth_user
        
        if test -n "$auth_hash"
            set winrm_args $winrm_args -H $auth_hash
        else
            set winrm_args $winrm_args -p $auth_pass
        end

        eval evil-winrm $winrm_args
    end
end
