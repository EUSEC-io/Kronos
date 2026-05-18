# description: Convert tickets between kirbi and ccache formats
function _kronos_convert --description "Convert tickets between kirbi and ccache formats"
    argparse h/help i/input= o/output= -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos convert [OPTIONS]"
        echo ""
        echo "Convert Kerberos tickets between kirbi and ccache formats using impacket-ticketConverter."
        echo ""
        echo "Options:"
        echo "  -i, --input FILE    Input ticket file (.kirbi or .ccache)"
        echo "  -o, --output FILE   Output ticket file (.ccache or .kirbi)"
        echo "  -h, --help          Show this help message"
        return 0
    end

    if not set -q _flag_input; or not set -q _flag_output
        echo "Error: Both -i/--input and -o/--output are required." >&2
        return 1
    end

    set -l impacket_cmd ""
    if command -s ticketConverter.py >/dev/null
        set impacket_cmd "ticketConverter.py"
    else if command -s impacket-ticketConverter >/dev/null
        set impacket_cmd "impacket-ticketConverter"
    else
        echo "Error: ticketConverter.py or impacket-ticketConverter not found in PATH." >&2
        return 1
    end

    echo "Converting $_flag_input to $_flag_output..."
    eval $impacket_cmd "\"$_flag_input\" \"$_flag_output\""
end
