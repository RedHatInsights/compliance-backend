#!/bin/bash

set -exv

CICD_TOOLS_URL="https://raw.githubusercontent.com/RedHatInsights/cicd-tools/main/src/bootstrap.sh"
# shellcheck source=/dev/null
source <(curl -sSL "$CICD_TOOLS_URL") image_builder

export CICD_IMAGE_BUILDER_IMAGE_NAME='quay.io/cloudservices/compliance-backend'

image_exists_in_quay() {
    local image_tag="$1"
    local repository="cloudservices/compliance-backend"
    local response
    local tags_count

    echo "Checking if image tag '$image_tag' already exists in quay.io..."

    response=$(curl -sL "https://quay.io/api/v1/repository/${repository}/tag?specificTag=${image_tag}&onlyActiveTags=true")

    if ! tags_count=$(echo "$response" | jq -r '.tags | length'); then
        echo "Error retrieving tag data from Quay"
        echo "Response: $response"
        return 1
    fi

    if [[ "$tags_count" -gt 0 ]]; then
        echo "Image tag '$image_tag' already exists in quay.io"
        return 0
    else
        echo "Image tag '$image_tag' does not exist in quay.io"
        return 1
    fi
}

# Check if the current Git branch is 'origin/security-compliance'.
if [[ "$GIT_BRANCH" == "origin/security-compliance" ]]; then
    # Generate a tag for the container image based on the current date and Git commit short hash.
    SECURITY_COMPLIANCE_TAG="sc-$(date +%Y%m%d)-$(git rev-parse --short=7 HEAD)"
    export "IMAGE_TAG=${SECURITY_COMPLIANCE_TAG}"
    TARGET_TAG="${SECURITY_COMPLIANCE_TAG}"
else
    # If the current Git branch is not 'origin/security-compliance':
    TARGET_TAG="$(cicd::image_builder::get_image_tag)"
    export CICD_IMAGE_BUILDER_BUILD_ARGS=("IMAGE_TAG=${TARGET_TAG}")
    export CICD_IMAGE_BUILDER_ADDITIONAL_TAGS=("latest")
fi

if image_exists_in_quay "$TARGET_TAG"; then
    echo "Skipping build - image already exists"
    exit 0
fi

cicd::image_builder::build_and_push
