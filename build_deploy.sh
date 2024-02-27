#!/bin/bash

set -exv


# Check if Red Hat Identity cert is available on the machine
echo '==================================================================='
echo '=== Use the identity cert to access Pulp content app ===='
echo '==================================================================='
pem_file="/etc/pki/consumer/cert.pem"

if [ -e "$pem_file" ]; then
    echo "The file $pem_file exists."
    ls -la "$pem_file"
    curl --cert "$pem_file" https://cert.console.stage.redhat.com/api/pulp-content/compliance/
else
    echo "The file $pem_file does not exist."
fi

CICD_TOOLS_URL="https://raw.githubusercontent.com/RedHatInsights/cicd-tools/main/src/bootstrap.sh"
# shellcheck source=/dev/null
source <(curl -sSL "$CICD_TOOLS_URL") image_builder

export CICD_IMAGE_BUILDER_IMAGE_NAME='quay.io/cloudservices/compliance-backend'
export CICD_IMAGE_BUILDER_BUILD_ARGS=("IMAGE_TAG=$(cicd::image_builder::get_image_tag)")
# Check if the current Git branch is 'origin/security-compliance'.
if [[ "$GIT_BRANCH" == "origin/security-compliance" ]]; then
    # Generate a tag for the Docker image based on the current date and Git commit short hash.
    SECURITY_COMPLIANCE_TAG="sc-$(date +%Y%m%d)-$(git rev-parse --short=7 HEAD)"
    
    # Set ADDITIONAL_TAGS to the generated security compliance tag.
    export CICD_IMAGE_BUILDER_ADDITIONAL_TAGS=("$SECURITY_COMPLIANCE_TAG")
else
    # If the current Git branch is not 'origin/security-compliance':
    export CICD_IMAGE_BUILDER_ADDITIONAL_TAGS=("latest")
fi

cicd::image_builder::build_and_push
