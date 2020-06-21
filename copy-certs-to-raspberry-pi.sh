#!/bin/bash
set -e

terraform output -json | jq ".certificate.value" | xargs printf '%b\n'> certs/pi_collector.crt
terraform output -json | jq ".private_key.value" | xargs printf '%b\n'> certs/pi_collector.key

scp certs/pi_collector.crt pi@noise-collector-8b6ad8.local:/tmp/pi_collector.crt
scp certs/pi_collector.key pi@noise-collector-8b6ad8.local:/tmp/pi_collector.key

cat <<"EOF"

# IMPORTANT: Run the following lines in the raspberry pi with root permissions
cp /tmp/pi_collector.crt /etc/certs/pi_collector.crt
cp /tmp/pi_collector.key /etc/certs/pi_collector.key
chmod 600 /etc/certs/pi_collector.key
service noise-cloud restart

# Connecting via SSH
EOF

ssh pi@noise-collector-8b6ad8.local