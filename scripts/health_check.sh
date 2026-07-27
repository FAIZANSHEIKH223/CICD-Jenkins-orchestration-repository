#!/bin/bash

set -e

EC2_HOST=$1

if [ -z "$EC2_HOST" ]; then
    echo "Usage:"
    echo "./health_check.sh <ec2_host>"
    exit 1
fi

echo "======================================"
echo "Running Health Check"
echo "======================================"

echo "Checking Docker container..."

ssh -o StrictHostKeyChecking=no \
    ubuntu@"$EC2_HOST" << 'EOF'

    if ! docker ps --format '{{.Names}}' | grep -q '^practice2-app$'; then

        echo "ERROR: practice2-app container is not running."

        docker ps -a

        exit 1

    fi

    echo "Container is running."

EOF

echo "Checking application endpoint..."

HTTP_STATUS=$(curl \
    --silent \
    --output /dev/null \
    --write-out "%{http_code}" \
    "http://${EC2_HOST}:8501")

if [ "$HTTP_STATUS" = "200" ]; then

    echo "======================================"
    echo "Health Check PASSED"
    echo "HTTP Status: $HTTP_STATUS"
    echo "======================================"

else

    echo "======================================"
    echo "Health Check FAILED"
    echo "HTTP Status: $HTTP_STATUS"
    echo "======================================"

    exit 1

fi
