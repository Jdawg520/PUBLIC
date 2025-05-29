#!/bin/bash


sudo adduser bitwarden

sudo usermod -aG docker bitwarden

sudo mkdir /opt/bitwarden

sudo chmod -R 700 /opt/bitwarden

sudo chown -R bitwarden:bitwarden /opt/bitwarden

