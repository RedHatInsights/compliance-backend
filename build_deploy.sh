#!/bin/bash

set -exv

source 'deploy/build-deploy-common.sh'

IMAGE_NAME="${IMAGE_NAME:-quay.io/cloudservices/compliance-backend}"

build_deploy_main || exit 1
