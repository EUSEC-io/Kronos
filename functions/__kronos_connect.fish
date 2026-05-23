# description: Dispatcher for protocol-specific connection subcommands
function __kronos_connect --description "Dispatcher for protocol-specific connection subcommands"
    set -l protocols rdp winrm smb rpc mssql ftp
    set -l subaction $argv[1]

    # If first arg is a protocol, just dispatch immediately to preserve flags
    if contains -- "$subaction" $protocols
        set -e argv[1]
        switch "$subaction"
            case rdp;    __kronos_rdp $argv
            case winrm;  __kronos_winrm $argv
            case ftp;    __kronos_ftp $argv
            case smb;    __kronos_smb $argv
            case rpc;    __kronos_rpc $argv
            case mssql;  __kronos_mssql $argv
        end
        return
    end
    
    # Otherwise, it's either an interactive call, help, or a global flag for connect
    argparse h/help q/quiet X/edit-cmd -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos connect [subcommand] [OPTIONS]"
        echo ""
        echo "Dispatcher for protocol-specific connection subcommands."
        echo ""
        echo "Subcommands: rdp, winrm, smb, rpc, mssql, ftp"
        echo ""
        echo "Options:"
        echo "  -q, --quiet     Skip prompts and use cached/default values"
        echo "  -X, --edit-cmd  Inspect and edit the command before execution"
        echo "  -h, --help      Show this help message"
        return 0
    end

    if test -z "$subaction"
        if not set -q _flag_quiet
            set subaction (__kronos_ask_choice "Pick a protocol to connect" "rdp" $protocols); or return 1
        else
            echo "error: protocol required in quiet mode" >&2; return 1
        end
    
    # Handle flags if they were passed BEFORE or AFTER subcommand (though above logic handles most cases)
    switch "$subaction"
        case rdp;    __kronos_rdp $argv
        case winrm;  __kronos_winrm $argv
        case ftp;    __kronos_ftp $argv
        case smb;    __kronos_smb $argv
        case rpc;    __kronos_rpc $argv
        case mssql;  __kronos_mssql $argv
        case '*'
            echo "error: unknown protocol '$subaction'" >&2
            __kronos_help
            return 1
    end