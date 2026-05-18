# description: Active Directory attack orchestrator
function kronos --description "Active Directory attack orchestrator"
    set -l action $argv[1]
    
    if test -z "$action"
        __kronos_help
        return 1
    end
    
    set -e argv[1]
    
    switch "$action"
        case help -h --help
            if set -q argv[1]
                set -l subaction $argv[1]
                switch "$subaction"
                    case userenum; __kronos_userenum --help
                    case dominfo;  __kronos_dominfo --help
                    case ingest;   __kronos_ingest --help
                    case rdp;      __kronos_rdp --help
                    case winrm;    __kronos_winrm --help
                    case ftp;      __kronos_ftp --help
                    case smb;      __kronos_smb --help
                    case rpc;      __kronos_rpc --help
                    case asrep-roast; __kronos_asrep_roast --help
                    case kerbroast;   __kronos_kerbroast --help
                    case spray;       __kronos_spray --help
                    case forcechange; __kronos_forcechange --help
                    case gmsa;        __kronos_gmsa --help
                    case ticket;      __kronos_ticket --help
                    case convert;     __kronos_convert --help
                    case request;     __kronos_request --help
                    case lookupsid;   __kronos_lookupsid --help
                    case install;     __kronos_install --help
                    case '*'
                        echo "error: unknown command '$subaction'" >&2
                        __kronos_help
                        return 1
                end
            else
                __kronos_help
            end
        case userenum;    __kronos_userenum $argv
        case dominfo;     __kronos_dominfo $argv
        case ingest;      __kronos_ingest $argv
        case rdp;         __kronos_rdp $argv
        case winrm;       __kronos_winrm $argv
        case ftp;         __kronos_ftp $argv
        case smb;         __kronos_smb $argv
        case rpc;         __kronos_rpc $argv
        case asrep-roast; __kronos_asrep_roast $argv
        case kerbroast;   __kronos_kerbroast $argv
        case spray;       __kronos_spray $argv
        case forcechange; __kronos_forcechange $argv
        case gmsa;        __kronos_gmsa $argv
        case ticket;      __kronos_ticket $argv
        case convert;     __kronos_convert $argv
        case request;     __kronos_request $argv
        case lookupsid;   __kronos_lookupsid $argv
        case install;     __kronos_install $argv
        case '*'
            echo "error: unknown command '$action'" >&2
            __kronos_help
            return 1
    end
end
