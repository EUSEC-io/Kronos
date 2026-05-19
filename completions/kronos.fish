# completions/kronos.fish

set -l commands userenum dominfo ingest connect asrep-roast kerbroast spray forcechange gmsa ticket convert request lookupsid add-user add-member add-computer dacl search secretsdump rbcd shadow-credentials install help
set -l protocols rdp winrm ftp smb rpc mssql

# Disable file completions unless explicitly allowed
complete -c kronos -f

# Main commands
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a userenum -d "Run kerbrute userenum"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a dominfo -d "Query domain info and password policy"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a ingest -d "Ingest AD data using bloodhound-python"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a connect -d "Connect to target via specific protocol"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a asrep-roast -d "AS-REP Roasting (GetNPUsers.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a kerbroast -d "Kerberoasting (GetUserSPNs.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a spray -d "Password spray using valid_users.txt"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a forcechange -d "Force change user password (bloodyAD)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a gmsa -d "Read GMSA passwords (nxc)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a add-user -d "Create a new AD user"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a add-member -d "Add a user to an AD group"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a add-computer -d "Create a new computer account"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a dacl -d "Manipulate AD object DACLs"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a search -d "Search and enumerate AD objects"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a secretsdump -d "Dump AD secrets (secretsdump.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a rbcd -d "Perform RBCD attack"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a shadow-credentials -d "Perform Shadow Credentials attack"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a ticket -d "Create Golden/Silver tickets"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a convert -d "Convert kirbi/ccache tickets"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a request -d "Request TGT/ST (getTGT/getST)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a lookupsid -d "Enumerate AD SIDs (lookupsid.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a install -d "Install all dependencies"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a help -d "Show help menu"

# Connect subcommands
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a rdp -d "Connect via RDP (xfreerdp3)"
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a winrm -d "Connect via WinRM (evil-winrm)"
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a ftp -d "Connect via FTP"
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a smb -d "Connect via SMB (smbclient)"
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a rpc -d "Connect via RPC (rpcclient)"
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a mssql -d "Connect via MSSQL (mssqlclient.py)"

# Shared flags
set -l needs_auth dominfo connect asrep-roast kerbroast forcechange gmsa lookupsid ingest request add-user add-member add-computer dacl search secretsdump rbcd shadow-credentials
complete -c kronos -n "__fish_seen_subcommand_from $needs_auth" -s u -l username -d "Username"
complete -c kronos -n "__fish_seen_subcommand_from $needs_auth" -s p -l password -d "Password"
complete -c kronos -n "__fish_seen_subcommand_from connect kerbroast forcechange gmsa lookupsid request add-computer secretsdump" -s H -l hash -d "NTLM Hash"
complete -c kronos -n "__fish_seen_subcommand_from dominfo connect asrep-roast kerbroast forcechange gmsa lookupsid ingest add-user add-member add-computer dacl search secretsdump rbcd shadow-credentials" -s k -l kerberos -d "Use Kerberos authentication"
complete -c kronos -n "__fish_seen_subcommand_from $commands" -s h -l help -d "Show help"

# Subcommand-specific flags
complete -c kronos -n "__fish_seen_subcommand_from userenum" -s w -l wordlist -r -d "Custom wordlist"
complete -c kronos -n "__fish_seen_subcommand_from add-user" -s U -l new-user -r -d "New username"
complete -c kronos -n "__fish_seen_subcommand_from add-user" -s P -l new-password -r -d "New password"
complete -c kronos -n "__fish_seen_subcommand_from add-member" -s g -l group -r -d "Target group"
complete -c kronos -n "__fish_seen_subcommand_from add-member" -s m -l member -r -d "User to add"
complete -c kronos -n "__fish_seen_subcommand_from add-computer" -s C -l computer -r -d "Computer name"
complete -c kronos -n "__fish_seen_subcommand_from add-computer" -s P -l computer-pass -r -d "Computer password"
complete -c kronos -n "__fish_seen_subcommand_from dacl" -s t -l target-object -r -d "Target object"
complete -c kronos -n "__fish_seen_subcommand_from dacl" -s m -l member -r -d "Grantee user/group"
complete -c kronos -n "__fish_seen_subcommand_from dacl" -s a -l action -x -a "add remove set" -d "Action"
complete -c kronos -n "__fish_seen_subcommand_from dacl" -s p -l permission -x -a "genericAll dcsync owner all" -d "Permission"
complete -c kronos -n "__fish_seen_subcommand_from search" -s q -l query -r -d "Search query"
complete -c kronos -n "__fish_seen_subcommand_from search" -s a -l attr -r -d "Attribute to fetch"
complete -c kronos -n "__fish_seen_subcommand_from rbcd" -s t -l target-computer -r -d "Target computer"
complete -c kronos -n "__fish_seen_subcommand_from rbcd" -s m -l delegate-to -r -d "Delegate to"
complete -c kronos -n "__fish_seen_subcommand_from rbcd" -s a -l action -x -a "add remove" -d "Action"
complete -c kronos -n "__fish_seen_subcommand_from shadow-credentials" -s t -l target-object -r -d "Target object"
complete -c kronos -n "__fish_seen_subcommand_from shadow-credentials" -s a -l action -x -a "add remove list" -d "Action"
complete -c kronos -n "__fish_seen_subcommand_from dominfo" -s P -l pass-policy -d "Query password policy"
complete -c kronos -n "__fish_seen_subcommand_from dominfo" -s N -l NULL -d "Force NULL session"
complete -c kronos -n "__fish_seen_subcommand_from ingest" -s o -l output -r -d "Output zip filename"
complete -c kronos -n "__fish_seen_subcommand_from kerbroast" -s t -l target -d "Roast specific user"
complete -c kronos -n "__fish_seen_subcommand_from spray" -s u -l userlist -r -d "User list"
complete -c kronos -n "__fish_seen_subcommand_from ticket" -s S -l sid -r -d "Domain SID"
complete -c kronos -n "__fish_seen_subcommand_from ticket" -s s -l spn -r -d "Target SPN"
complete -c kronos -n "__fish_seen_subcommand_from request" -s s -l spn -r -d "Target SPN"
complete -c kronos -n "__fish_seen_subcommand_from lookupsid" -s f -l filter -r -d "Filter output"
complete -c kronos -n "__fish_seen_subcommand_from lookupsid" -s D -l domain-sid -d "Only show Domain SID"
complete -c kronos -n "__fish_seen_subcommand_from convert" -s i -l input -r -d "Input ticket"
complete -c kronos -n "__fish_seen_subcommand_from convert" -s o -l output -r -d "Output ticket"
