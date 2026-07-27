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

IS_MASTER_BRANCH=false
if [[ "$GIT_BRANCH" == "origin/master" ]] || [[ "$GIT_BRANCH" == "master" ]]; then
    IS_MASTER_BRANCH=true
fi

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
    if [[ "$IS_MASTER_BRANCH" == "true" ]]; then
        export CICD_IMAGE_BUILDER_ADDITIONAL_TAGS=("latest")
    else
        export CICD_IMAGE_BUILDER_ADDITIONAL_TAGS=()
    fi
fi

if image_exists_in_quay "$TARGET_TAG"; then
    echo "Skipping build - image already exists"
    exit 0
fi

# ==============================================================================
# OUTER CACHE MANAGEMENT
# ==============================================================================

CACHE_REPO="quay.io/cloudservices/compliance-backend"

# Determine merge-base with master to extract a consistent commit timestamp for reproducible layer caching
MERGE_BASE=$(git merge-base HEAD origin/master 2>/dev/null || git merge-base HEAD master 2>/dev/null || echo "")
BUILD_TIMESTAMP=""

if [ -n "$MERGE_BASE" ]; then
    BUILD_TIMESTAMP=$(git log --no-show-signature -1 --format=%ct "$MERGE_BASE" 2>/dev/null || echo "")
fi

if [ -n "$BUILD_TIMESTAMP" ]; then
    echo "Resolved build timestamp to master merge-base $MERGE_BASE: $BUILD_TIMESTAMP"
else
    BUILD_TIMESTAMP=$(git log --no-show-signature -1 --format=%ct HEAD 2>/dev/null || echo "0")
    echo "WARNING: Could not determine git merge-base timestamp with master! Falling back to HEAD timestamp $BUILD_TIMESTAMP." >&2
fi

if [[ "$IS_MASTER_BRANCH" == "true" ]]; then
    echo "Master branch build detected. Building image with remote cache and populating Quay..."

    # On master: build and populate remote cache for intermediate build stage first
    cicd::image_builder::build --layers \
        --target build \
        --format oci \
        --timestamp "$BUILD_TIMESTAMP" \
        --cache-from "$CACHE_REPO" \
        --cache-to "$CACHE_REPO"

    # On master: build using remote layer cache from Quay and populate remote cache in Quay for final image
    cicd::image_builder::build_and_push --layers \
        --format oci \
        --timestamp "$BUILD_TIMESTAMP" \
        --cache-from "$CACHE_REPO" \
        --cache-to "$CACHE_REPO"
else
    echo "PR build detected. Using outer layer cache from Quay..."

    # On PRs: build using remote layer cache from Quay
    cicd::image_builder::build_and_push --layers \
        --format oci \
        --timestamp "$BUILD_TIMESTAMP" \
        --cache-from "$CACHE_REPO" \
        --label "quay.expires-after=30d"
fi
