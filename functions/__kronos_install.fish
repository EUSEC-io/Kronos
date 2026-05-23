# description: Install Kronos external dependencies
function __kronos_install --description "Install Kronos external dependencies"
    set_color cyan; echo "[*] Initializing Kronos Dependency Installer..."; set_color normal

    # 1. Kerbrute
    if not command -v kerbrute >/dev/null; and not command -v kerbrute.py >/dev/null
        echo "[*] Installing kerbrute via go..."
        if command -v go >/dev/null
            go install github.com/ropnop/kerbrute@latest
            echo "[+] kerbrute installed to ~/go/bin"
        else
            set_color red; echo "[!] Error: 'go' is not installed. Skipping kerbrute."; set_color normal
        end
    else
        echo "[+] kerbrute already installed."
    end

    # 2. NetExec (nxc)
    if not command -v nxc >/dev/null
        echo "[*] Installing NetExec (nxc) via pipx..."
        if command -v pipx >/dev/null
            pipx install netexec
            echo "[+] nxc installed."
        else
            set_color red; echo "[!] Error: 'pipx' not found. Install pipx first."; set_color normal
        end
    else
        echo "[+] nxc already installed."
    end

    # 3. Samba Tools
    if not command -v rpcclient >/dev/null; or not command -v smbclient >/dev/null
        set_color yellow; echo "[*] rpcclient/smbclient not found. Please install your OS samba-common-bin package."; set_color normal
    else
        echo "[+] rpcclient and smbclient already installed."
    end

    # 4. bloodyAD
    if not command -v bloodyAD >/dev/null
        echo "[*] Installing bloodyAD via pipx..."
        if command -v pipx >/dev/null
            pipx install bloodyAD
            echo "[+] bloodyAD installed."
        else
            set_color red; echo "[!] Error: 'pipx' not found."; set_color normal
        end
    else
        echo "[+] bloodyAD already installed."
    end

    # 5. evil-winrm
    if not command -v evil-winrm >/dev/null
        echo "[*] Installing evil-winrm via gem..."
        if command -v gem >/dev/null
            sudo gem install evil-winrm
            echo "[+] evil-winrm installed."
        else
            set_color red; echo "[!] Error: 'gem' (Ruby) not found."; set_color normal
        end
    else
        echo "[+] evil-winrm already installed."
    end

    # 6. xfreerdp3
    if not command -v xfreerdp3 >/dev/null; and not command -v xfreerdp >/dev/null
        set_color yellow; echo "[*] RDP client not found. Please install xfreerdp3 or xfreerdp."; set_color normal
    else
        echo "[+] RDP client already installed."
    end

    # 7. Impacket
    if not command -v GetUserSPNs.py >/dev/null; and not command -v impacket-GetUserSPNs >/dev/null
        echo "[*] Installing Impacket via pipx..."
        if command -v pipx >/dev/null
            pipx install impacket
            echo "[+] Impacket installed."
        else
            set_color red; echo "[!] Error: 'pipx' not found."; set_color normal
        end
    else
        echo "[+] Impacket tools already installed."
    end

    # 8. bloodhound-python
    if not command -v bloodhound-python >/dev/null
        echo "[*] Installing bloodhound-python via pipx..."
        if command -v pipx >/dev/null
            pipx install bloodhound-python
            echo "[+] bloodhound-python installed."
        else
            set_color red; echo "[!] Error: 'pipx' not found."; set_color normal
        end
    else
        echo "[+] bloodhound-python already installed."
    end

    # 9. gum (Interactive UI)
    if not command -v gum >/dev/null
        echo "[*] Installing gum via go..."
        if command -v go >/dev/null
            go install github.com/charmbracelet/gum@latest
            echo "[+] gum installed."
        else
            set_color red; echo "[!] Error: 'go' not found."; set_color normal
        end
    else
        echo "[+] gum already installed."
    end

    set_color green; echo "[*] Kronos dependency check complete."; set_color normal
end