#!/bin/bash

set -exv

source 'scripts/deploy/build-deploy-common.sh'

IMAGE_NAME="${IMAGE_NAME:-quay.io/cloudservices/compliance-backend}"
ADDITIONAL_TAGS="latest"
REQUIRED_REGISTRIES_LOCAL=''
REQUIRED_REGISTRIES='quay'

build_deploy_main || exit 1
