#!/bin/bash

cd "$APP_ROOT"
export IMAGE="quay.io/cloudservices/compliance-backend"
IMAGE_TAG=$(git rev-parse --short=7 HEAD)
export IMAGE_TAG

function teardown_docker {
  docker rm -f "$DB_CONTAINER_ID" || true
  docker rm -f "$TEST_CONTAINER_ID" || true
  docker network rm "$NETWORK" || true
}

trap "teardown_docker" EXIT SIGINT SIGTERM

NETWORK="compliance-test-${IMAGE_TAG}"
POSTGRES_IMAGE="quay.io/cloudservices/postgresql-rds:cyndi-12-1"
IMAGE="quay.io/cloudservices/compliance-backend"
IMAGE_TAG=$(git rev-parse --short=7 HEAD)
DATABASE_USER="compliance"
DATABASE_PASSWORD="changeme"
DATABASE_NAME="compliance-test"
DATABASE_HOST="compliance-db"

docker network rm "$NETWORK" || echo "network likely doesn't exist"
docker network create --driver bridge "$NETWORK"

DB_CONTAINER_ID=$(docker run -d \
  --name "$DATABASE_HOST" \
  --network "$NETWORK" \
  -e POSTGRESQL_USER="$DATABASE_USER" \
  -e POSTGRESQL_PASSWORD="$DATABASE_PASSWORD" \
  -e POSTGRESQL_DATABASE="$DATABASE_NAME" \
  "$POSTGRES_IMAGE" || echo "0")

if [[ "$DB_CONTAINER_ID" == "0" ]]; then
  echo "Failed to start DB container"
  exit 1
fi

# Do tests
TEST_CONTAINER_ID=$(docker run -d \
  --network "$NETWORK" \
  -e DATABASE_SERVICE_NAME=postgresql \
  -e POSTGRESQL_SERVICE_HOST="$DATABASE_HOST" \
  -e POSTGRESQL_USER="$DATABASE_USER" \
  -e POSTGRESQL_PASSWORD="$DATABASE_PASSWORD" \
  -e POSTGRESQL_DATABASE="$DATABASE_NAME" \
  -e RAILS_ENV=test \
  -e CODECOV_TOKEN="$CODECOV_TOKEN" \
  -v .git:/opt/app-root/src/.git
  "$IMAGE:$IMAGE_TAG" \
  /bin/bash -c 'sleep infinity' || echo "0")

if [[ "$TEST_CONTAINER_ID" == "0" ]]; then
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
docker exec "$TEST_CONTAINER_ID" /bin/bash -c 'bundle install --with test'
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
docker exec "$TEST_CONTAINER_ID" /bin/bash -c 'bundle exec rake db:test:prepare'
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
docker cp "$TEST_CONTAINER_ID":/opt/app-root/src/db/cyndi_setup_test.sql "$WORKSPACE/"
docker cp "$WORKSPACE/cyndi_setup_test.sql" "$DB_CONTAINER_ID":/var/lib/pgsql/
rm "$WORKSPACE/cyndi_setup_test.sql"
docker exec "$DB_CONTAINER_ID" /bin/bash -c 'psql -d $POSTGRESQL_DATABASE < cyndi_setup_test.sql'
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
docker exec "$TEST_CONTAINER_ID" /bin/bash -c 'bundle exec rake test:validate'
TEST_RESULT=$?
set -e
# Copy test reports
docker cp "$TEST_CONTAINER_ID":/opt/app-root/src/test/reports/. "$WORKSPACE"/artifacts
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
