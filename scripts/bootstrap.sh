#!/usr/bin/env bash

set -e

PODNAME="insights-compliance-backend"

WORKDIR="$(dirname $( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd ))"

DB_DATA_DIR="${WORKDIR}/tmp/insights-compliance-db"

POSTGRES_PASSWORD='postgres'

DEFAULT_HOST=192.168.122.1

#PODMAN_NETWORK="cni-podman1"
#PODMAN_GATEWAY=$(podman network inspect $PODMAN_NETWORK | jq -r '..| .gateway? // empty')

if podman pod exists "$PODNAME"; then
    podman pod rm "$PODNAME" -f
fi

#if ! podman pod exists $PODNAME; then
podman pod create --name "$PODNAME" -p "8080:3000"
	#podman pod create --name "$PODNAME" -p "8080:3000"
#	podman pod create --name "$PODNAME" --network "$PODMAN_NETWORK"
	#podman pod create --name "$PODNAME" -p "8080:3000"
#		--add-host "ci.foo.redhat.com:$PODMAN_GATEWAY" \
#		--add-host "qa.foo.redhat.com:$PODMAN_GATEWAY" \
#		--add-host "stage.foo.redhat.com:$PODMAN_GATEWAY" \
#		--add-host "prod.foo.redhat.com:$PODMAN_GATEWAY"
#fi

#podman build "$WORKDIR" -t "compliance-backend-rails"

# zookeeper
#podman run --pod "$PODNAME" -d --name "zookeeper" \
#	-e ZOOKEEPER_CLIENT_PORT=32181 \
#	-e ZOOKEEPER_SERVER_ID=1 \
#	confluentinc/cp-zookeeper

# kafka
#podman run --pod "$PODNAME" -d --name "kafka" \
#	-e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT \
#	-e KAFKA_BROKER_ID=1 \
#	-e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
#	-e KAFKA_ZOOKEEPER_CONNECT=localhost:32181 \
#	confluentinc/cp-kafka

# compliance-redis
podman run --pod "$PODNAME" -d --name "redis" \
    redis

# compliance-db
podman run --pod "$PODNAME" -d --name "db" \
    -v "$DB_DATA_DIR:/var/lib/postgresql/data:z" \
	-e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
    postgres


# compliance-prometheus-exporter
podman run --pod "$PODNAME" -d --name "prometheus" -v "$WORKDIR:/app:z" \
	-e DATABASE_SERVICE_NAME=postgres \
	-e POSTGRES_SERVICE_HOST=localhost \
	-e POSTGRESQL_USER=postgres \
	-e POSTGRESQL_PASSWORD=$POSTGRES_PASSWORD \
	-e RAILS_ENV=development \
	-e APP_NAME=compliance \
	-e PATH_PREFIX=/api \
	-e RAILS_LOG_TO_STDOUT=true \
	compliance-backend-rails \
	bundle exec prometheus_exporter -b 0.0.0.0 -t 50 --verbose -a lib/prometheus/graphql_collector.rb -a lib/prometheus/business_collector.rb


# compliance-db-migrations
podman run --pod "$PODNAME" --rm --name "migration" -v "${WORKDIR}:/app:z" \
	-e DATABASE_SERVICE_NAME=postgres \
	-e POSTGRES_SERVICE_HOST=localhost \
	-e POSTGRESQL_USER=postgres \
	-e POSTGRESQL_PASSWORD=$POSTGRES_PASSWORD \
	-e RAILS_LOG_TO_STDOUT=true \
	-e SETTINGS__PROMETHEUS_EXPORTER_HOST=localhost \
	-e SETTINGS__REDIS_URL=localhost\
	compliance-backend-rails \
	bundle exec rake db:create db:migrate

# compliance-backend
podman run --pod "$PODNAME" -d --name "rails" -v "${WORKDIR}:/app:z" \
	-e DATABASE_SERVICE_NAME=postgres \
	-e POSTGRES_SERVICE_HOST=localhost \
	-e POSTGRESQL_DATABASE=postgres \
	-e POSTGRESQL_TEST_DATABASE=compliance_test \
	-e POSTGRESQL_USER=postgres \
	-e SETTINGS__PROMETHEUS_EXPORTER_HOST=localhost \
	-e DISABLE_DATABASE_ENVIRONMENT_CHECK=1 \
	-e SETTINGS__REDIS_URL=localhost\
	-e SETTINGS__DISABLE_RBAC=true \
	compliance-backend-rails


# compliance-consumer
podman run --pod "$PODNAME" -d --name "reports-consumer" -v "${WORKDIR}:/app:z" \
	-e DATABASE_SERVICE_NAME=postgres \
	-e POSTGRES_SERVICE_HOST=localhost \
	-e POSTGRESQL_DATABASE=postgres \
	-e POSTGRESQL_TEST_DATABASE=compliance_test \
	-e POSTGRESQL_USER=postgres \
	-e SETTINGS__PROMETHEUS_EXPORTER_HOST=localhost \
	-e SETTINGS__REDIS_URL=localhost \
    -e KAFKAMQ=${DEFAULT_HOST}:29092 \
	compliance-backend-rails \
	bundle exec racecar -l log/consumer.log ComplianceReportsConsumer


# compliance-sidekiq
podman run --pod "$PODNAME" -d --name "sidekiq" -v "${WORKDIR}:/app:z" \
    -e MALLOC_ARENA_MAX=2 \
	-e SETTINGS__REDIS_URL=localhost \
	-e SETTINGS__PROMETHEUS_EXPORTER_HOST=localhost \
	-e DATABASE_SERVICE_NAME=postgres \
	-e POSTGRES_SERVICE_HOST=localhost \
	-e POSTGRESQL_DATABASE=postgres \
	-e POSTGRESQL_TEST_DATABASE=compliance_test \
	-e POSTGRESQL_USER=postgres \
	compliance-backend-rails \
	bundle exec sidekiq

