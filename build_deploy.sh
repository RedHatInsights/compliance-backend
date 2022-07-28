#!/bin/bash

set -exv

source 'scripts/deploy/build-deploy-common.sh'

BACKWARDS_COMPATIBILITY_TAGS="latest qa"
IMAGE_NAME="${IMAGE_NAME:-quay.io/cloudservices/compliance-backend}"
IMAGE_TAG="${IMAGE_TAG:?}"

build_deploy_main || exit 1
