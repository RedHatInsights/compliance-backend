#!/bin/bash

set -exv

source 'deploy/build-deploy-common.sh'

IMAGE_NAME="${IMAGE_NAME:-quay.io/cloudservices/compliance-backend}"
ADDITIONAL_TAGS="latest"
CONTAINER_ENGINE_CMD="docker"

build_deploy_main || exit 1
