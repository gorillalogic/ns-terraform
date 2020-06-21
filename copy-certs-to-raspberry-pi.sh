#!/bin/bash
set -e

terraform_output=$(terraform output -json)
echo $terraform_output | jq ".certificate.value" | xargs printf '%b\n'> certs/pi_collector.cert.pem
echo $terraform_output | jq ".public_key.value"  | xargs printf '%b\n'> certs/pi_collector.public.key
echo $terraform_output | jq ".private_key.value" | xargs printf '%b\n'> certs/pi_collector.private.key

scp certs/pi_collector.cert.pem pi@noise-collector-8b6ad8.local:/tmp/pi_collector.cert.pem
scp certs/pi_collector.public.key pi@noise-collector-8b6ad8.local:/tmp/pi_collector.public.key
scp certs/pi_collector.private.key pi@noise-collector-8b6ad8.local:/tmp/pi_collector.private.key

cat <<"EOF"

# IMPORTANT: Run the following lines in the raspberry pi with root permissions
cp /tmp/pi_collector.cert.pem /etc/certs/pi_collector.cert.pem
cp /tmp/pi_collector.public.key /etc/certs/pi_collector.public.key
cp /tmp/pi_collector.private.key /etc/certs/pi_collector.private.key
chmod 600 /etc/certs/pi_collector.private.key
service noise-cloud restart

# Connecting via SSH
EOF

ssh pi@noise-collector-8b6ad8.local
