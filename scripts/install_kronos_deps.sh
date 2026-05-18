#!/bin/bash
# Kronos Dependency Installer

set -e

echo "[*] Initializing Kronos Dependency Installer..."

# Helper to check command existence
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Kerbrute
if ! command_exists kerbrute && ! command_exists kerbrute.py; then
    echo "[*] Installing kerbrute via go..."
    if command_exists go; then
        go install github.com/ropnop/kerbrute@latest
        echo "[+] kerbrute installed to ~/go/bin"
    else
        echo "[!] Error: 'go' is not installed. Skipping kerbrute."
    fi
else
    echo "[+] kerbrute already installed."
fi

# 2. NetExec (nxc)
if ! command_exists nxc; then
    echo "[*] Installing NetExec (nxc) via pipx..."
    if command_exists pipx; then
        pipx install netexec
        echo "[+] nxc installed."
    else
        echo "[!] Error: 'pipx' is not installed. Please install pipx to install NetExec."
    fi
else
    echo "[+] nxc already installed."
fi

# 3. rpcclient (Samba)
if ! command_exists rpcclient; then
    echo "[*] rpcclient not found. Please install the 'samba-common-bin' or 'smbclient' package for your distro."
else
    echo "[+] rpcclient already installed."
fi

# 4. bloodyAD
if ! command_exists bloodyAD; then
    echo "[*] Installing bloodyAD via pipx..."
    if command_exists pipx; then
        pipx install bloodyAD
        echo "[+] bloodyAD installed."
    else
        echo "[!] Error: 'pipx' is not installed."
    fi
else
    echo "[+] bloodyAD already installed."
fi

# 5. evil-winrm
if ! command_exists evil-winrm; then
    echo "[*] Installing evil-winrm via gem..."
    if command_exists gem; then
        sudo gem install evil-winrm
        echo "[+] evil-winrm installed."
    else
        echo "[!] Error: 'gem' (Ruby) is not installed."
    fi
else
    echo "[+] evil-winrm already installed."
fi

# 6. xfreerdp3
if ! command_exists xfreerdp3 && ! command_exists xfreerdp; then
    echo "[*] RDP client not found. Please install xfreerdp3 or xfreerdp."
else
    echo "[+] RDP client already installed."
fi

# 7. Impacket
if ! command_exists GetUserSPNs.py && ! command_exists impacket-GetUserSPNs; then
    echo "[*] Installing Impacket via pipx..."
    if command_exists pipx; then
        pipx install impacket
        echo "[+] Impacket installed."
    else
        echo "[!] Error: 'pipx' is not installed."
    fi
else
    echo "[+] Impacket tools already installed."
fi

# 8. bloodhound-python
if ! command_exists bloodhound-python; then
    echo "[*] Installing bloodhound-python via pipx..."
    if command_exists pipx; then
        pipx install bloodhound-python
        echo "[+] bloodhound-python installed."
    else
        echo "[!] Error: 'pipx' is not installed."
    fi
else
    echo "[+] bloodhound-python already installed."
fi

echo "[*] Kronos dependency check complete."
