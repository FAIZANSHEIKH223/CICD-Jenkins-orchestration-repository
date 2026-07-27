#!/bin/bash

set -e

EC2_HOST=$1

if [ -z "$EC2_HOST" ]; then
    echo "Usage:"
    echo "./configure_logging.sh <ec2_host>"
    exit 1
fi

echo "======================================"
echo "Configuring Docker Logging"
echo "======================================"

ssh -o StrictHostKeyChecking=no \
    ubuntu@"$EC2_HOST" << 'EOF'

    set -e

    sudo mkdir -p /etc/docker

    sudo tee /etc/docker/daemon.json > /dev/null << 'JSON'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
JSON

    sudo systemctl restart docker

    echo "Docker logging configured successfully."

EOF

echo "======================================"
echo "Logging Configuration Completed"
echo "======================================"
