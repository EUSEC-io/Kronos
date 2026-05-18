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
        case '*'
            echo "Error: Unknown command '$action'" >&2
            _kronos_help
            return 1
    end
end
