# description: Force change a user's password using bloodyAD
function _kronos_forcechange --description "Force change a user's password using bloodyAD"
    argparse h/help u/username= p/password= H/hash= t/target-user= P/new-password= k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos forcechange [TARGET] [OPTIONS]"
        echo ""
        echo "Force change a user's password using bloodyAD."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC or \$TGT)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username for authentication"
        echo "  -p, --password PASS Provide password for authentication"
        echo "  -H, --hash HASH     Provide NTLM hash for authentication"
        echo "  -t, --target-user U Target user whose password will be changed"
        echo "  -P, --new-password  The new password to set"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
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
            echo "Usage: kronos forcechange [TARGET] [OPTIONS]" >&2
            return 1
        end
    end

    if not set -q _flag_target_user
        echo "Error: Target user (-t/--target-user) is required." >&2
        return 1
    end

    if not set -q _flag_new_password
        echo "Error: New password (-P/--new-password) is required." >&2
        return 1
    end

    set -l auth_user ""
    set -l auth_pass ""
    set -l auth_hash ""
    set -l has_creds 0

    if set -q _flag_kerberos
        set has_creds 1
    else if set -q _flag_username
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
        echo "Error: Credentials or Kerberos flag are required." >&2
        return 1
    end

    set -l domain ""
    if test -n "$TGT_AD_DOMAIN"
        set domain $TGT_AD_DOMAIN
    else
        echo "Error: TGT_AD_DOMAIN is not set." >&2
        return 1
    end

    if not command -s bloodyAD >/dev/null
        echo "Error: bloodyAD not found in PATH." >&2
        return 1
    end

    set -l cmd_str "bloodyAD --host \"$target\" -d \"$domain\""

    if set -q _flag_kerberos
        set cmd_str "$cmd_str -k"
    else
        set cmd_str "$cmd_str -u \"$auth_user\""
        if test -n "$auth_hash"
            set cmd_str "$cmd_str -p \":$auth_hash\""
        else
            set cmd_str "$cmd_str -p \"$auth_pass\""
        end
    end

    set cmd_str "$cmd_str set password \"$_flag_target_user\" \"$_flag_new_password\""

    echo "Running bloodyAD to change password for $_flag_target_user..."
    eval $cmd_str
end
