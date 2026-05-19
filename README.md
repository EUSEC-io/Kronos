# Kronos Active Directory Attack Orchestrator

Kronos is a modular Fish shell orchestration tool designed to automate and simplify Active Directory penetration testing. It acts as a powerful wrapper around industry-standard tools, providing a unified CLI with deep context integration via the **[tgt](https://github.com/fuxx/tgt)** framework.

## 🛠 Tools Invoked Under the Hood
Kronos orchestrates the following utilities:
- **NetExec (nxc)**: Password spraying, GMSA dumping, and domain information.
- **Impacket**: AS-REP roasting, Kerberoasting, SID enumeration, secrets dumping, computer creation, and ticketing.
- **BloodyAD**: Forceful password resets, DACL manipulation, group management, RBCD, and Shadow Credentials.
- **Kerbrute**: Rapid user enumeration.
- **Evil-WinRM**: Command-line WinRM access.
- **xfreerdp3**: High-performance GUI RDP access.
- **BloodHound-Python**: AD data ingestion for BloodHound.
- **Gum**: Powers the interactive wizards and prompts.

## 📦 Installation

1. **Install Fish Functions (Autoloading):**
   Symlink the Kronos functions and completions to your Fish configuration directory:
   \`\`\`bash
   mkdir -p ~/.config/fish/functions ~/.config/fish/completions
   ln -sf /path/to/Kronos-Active-Directory-attack-orchestrator/functions/*.fish ~/.config/fish/functions/
   ln -sf /path/to/Kronos-Active-Directory-attack-orchestrator/completions/kronos.fish ~/.config/fish/completions/
   \`\`\`

2. **Install External Dependencies:**
   Kronos includes an automated installer for all required external tools:
   \`\`\`bash
   kronos install
   \`\`\`

## 🎯 Deep TGT Integration
Kronos respects the following \`tgt\` global variables to eliminate manual targeting:
- \`TGT_DC_IP\` / \`TGT_DC\`: Primary targets for AD operations.
- \`TGT_DC_DOMAIN\`: Lowercase domain for authentication flags.
- \`TGT_CRED_USERNAME\` / \`TGT_CRED_PASSWORD\`: Active credentials.
- \`KRB5CCNAME\`: Automatic Kerberos context for \`-k\` flags.

## 🚀 Usage

### Connection Protocols
- \`kronos connect rdp <IP>\`: Connect via RDP (xfreerdp3).
- \`kronos connect winrm <IP>\`: Connect via WinRM (evil-winrm).
- \`kronos connect smb <IP>\`: Interactive SMB shell (smbclient).
- \`kronos connect rpc <IP>\`: Interactive RPC shell (rpcclient).
- \`kronos connect ftp <IP>\`: Connect via FTP.
- \`kronos connect mssql <IP>\`: Interactive MSSQL shell (mssqlclient.py).

### Active Directory Operations
- \`kronos userenum\`: Enumerate users and auto-save to \`valid_users.txt\`.
- \`kronos spray -p <pass>\`: Spray \`valid_users.txt\` using nxc.
- \`kronos asrep-roast\`: Perform AS-REP roasting.
- \`kronos kerbroast\`: Perform Kerberoasting.
- \`kronos lookupsid\`: Enumerate all AD SIDs or isolate the Domain SID (\`-D\`).
- \`kronos ingest\`: Gather BloodHound data.
- \`kronos forcechange -t <user> -P <newpass>\`: Force a password reset.
- \`kronos search -q <query>\`: Search and enumerate AD objects.
- \`kronos add-user -U <newuser> -P <pass>\`: Create a new AD user.
- \`kronos add-member -g <group> -m <user>\`: Add a user to an AD group.
- \`kronos add-computer -C <computer> -P <pass>\`: Create a new computer account.
- \`kronos dacl -t <target> -m <user> -a add -p genericAll\`: Manipulate DACLs.
- \`kronos secretsdump\`: Dump AD secrets (hashes/keys).
- \`kronos rbcd -t <computer> -m <attacker>\`: Perform RBCD attack.
- \`kronos shadow-credentials -t <user>\`: Perform Shadow Credentials attack.

### Ticketing & Kerberos
- \`kronos request\`: Request a TGT/ST and **get the manual export command**.
- \`kronos ticket [golden|silver]\`: Forge Golden/Silver tickets. If called without flags, **an interactive wizard** will guide you through the process.
- \`kronos convert\`: Convert between \`.kirbi\` and \`.ccache\`.

## 📜 License
**NON-COMMERCIAL / NON-DISTRIBUTION LICENSE**
You may use this software personally. You may NOT distribute, publish, share, or sell this software or any derivative works.
