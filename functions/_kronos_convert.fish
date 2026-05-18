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

    if not command -s impacket-ticketConverter >/dev/null
        echo "Error: impacket-ticketConverter not found in PATH." >&2
        return 1
    end

    echo "Converting $_flag_input to $_flag_output..."
    impacket-ticketConverter "$_flag_input" "$_flag_output"
end
