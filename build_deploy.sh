#!/bin/bash

# Check if Red Hat Identity cert is available on the machine
echo '==================================================================='
echo '=== Use the identity cert to access Pulp content app ===='
echo '==================================================================='
pem_file="/etc/pki/consumer/cert.pem"

whoami
sudo whoami

if [ -e "$pem_file" ]; then
    echo "The file $pem_file exists."
    ls -la "$pem_file"
    curl --cert "$pem_file" https://cert.console.stage.redhat.com/api/pulp-content/compliance/
else
    echo "The file $pem_file does not exist."
fi
exit 99
