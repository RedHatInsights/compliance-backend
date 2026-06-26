# AGENTS.md

This file provides guidance to any and all large language models when working with code in this repository.

When working in this repository, prioritize readability and following already introduced patterns.

When doing changes, make sure that each time, the changed file has a unit test covering it and that it does pass.

## Project Overview

compliance-backend is a Ruby on Rails 8.1 backend. It provides a REST API for compliance data management, parses OpenSCAP reports into a database, and integrates with Kafka for event-driven workflows.

## Architecture

### Core Components

The application consists of three main processes:

1. **Rails API Server** (Puma, port 3000) - REST API serving V2 endpoints
2. **Karafka Consumer** - Kafka message processor for inventory events (including report parsing)
3. **Sidekiq Worker** - Background job processor (requires Redis)

### API

- **V2 API** (`/api/compliance/v2/`) - Current API using `panko_serializer`, models in `app/models/v2/`

V2 models are backed by real database tables. The `V2::System` model is an exception — it is a view over the `inventory.hosts` table in a different schema that is read-only.

#### V2 auto-join

Controllers never write explicit `joins` or `select` calls. Instead, serializers declare their data dependencies using two class-level DSL methods:

- `derived_attribute(name, association: [:column])` — marks a field as coming from a 1:1 joined table.
- `aggregated_attribute(name, association, function)` — marks a field as an aggregate (e.g. `COUNT`, `MAX`) over a has-many association.

`Resolver` reads those declarations at query time and automatically builds the SQL:

1. **Parent joins** (`join_parents`) — nested routes (e.g. `/policies/:id/reports`) are scoped by joining and filtering on each route parent, with Pundit authorization applied per parent.
2. **1:1 joins** (`join_associated`) — associations declared via `derived_attribute` are joined with `WHERE associated`, so only records that satisfy the relationship are returned.
3. **Aggregate subquery joins** (`join_aggregated`) — has-many aggregations are computed in a `LEFT OUTER JOIN` subquery grouped by primary key and self-joined back to the main query.
4. **Field selection** (`select_fields`) — only the columns required by the serializer are selected; columns from joined tables are aliased as `association__column` to avoid conflicts.

At serialization time, `filters_for` receives the set of actually-joined associations and silently omits any `derived_attribute` or `aggregated_attribute` whose dependency was not joined — preventing errors on partial scopes.

### Data Flow of Report parsing

```
Inventory Event → Kafka Topic → InventoryEventsConsumer
  ↓
Kafka::ReportParser (validates, downloads XCCDF from S3)
  ↓
ParseReportJob (Sidekiq)
  ↓
XccdfReportParser.parse() → TestResult + RuleResults replaced with the newer ones
  ↓
Notifications sent to Kafka, Remediations service updated
```

### Important Models (V2)

- **V2::SecurityGuide** - SCAP benchmark metadata (XCCDF datastreams)
- **V2::Profile** - Canonical security profile from upstream SSG
- **V2::Policy** - Compliance policy (references V2::Profile, has many V2::Tailoring)
- **V2::Tailoring** - Profile customization per OS minor version
- **V2::TestResult** - Scan result of a system for a policy
- **V2::RuleResult** - Individual rule compliance outcome (pass/fail/error/notchecked/notselected)
- **V2::Report** - Stores aggregated policy statistics
- **V2::System** - View over `inventory.hosts` in the `inventory` schema (read-only)

### DB migrations

No AI model should in any case generate or run migrations. This task is potentially dangerous and should always be done by a human developer.

### Database Views & Functions

The app uses the `fx` and `scenic` gems for managing PostgreSQL views, functions, and triggers. Views are in `db/views/`, functions in `db/functions/`, triggers in `db/triggers/`.
V1 models are backed by database views. `V2::System` is also view-backed (read-only alias of `inventory.hosts`).

### Authorization

