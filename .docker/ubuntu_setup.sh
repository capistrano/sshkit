#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive
apt -y update

# Create `deployer` user that can sudo without a password
apt-get -y install sudo
adduser --disabled-password deployer < /dev/null
echo "deployer:topsecret" | chpasswd
echo "deployer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install and configure sshd
apt-get -y install openssh-server
{
  echo "Port 22"
  echo "PasswordAuthentication yes"
  echo "ChallengeResponseAuthentication no"
} >> /etc/ssh/sshd_config
mkdir /var/run/sshd
chmod 0755 /var/run/sshd
