#!/bin/bash

CICD_BOOTSTRAP_REPO_BRANCH='main'
CICD_BOOTSTRAP_REPO_ORG='RedHatInsights'
CICD_TOOLS_URL="https://raw.githubusercontent.com/${CICD_BOOTSTRAP_REPO_ORG}/cicd-tools/${CICD_BOOTSTRAP_REPO_BRANCH}/src/bootstrap.sh"
# shellcheck source=/dev/null
source <(curl -sSL "$CICD_TOOLS_URL") image_builder

if ! cicd::image_builder::is_change_request_context; then
  echo "Not running from a context of a PR"
  exit 1
fi

APP_ROOT=${APP_ROOT:-.}
cd "$APP_ROOT"
export CICD_IMAGE_BUILDER_IMAGE_NAME="quay.io/cloudservices/compliance-backend"

RANDOM_ID=$(md5sum -z <<< "$RANDOM" | cut -c -6)
DB_CONTAINER_NAME="compliance-db-${RANDOM_ID}"
TEST_CONTAINER_NAME="compliance-test-${RANDOM_ID}"
POD_NAME="compliance-pod-${RANDOM_ID}"
COMPLIANCE_POD_ID=''
DB_CONTAINER_ID=''
TEST_CONTAINER_ID=''

POSTGRES_IMAGE="quay.io/cloudservices/postgresql-rds:cyndi-12-1"
DATABASE_USER="compliance"
DATABASE_PASSWORD="changeme"
DATABASE_NAME="compliance-test"

teardown() {

  for id in "$DB_CONTAINER_ID" "$TEST_CONTAINER_ID"; do
    cicd::container::cmd rm -f "$id" || echo "couldn't delete container ID: $id"
  done

  cicd::container::cmd pod rm -f "$COMPLIANCE_POD_ID" || echo "couldn't delete pod ID: $COMPLIANCE_POD_ID"
}

trap "teardown" EXIT SIGINT SIGTERM

if ! COMPLIANCE_POD_ID=$(cicd::container::cmd pod create --name "$POD_NAME"); then
    echo "Failed creating pod image"
    exit 1
fi

# Make sure the build stage image is available
IMAGE_TAG=$(cicd::image_builder::get_image_tag)
SERVICE_IMAGE=$(cicd::container::cmd images --filter "label=BUILD_STAGE_OF=${IMAGE_TAG}" -q | head -1)

if [[ -z "${SERVICE_IMAGE}" ]]; then
  echo "First stage image is not available"
  exit 1
fi

if ! DB_CONTAINER_ID=$(cicd::container::cmd run -d \
  --pod "${COMPLIANCE_POD_ID}" \
  --rm \
  --name "${DB_CONTAINER_NAME}" \
  -e POSTGRESQL_USER="$DATABASE_USER" \
  -e POSTGRESQL_PASSWORD="$DATABASE_PASSWORD" \
  -e POSTGRESQL_DATABASE="$DATABASE_NAME" \
  "$POSTGRES_IMAGE"); then

  echo "Failed to start DB container"
  exit 1
fi

# Do tests
if ! TEST_CONTAINER_ID=$(cicd::container::cmd run -d \
  --pod "${COMPLIANCE_POD_ID}" \
  --rm \
  -e HOSTNAME="$TEST_CONTAINER_NAME" \
  -e POSTGRESQL_SERVICE_HOST="$POD_NAME" \
  -e DATABASE_SERVICE_NAME=postgresql \
  -e POSTGRESQL_USER="$DATABASE_USER" \
  -e POSTGRESQL_PASSWORD="$DATABASE_PASSWORD" \
  -e POSTGRESQL_DATABASE="$DATABASE_NAME" \
  -e RAILS_ENV=test \
  -e CI=true \
  -e JENKINS_URL="$JENKINS_URL" \
  -e ghprbSourceBranch="${ghprbSourceBranch:?}" \
  -e GIT_BRANCH="$GIT_BRANCH" \
  -e ghprbActualCommit="${ghprbActualCommit:?}" \
  -e GIT_COMMIT="$GIT_COMMIT" \
  -e BUILD_NUMBER="$BUILD_NUMBER" \
  -e ghprbPullId="${ghprbPullId:?}" \
  -e BUILD_URL="$BUILD_URL" \
  "${SERVICE_IMAGE}" \
  /bin/bash -c 'sleep infinity'); then

  echo "Failed to start test container"
  exit 1
