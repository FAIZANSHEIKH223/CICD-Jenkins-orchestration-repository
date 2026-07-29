#!/bin/bash

set -e

EC2_IP="$1"

APP_DIR="practice1"

REMOTE_USER="ubuntu"

REMOTE_DIR="/opt/practice1"

echo "Deploying application to EC2: ${EC2_IP}"

ssh -o StrictHostKeyChecking=no \
    "${REMOTE_USER}@${EC2_IP}" \
    "sudo mkdir -p ${REMOTE_DIR} && sudo chown -R ubuntu:ubuntu ${REMOTE_DIR}"

scp -o StrictHostKeyChecking=no \
    -r "${APP_DIR}/." \
    "${REMOTE_USER}@${EC2_IP}:${REMOTE_DIR}/"

ssh -o StrictHostKeyChecking=no \
    "${REMOTE_USER}@${EC2_IP}" <<EOF

set -e

cd ${REMOTE_DIR}

python3 -m venv venv

source venv/bin/activate

pip install --upgrade pip

pip install -r requirements.txt

pkill -f "streamlit run app.py" || true

nohup streamlit run app.py \
    --server.address=0.0.0.0 \
    --server.port=8501 \
    > streamlit.log 2>&1 &

EOF

echo "Application deployment completed."
