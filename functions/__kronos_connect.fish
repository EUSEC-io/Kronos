# description: Dispatcher for protocol-specific connection subcommands
function __kronos_connect --description "Dispatcher for protocol-specific connection subcommands"
    set -l subaction $argv[1]
    
    if test -z "$subaction"
        set subaction (__kronos_ask_choice "Pick a protocol to connect" "rdp" rdp winrm smb rpc mssql ftp); or return 1
    end
    
    set -e argv[1]
    
    switch "$subaction"
        case help -h --help
            if set -q argv[1]
                set -l proto $argv[1]
                switch "$proto"
                    case rdp; __kronos_rdp --help
                    case winrm; __kronos_winrm --help
                    case ftp; __kronos_ftp --help
                    case smb; __kronos_smb --help
                    case rpc; __kronos_rpc --help
                    case mssql; __kronos_mssql --help
                    case '*'
                        echo "error: unknown protocol '$proto'" >&2
                        __kronos_help
                        return 1
                end
            else
                __kronos_help
            end
        case rdp;    __kronos_rdp $argv --wizard
        case winrm;  __kronos_winrm $argv --wizard
        case ftp;    __kronos_ftp $argv --wizard
        case smb;    __kronos_smb $argv --wizard
        case rpc;    __kronos_rpc $argv --wizard
        case mssql;  __kronos_mssql $argv --wizard
        case '*'
            echo "error: unknown protocol '$subaction'" >&2
            __kronos_help
            return 1
    end
end
