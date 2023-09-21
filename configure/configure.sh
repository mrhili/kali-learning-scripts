
echo "[+] Update and upgrade machine"

sudo apt update -y && sudo apt full-upgrade -y

echo "[OK]"
echo "[+] ..."
echo "[+] ..."
echo "[+] ..."
echo "[+] Maybe you should reboot"
echo "[+] ..."
echo "[+] ..."
echo "[+] ..."

echo "[+] INSTALLING HEADERS"
sudo apt -y install linux-headers-$(uname -r)
echo "[OK]"

echo "[+] CHANGING CURRENT PASS"
sudo passwd 
echo "[OK]"

echo "[+] CHANGING ROOT PASS"
sudo passwd root
echo "[OK]"

echo "[+] CONFIGURING SHARING FOLDER"
sudo usermod -aG vboxsf kali
mount
echo "[OK]"


echo "[+] ZSH SHELL"
sudo chsh -s /bin/zsh
echo "[OK]"

echo "[+] INSTALLING TERMINATOR"
sudo apt -y install terminator
echo "[OK]"


echo "[+] CLEANING"
sudo apt clean && sudo apt autoclean &&  sudo apt autoremove -y
echo "[OK]"