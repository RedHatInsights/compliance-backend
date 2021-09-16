#!/bin/bash

set -exv

source 'deploy/build-deploy-common.sh'

BACKWARDS_COMPATIBILITY_TAGS="latest qa"
IMAGE_NAME="${IMAGE_NAME:-quay.io/cloudservices/compliance-backend}"
IMAGE_TAG="${IMAGE_TAG}"
TARGET_BUILD_STAGE="${TARGET_BUILD_STAGE:-compliance-backend}"

build_deploy_main || exit 1
