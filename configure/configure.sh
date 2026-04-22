
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
echo "[+] Installed headers successfully"

echo "[+] CHANGING CURRENT PASS"
sudo passwd 
echo "[+] pass changed successfully"

echo "[+] CHANGING ROOT PASS"
sudo passwd root
echo "[+] root pass changed successfully"

echo "[+] CONFIGURING SHARING FOLDER"
sudo usermod -aG vboxsf kali
mount
echo "[+] shared fold conf successfully"




echo "[+] ZSH SHELL"
sudo chsh -s /bin/zsh
echo "[+] Zshel change successfully"

echo "[+] INSTALLING PIPX"
sudo apt -y install pipx
echo "[+] Installed pipx successfully"

echo "[+] INSTALLING TERMINATOR"
sudo apt -y install terminator
echo "[+] Installed terminator successfully"

echo "[+] INSTALLING BLOODHOUND"
sudo apt -y install bloodhound
echo "[+] Installed bloodhound successfully"

echo "[+] INSTALLING empire"
sudo apt -y install empire
echo "[+] Installed empire successfully"

echo "[+] INSTALLING XSSTRIKE"
sudo apt -y install xsstrike
echo "[+] Installed xsstrike successfully"

echo "[+] INSTALLING nuclei"
sudo apt -y install nuclei
echo "[+] Installed nuclei successfully"

echo "[+] INSTALLING DIRSEARCH"
sudo apt -y install dirsearch
echo "[+] Installed dirsearch successfully"

echo "[+] INSTALLING cmseek"
sudo apt -y install cmseek
echo "[+] Installed cmseek successfully"

echo "[+] INSTALLING gitxray"
sudo apt -y install gitxray
echo "[+] Installed gitxray successfully"


echo "[+] INSTALLING CHISEL"
sudo apt install -y chisel 
echo "[+] Installed chisel successfully"

echo "[+] INSTALLING rubeus"
sudo apt install -y rubeus 
echo "[+] Installed rubeus successfully"

echo "[+] INSTALLING paramspider"
sudo apt install -y paramspider 
echo "[+] Installed paramspider successfully"

echo "[+] INSTALLING ARJUN"
sudo apt install -y arjun 
echo "[+] Installed arjun successfully"

echo "[+] INSTALLING SUBFINDER"
sudo apt install -y subfinder 
echo "[+] Installed subfider successfully"


echo "[+] INSTALLING DIRSEARCH"
sudo apt install -y golang 
echo "[+] Installed golang successfully"

echo "[+] INSTALLING Zmap"
sudo apt install -y zmap 
echo "[+] Installed Zmap successfully"

echo "[+] INSTALLING awscli"
sudo apt install -y awscli 
echo "[+] Installed awscli successfully"

echo "[+] INSTALLING s3scanner"
sudo apt install -y s3scanner 
echo "[+] Installed s3scanner successfully"

echo "[+] INSTALLING httrack"
sudo apt install -y httrack 
echo "[+] Installed httrack successfully"



echo "[+] INSTALLING dalfox"
go install github.com/hahwul/dalfox/v2@latest
echo "[+] Installed dalfox successfully"

echo "[+] INSTALLING gau"
go install github.com/lc/gau/v2/cmd/gau@latest
echo "[+] Installed gau successfully"

git clone https://github.com/assetnote/kiterunner.git ~/Downloads/tools/kiterunner && \
(cd ~/Downloads/tools/kiterunner && sudo make build) && \
sudo ln -sf ~/Downloads/tools/kiterunner/dist/kr /usr/local/bin/kr && \
kr -h

echo "[+] Installed kiterunner successfully"

echo "[+] INSTALLING INTERLACE"
pipx install git+https://github.com/codingo/Interlace.git
echo "[+] Installed INTERLACE successfully"

echo "[+] INSTALLING ghauri"
pipx install git+https://github.com/r0oth3x49/ghauri
echo "[+] Installed ghauri successfully"


echo "[+] INSTALLING DorksEye"

git clone https://github.com/BullsEye0/dorks-eye.git ~/Downloads/tools/dorks-eye && \
(cd ~/Downloads/tools/dorks-eye && python3 -m venv env && ./env/bin/pip install -r requirements.txt)

echo "[+] Installed DorksEye successfully"

echo "[+] Aliasing DorksEye"

echo "alias dorks-eye='~/Downloads/tools/dorks-eye/env/bin/python ~/Downloads/tools/dorks-eye/dorks-eye.py'" >> ~/.bash_aliases

echo "[+] Aliasing DorksEye successfully"
echo "[+] Reload your shell or run: source ~/.bash_aliases"
echo "[+] Then run: dorks-eye"




echo "[+] INSTALLING GVM"
sudo apt install gvm -y && \
sudo gvm-setup && \
sudo gvm-check-setup && \
sudo gvm-start && \
echo "----------------------------------------------------------------" && \
echo "Installation successful! Scroll up to find your ADMIN password." && \
echo "Access the dashboard at: https://127.0.0.1:9392" && \
echo "----------------------------------------------------------------"








# echo "[+] INSTALLING Some-Tools"
# git clone https://github.com/som3canadian/Some-Tools ~/Downloads/tools/Some-Tools && \
# sudo ~/Downloads/tools/Some-Tools/sometools.sh setup



echo "[+] CLEANING"
sudo apt clean && sudo apt autoclean &&  sudo apt autoremove -y
echo "[OK]"