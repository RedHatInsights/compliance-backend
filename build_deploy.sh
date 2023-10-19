#!/bin/bash

set -exv

export CICD_BOOTSTRAP_REPO_BRANCH='refactor-variable-names'
export CICD_BOOTSTRAP_REPO_ORG='Victoremepunto'
CICD_TOOLS_URL="https://raw.githubusercontent.com/${CICD_BOOTSTRAP_REPO_ORG}/cicd-tools/${CICD_BOOTSTRAP_REPO_BRANCH}/src/bootstrap.sh"
# shellcheck source=/dev/null
source <(curl -sSL "$CICD_TOOLS_URL") image_builder

export IMAGE_NAME='quay.io/cloudservices/compliance-backend'
export BUILD_ARGS=("IMAGE_TAG=$(cicd_tools::image_builder::get_image_tag)")
# Check if the current Git branch is 'origin/security-compliance'.
if [[ "$GIT_BRANCH" == "origin/security-compliance" ]]; then
    # Generate a tag for the Docker image based on the current date and Git commit short hash.
    SECURITY_COMPLIANCE_TAG="sc-$(date +%Y%m%d)-$(git rev-parse --short=7 HEAD)"
    
    # Set ADDITIONAL_TAGS to the generated security compliance tag.
    ADDITIONAL_TAGS=("$SECURITY_COMPLIANCE_TAG")
else
    # If the current Git branch is not 'origin/security-compliance':
    ADDITIONAL_TAGS=("latest")
fi
export ADDITIONAL_TAGS


cicd::image_builder::build_and_push
