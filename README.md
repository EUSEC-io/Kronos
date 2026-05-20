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
- 🧙 **Interactive Wizards**: Guided prompts for complex attacks (Golden/Silver/Diamond/Sapphire tickets).
- 🧠 **Smart Persistence**: Remembers your previous inputs (SIDs, Hashes, IPs) to save you from repetitive copy-pasting.
- 🎯 **Deep Context**: Seamlessly pulls targets and credentials from the **[tgt](https://github.com/EUSEC-io/tgt)** framework.
- ⚡ **Auto-Loading**: Native Fish completions and functions for a fluid CLI experience.

---

## 🛠 Tools Invoked Under the Hood
Kronos stands on the shoulders of giants:
- **[NetExec (nxc)](https://github.com/PennyIsWise/NetExec)**: Password spraying, GMSA dumping, and domain information.
- **[Impacket](https://github.com/fortra/impacket)**: The powerhouse behind roasting, SID enumeration, secrets dumping, and ticketing.
- **[BloodyAD](https://github.com/CravateRouge/bloodyAD)**: Advanced DACL manipulation, group management, and modern AD attacks (RBCD, Shadow Credentials).
- **[Kerbrute](https://github.com/ropnop/kerbrute)**: Lightning-fast user enumeration.
- **[Evil-WinRM](https://github.com/Hackplayers/evil-winrm)**: The ultimate WinRM shell.
- **[xfreerdp3](https://github.com/FreeRDP/FreeRDP)**: High-performance RDP access with auto-sharing.
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
After installing the Fish functions, run the automated bootstrap script to install NetExec, Impacket, bloodyAD, Kerbrute, and more:

```bash
kronos install
```

---

## 🎯 Deep TGT Integration
Kronos is built to be used alongside **[tgt](https://github.com/EUSEC-io/tgt)**. It automatically monitors your environment for the following variables:

| Variable | Usage |
| :--- | :--- |
| `TGT_DC_IP` | Primary target for all AD-based commands. |
| `TGT_DC_DOMAIN` | Target domain FQDN for authentication. |
| `TGT_CRED_USERNAME` | Active username used for login. |
| `TGT_CRED_PASSWORD` | Active password or NTLM hash. |
| `KRB5CCNAME` | Active Kerberos ticket used when `-k` is passed. |

---

## 🚀 Usage

### Connection Protocols
Standard protocols are nested under the `connect` command.
- **Interactive Mode**: Simply run `kronos connect` to open the protocol selector.
- **Direct Mode**: `kronos connect <proto> <IP>`
  - `rdp`: Connect via RDP. Supports wizard for screen-size and drive sharing.
  - `winrm`: Connect via Evil-WinRM (supports `-k` and `-H`).
  - `smb`: Launch an interactive `smbclient` shell.
  - `mssql`: Connect via `mssqlclient.py` (supports `-k`).
  - `rpc`: Connect via `rpcclient`.

### Active Directory Operations
Automate common enumeration and manipulation tasks:
- `userenum`: Run Kerbrute and automatically save results to `valid_users.txt`.
- `spray`: Password spray using `valid_users.txt` (or custom list) via NetExec.
- `asrep-roast`: Perform AS-REP roasting against target users.
- `kerbroast`: Perform Kerberoasting against all or specific SPNs.
- `lookupsid`: Enumerate SIDs. Use `-D` to quickly grab the **Domain SID**.
- `ingest`: Run BloodHound-Python and generate a clean `.zip` output.
- `forcechange`: Forcefully reset a user's password using `bloodyAD`.
- `search`: Search AD objects and fetch specific attributes.
- `dacl`: Full ACE manipulation (Add/Remove permissions like DCSync).
- `secretsdump`: Dump hashes, LSA secrets, and NTDS.dit.
- `rbcd` / `shadow-credentials`: Modern AD escalation primitives.

### Ticketing & Kerberos
- `request`: Wrapper for `getTGT` / `getST`. **Auto-exports** `KRB5CCNAME` context.
- `ticket [golden|silver|diamond|sapphire]`:
  - Run with flags for direct forging.
  - Run without flags for a **Guided Wizard** that pre-fills your cached values.
- `convert`: Seamlessly convert between `.kirbi` and `.ccache` formats.

---

## 🧠 Smart Features

### **Persistent Variable Caching**
Kronos remembers what you do so you don't have to. Whenever you enter a SID, a Hash, or a Domain in a wizard, it is saved to your Fish universal variables. The next time you run a command, those values are offered as the default.
> **Tip**: To clear a cached value, delete the text in the prompt and type a single dot `.`

### **Kerberos Authentication**
Most Kronos commands support the `-k` or `--kerberos` flag. If you have a valid ticket in your `$KRB5CCNAME` (likely generated by `kronos request`), Kronos will automatically bypass password requirements and use the ticket.

---

## 📜 License
**NON-COMMERCIAL / NON-DISTRIBUTION LICENSE**

Permission is granted to use this software for personal and educational purposes only. 
- **NO** distribution or publishing of the source code or derivative works.
- **NO** commercial exploitation or selling of this software.

Copyright (c) 2026.
