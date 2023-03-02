#!/bin/bash

APP_ROOT=${APP_ROOT:-.}
cd "$APP_ROOT"
export IMAGE="quay.io/cloudservices/compliance-backend"
IMAGE_TAG=$(git rev-parse --short=7 HEAD)
export IMAGE_TAG


RANDOM_ID=$(md5sum -z <<< "$RANDOM" | cut -c -6)
DB_CONTAINER_NAME="compliance-db-${RANDOM_ID}"
TEST_CONTAINER_NAME="compliance-test-${RANDOM_ID}"
POD_NAME="compliance-pod-${RANDOM_ID}"
COMPLIANCE_POD_ID=''
DB_CONTAINER_ID=''
TEST_CONTAINER_ID=''

POSTGRES_IMAGE="quay.io/cloudservices/postgresql-rds:cyndi-12-1"
IMAGE="quay.io/cloudservices/compliance-backend"
IMAGE_TAG=$(git rev-parse --short=7 HEAD)
DATABASE_USER="compliance"
DATABASE_PASSWORD="changeme"
DATABASE_NAME="compliance-test"

# if this is a PR, use a different tag, since PR tags expire
if [[ -n "$ghprbPullId" ]]; then
  export IMAGE_TAG="pr-${ghprbPullId}-${IMAGE_TAG}"
fi

function teardown_podman {
  podman rm -f "$DB_CONTAINER_ID" || true
  podman rm -f "$TEST_CONTAINER_ID" || true
  podman pod rm -f "$COMPLIANCE_POD_ID" || true
}

trap "teardown_podman" EXIT SIGINT SIGTERM

if ! COMPLIANCE_POD_ID=$(podman pod create --name "$POD_NAME"); then
    exit 1
fi

if ! DB_CONTAINER_ID=$(podman run -d \
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
if ! TEST_CONTAINER_ID=$(podman run -d \
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
  -e ghprbPullId="$ghprbPullId" \
  -e BUILD_URL="$BUILD_URL" \
  "$IMAGE:$IMAGE_TAG" \
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
podman exec -u 0 "$TEST_CONTAINER_ID" /bin/bash -c 'microdnf install -y $DEV_DEPS'
podman exec "$TEST_CONTAINER_ID" /bin/bash -c '
  bundle config set --local without development &&
  bundle config set --local with test &&
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
podman exec "$TEST_CONTAINER_ID" /bin/bash -c 'bundle exec rake db:test:prepare'
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
podman cp "$TEST_CONTAINER_ID":/opt/app-root/src/db/cyndi_setup_test.sql "$WORKSPACE/"
podman cp "$WORKSPACE/cyndi_setup_test.sql" "$DB_CONTAINER_ID":/var/lib/pgsql/
rm "$WORKSPACE/cyndi_setup_test.sql"
podman exec "$DB_CONTAINER_ID" /bin/bash -c 'psql -d $POSTGRESQL_DATABASE < cyndi_setup_test.sql'
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
podman exec "$TEST_CONTAINER_ID" /bin/bash -c 'bundle exec rake test:validate'
TEST_RESULT=$?
set -e
# Copy test reports
podman cp "$TEST_CONTAINER_ID":/opt/app-root/src/test/reports/. "$WORKSPACE"/artifacts
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
