# Kronos Active Directory Attack Orchestrator

Kronos is a modular Fish shell orchestration tool designed to automate and simplify Active Directory penetration testing. It acts as a powerful wrapper around industry-standard tools, providing a unified CLI with deep context integration via the **[tgt](https://github.com/fuxx/tgt)** framework.

## 🛠 Tools Invoked Under the Hood
Kronos orchestrates the following utilities:
- **NetExec (nxc)**: Password spraying, GMSA dumping, and domain information.
- **Impacket**: AS-REP roasting (`GetNPUsers.py`), Kerberoasting (`GetUserSPNs.py`), SID enumeration (`lookupsid.py`), and ticketing (`ticketer.py`, `getTGT.py`, `getST.py`).
- **BloodyAD**: Forceful password resets and advanced AD object manipulation.
- **Kerbrute**: Rapid user enumeration.
- **Evil-WinRM**: Command-line WinRM access.
- **xfreerdp3**: High-performance GUI RDP access.
- **BloodHound-Python**: AD data ingestion for BloodHound.

## 📦 Installation

1. **Install Fish Functions (Autoloading):**
   Symlink the Kronos functions and completions to your Fish configuration directory:
   ```bash
   mkdir -p ~/.config/fish/functions ~/.config/fish/completions
   ln -sf /path/to/Kronos-Active-Directory-attack-orchestrator/functions/*.fish ~/.config/fish/functions/
   ln -sf /path/to/Kronos-Active-Directory-attack-orchestrator/completions/kronos.fish ~/.config/fish/completions/
   ```

2. **Install External Dependencies:**
   Kronos includes an automated installer for all required external tools:
   ```bash
   kronos install
   ```

## 🎯 Deep TGT Integration
Kronos respects the following `tgt` global variables to eliminate manual targeting:
- `TGT_DC_IP` / `TGT_DC`: Primary targets for AD operations.
- `TGT_DC_DOMAIN`: Lowercase domain for authentication flags.
- `TGT_CRED_USERNAME` / `TGT_CRED_PASSWORD`: Active credentials.
- `KRB5CCNAME`: Automatic Kerberos context for `-k` flags.

## 🚀 Usage

### Connection Protocols
- `kronos rdp <IP>`: Connect via RDP (xfreerdp3).
- `kronos winrm <IP>`: Connect via WinRM (evil-winrm).
- `kronos smb <IP>`: Interactive SMB shell (smbclient).
- `kronos rpc <IP>`: Interactive RPC shell (rpcclient).
- `kronos ftp <IP>`: Connect via FTP.

### Active Directory Operations
- `kronos userenum`: Enumerate users and auto-save to `valid_users.txt`.
- `kronos spray -p <pass>`: Spray `valid_users.txt` using nxc.
- `kronos asrep-roast`: Perform AS-REP roasting.
- `kronos kerbroast`: Perform Kerberoasting.
- `kronos lookupsid`: Enumerate all AD SIDs or isolate the Domain SID (`-D`).
- `kronos ingest`: Gather BloodHound data.
- `kronos forcechange -t <user> -P <newpass>`: Force a password reset.

### Ticketing & Kerberos
- `kronos request`: Request a TGT/ST and **automatically export KRB5CCNAME**.
- `kronos ticket`: Forge Golden/Silver tickets.
- `kronos convert`: Convert between `.kirbi` and `.ccache`.

## 📜 License
**NON-COMMERCIAL / NON-DISTRIBUTION LICENSE**
You may use this software personally. You may NOT distribute, publish, share, or sell this software or any derivative works.
