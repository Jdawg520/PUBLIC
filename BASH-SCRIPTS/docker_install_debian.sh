#!/bin/bash

cat << "EOF"

 ____             _               
|  _ \  ___   ___| | _____ _ __   
| | | |/ _ \ / __| |/ / _ \ '__|  
| |_| | (_) | (__|   <  __/ |     
|____/ \___/ \___|_|\_\___|_| _ _ 
      |_ _|_ __  ___| |_ __ _| | |
       | || '_ \/ __| __/ _` | | |
       | || | | \__ \ || (_| | | |
      |___|_| |_|___/\__\__,_|_|_|

EOF

cat << EOF
This script will install Docker and Docker Compose
on this system.

Copyright 2025-$(date +'%Y'), Jonathan Syposs.

===================================================

EOF


# Update Repositories

sudo apt update && sudo apt upgrade -y

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install latest version

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify installation

sudo docker run hello-world

echo ""
echo ""
echo "DOCKER INSTALL COMPLETE"
