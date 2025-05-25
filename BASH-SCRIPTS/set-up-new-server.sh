#!/bin/bash

# Update repositories

sudo apt update && sudo apt upgrade -y

# Set hostname

while true; do
    echo ""
    read -p "Set Hostname? [Y=yes, N=no]" yesno
    case $yesno in
        [Yy]* )
            echo ""
            read -p 'new hostname:  ' hostname
            hostnamectl set-hostname $hostname
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

# Install Postfix

sudo apt install -y libsasl2-modules mailutils
sudo apt install -y postfix postfix-pcre

# Input for SMTP account
echo ""
echo "Enter SMTP Server Password..."
read -sp 'Password:  ' PWORD

sudo echo "smtp.gmail.com cyoppsalerts@gmail.com:$PWORD" > /etc/postfix/sasl_passwd

sudo postmap hash:/etc/postfix/sasl_passwd
sudo chmod 600 /etc/postfix/sasl_passwd

sudo sed -i 's/relayhost =/#relayhost =/g' /etc/postfix/main.cf 

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
echo "Enter Server Name..."
read -p 'Server Name:  ' servername

sudo echo "/^From:.*/ REPLACE From: $servername-Alert <pve1-alert@something.com>" > /etc/postfix/smtp_header_checks

sudo postmap hash:/etc/postfix/smtp_header_checks
echo ""

sudo postfix reload

# send test email

echo ""
echo "The server will now send a test email message. please enter the recipient email address."

read -p 'Recipient email address:  ' email

sudo echo "This is a test message from a new Linux server installation" | mail -s "Test Email From New Debian Server" $email

# setup unattended Upgrades

sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades

## Change 50unattended-upgrades File

sudo echo 'Unattended-Upgrade::Mail "email";
Unattended-Upgrade::MailReport "on-change";
Unattended-Upgrade::Automatic-Reboot "true";
' >> /etc/apt/apt.conf.d/51my-unattended-upgrades

echo ""
echo "Enter Admin email address for notifications..."
read -p 'Admin email address:  ' admin

sudo sed -i 's/email =/$admin =/g' /etc/apt/apt.conf.d/51my-unattended-upgrades


sudo unattended-upgrades -d

# setup UFW


# setup SSH

sudo echo "PubkeyAuthentication yes
AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2
PasswordAuthentication yes
PermitRootLogin no" >> /etc/ssh/sshd_config.d/my_config.conf
sudo mkdir .ssh
echo ""
echo "Enter Public SSH Key..."
read -p 'PUBLIC SSH KEY:  ' sshkey
sudo echo "$sshkey" >> ~/.ssh/authorized_keys
sudo systemctl restart sshd
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
            break

        ;;
        * )
            echo ""
            echo "Select either Y or N";;
    esac
done
