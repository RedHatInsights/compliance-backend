#!/bin/bash

# Install bonfire repo/initialize
CICD_URL=https://raw.githubusercontent.com/RedHatInsights/bonfire/master/cicd
# shellcheck source=/dev/null
curl -s $CICD_URL/bootstrap.sh > .cicd_bootstrap.sh && source .cicd_bootstrap.sh

# --------------------------------------------
# Options that must be configured by app owner
# --------------------------------------------
export APP_NAME="compliance"  # name of app-sre "application" folder this component lives in
export COMPONENT_NAME="compliance"  # name of app-sre "resourceTemplate" in deploy.yaml for this component
export IMAGE="quay.io/cloudservices/compliance-backend"
cat /etc/redhat-release

# shellcheck source=/dev/null
# build the PR commit image
source "${CICD_ROOT}/build.sh"

# Make directory for artifacts
mkdir -p artifacts

export IQE_PLUGINS="compliance"
export IQE_MARKER_EXPRESSION="compliance_smoke"
export IQE_FILTER_EXPRESSION=""
export IQE_CJI_TIMEOUT="30m" # 30 minutes
export REF_ENV="insights-stage"
# Allows to test custom IQE images
# export IQE_IMAGE_TAG=""

export COMPONENTS_W_RESOURCES="compliance rbac"

# Run unit tests
bash -x "${APP_ROOT}/scripts/unit_test.sh"

# Run smoke tests
# shellcheck source=/dev/null
source "${CICD_ROOT}/deploy_ephemeral_env.sh"
# shellcheck source=/dev/null
source "${CICD_ROOT}/cji_smoke_test.sh"
# shellcheck source=/dev/null
source "${CICD_ROOT}/post_test_results.sh"
