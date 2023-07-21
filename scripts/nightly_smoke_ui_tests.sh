#!/bin/bash

# This job is used for checking compliance frontend health in ephemeral environment

set -ex

export IMAGE="quay.io/cloudservices/compliance-backend"
export APP_NAME="compliance"  # name of app-sre "application" folder this component lives in
export COMPONENT_NAME="compliance-backend"  # name of app-sre "resourceTemplate" in deploy.yaml for this component
export IQE_PLUGINS="compliance"
export IQE_MARKER_EXPRESSION="ephemeral_ui_nightly"
export IQE_FILTER_EXPRESSION=""
export IQE_ENV="ephemeral"
export IQE_SELENIUM="true"
export IQE_CJI_TIMEOUT="30m"
export DEPLOY_TIMEOUT="900"
export DEPLOY_FRONTENDS="true"
export COMPONENTS_W_RESOURCES="compliance"

# Get bonfire helper scripts
CICD_URL="https://raw.githubusercontent.com/RedHatInsights/cicd-tools/main"
rm -f .cicd_bootstrap.sh
# shellcheck source=/dev/null
curl -s $CICD_URL/bootstrap.sh > .cicd_bootstrap.sh && source .cicd_bootstrap.sh

# Smoke tests
# shellcheck source=/dev/null
source "$CICD_ROOT/deploy_ephemeral_env.sh"
# shellcheck source=/dev/null
source "$CICD_ROOT/cji_smoke_test.sh"
