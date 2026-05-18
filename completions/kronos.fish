# completions/kronos.fish

set -l commands userenum dominfo ingest rdp winrm ftp smb rpc asrep-roast kerbroast spray forcechange gmsa ticket convert request lookupsid install help

# Disable file completions unless explicitly allowed
complete -c kronos -f

# Main commands
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a userenum -d "Run kerbrute userenum"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a dominfo -d "Query domain info and password policy"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a ingest -d "Ingest AD data using bloodhound-python"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a rdp -d "Connect via RDP (xfreerdp3)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a winrm -d "Connect via WinRM (evil-winrm)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a ftp -d "Connect via FTP"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a smb -d "Connect via SMB (smbclient)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a rpc -d "Connect via RPC (rpcclient)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a asrep-roast -d "AS-REP Roasting (GetNPUsers.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a kerbroast -d "Kerberoasting (GetUserSPNs.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a spray -d "Password spray using valid_users.txt"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a forcechange -d "Force change user password (bloodyAD)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a gmsa -d "Read GMSA passwords (nxc)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a ticket -d "Create Golden/Silver tickets"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a convert -d "Convert kirbi/ccache tickets"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a request -d "Request TGT/ST (getTGT/getST)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a lookupsid -d "Enumerate AD SIDs (lookupsid.py)"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a install -d "Install all dependencies"
complete -c kronos -n "not __fish_seen_subcommand_from $commands" -a help -d "Show help menu"

# Shared flags
set -l auth_flags -u --username -p --password -H --hash -k --kerberos -d --domain
complete -c kronos -n "__fish_seen_subcommand_from dominfo rdp winrm smb rpc asrep-roast kerbroast forcechange gmsa lookupsid ingest request" -s u -l username -d "Username"
complete -c kronos -n "__fish_seen_subcommand_from dominfo rdp winrm smb rpc kerbroast forcechange gmsa lookupsid ingest request" -s p -l password -d "Password"
complete -c kronos -n "__fish_seen_subcommand_from rdp winrm smb rpc kerbroast forcechange gmsa lookupsid request" -s H -l hash -d "NTLM Hash"
complete -c kronos -n "__fish_seen_subcommand_from dominfo winrm smb rpc asrep-roast kerbroast forcechange gmsa lookupsid ingest" -s k -l kerberos -d "Use Kerberos authentication"
complete -c kronos -n "__fish_seen_subcommand_from userenum dominfo ingest rdp winrm ftp smb rpc asrep-roast kerbroast spray forcechange gmsa ticket convert request lookupsid" -s h -l help -d "Show help"

# Subcommand-specific flags
complete -c kronos -n "__fish_seen_subcommand_from userenum" -s w -l wordlist -r -d "Custom wordlist"
complete -c kronos -n "__fish_seen_subcommand_from dominfo" -s P -l pass-policy -d "Query password policy"
complete -c kronos -n "__fish_seen_subcommand_from dominfo" -s N -l NULL -d "Force NULL session"
complete -c kronos -n "__fish_seen_subcommand_from ingest" -s o -l output -r -d "Output zip filename"
complete -c kronos -n "__fish_seen_subcommand_from smb" -s s -l share -d "Target share (default: C\$)"
complete -c kronos -n "__fish_seen_subcommand_from kerbroast" -s t -l target -d "Roast specific user"
complete -c kronos -n "__fish_seen_subcommand_from spray" -s u -l userlist -r -d "User list (defaults to valid_users.txt)"
complete -c kronos -n "__fish_seen_subcommand_from forcechange" -s t -l target-user -d "Target user"
complete -c kronos -n "__fish_seen_subcommand_from forcechange" -s P -l new-password -d "New password"
complete -c kronos -n "__fish_seen_subcommand_from ticket" -s S -l sid -d "Domain SID"
complete -c kronos -n "__fish_seen_subcommand_from ticket" -s s -l spn -d "Target SPN (for Silver Ticket)"
complete -c kronos -n "__fish_seen_subcommand_from request" -s s -l spn -d "Target SPN (for ST request)"
complete -c kronos -n "__fish_seen_subcommand_from lookupsid" -s f -l filter -d "Filter output"
complete -c kronos -n "__fish_seen_subcommand_from lookupsid" -s D -l domain-sid -d "Only show Domain SID"
complete -c kronos -n "__fish_seen_subcommand_from convert" -s i -l input -r -d "Input ticket"
complete -c kronos -n "__fish_seen_subcommand_from convert" -s o -l output -r -d "Output ticket"
