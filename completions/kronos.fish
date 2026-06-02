# completions/kronos.fish

set -l commands userenum dominfo dnsdump gpp faketime ingest connect search asrep-roast kerberoast lookupsid spray forcechange gmsa add-user add-member add-computer dacl search secretsdump psexec rbcd shadow-credentials ticket convert request install reset help
set -l protocols rdp winrm ftp smb rpc mssql
set -l ticket_types golden silver diamond sapphire trust cross-forest bronze
set -l dominfo_cmds users groups shares policy loggedon

# Disable file completions unless explicitly allowed
complete -c kronos -f

# Main commands
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a userenum -d "Run kerbrute userenum"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a dominfo -d "Query domain info and enumerate objects"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a dnsdump -d "Dump all DNS records from AD (adidnsdump)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a gpp -d "Extract GPP passwords and Autologon registries"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a faketime -d "Set/Clear global faketime offset"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a ingest -d "Ingest AD data using bloodhound-python"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a connect -d "Connect to target via specific protocol"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a asrep-roast -d "AS-REP Roasting (GetNPUsers.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a kerberoast -d "Kerberoasting (GetUserSPNs.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a spray -d "Password spray using valid_users.txt"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a forcechange -d "Force change user password (bloodyAD)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a gmsa -d "Read GMSA passwords (ldeep)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a add-user -d "Create a new AD user"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a add-member -d "Add a user to an AD group"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a add-computer -d "Create a new computer account"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a dacl -d "Manipulate AD object DACLs"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a search -d "Search and enumerate AD objects"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a secretsdump -d "Dump AD secrets (secretsdump.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a psexec -d "Remote command execution (psexec.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a rbcd -d "Perform RBCD attack"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a shadow-credentials -d "Perform Shadow Credentials attack"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a ticket -d "Create advanced AD tickets"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a convert -d "Convert kirbi/ccache tickets"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a request -d "Request TGT/ST (getTGT/getST)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a lookupsid -d "Enumerate AD SIDs (lookupsid.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a install -d "Install all dependencies"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a reset -d "Clear all persistent cache variables"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a help -d "Show help menu"

# Faketime subcommands
complete -c kronos -n "__fish_seen_subcommand_from faketime" -a clear -d "Clear global faketime"
complete -c kronos -n "__fish_seen_subcommand_from faketime" -a reset -d "Clear global faketime"

# Dominfo subcommands
complete -c kronos -n "__fish_seen_subcommand_from dominfo" -a users -d "List domain users"
complete -c kronos -n "__fish_seen_subcommand_from dominfo" -a groups -d "List domain groups"
complete -c kronos -n "__fish_seen_subcommand_from dominfo" -a shares -d "List shares"
complete -c kronos -n "__fish_seen_subcommand_from dominfo" -a policy -d "Query password policy"
complete -c kronos -n "__fish_seen_subcommand_from dominfo" -a loggedon -d "List logged on users"

# Connect subcommands
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a rdp -d "Connect via RDP (xfreerdp3)"
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a winrm -d "Connect via WinRM (evil-winrm)"
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a ftp -d "Connect via FTP"
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a smb -d "Connect via SMB (smbclient)"
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a rpc -d "Connect via RPC (rpcclient)"
complete -c kronos -n "__fish_seen_subcommand_from connect; and not __fish_seen_subcommand_from $protocols" -a mssql -d "Connect via MSSQL (mssqlclient.py)"

# Ticket subcommands
complete -c kronos -n "__fish_seen_subcommand_from ticket; and not __fish_seen_subcommand_from $ticket_types" -a golden -d "Create Golden Ticket"
complete -c kronos -n "__fish_seen_subcommand_from ticket; and not __fish_seen_subcommand_from $ticket_types" -a silver -d "Create Silver Ticket"
complete -c kronos -n "__fish_seen_subcommand_from ticket; and not __fish_seen_subcommand_from $ticket_types" -a diamond -d "Create Diamond Ticket"
complete -c kronos -n "__fish_seen_subcommand_from ticket; and not __fish_seen_subcommand_from $ticket_types" -a sapphire -d "Create Sapphire Ticket"
complete -c kronos -n "__fish_seen_subcommand_from ticket; and not __fish_seen_subcommand_from $ticket_types" -a trust -d "Create Trust Ticket"
complete -c kronos -n "__fish_seen_subcommand_from ticket; and not __fish_seen_subcommand_from $ticket_types" -a cross-forest -d "Create Cross-Forest Golden Ticket"
complete -c kronos -n "__fish_seen_subcommand_from ticket; and not __fish_seen_subcommand_from $ticket_types" -a bronze -d "Create Bronze Ticket (Bronze Bit / CVE-2020-17049)"

# Universal Flags
set -l all_cmds $commands $protocols $ticket_types $dominfo_cmds
complete -c kronos -n "__fish_seen_subcommand_from $all_cmds" -s h -l help -d "Show help"
complete -c kronos -n "__fish_seen_subcommand_from $all_cmds" -s q -l quiet -d "Skip prompts and use cached values"
complete -c kronos -n "__fish_seen_subcommand_from $all_cmds" -s X -l edit-cmd -d "Inspect and edit command before execution"
complete -c kronos -n "__fish_seen_subcommand_from $all_cmds" -s t -l target -r -d "Target IP or Hostname"

# Shared Auth Flags
set -l needs_auth userenum dominfo dnsdump gpp faketime connect asrep-roast kerberoast forcechange gmsa lookupsid ingest request add-user add-member add-computer dacl search secretsdump psexec rbcd shadow-credentials ticket rdp winrm ftp smb rpc mssql $dominfo_cmds
complete -c kronos -n "__fish_seen_subcommand_from $needs_auth" -s u -l username -r -d "Username"
complete -c kronos -n "__fish_seen_subcommand_from $needs_auth" -s p -l password -r -d "Password"
complete -c kronos -n "__fish_seen_subcommand_from $needs_auth" -s H -l hash -r -d "NTLM Hash"
complete -c kronos -n "__fish_seen_subcommand_from $needs_auth" -s k -l kerberos -d "Use Kerberos authentication"

# Subcommand-specific flags
complete -c kronos -n "__fish_seen_subcommand_from userenum" -s w -l wordlist -r -d "Custom wordlist"
complete -c kronos -n "__fish_seen_subcommand_from userenum" -s N -l null -d "Use NULL session"
complete -c kronos -n "__fish_seen_subcommand_from dnsdump" -s r -l resolve -d "Resolve all records"
complete -c kronos -n "__fish_seen_subcommand_from gpp" -s m -l gpp-password -d "Scan for GPP passwords"
complete -c kronos -n "__fish_seen_subcommand_from gpp" -s a -l autologin -d "Scan for Autologon registries"
complete -c kronos -n "__fish_seen_subcommand_from add-user" -s U -l new-user -r -d "New username"
complete -c kronos -n "__fish_seen_subcommand_from add-user" -s P -l new-password -r -d "New password"
complete -c kronos -n "__fish_seen_subcommand_from add-member" -s g -l group -r -d "Target group"
complete -c kronos -n "__fish_seen_subcommand_from add-member" -s m -l member -r -d "User to add"
complete -c kronos -n "__fish_seen_subcommand_from add-computer" -s C -l computer -r -d "Computer name"
complete -c kronos -n "__fish_seen_subcommand_from dacl" -s t -l target-object -r -d "Target object (DN or SamAccountName)"
complete -c kronos -n "__fish_seen_subcommand_from search" -l query -r -d "Search query"
complete -c kronos -n "__fish_seen_subcommand_from kerberoast" -s T -l target-user -r -d "Specific user to roast"
complete -c kronos -n "__fish_seen_subcommand_from secretsdump" -s T -l target-user -r -d "Specific user to dump"
complete -c kronos -n "__fish_seen_subcommand_from reset" -s y -l yes -d "Skip confirmation prompt"
