# description: Request TGT or ST using impacket
function _kronos_request --description "Request TGT or ST using impacket"
    argparse h/help u/username= p/password= H/hash= s/spn= d/domain= t/target= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos request [OPTIONS]"
        echo ""
        echo "Request a TGT or ST using impacket's getTGT.py or getST.py."
        echo ""
        echo "Options:"
        echo "  -u, --username USER Provide username"
        echo "  -p, --password PASS Provide password"
        echo "  -H, --hash HASH     Provide NTLM hash"
        echo "  -s, --spn SPN       Target SPN (for requesting an ST)"
        echo "  -d, --domain DOMAIN Target domain (falls back to \$TGT_AD_DOMAIN)"
        echo "  -t, --target DC_IP  DC IP or hostname (falls back to \$TGT_DC or \$TGT)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l target ""
    if set -q _flag_target
        set target $_flag_target
    else if test -n "$TGT_DC"
        set target $TGT_DC
    else if test -n "$TGT"
        set target $TGT
    else
        echo "Error: Target DC is required (-t/--target)." >&2
        return 1
    end

    set -l domain ""
    if set -q _flag_domain
        set domain $_flag_domain
    else if test -n "$TGT_AD_DOMAIN"
        set domain $TGT_AD_DOMAIN
    else
        echo "Error: Domain is required (-d/--domain)." >&2
        return 1
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
        echo "Error: Credentials are required." >&2
        return 1
    end

    if set -q _flag_spn
        if not command -s impacket-getST >/dev/null
            echo "Error: impacket-getST not found in PATH." >&2
            return 1
        end
        
        echo "Requesting Service Ticket for $_flag_spn..."
        set -l cmd_str "impacket-getST -spn $_flag_spn -dc-ip $target"
        
        if test -n "$auth_hash"
            set cmd_str "$cmd_str -hashes $auth_hash $domain/$auth_user"
        else
            set cmd_str "$cmd_str $domain/$auth_user:$auth_pass"
        end
        
        eval $cmd_str

        # getST.py usually outputs to user.ccache
        if test -f "$auth_user.ccache"
            set -gx KRB5CCNAME "$PWD/$auth_user.ccache"
            echo "Ticket exported to KRB5CCNAME=$KRB5CCNAME"
        end
    else
        if not command -s impacket-getTGT >/dev/null
            echo "Error: impacket-getTGT not found in PATH." >&2
            return 1
        end

        echo "Requesting Ticket Granting Ticket for $auth_user..."
        set -l cmd_str "impacket-getTGT -dc-ip $target"
        
        if test -n "$auth_hash"
            set cmd_str "$cmd_str -hashes $auth_hash $domain/$auth_user"
        else
            set cmd_str "$cmd_str $domain/$auth_user:$auth_pass"
        end
        
        eval $cmd_str

        # getTGT.py usually outputs to user.ccache
        if test -f "$auth_user.ccache"
            set -gx KRB5CCNAME "$PWD/$auth_user.ccache"
            echo "Ticket exported to KRB5CCNAME=$KRB5CCNAME"
        end
    end
end
