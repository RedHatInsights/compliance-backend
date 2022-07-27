#!/bin/bash

set -exv

source 'scripts/deploy/build-deploy-common.sh'

IMAGE_NAME="${IMAGE_NAME:-quay.io/cloudservices/compliance-backend}"
ADDITIONAL_TAGS="latest"
#PREFER_CONTAINER_ENGINE="docker"

build_deploy_main || exit 1
