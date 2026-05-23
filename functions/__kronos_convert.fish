# description: Convert tickets between kirbi and ccache formats
function __kronos_convert --description "Convert tickets between kirbi and ccache formats"
    set -l wizard 0
    if test (count $argv) -eq 0
        set wizard 1
    end

    argparse h/help q/quiet i/input= o/output= X/edit-cmd w/wizard -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: kronos convert [OPTIONS]"
        echo ""
        echo "Convert Kerberos tickets between kirbi and ccache formats."
        echo ""
        echo "Options:"
        echo "  -i, --input FILE    Input ticket file (.kirbi or .ccache)"
        echo "  -o, --output FILE   Output ticket file (.ccache or .kirbi)"
        echo "  -X, --edit-cmd      Inspect and edit the command before execution"
        echo "  -q, --quiet         Skip prompts and use fallbacks"
        echo "  -h, --help          Show this help message"
        return 0
    end

    set -l input $_flag_input
    set -l output $_flag_output

    # Load defaults
    if test -z "$input"; set input $__KRONOS_CACHE_CONVERT_INPUT; end
    if test -z "$output"; set output $__KRONOS_CACHE_CONVERT_OUTPUT; end

    # Interactive Wizard
    if not set -q _flag_quiet
        if test (count $argv) -eq 0; or set -q _flag_wizard
            set_color cyan; echo "[*] Starting Convert wizard..."; set_color normal

            set input (__kronos_ask "Input Ticket File" "$input"); or return 1
            set -U __KRONOS_CACHE_CONVERT_INPUT "$input"

            if test -z "$output"
                if string match -q "*.kirbi" "$input"
                    set output (string replace ".kirbi" ".ccache" "$input")
                else if string match -q "*.ccache" "$input"
                    set output (string replace ".ccache" ".kirbi" "$input")
                end
            end

            set output (__kronos_ask "Output Ticket File" "$output"); or return 1
            set -U __KRONOS_CACHE_CONVERT_OUTPUT "$output"
        end
    end

    if test -z "$input"; echo "error: input is required"; return 1; end
    if test -z "$output"; echo "error: output is required"; return 1; end

    if not test -f "$input"
        echo "error: input file not found at $input" >&2
        return 1
    end

    set -l impacket_cmd ""
    if command -v ticketConverter.py >/dev/null
        set impacket_cmd ticketConverter.py
    else if command -v impacket-ticketConverter >/dev/null
        set impacket_cmd impacket-ticketConverter
    else
        echo "error: ticketConverter not found. run 'kronos install'."; return 1; end

    set -l cmd_str "$impacket_cmd \"$input\" \"$output\""
    
    if set -q _flag_edit_cmd
        set cmd_str (__kronos_edit_cmd "$cmd_str"); or return 1
    end

    __kronos_check_dep $impacket_cmd; or return 1

    echo "[*] Converting $input to $output..."
    eval $cmd_str
end
