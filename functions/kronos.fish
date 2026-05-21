# description: Active Directory attack orchestrator
function kronos --description "Active Directory attack orchestrator"
    set -l action $argv[1]
    set -l commands userenum dominfo ingest connect search asrep-roast kerbroast lookupsid spray forcechange gmsa add-user add-member add-computer dacl secretsdump psexec rbcd shadow-credentials ticket convert request install reset help

    if test -z "$action"
        # Interactive Mode
        set_color cyan
        echo "  _  _______   ____  _   _  ____   _____ "
        echo " | |/ /  __ \ / __ \| \ | |/ __ \ / ____|"
        echo " | ' /| |__) | |  | |  \| | |  | | (___  "
        echo " |  < |  _  /| |  | | . ` | |  | |\___ \ "
        echo " | . \| | \ \| |__| | |\  | |__| |____) |"
        echo " |_|\_\_|  \_\____/|_| \_|\____/|_____/ "
        set_color normal
        echo ""
        echo "Kronos is a modular orchestration tool designed to automate and simplify"
        echo "AD penetration testing by wrapping industry-standard tools into a unified CLI."
        echo ""
        
        # Start at top (default to userenum)
        set action (__kronos_ask_choice "Pick a command to execute" "userenum" $commands); or return 1
    end
    
    if test "$action" = "help" -o "$action" = "-h" -o "$action" = "--help"
        if test (count $argv) -gt 1
            set -l sub $argv[2]
            switch "$sub"
                case userenum;    __kronos_userenum --help
                case dominfo;     __kronos_dominfo --help
                case ingest;      __kronos_ingest --help
                case connect;     __kronos_connect --help
                case search;      __kronos_search --help
                case asrep-roast; __kronos_asrep_roast --help
                case kerbroast;   __kronos_kerbroast --help
                case lookupsid;   __kronos_lookupsid --help
                case spray;       __kronos_spray --help
                case forcechange; __kronos_forcechange --help
                case gmsa;        __kronos_gmsa --help
                case add-user;    __kronos_add_user --help
                case add-member;  __kronos_add_member --help
                case add-computer; __kronos_add_computer --help
                case dacl;        __kronos_dacl --help
                case secretsdump; __kronos_secretsdump --help
                case psexec;      __kronos_psexec --help
                case rbcd;        __kronos_rbcd --help
                case shadow-credentials; __kronos_shadow_credentials --help
                case ticket;      __kronos_ticket --help
                case convert;     __kronos_convert --help
                case request;     __kronos_request --help
                case install;     __kronos_install --help
                case reset;       __kronos_reset --help
                case '*'
                    __kronos_help
            end
        else
            __kronos_help
        end
        return 0
    end

    # If it was an interactive selection, argv[1] might be empty if we set action from choice
    if test (count $argv) -gt 0; and test "$argv[1]" = "$action"
        set -e argv[1]
    end
    
    switch "$action"
        case userenum;    __kronos_userenum $argv
        case dominfo;     __kronos_dominfo $argv
        case ingest;      __kronos_ingest $argv
        case connect;     __kronos_connect $argv
        case asrep-roast; __kronos_asrep_roast $argv
        case kerbroast;   __kronos_kerbroast $argv
        case spray;       __kronos_spray $argv
        case forcechange; __kronos_forcechange $argv
        case gmsa;        __kronos_gmsa $argv
        case ticket;      __kronos_ticket $argv
        case convert;     __kronos_convert $argv
        case request;     __kronos_request $argv
        case lookupsid;   __kronos_lookupsid $argv
        case add-user;    __kronos_add_user $argv
        case add-member;  __kronos_add_member $argv
        case add-computer; __kronos_add_computer $argv
        case dacl;        __kronos_dacl $argv
        case search;      __kronos_search $argv
        case secretsdump; __kronos_secretsdump $argv
        case psexec;      __kronos_psexec $argv
        case rbcd;        __kronos_rbcd $argv
        case shadow-credentials; __kronos_shadow_credentials $argv
        case install;     __kronos_install $argv
        case reset;       __kronos_reset $argv
        case '*'
            echo "error: unknown command '$action'" >&2
            __kronos_help
            return 1
    end
end
