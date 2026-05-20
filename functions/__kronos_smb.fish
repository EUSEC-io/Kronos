# description: Connect to target using smbclient (SMB)
function __kronos_smb --description "Connect to target using smbclient (SMB)"
    argparse h/help u/username= p/password= H/hash= d/domain= k/kerberos s/share= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos smb [TARGET] [OPTIONS]"
        echo ""
        echo "Connect to a target via SMB using smbclient."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username (falls back to \$TGT_CRED_USERNAME)"
        echo "  -p, --password PASS Provide password (falls back to \$TGT_CRED_PASSWORD)"
        echo "  -H, --hash HASH     Provide NTLM hash (requires -u)"
        echo "  -d, --domain DOMAIN Provide domain (falls back to \$TGT_DC_DOMAIN)"
        echo "  -k, --kerberos      Use Kerberos authentication (requires KRB5CCNAME)"
        echo "  -s, --share SHARE   Target share (default: C\$)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target $argv[1]
    if test -z "$target"; set target $TGT; end

    if test -z "$target"
        echo "error: target is required" >&2
        return 1
    end

    set -l user $_flag_username
    if test -z "$user"; set user $TGT_CRED_USERNAME; end

    set -l domain $_flag_domain
    if test -z "$domain"
        set domain $TGT_DC_DOMAIN
    end

    set -l share "C\$"
    if set -q _flag_share
        set share $_flag_share
    end

    if not command -v smbclient >/dev/null
        echo "error: smbclient not found. run 'kronos install'." >&2
        return 1
    end

    set -l smb_args "//$target/$share"
    
    if set -q _flag_kerberos
        set -a smb_args -k
    else
        if test -n "$user"
            set -a smb_args -U "$user"
        end
        if test -n "$domain"
            set -a smb_args -W "$domain"
        end

        if set -q _flag_hash
            set -a smb_args --pw-nt-hash "$_flag_hash"
        else
            set -l pass $_flag_password
            if test -z "$pass"; set pass $TGT_CRED_PASSWORD; end
            # smbclient often prompts better than being passed on CLI
        end
    end

    echo "[*] Connecting to //$target/$share via SMB..."
    command smbclient $smb_args
end
