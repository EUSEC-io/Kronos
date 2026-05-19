# test/test_kronos_router.fish
source (status dirname)/../../pentest-fish-functions/test/helpers.fish

# Mock all private functions to verify dispatch
function __kronos_help; echo "mock_help"; end
function __kronos_userenum; echo "mock_userenum $argv"; end
function __kronos_rdp; echo "mock_rdp $argv"; end
function __kronos_winrm; echo "mock_winrm $argv"; end
function __kronos_install; echo "mock_install"; end

@test "router: no args calls help" \
    (kronos | string match -q "mock_help"; echo $status) -eq 0

@test "router: userenum dispatch" \
    (kronos userenum arg1 | string match -q "mock_userenum arg1"; echo $status) -eq 0

@test "router: connect rdp dispatch" \
    (kronos connect rdp 10.1.1.1 | string match -q "mock_rdp 10.1.1.1"; echo $status) -eq 0

@test "router: connect winrm dispatch" \
    (kronos connect winrm 10.1.1.1 | string match -q "mock_winrm 10.1.1.1"; echo $status) -eq 0

@test "router: install dispatch" \
    (kronos install | string match -q "mock_install"; echo $status) -eq 0

@test "router: invalid command calls help" \
    (kronos bogus 2>&1 | string match -q "mock_help"; echo $status) -eq 0
