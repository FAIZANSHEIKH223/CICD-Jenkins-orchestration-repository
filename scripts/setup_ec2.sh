#!/bin/bash

set -e

echo "======================================"
echo "Updating System"
echo "======================================"

sudo apt-get update -y

echo "======================================"
echo "Installing Required Packages"
echo "======================================"

sudo apt-get install -y \
    ca-certificates \
    curl \
    unzip \
    jq

echo "======================================"
echo "Installing Docker"
echo "======================================"

if ! command -v docker >/dev/null 2>&1; then

    curl -fsSL https://get.docker.com | sudo sh

    sudo systemctl enable docker
    sudo systemctl start docker

    sudo usermod -aG docker "$USER"

else

    echo "Docker is already installed."

fi

echo "======================================"
echo "Installing AWS CLI"
echo "======================================"

if ! command -v aws >/dev/null 2>&1; then

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
        -o "/tmp/awscliv2.zip"

    unzip -q /tmp/awscliv2.zip -d /tmp

    sudo /tmp/aws/install

else

    echo "AWS CLI is already installed."

fi

echo "======================================"
echo "Docker Version"
echo "======================================"

docker --version

echo "======================================"
echo "AWS CLI Version"
echo "======================================"

aws --version

echo "======================================"
echo "EC2 Setup Completed"
echo "======================================"
