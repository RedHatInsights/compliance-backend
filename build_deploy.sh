#!/bin/bash

set -exv

source 'deploy/build-deploy-common.sh'

BACKWARDS_COMPATIBILITY_TAGS="latest-new qa-new"
IMAGE_NAME="${IMAGE_NAME:-quay.io/cloudservices/compliance-backend}"
IMAGE_TAG="${IMAGE_TAG}-new"

build_deploy_main || exit 1
