#!/bin/bash

set -e

EC2_IP="$1"

APP_URL="http://${EC2_IP}:8501"

echo "Checking application: ${APP_URL}"

for i in {1..12}
do

    if curl --silent --fail "${APP_URL}" > /dev/null
    then
        echo "Application is UP."
        echo "URL: ${APP_URL}"
        exit 0
    fi

    echo "Application not ready. Attempt ${i}/12"

    sleep 10

done

echo "Application health check failed."

exit 1