fi

WORKSPACE=${WORKSPACE:-./}
ARTIFACTS_DIR="$WORKSPACE/artifacts"
mkdir -p "$ARTIFACTS_DIR"

# gem install
echo '===================================='
echo '=== Installing Gem Dependencies ===='
echo '===================================='
set +e
cicd::container::cmd cp ./. "$TEST_CONTAINER_ID":/opt/app-root/src
cicd::container::cmd exec "$TEST_CONTAINER_ID" /bin/bash -c '
  bundle config set --local without development &&
  bundle config set --local with test &&
  bundle config set --local deployment "true" &&
  bundle config set --local path "./.bundle" &&
  bundle install'
TEST_RESULT=$?
set -e
if [[ $TEST_RESULT -ne 0 ]]; then
  echo '====================================='
  echo '==== ✖ ERROR: GEM INSTALL FAILED ===='
  echo '====================================='
  exit 1
fi

# setup db
echo '===================================='
echo '===     Setting Up Database     ===='
echo '===================================='
set +e
cicd::container::cmd exec "$TEST_CONTAINER_ID" /bin/bash -c 'ACG_CONFIG=/opt/app-root/src/test.json bundle exec rake db:test:prepare'
TEST_RESULT=$?
set -e
if [[ $TEST_RESULT -ne 0 ]]; then
  echo '====================================='
  echo '====  ✖ ERROR: DB SETUP FAILED   ===='
  echo '====================================='
  exit 1
fi

# setup cyndi
echo '===================================='
echo '===       Setting Up Cyndi      ===='
echo '===================================='
set +e
cicd::container::cmd cp "$TEST_CONTAINER_ID":/opt/app-root/src/db/cyndi_setup_test.sql "$WORKSPACE/"
cicd::container::cmd cp "$WORKSPACE/cyndi_setup_test.sql" "$DB_CONTAINER_ID":/var/lib/pgsql/
rm "$WORKSPACE/cyndi_setup_test.sql"
# We want to expand $POSTGRESQL_DATABASE within the container's session
# shellcheck disable=SC2016
cicd::container::cmd exec "$DB_CONTAINER_ID" /bin/bash -c 'psql -d $POSTGRESQL_DATABASE < cyndi_setup_test.sql'
TEST_RESULT=$?
set -e
if [[ $TEST_RESULT -ne 0 ]]; then
  echo '====================================='
  echo '==== ✖ ERROR: CYNDI SETUP FAILED ===='
  echo '====================================='
  exit 1
fi

# unit tests
echo '===================================='
echo '===     Running Unit Tests      ===='
echo '===================================='
set +e
cicd::container::cmd exec "$TEST_CONTAINER_ID" /bin/bash -c 'ACG_CONFIG=/opt/app-root/src/test.json bundle exec rake test:validate'
TEST_RESULT=$?
set -e
# Copy test reports
cicd::container::cmd cp "$TEST_CONTAINER_ID":/opt/app-root/src/test/reports/. "$WORKSPACE"/artifacts
# Prefix name of reports with 'junit-' so jenkins analysis picks them up
cd "$WORKSPACE/artifacts"
for FILENAME in TEST-*.xml; do mv "$FILENAME" "junit-$FILENAME"; done
cd -
if [[ $TEST_RESULT -ne 0 ]]; then
  echo '====================================='
  echo '====  ✖ ERROR: UNIT TEST FAILED  ===='
  echo '====================================='
  exit 1
fi

echo '====================================='
echo '====   ✔ SUCCESS: PASSED TESTS   ===='
echo '====================================='
