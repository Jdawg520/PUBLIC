#!/bin/bash

#==================================================
# Debian Server Initial Setup Script
# Author: Jonathan Syposs (2025-$(date +'%Y'))
#==================================================

# Colors
RED='\033[0;31m'
NC='\033[0m'

# Root check
if [[ $(id -u) -ne 0 ]]; then
    echo -e "${RED}ERROR:${NC} This script must be run as root."
    exit 1
fi

# Banner
cat << "EOF"
 ____                                    
/ ___|  ___ _ ____   _____ _ __          
\___ \ / _ \ '__\ \ / / _ \ '__|         
 ___) |  __/ |   \ V /  __/ |            
|____/ \___|_|    \_/ \___|_|            
      / ___|  ___| |_ _   _ _ __         
      \___ \ / _ \ __| | | | '_ \        
       ___) |  __/ |_| |_| | |_) |       
      |____/ \___|\__|\__,_| .__/        
             ____          |_|       _   
            / ___|  ___ _ __(_)_ __ | |_ 
            \___ \ / __| '__| | '_ \| __|
             ___) | (__| |  | | |_) | |_ 
            |____/ \___|_|  |_| .__/ \__|
                              |_|        
EOF

cat << EOF
This script performs the initial set up of a Debian-based server.

===================================================

EOF

# Update system
echo "Updating repositories and packages..."
apt -qq update && apt-get -qq upgrade -y

# Install dependencies
echo "Installing dependencies..."
apt-get -qq install -y curl neofetch libsasl2-modules mailutils postfix postfix-pcre unattended-upgrades ufw

# Hostname setup
while true; do
    read -p "Set Hostname? [Y/N]: " yn
    case $yn in
        [Yy]* )
            read -p "New hostname: " hostname
            hostnamectl set-hostname "$hostname"
            echo "Hostname set to $hostname."
            break ;;
        [Nn]* ) break ;;
        * ) echo "Please enter Y or N." ;;
    esac
done

# Install Figurine safely
echo "Installing Figurine..."
tmpdir=$(mktemp -d)
cd "$tmpdir"
wget -q https://github.com/arsham/figurine/releases/download/v1.3.0/figurine_linux_amd64_v1.3.0.tar.gz
# TODO: Add checksum verification here
tar xvf figurine_linux_amd64_v1.3.0.tar.gz
mv deploy/figurine /usr/local/bin/
cd /
rm -rf "$tmpdir"

# Create fig_neo.sh
read -p "ENTER SSH / SHELL SERVER DISPLAY NAME: " neoname
tee /etc/profile.d/fig_neo.sh > /dev/null <<EOF
#!/bin/bash
echo ""
/usr/local/bin/figurine -f "3d.flf" "$neoname"
echo ""
echo ""
neofetch
echo ""
EOF
chmod +x /etc/profile.d/fig_neo.sh

# Configure Postfix for Gmail relay
read -sp "Enter SMTP Server Password: " PWORD
echo
tee /etc/postfix/sasl_passwd > /dev/null <<EOF
smtp.gmail.com cyoppsalerts@gmail.com:$PWORD
EOF
postmap hash:/etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd

sed -i 's/^relayhost/#relayhost/g' /etc/postfix/main.cf
tee -a /etc/postfix/main.cf > /dev/null <<EOF
relayhost = smtp.gmail.com:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options =
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/Entrust_Root_Certification_Authority.pem
smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache
smtp_tls_session_cache_timeout = 3600s
smtp_header_checks = pcre:/etc/postfix/smtp_header_checks
EOF

read -p "Enter Email Display Name: " servername
tee /etc/postfix/smtp_header_checks > /dev/null <<EOF
/^From:.*/ REPLACE From: ${servername}-Alert <pve1-alert@something.com>
EOF
postmap hash:/etc/postfix/smtp_header_checks
postfix reload

# Test email
read -p "Recipient email address for test: " email
echo "This is a test message from a new Debian server installation" | mail -s "Test Email From New Debian Server" "$email"

# Configure unattended upgrades
read -p "Enter Admin email address for notifications: " admin
tee /etc/apt/apt.conf.d/51my-unattended-upgrades > /dev/null <<EOF
Unattended-Upgrade::Mail "$admin";
Unattended-Upgrade::MailReport "on-change";
Unattended-Upgrade::Automatic-Reboot "true";
EOF
unattended-upgrades -d

# Configure UFW firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw enable

# Configure SSH
mkdir -p /root/.ssh
chmod 700 /root/.ssh
read -p "Enter Public SSH Key: " sshkey
echo "$sshkey" > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

tee /etc/ssh/sshd_config.d/my_config.conf > /dev/null <<EOF
PubkeyAuthentication yes
AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2
PasswordAuthentication no
PermitRootLogin no
EOF
systemctl restart sshd

# Install bashrc customizations
for path in "/root/.bashrc" "/etc/skel/.bashrc"; do
    curl -q https://raw.githubusercontent.com/Jdawg520/PUBLIC/refs/heads/main/BASH-SCRIPTS/files/bashrc --output "$path"
done
read -p "Enter username to update .bashrc: " username
if id "$username" &>/dev/null; then
    curl -q https://raw.githubusercontent.com/Jdawg520/PUBLIC/refs/heads/main/BASH-SCRIPTS/files/bashrc --output "/home/$username/.bashrc"
    chown "$username":"$username" "/home/$username/.bashrc"
fi

# Reboot prompt
while true; do
    read -p "SYSTEM REBOOT REQUIRED!!! Reboot now? [Y/N]: " yn
    case $yn in
        [Yy]* ) reboot now ;;
        [Nn]* )
            echo "Please reboot the system as soon as possible!"
            echo "INSTALLATION COMPLETE"
            exit 0 ;;
        * ) echo "Please enter Y or N." ;;
    esac
done