[![codecov](https://codecov.io/gh/RedHatInsights/compliance-backend/branch/master/graph/badge.svg)](https://codecov.io/gh/RedHatInsights/compliance-backend)
[![CI](https://github.com/RedHatInsights/compliance-backend/actions/workflows/ci.yml/badge.svg)](https://github.com/RedHatInsights/compliance-backend/actions/workflows/ci.yml)


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
* [Insights RBAC](https://github.com/RedHatInsights/insights-rbac) (Role-based access control)


## Getting started

Let's examine how to run the project:

### Option 1: Ephemeral Environment with [Bonfire](https://github.com/RedHatInsights/bonfire/)

#### Prerequisites

* [`oc`](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz)
  ([docs](https://docs.openshift.com/dedicated/4/cli_reference/openshift_cli/getting-started-cli.html))
* [`bonfire`](https://github.com/RedHatInsights/bonfire/)

#### Setup

1. Log in into the ephemeral cluster
2. Set up bonfire configuration (optional)

    To use local deployement confguration update the `~/.config/bonfire/config.yaml` as follows:
    ```
    apps:
    - name: compliance
      components:
        - name: compliance
          host: local
          repo: ~/path/to/local/compliance-backend
          path: deploy/clowdapp.yaml
          parameters:
            REDIS_SSL: 'false'
    ```

#### Deployment

```shell
bonfire deploy compliance --optional-deps-method hybrid --frontends true --source=appsre --ref-env insights-stage --timeout 900 --no-remove-resources=all
```

This will set up the environment with all service dependencies, 3scale gateway, frontend
and platform [mocks](https://github.com/RedHatInsights/mocks/) (authentication & authorization).

A custom (local) clowdapp can be used for deployment if the step 2 of the setup has been not skipped. 
A custom image can be used by overwriting parameters of the clowder template. Note that the container
image needs to be pushed to an accessible location.
```shell
bonfire deploy compliance ... -p compliance/IMAGE=quay.io/me/myimage -p compliance/IMAGE_TAG=mytag
```

#### Access

The frontend route and credentials can be retrieved by calling the following command:
```shell
bonfire namespace describe <ephemeral-######>
```

### Option 2: Docker/Podman Compose Development setup

The first step is to copy over the .env file from .env.example and modify the
values as needed:

```shell
cp .env.example .env
```

Either podman-compose or docker-compose should work. Note that *1.0.6* and newer
versions of podman-compose [handle multi-level dependencies poorly](https://github.com/containers/podman-compose/issues/683)
which might cause problems with startup. Furthermore podman-compose does not
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

Attach the container to the current terminal:
```shell
docker attach compliance-backend_rails_1
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

# run a single test case
docker-compose exec rails bundle exec rake test TEST=test/path/to_test.rb TESTOPTS="-n '/matching test description/'"
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

### Seeding data

To seed accounts, policies, results and hosts use `dev:db:seed` rake task.
It is required to wait for the SSG content to be synchronized. Watch `compliance-backend_import-ssg_1` container to see the synchronization progress.
It is recommeneded to run the command after a first log in was initiated, as it would generate data for that account.

```
bundle exec rake dev:db:seed
```

### Creating hosts in the inventory

To create hosts in the inventory the `kafka_producer.py` script can be used from the `inventory` container:

```
docker-compose run -e NUM_HOSTS=1000 -e INVENTORY_HOST_ACCOUNT=00001 inventory-web bash -c 'pipenv install --system --dev; python3 ./utils/kafka_producer.py;'
```

### Tagging

If there is a `tags` column defined in any model, it always should be a `jsonb` column and follow the structured representation of tags described in Insights, i.e. an array of hashes. If this convention is not kept, the controllers might break when a user tries to pass the `tags` attribute to a GET request.

## API documentation

The API documentation can be found at `/api/compliance` and you may access the raw OpenAPI
definition [here](https://github.com/RedHatInsights/compliance-backend/blob/master/swagger/v1/openapi.json).
Docs can be updated by running:
```shell
rake rswag:specs:swaggerize
```
You can build this API by converting the JSON representation (OpenAPI 2.x) using [swagger2openapi](https://github.com/Mermade/oas-kit/blob/master/packages/swagger2openapi).

## Contributing

If you'd like to contribute, please fork the repository and use a feature
branch. Pull requests are warmly welcome.

This project ensures code style guidelines are followed on every pull request
using [Rubocop](https://github.com/rubocop-hq/rubocop).

## Licensing

The code in this project is licensed under GPL v3 license.
