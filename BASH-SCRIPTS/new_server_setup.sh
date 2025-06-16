#!/bin/bash

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
This script performs the inital set up of a Debian 
based server the way I like it.

Copyright 2025-$(date +'%Y'), Jonathan Syposs.

===================================================

EOF

# Check if script has root privileges

if [[ $(whoami) != "root" ]]; then
    echo ""
    echo "ERROR: This script must be run as 'root' or with 'sudo' to function."
    exit 1
fi

# Check if script has read / write privileges

if ! [[ $(stat -c "%A" $0) =~ "rw" ]]; then
   echo ""
   echo "ERROR: This script requires read / write privileges to function."
   exit 1
fi

# Update repositories

sudo apt update && sudo apt upgrade -y

# Install dependencies

sudo apt install curl

# Set hostname

while true; do
    echo ""
    read -p "Set Hostname? [Y=yes, N=no]" yesno
    case $yesno in
        [Yy]* )
            echo ""
            read -p 'new hostname:  ' hostname
            sudo hostnamectl set-hostname $hostname
            echo "NEW HOSTNAME SET!!!!"
            echo ""
            echo ""
            break

        ;;
        [Nn]* )
            break

        ;;
        * )
            echo ""
            echo "Select either Y or N";;
    esac
done

# Install Neofetch and Figurine

sudo apt install -y neofetch
sudo mkdir tmp
cd tmp
sudo wget https://github.com/arsham/figurine/releases/download/v1.3.0/figurine_linux_amd64_v1.3.0.tar.gz
sudo tar xvf figurine_linux_amd64_v1.3.0.tar.gz
sudo mv deploy/figurine /usr/local/bin/
cd ..
sudo rm -r tmp

sudo echo '#!/bin/bash

echo ""
/usr/local/bin/figurine -f "3d.flf" name1
echo ""
echo ""
neofetch
echo ""' > fig_neo.sh

echo ""
echo "ENTER SHELL DISPLAY NAME"
read -p 'Server Name:  ' neoname

sudo sed -i "s/name1/$neoname/g" fig_neo.sh
sudo mv fig_neo.sh /etc/profile.d/fig_neo.sh

# Install Postfix

sudo apt install -y libsasl2-modules mailutils
sudo apt install -y postfix postfix-pcre

# Input for SMTP account

echo ""
echo "Enter SMTP Server Password..."
read -sp 'Password:  ' PWORD

sudo sh -c "echo 'smtp.gmail.com cyoppsalerts@gmail.com:$PWORD' > /etc/postfix/sasl_passwd"

sudo postmap hash:/etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd

sudo sh -c "sed -i 's/relayhost/#relayhost/g' /etc/postfix/main.cf" 

sudo echo "# google mail configuration

relayhost = smtp.gmail.com:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options =
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/Entrust_Root_Certification_Authority.pem
smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache
smtp_tls_session_cache_timeout = 3600s
smtp_header_checks = pcre:/etc/postfix/smtp_header_checks" >> /etc/postfix/main.cf

echo ""
echo "Enter Email Display Name..."
read -p 'Server Name:  ' servername

sudo echo "/^From:.*/ REPLACE From: $servername-Alert <pve1-alert@something.com>" > /etc/postfix/smtp_header_checks

sudo postmap hash:/etc/postfix/smtp_header_checks
echo ""

sudo postfix reload

# send test email

echo ""
echo "The server will now send a test email message. please enter the recipient email address."

read -p 'Recipient email address:  ' email
echo "This is a test message from a new Linux server installation" | mail -s "Test Email From New Debian Server" $email


# setup unattended Upgrades

sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Change unattended-upgrades config File

sudo echo 'Unattended-Upgrade::Mail "email";
Unattended-Upgrade::MailReport "on-change";
Unattended-Upgrade::Automatic-Reboot "true";
' > /etc/apt/apt.conf.d/51my-unattended-upgrades

echo ""
echo "Enter Admin email address for notifications..."
read -p 'Admin email address:  ' admin

sudo sed -i "s/email/$admin/g" /etc/apt/apt.conf.d/51my-unattended-upgrades


sudo unattended-upgrades -d

# setup UFW


# setup SSH

sudo sh -c "echo 'PubkeyAuthentication yes
AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2
PasswordAuthentication no
PermitRootLogin no' > /etc/ssh/sshd_config.d/my_config.conf"

sudo mkdir .ssh

echo ""
echo "Enter Public SSH Key..."
read -p 'PUBLIC SSH KEY:  ' sshkey
sudo sh -c "echo '$sshkey' > .ssh/authorized_keys"

sudo systemctl restart sshd

# Copy bashrc file

sudo curl https://raw.githubusercontent.com/Jdawg520/PUBLIC/refs/heads/main/BASH-SCRIPTS/files/bashrc --output ~/.bashrc

# SYSTEM REBOOT

echo ""
echo ""
echo "SYSTEM REBOOT REQUIRED!!!"
while true; do
    read -p "Reboot Now? [Y=yes, N=no]" yesno2
    case $yesno2 in
        [Yy]* )
            sudo reboot now            
            break

        ;;
        [Nn]* )
            echo ""
            cat << EOF
               Please reboot the system as soon as possible.
            ===================================================   
                           INSTALLATION COMPLETE                
            ===================================================               

EOF
            exit 0
        ;;
        * )
            echo ""
            echo "Select either Y or N";;
    esac
done
exit 0
    esac
done
exit 0
