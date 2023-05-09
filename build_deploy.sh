#!/bin/bash

set -exv

source 'scripts/deploy/build-deploy-common.sh'

IMAGE_NAME="${IMAGE_NAME:-quay.io/cloudservices/compliance-backend}"
SECURITY_COMPLIANCE_TAG="sc-$(date +%Y%m%d)"
ADDITIONAL_TAGS="$SECURITY_COMPLIANCE_TAG"
REQUIRED_REGISTRIES_LOCAL=''

build_deploy_main || exit 1
