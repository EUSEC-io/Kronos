# description: Active Directory attack orchestrator
function kronos --description "Active Directory attack orchestrator"
    set -l action $argv[1]
    
    if test -z "$action"
        _kronos_help
        return 1
    end
    
    set -e argv[1]
    
    switch "$action"
        case help -h --help
            if set -q argv[1]
                set -l subaction $argv[1]
                switch "$subaction"
                    case userenum
                        _kronos_userenum --help
                    case dominfo
                        _kronos_dominfo --help
                    case ingest
                        _kronos_ingest --help
                    case connect
                        _kronos_connect --help
                    case asrep-roast
                        _kronos_asrep_roast --help
                    case kerbroast
                        _kronos_kerbroast --help
                    case spray
                        _kronos_spray --help
                    case forcechange
                        _kronos_forcechange --help
                    case gmsa
                        _kronos_gmsa --help
                    case ticket
                        _kronos_ticket --help
                    case convert
                        _kronos_convert --help
                    case request
                        _kronos_request --help
                    case '*'
                        echo "Error: Unknown command '$subaction'" >&2
                        _kronos_help
                        return 1
                end
            else
                _kronos_help
            end
        case userenum
            if test "$argv[1]" = "help"
                _kronos_userenum --help
            else
                _kronos_userenum $argv
            end
        case dominfo
            if test "$argv[1]" = "help"
                _kronos_dominfo --help
            else
                _kronos_dominfo $argv
            end
        case ingest
            if test "$argv[1]" = "help"
                _kronos_ingest --help
            else
                _kronos_ingest $argv
            end
        case connect
            if test "$argv[1]" = "help"
                _kronos_connect --help
            else
                _kronos_connect $argv
            end
        case asrep-roast
            if test "$argv[1]" = "help"
                _kronos_asrep_roast --help
            else
                _kronos_asrep_roast $argv
            end
        case kerbroast
            if test "$argv[1]" = "help"
                _kronos_kerbroast --help
            else
                _kronos_kerbroast $argv
            end
        case spray
            if test "$argv[1]" = "help"
                _kronos_spray --help
            else
                _kronos_spray $argv
            end
        case forcechange
            if test "$argv[1]" = "help"
                _kronos_forcechange --help
            else
                _kronos_forcechange $argv
            end
        case gmsa
            if test "$argv[1]" = "help"
                _kronos_gmsa --help
            else
                _kronos_gmsa $argv
            end
        case ticket
            if test "$argv[1]" = "help"
                _kronos_ticket --help
            else
                _kronos_ticket $argv
            end
        case convert
            if test "$argv[1]" = "help"
                _kronos_convert --help
            else
                _kronos_convert $argv
            end
        case request
            if test "$argv[1]" = "help"
                _kronos_request --help
            else
                _kronos_request $argv
            end
        case '*'
            echo "Error: Unknown command '$action'" >&2
            _kronos_help
            return 1
    end
end
