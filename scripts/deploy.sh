#!/bin/bash

set -e

APP_DIR=$1
AWS_REGION=$2
ECR_REPOSITORY=$3
EC2_HOST=$4

if [ -z "$APP_DIR" ] || [ -z "$AWS_REGION" ] || [ -z "$ECR_REPOSITORY" ] || [ -z "$EC2_HOST" ]; then
    echo "Usage:"
    echo "./deploy.sh <app_dir> <aws_region> <ecr_repository> <ec2_host>"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity \
    --query Account \
    --output text)

ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

IMAGE_NAME="${ECR_REGISTRY}/${ECR_REPOSITORY}:latest"

echo "======================================"
echo "Building Docker Image"
echo "======================================"

cd "$APP_DIR"

docker build -t "${ECR_REPOSITORY}:latest" .

echo "======================================"
echo "Logging in to Amazon ECR"
echo "======================================"

aws ecr get-login-password \
    --region "$AWS_REGION" | \
    docker login \
    --username AWS \
    --password-stdin "$ECR_REGISTRY"

echo "======================================"
echo "Tagging Docker Image"
echo "======================================"

docker tag \
    "${ECR_REPOSITORY}:latest" \
    "$IMAGE_NAME"

echo "======================================"
echo "Pushing Image to ECR"
echo "======================================"

docker push "$IMAGE_NAME"

echo "======================================"
echo "Deploying to EC2"
echo "======================================"

ssh -o StrictHostKeyChecking=no \
    ubuntu@"$EC2_HOST" << EOF

    set -e

    echo "Pulling latest Docker image..."

    aws ecr get-login-password \
        --region "$AWS_REGION" | \
        docker login \
        --username AWS \
        --password-stdin "$ECR_REGISTRY"

    docker pull "$IMAGE_NAME"

    echo "Stopping old container..."

    docker stop practice1-app 2>/dev/null || true

    docker rm practice1-app 2>/dev/null || true

    echo "Starting new container..."

    docker run -d \
        --name practice1-app \
        --restart unless-stopped \
        -p 8501:8501 \
        "$IMAGE_NAME"

EOF

echo "======================================"
echo "Deployment Completed"
echo "======================================"
