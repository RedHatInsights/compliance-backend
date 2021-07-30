[![codecov](https://codecov.io/gh/RedHatInsights/compliance-backend/branch/master/graph/badge.svg)](https://codecov.io/gh/RedHatInsights/compliance-backend)


# Cloud Services for RHEL: Compliance Backend

compliance-backend is a project meant to parse OpenSCAP reports into a database,
and perform all kind of actions that will make your systems more compliant with
a policy. For example, you should be able to generate reports of all kinds for
your auditors, get alerts, and create playbooks to fix your hosts.


## Architecture

This project does two main things:

1. Serve as the API/GraphQL backend for the web UI
   [compliance-frontend](https://github.com/RedHatInsights/compliance-frontend)
   and for other consumers,
2. Connect to a Kafka message queue provided by the Insights Platform.

### Components

The Insights Compliance backend comprises of these components/services:

* Rails web server — serving REST API and GraphQL (port 3000)
* Sidekiq — job runner connected through Redis (see [app/jobs](app/jobs))
* Inventory Consumer (racecar) — processor of Kafka messages,
  mainly to process and parse reports
* Prometheus Exporter (optional) — providing metrics (port 9394)

### Dependent Services

Before running the project, these services must be running and acessible:

* Kafka — message broker (default port 29092)
  - set by `SETTINGS__KAFKA__BROKERS` environment variable
* Redis — Job queue and cache
* PostgreSQL compatible database
  - `DATABASE_SERVICE_NAME=postgres`
  - conrolled by environment variables `POSTGRES_SERVICE_HOST`,
    `POSTGRESQL_DATABASE`, `POSTGRESQL_USER`, `POSTGRESQL_PASSWORD`
* [Insights Ingress](https://github.com/RedHatInsights/insights-ingress-go)
  (also requires S3/minio)
* [Insights PUPTOO](https://github.com/RedHatInsights/insights-puptoo)
  — Platform Upload Processor
* [Insights Host Inventory](https://github.com/RedHatInsights/insights-host-inventory) (MQ service and web service)


## Getting started

Let's examine how to run the project:

### Option 1: Ephemeral Environment with [Bonfire](https://github.com/RedHatInsights/bonfire/)

#### Prerequisites

* [`oc`](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz)
  ([docs](https://docs.openshift.com/dedicated/4/cli_reference/openshift_cli/getting-started-cli.html))
* [`bonfire`](https://github.com/RedHatInsights/bonfire/)

#### Deploy

```shell
bonfire deploy compliance gateway insights-ephemeral --no-remove-resources all --set-image-tag 'quay.io/cloudservices/compliance-backend=latest-new'
```

### Option 2: Development setup

compliance-backend is a Ruby on Rails application. It should run using
at least three different processes:

#### Prerequisites

Prerequisites:

* URL to Kafka
  - environment variable: `SETTINGS__KAFKA__BROKERS` (`SETTINGS__KAFKA__BROKERS=localhost:29092`)
* URL to PostgreSQL database
  - environment variables: `POSTGRESQL_DATABASE`, `POSTGRESQL_SERVICE_HOST`, `POSTGRESQL_USER`, `POSTGRESQL_PASSWORD`, `POSTGRESQL_ADMIN_PASSWORD`, `DATABASE_SERVICE_NAME`
* URL to Redis
  - `redis_url` and `redis_cache_url` configured in [settings](config/settings/development.yml)
  - or, environment variables `SETTINGS__REDIS_URL` and `SETTINGS__REDIS_CACHE_URL`
* URL to [Insights Inventory](https://github.com/RedHatInsights/insights-host-inventory)
  - or, `host_inventory_url` configured in [settings](config/settings/development.yml)
* Basic authethication credentials set by
  [option `platform_basic_auth`](config/settings/development.yml)
  - or, environment variables `SETTINGS__PLATFORM_BASIC_AUTH_USERNAME` and `SETTINGS__PLATFORM_BASIC_AUTH_PASSWORD`
* Generated minio credentials (for Ingress)
  - environment variables: `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`

Note, that the environment variables can be written to `.env` file
(see [.env.example](.env.example)).
They are being read by dotenv.

First, let's install all dependencies and initialize the database.

```shell
bundle install
bundle exec rake db:setup # invoke only on first setup!
bundle exec rake db:test:prepare # for test DB setup
```

Once you have database initialized, you might want to import SSG policies:

```shell
bundle exec rake ssg:import_rhel_supported
```

#### Project Cyndi

The compliance project integrates with project cyndi. For local development, a database view is created, built from the inventory database which runs alongside the compliance database. The Cyndi hosts view exists within an inventory schema within the compliance database.

```shell
bundle exec rails db < db/cyndi_setup_devel.sql # syndicated (cyndi) hosts from inventory
RAILS_ENV=test bundle exec rails db < db/cyndi_setup_test.sql # cyndi for test DB
```

You can verify everything worked as expected within psql for compliance_dev and
compliance_test databases:

```
compliance_dev=# \dv inventory.
          List of relations
  Schema   | Name  | Type |  Owner
-----------+-------+------+----------
 inventory | hosts | view | insights
(1 row)
```

#### Kafka Consumers (XCCDF report consumers)

At this point you can launch as many ['racecar'](https://github.com/zendesk/racecar)
processes as you want. These processes will become part of a *consumer group*
in Kafka, so by default the system is highly available.

To run a Reports consumer:

```shell
bundle exec racecar InventoryEventsConsumer
```

#### Web Server

You may simply run:

```shell
bundle exec rails server
```

Notice there's no CORS protection by default. If you want your requests to be
CORS-protected, check out `config/initializers/cors.rb` and change it to only
allow a certain domain.

After this, make sure you can redirect your requests to your the backend's port 3000
using [insights-proxy](https://github.com/RedHatInsights/insights-proxy).
You may run the proxy using the SPANDX config provided here:

```ruby
SPANDX_CONFIG=$(pwd)/compliance-backend.js ../insights-proxy/scripts/run.sh
```

#### Job Runner

Asynchonous jobs are run by sidekiq with messages being exchanged through Redis.

To start the runner execute:

```shell
bundle exec sidekiq
```

### Option 3: Docker/Podman Compose Development setup

The first step is to copy over the .env file from .env.example and modify the
values as needed:

```shell
cp .env.example .env
```

You may also need to set up basic auth in
[settings](config/settings/development.yml), option `platform_basic_auth`
(see Development notes).

Either podman-compose or docker-compose should work. podman-compose does not
support exec, so podman commands must be run manually against the running
container, as demonstrated:

```shell
# docker
docker-compose exec rails bash

# podman
podman exec compliance-backend_rails_1 bash
```

Bring up the everything, including inventory, ingress, etc.:

```shell
docker-compose up
```

Access the rails console:

```shell
docker-compose exec rails bundle exec rails console
```

Debug with pry-remote:

```shell
docker-compose exec rails pry-remote -w
```

Run the tests:

```shell
# run all tests (same thing run on PRs to master)
docker-compose exec rails bundle exec rake test:validate

# run a single test file
docker-compose exec -e TEST=$TEST rails bundle exec rake test TEST=test/consumers/inventory_events_consumer_test.rb
```

Access logs:
note: podman-compose does not support the logs command, so similar to exec,
it must be run against the container itself, as shown

```shell
docker-compose logs -f sidekiq

# podman
podman logs -f compliance-backend_sidekiq_1
```

### Building the image

This project uses `build_deploy.sh` to build and push this image to a remote registry.
You must set the required variables to provide authentication to the required registries.
You must set at least the Red Hat Registry credentials to be able to pull the base image.

Example:
```
LOCAL_BUILD=true RH_REGISTRY_USER=guybrush RH_REGISTRY_TOKEN=M0nk3y ./build_deploy.sh
```

Optionally, if you want to push to the remote registry you must set the remote registry credentials as well (LOCAL_BUILD defaults to `false`)

Example:
```
LOCAL_BUILD=true RH_REGISTRY_USER=guybrush RH_REGISTRY_TOKEN=monkey QUAY_USER=lechuck QUAY_TOKEN=Ela1ne ./build_deploy.sh
```

## Development notes

### Running Sonarqube

Follow instructions to set up self-signed certs, as described [here](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/).

In order to get coverage to properly report, you must manually edit the
coverage/.resultset.json and update the paths to `/usr/src/...` from whatever
local paths are listed there.

Use the docker image:

```
podman run -itv $PWD:/usr/src -v $PWD/cacerts:/opt/java/openjdk/lib/security/cacerts --rm --name sonar-scanner-cli -e SONAR_HOST_URL='<sonarqube host>' -e SONAR_LOGIN=<token> sonarsource/sonar-scanner-cli
```

### Seeding data

To seed accounts, policies, results and hosts use `dev:db:seed` rake task.
It is recommeneded to run the command after a first log in was initiated, as it would generate data for that account.

```
bundle exec rake dev:db:seed
```

### Creating hosts in the inventory

To create hosts in the inventory the `kafka_producer.py` script can be used from the `inventory` container:

```
docker-compose run -e NUM_HOSTS=1000 -e INVENTORY_HOST_ACCOUNT=00001 inventory-web bash -c 'pipenv install --system --dev; python3 ./utils/kafka_producer.py;'
```

### Basic Auth Platform Credentials

Basic authentication ([`platform_basic_auth` option](config/settings/development.yml))
might be needed for platform services such as inventory, rbac, and remediations.
Anything not deployed locally will require basic auth instead of using
an identity header (i.e. rbac, remediations).

### Disabling Prometheus

To disable Prometheus (e.g. in develompent) clear `prometheus_exporter_host` setting (set to empty).

### Tagging

If there is a `tags` column defined in any model, it always should be a `jsonb` column and follow the structured representation of tags described in Insights, i.e. an array of hashes. If this convention is not kept, the controllers might break when a user tries to pass the `tags` attribute to a GET request.

## API documentation

The API documentation can be found at `Settings.path_prefix/Settings.app_name`. To generate the docs, run `rake rswag:specs:swaggerize`. You may also get the OpenAPI definition at `Settings.path_prefix/Settings.app_name/v1/openapi.json`
The OpenAPI version 3.0 description can be found at `Settings.path_prefix/Settings.app_name/openapi`. You can build this API by converting the JSON representation (OpenAPI 2.x) using [swagger2openapi](https://github.com/Mermade/oas-kit/blob/master/packages/swagger2openapi).

## Database migration notes

Database migrations need to be run prior to intialization of backend containers,
to proprely initialize model attributes on all instances.

## Contributing

If you'd like to contribute, please fork the repository and use a feature
branch. Pull requests are warmly welcome.

This project ensures code style guidelines are followed on every pull request
using [Rubocop](https://github.com/rubocop-hq/rubocop).

## Licensing

The code in this project is licensed under GPL v3 license.
