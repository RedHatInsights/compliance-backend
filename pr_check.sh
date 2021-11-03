#!/bin/bash

# Install bonfire repo/initialize
CICD_URL=https://raw.githubusercontent.com/RedHatInsights/bonfire/master/cicd
curl -s $CICD_URL/bootstrap.sh > .cicd_bootstrap.sh && source .cicd_bootstrap.sh

# --------------------------------------------
# Options that must be configured by app owner
# --------------------------------------------
# Workaround Patch until https://github.com/RedHatInsights/insights-host-inventory/pull/1021 gets merged
export APP_NAME="compliance xjoin"  # name of app-sre "application" folder this component lives in
export COMPONENT_NAME="compliance"  # name of app-sre "resourceTemplate" in deploy.yaml for this component
export IMAGE="quay.io/cloudservices/compliance-backend"
cat /etc/redhat-release

# build the PR commit image
source $CICD_ROOT/build.sh

# Make directory for artifacts
mkdir -p artifacts

export IQE_PLUGINS="compliance"
export IQE_MARKER_EXPRESSION="compliance_smoke"
export IQE_FILTER_EXPRESSION=""
export IQE_CJI_TIMEOUT="30m" # 30 minutes
export DEPLOY_TIMEOUT=2000
# Allows to test custom IQE images
# export IQE_IMAGE_TAG=""

export COMPONENTS_W_RESOURCES="compliance"

# Run unit tests
#source $APP_ROOT/unit_test.sh

# Run smoke tests
source $CICD_ROOT/deploy_ephemeral_env.sh


source $CICD_ROOT/cji_smoke_test.sh