Two RBAC systems coexist:
- **V1 RBAC** - `insights-rbac-api-client` gem, service at Settings.rbac_url
- **V2 RBAC (Kessel)** - `kessel-sdk` gem, gRPC service with OAuth2 auth

Controllers use Pundit policies (`app/policies/` and `app/policies/v2/`) for authorization. User context set via `User.current` from identity header middleware.

## Development Setup

- Containerized via Dockerfile
- OpenShift/Kubernetes ready (`deploy/clowdapp.yaml`)
- Compose file stands up the whole project with containers mocking external platform dependencies

The project does and should support both podman and docker.
All commands should be ran inside the container context, like so:

```bash
# For host systems where podman is preferred
podman-compose exec rails {command}

# For host systems where docker is preferred
docker-compose exec rails {command}
```

### Running Tests

The project uses RSpec (spec/) for testing.

```bash
# Run all specs and static analysis (CI validation suite)
bundle exec rake spec:validate

# Run RSpec tests
bundle exec rake spec
```

### OpenAPI Documentation

API documentation is auto-generated from RSpec request specs using [rswag](https://github.com/rswag/rswag):

```bash
# Update OpenAPI spec after changing the API
bundle exec rake rswag:specs:swaggerize
```

## Configuration

Settings managed via `config` gem:
- `config/settings.yml` - Legacy base configuration.
- Environment variables override settings (e.g., `SETTINGS__KAFKA__BROKERS`)
- Clowder integration via `ACG_CONFIG` env var (pointing to a JSON config file). Highest level of config, overrides everything using a Rails engine called [clowder-common-ruby](https://github.com/RedHatInsights/clowder-common-ruby). Locally sourced from `devel.json`.

## Service Integration Patterns

### Kafka Consumers

Consumers in `app/consumers/` extend `ApplicationConsumer`. Routing configured in `karafka.rb`. Message handlers delegate to service classes in `app/services/kafka/` or to jobs in `app/jobs/`.

### Kafka Producers

Producers in `app/producers/` extend `ApplicationProducer`. Use Karafka for publishing. Key producers:
- `Notification` - Compliance event notifications
- `ReportValidation` - Report validation results
- `RemediationUpdates` - Failed rule notifications
- `InventoryViews` - System related Compliance data publishing

### External Services

- **Inventory** - Read systems from `inventory.hosts` table (via V2::System model)
- **RBAC** - `Rbac` service (V1) or `KesselRbac` service (V2)
- **Object Storage** - Reports downloaded via `SafeDownloader` from signed URLs

## Testing Conventions

- [RSpec](https://github.com/rspec/rspec) for API spec generation tests (`spec/integration/`) and model, API, Rake task and Kafka-related unit tests (`spec/*`)
- [FactoryBot](https://github.com/thoughtbot/factory_bot) factories defined in `spec/factories/`
- Mock external services with WebMock
- Kafka testing via [karafka-testing](https://github.com/karafka/karafka-testing) gem
- Never hardcode arbitrary test strings, use the [Faker](https://github.com/faker-ruby/faker) gem.

## Common Patterns

### Models

Models live in the `V2` namespace and are backed by real database tables. `V2::System` is an exception — it is a view over the `inventory.hosts` table and is read-only.

### Tags Convention

Any model with a `tags` column must use `jsonb` type with Insights structured format (array of hashes). Controllers filter by tags via query parameters.

### JSONB System Profile

System metadata stored in `system_profile` JSONB column:
```ruby
system_profile['operating_system']['major']
system_profile['operating_system']['minor']
```

### Scoped Search

Most V2 models use `scoped_search` gem for filtering. Define searchable fields in model, reference in serializer.

### Audit Logging

Use `Rails.logger.audit_success` and `Rails.logger.audit_fail` for compliance events (not standard Rails logger methods).

## Git Workflow

- Commit messages follow `.commitlint.yml` format
- PRs require passing CI (rubocop, brakeman, tests, OpenAPI validation)
- Main branch: `master`
- Hotfixes to `hotfix` branch
