# 🪐 KRONOS
### *Active Directory Attack Orchestrator*

![Fish Shell](https://img.shields.io/badge/Shell-Fish-blue.svg)
![License](https://img.shields.io/badge/License-Non--Commercial-red.svg)
![Maintained](https://img.shields.io/badge/Maintained-Yes-green.svg)

**Kronos** is a modular, high-performance orchestration tool built for the Fish shell. It is designed to automate and simplify the complexities of Active Directory penetration testing by wrapping industry-standard tools into a unified, context-aware CLI.

---

## 📑 Contents
- [✨ Features](#-features)
- [🛠 Tools Orchestrated](#-tools-invoked-under-the-hood)
- [📦 Installation](#-installation)
- [🎯 Deep TGT Integration](#-deep-tgt-integration)
- [🚀 Usage](#-usage)
  - [Connection Protocols](#connection-protocols)
  - [Active Directory Operations](#active-directory-operations)
  - [Ticketing & Kerberos](#ticketing--kerberos)
- [🧠 Smart Features](#-smart-features)
- [📜 License](#-license)

---

## ✨ Features
- 🚀 **Unified Workflow**: One command to rule them all. No more remembering complex flag syntax for 10+ different tools.
- 🧙 **Interactive Wizards**: Guided prompts for complex attacks (Golden/Silver/Diamond/Sapphire/Bronze tickets).
- 🧬 **Automated Abuse Chains**: Built-in sequences for AD CS exploitation (ESC1 through ESC13).
- 🕒 **Global Faketime**: Sync your system time with the DC for Kerberos authentication in one command.
- 🧠 **Smart Persistence**: Remembers your previous inputs (SIDs, Hashes, IPs) and **identifies sources** (TGT, Cache, CLI).
- 🎯 **Deep Context**: Seamlessly pulls targets and credentials from the **[tgt](https://github.com/EUSEC-io/tgt)** framework.
- ⚡ **Auto-Loading**: Native Fish completions and functions for a fluid CLI experience.


---

## 🎬 Demos

### 🌟 Unified Interactive Menu
Launch the main orchestrator and pick your attack vector from the top-down menu.
![Kronos Main Menu](assets/kronos-main.gif)

### 🪄 Guided Attack Wizards
Complex commands like **PsExec** or **SecretsDump** now guide you through every step with pre-filled context from `tgt`.
![PsExec Wizard](assets/kronos-psexec.gif)

### 🔎 Command Inspection & Editing
Use the `-X` flag to preview and manually tweak the constructed command before execution.
![Command Inspection](assets/kronos-inspect.gif)
---

## 🛠 Tools Invoked Under the Hood
Kronos stands on the shoulders of giants:
- **[NetExec (nxc)](https://github.com/PennyIsWise/NetExec)**: Spraying, GMSA dumping, info gathering, and AD CS relay.
- **[Impacket](https://github.com/fortra/impacket)**: The powerhouse behind roasting, SID enumeration, secrets dumping, and ticketing.
- **[Certipy](https://github.com/ly4k/Certipy)**: Comprehensive AD CS discovery and exploitation (ESC1..ESC13).
- **[BloodyAD](https://github.com/CravateRouge/bloodyAD)**: Advanced DACL manipulation, group management, and modern AD attacks.
- **[LDeep](https://github.com/franc-pentest/ldeep)**: High-performance LDAP enumeration and GMSA dumping.
- **[Adidnsdump](https://github.com/dirkjanm/adidnsdump)**: Internal AD DNS record extraction.
- **[Kerbrute](https://github.com/ropnop/kerbrute)**: Lightning-fast user enumeration.
- **[Evil-WinRM](https://github.com/Hackplayers/evil-winrm)**: The ultimate WinRM shell.
- **[xfreerdp3](https://github.com/FreeRDP/FreeRDP)**: High-performance RDP access with auto-sharing and clipboard support.
- **[Gum](https://github.com/charmbracelet/gum)**: Powers the beautiful interactive menus and prompts.

---

## 📦 Installation

### 1. Install via Fisher (Recommended)
The easiest way to install Kronos is using the **[fisher](https://github.com/jorgebucaran/fisher)** plugin manager:

```bash
fisher install EUSEC-io/Kronos
```

### 2. Manual Installation
If you prefer to link the files manually:
```bash
mkdir -p ~/.config/fish/functions ~/.config/fish/completions
ln -sf /path/to/Kronos/functions/*.fish ~/.config/fish/functions/
ln -sf /path/to/Kronos/completions/kronos.fish ~/.config/fish/completions/
```

### 3. Bootstrap Dependencies
After installing the Fish functions, run the automated bootstrap script to install all required utilities:

```bash
kronos install
```

---

## 🎯 Deep TGT Integration
Kronos is built to be used alongside **[tgt](https://github.com/EUSEC-io/tgt)**. It automatically monitors your environment for the following variables:

| Variable | Usage | Priority |
| :--- | :--- | :--- |
| `TGT` | Primary Target IP Address. | **High** |
| `TGT_HOSTS` | Primary Target Domain Name. | **High** |
| `TGT_DC_IP` | Fallback IP for Domain Controllers. | Medium |
| `TGT_DC_DOMAIN` | Fallback FQDN for authentication. | Medium |
| `TGT_CRED_USERNAME` | Active username used for login. | Medium |
| `TGT_CRED_PASSWORD` | Active password or NTLM hash. | Medium |
| `KRB5CCNAME` | Active Kerberos ticket used when `-k` is passed. | **Auto** |

---

## 🚀 Usage

### Connection Protocols
Standard protocols are nested under the `connect` command.
- **Interactive Mode**: Simply run `kronos connect` to open the protocol selector.
- **Direct Mode**: `kronos connect <proto> <IP>`
  - `rdp`: Connect via RDP. Supports wizard for **Fullscreen** and **Drive Sharing**.
  - `winrm`: Connect via Evil-WinRM (supports `-k` and `-H`).
  - `smb`: Launch an interactive `smbclient` shell.
  - `mssql`: Connect via `mssqlclient.py` (supports `-k` and hashes).
  - `rpc`: Connect via `rpcclient`.

### Active Directory Operations
Automate common enumeration and manipulation tasks:
- `userenum`: Multi-mode enumeration (**Wordlist**, **NULL Session**, or **Credentials**). Supports **LDAP Export** to `users.txt`.
- `dominfo`: High-performance enumeration with multi-select wizard.
  - `users`, `groups` (via LDAP), `shares`, `policy`, `loggedon`.
- `cert`: Full AD CS attack suite.
  - `find` (discovery), `req` (request), `auth` (pfx auth), `abuse` (**ESC1-ESC13 chains**).
- `gpp`: Extract and decrypt **GPP Passwords** and **Autologon** registries.
- `dnsdump`: Dump all internal AD DNS records using `adidnsdump`.
- `faketime`: Set a global time offset (e.g. `+8h`) for Kerberos commands.
- `spray`: Password spray using `valid_users.txt` via NetExec.
- `asrep-roast` / `kerberoast`: Roasting attacks (automatically exports tickets).
- `lookupsid`: Enumerate SIDs. Use `-D` to quickly grab the **Domain SID**.
- `ingest`: Run BloodHound-Python and generate a clean `.zip` output.
- `secretsdump`: Dump hashes, LSA secrets, and NTDS.dit.
- `psexec`: Remote command execution via `psexec.py`.
- `rbcd` / `shadow-credentials`: Modern AD escalation primitives.

### Ticketing & Kerberos
- `request`: Wrapper for `getTGT` / `getST`. **Auto-exports** `KRB5CCNAME`.
- `ticket [golden|silver|diamond|sapphire|trust|cross-forest|bronze]`:
  - `cross-forest`: Automated **RaiseChild** attack via NetExec.
  - `bronze`: **Bronze Bit** attack (CVE-2020-17049) using `getST.py`.
- `convert`: Seamlessly convert between `.kirbi` and `.ccache` formats.
- `reset`: Clear all persistent cache variables (SIDs, Hashes, etc.).

---

## 🧠 Smart Features

### **Wizard Source Tracking**
Prompts now show you exactly where the default value is coming from:
*   `[Source: TGT | ...]`
*   `[Source: TGT_HOSTS | ...]`
*   `[Source: Cache | ...]`

### **Automatic Ticket Export**
Kronos automatically detects when a new Kerberos ticket (`.ccache`) is generated and exports its full path to your **`$KRB5CCNAME`** environment variable immediately.

### **Persistent Variable Caching**
Kronos remembers what you do so you don't have to. Whenever you enter a SID, a Hash, or a Domain in a wizard, it is saved to your Fish universal variables. 
> **Tip**: To clear a cached value, delete the text in the prompt and type a single dot `.`

---

## 📜 License
**NON-COMMERCIAL / NON-DISTRIBUTION LICENSE**

Permission is granted to use this software for personal and educational purposes only. 
- **NO** distribution or publishing of the source code or derivative works.
- **NO** commercial exploitation or selling of this software.

Copyright (c) 2026. EUSEC.
