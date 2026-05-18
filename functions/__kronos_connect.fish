# description: Dispatcher for protocol-specific connection subcommands
function __kronos_connect --description "Dispatcher for protocol-specific connection subcommands"
    set -l subaction $argv[1]
    
    if test -z "$subaction"
        __kronos_help
        return 1
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
end
