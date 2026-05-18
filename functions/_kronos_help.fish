# description: Global help for Kronos
function _kronos_help --description "Global help for Kronos"
    echo "Usage: kronos <command> [options]"
    echo ""
    echo "Active Directory attack orchestrator."
    echo ""
    echo "Commands:"
    echo "  userenum    Run kerbrute userenum"
    echo "  dominfo     Query domain info and password policy"
    echo "  ingest      Ingest Active Directory data using bloodhound-python"
    echo "  help        Show this global help message or command-specific help"
    echo ""
    echo "Run 'kronos <command> help' or 'kronos help <command>' for more information on a specific command."
end
