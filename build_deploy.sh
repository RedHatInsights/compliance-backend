#!/bin/bash

set -exv

source 'scripts/deploy/build-deploy-common.sh'

IMAGE_NAME="${IMAGE_NAME:-quay.io/cloudservices/compliance-backend}"

# Check if the current Git branch is 'origin/security-compliance'.
if [[ "$GIT_BRANCH" == "origin/security-compliance" ]]; then
    # Generate a tag for the Docker image based on the current date and Git commit short hash.
    SECURITY_COMPLIANCE_TAG="sc-$(date +%Y%m%d)-$(git rev-parse --short=7 HEAD)"
    
    # Set ADDITIONAL_TAGS to the generated security compliance tag.
    ADDITIONAL_TAGS="$SECURITY_COMPLIANCE_TAG"
else
    # If the current Git branch is not 'origin/security-compliance':
    ADDITIONAL_TAGS="latest"
fi

REQUIRED_REGISTRIES_LOCAL=''
BUILD_ARGS=("IMAGE_TAG")

build_deploy_main || exit 1
