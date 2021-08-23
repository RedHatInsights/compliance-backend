#!/bin/bash

set -exv

# Install bonfire repo/initialize
CICD_URL=https://raw.githubusercontent.com/RedHatInsights/bonfire/master/cicd
curl -s $CICD_URL/bootstrap.sh > .cicd_bootstrap.sh && source .cicd_bootstrap.sh

# --------------------------------------------
# Options that must be configured by app owner
# --------------------------------------------
export APP_NAME="compliance"  # name of app-sre "application" folder this component lives in
export COMPONENT_NAME="compliance"  # name of app-sre "resourceTemplate" in deploy.yaml for this component
export IMAGE="quay.io/cloudservices/compliance-backend"
cat /etc/redhat-release

# build the PR commit image
source $CICD_ROOT/build.sh

# Make directory for artifacts
mkdir -p artifacts

cat << EOF > artifacts/junit-dummy.xml
<testsuite tests="1">
    <testcase classname="dummy" name="dummytest"/>
</testsuite>
EOF
