# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

When working in this repository, prioritize readability and following already introduced patterns.

When doing changes, make sure that each time, the changed file has a unit test covering it and that it does pass.

## Project Overview

compliance-backend is a Ruby on Rails 8.0 API backend. It parses OpenSCAP reports into a database, provides REST APIs for compliance data, and integrates with Kafka for event-driven workflows.

## Architecture

### Core Components

The application consists of three main processes:

1. **Rails API Server** (Puma, port 3000) - REST API serving V2 endpoints
2. **Karafka Consumer** - Kafka message processor for inventory events and report parsing
3. **Sidekiq Workers** - Background job processor (requires Redis)

### API Versioning

- **V1 API** (`/api/compliance/`) - Legacy API using `jsonapi-serializer`, models in `app/models/`
- **V2 API** (`/api/compliance/v2/`) - Current API using `panko_serializer`, models in `app/models/v2/`

V2 uses database views extensively for performance (e.g., `v2_policies`, `v2_reports`, `v2_test_results`). Models like `V2::Report` are view-backed, while `V2::Policy` is a real table. The `V2::System` model aliases `inventory.hosts` (read-only in production).

### Key Data Flow

```
Inventory Event → Kafka Topic → InventoryEventsConsumer
  ↓
Kafka::ReportParser (validates, downloads XCCDF from S3)
  ↓
ParseReportJob (Sidekiq)
  ↓
XccdfReportParser.parse() → TestResult + RuleResults saved
  ↓
Notifications sent to Kafka, Remediations service updated
```

### Important Models (V2)

- **V2::Policy** - Compliance policy (references V2::Profile, has many V2::Tailoring)
- **V2::Profile** - Canonical security profile from upstream SSG
- **V2::SecurityGuide** - SCAP benchmark metadata (XCCDF datastreams)
- **V2::Tailoring** - Profile customization per OS minor version
- **V2::TestResult** - Scan result from a system for a policy
- **V2::RuleResult** - Individual rule compliance outcome (pass/fail/error/notchecked)
- **V2::System** - Alias of `inventory.hosts` (read-only)
- **V2::Report** - View-backed, aliases `v2_policies` with aggregated statistics

### Database Views & Functions

The app uses the `fx` and `scenic` gems for managing PostgreSQL views, functions, and triggers. Views are in `db/views/`, functions in `db/functions/`, triggers in `db/triggers/`. Many V2 models are backed by views with insert/update/delete trigger functions.

### Authorization

Two RBAC systems coexist:
- **V1 RBAC** - `insights-rbac-api-client` gem, service at Settings.rbac_url
- **V2 RBAC (Kessel)** - `kessel-sdk` gem, gRPC service with OAuth2 auth

Controllers use Pundit policies (`app/policies/` and `app/policies/v2/`) for authorization. User context set via `User.current` from identity header middleware.

## Development Setup

### Running Tests

The project uses both RSpec (spec/) and Minitest (test/).

```bash
# Run all tests (CI validation suite)
docker compose exec rails bundle exec rake test:validate

# Run RSpec tests in directory
podman-compose exec -e SPEC_OPTS="-P 'spec/policies/v2/*.rb' --color --tty --format documentation" rails bundle exec rake spec

# Run all static analysis
bundle exec rake test:validate
```

### OpenAPI Documentation

API documentation is auto-generated from RSpec request specs using rswag:

```bash
# Update OpenAPI spec after changing API
rake rswag:specs:swaggerize
```

## Important Rake Tasks

```bash
# Import SCAP datastreams (SSG content)
rake ssg:import_rhel_supported      # Download and import all supported SSGs
rake ssg:check_synced                # Verify SSG/remediations are synced
rake ssg:sync_supported              # Update supported_ssg.default.yaml

# Database migrations
rake db:migrate                      # Run pending migrations
rake zeitwerk:check                  # Verify autoloading

# Development
rake dev:db:seed                     # Seed dev data (requires synced SSG)
```

## Configuration

Settings managed via `config` gem:
- `config/settings.yml` - Base configuration
- Environment variables override settings (e.g., `SETTINGS__KAFKA__BROKERS`)
- Clowder integration via `ACG_CONFIG` env var (JSON config file)

Key settings:
- `Settings.app_name` - 'compliance'
- `Settings.kafka.brokers` - Kafka broker list
- `Settings.kessel.enabled` - Toggle Kessel RBAC
- `Settings.disable_rbac` - Skip authorization (dev only)

## Service Integration Patterns

### Kafka Consumers

Consumers in `app/consumers/` extend `ApplicationConsumer`. Routing configured in `karafka.rb`. Message handlers typically delegate to service classes in `app/services/kafka/`.

### Kafka Producers

Producers in `app/producers/` extend `ApplicationProducer`. Use WaterDrop for publishing. Key producers:
- `Notification` - Compliance event notifications
- `ReportValidation` - Report validation results
- `RemediationUpdates` - Failed rule notifications

### External Services

- **Inventory** - Read systems from `inventory.hosts` table (via V2::System model)
- **RBAC** - `Rbac` service (V1) or `KesselRbac` service (V2)
- **Object Storage** - Reports downloaded via `SafeDownloader` from signed URLs

## Testing Conventions

- RSpec for integration tests (spec/api/, spec/integration/)
- Minitest for unit tests (test/models/, test/jobs/, test/services/)
- Factories defined in spec/factories/ and test/factories/
- Use `shoulda-context` and `shoulda-matchers` for Minitest
- Mock external services with WebMock
- Kafka testing via `karafka-testing` gem

## Common Patterns

### Tags Convention

Any model with a `tags` column must use `jsonb` type with Insights structured format (array of hashes). Controllers filter by tags via query parameters.

### JSONB System Profile

System metadata stored in `system_profile` JSONB column:
```ruby
system_profile['operating_system']['major']
system_profile['operating_system']['minor']
```

### Scoped Search

Most V2 models use `scoped_search` gem for filtering/sorting. Define searchable fields in model, reference in serializer.

### Audit Logging

Use `Rails.logger.audit_success` and `Rails.logger.audit_fail` for compliance events (not standard Rails logger methods).

## Migration Notes

When adding migrations:
- Views/functions/triggers use `fx` gem (`rails g function`, `rails g trigger`)
- Scenic gem for view versioning (`rails g scenic:view`)
- Always update `db/schema.rb` via `rake db:migrate`
- Run `zeitwerk:check` to verify autoloading

## Deployment

- Containerized via Dockerfile
- OpenShift/Kubernetes ready (deploy/ configs)
- Bonfire for ephemeral environments
- CI via GitHub Actions (.github/workflows/ci.yml)
- Three containers: rails (API), sidekiq (workers), karafka (consumer)

## Git Workflow

- Commit messages follow `.commitlint.yml` format
- PRs require passing CI (rubocop, brakeman, tests, OpenAPI validation)
- Main branch: `master`
- Hotfixes to `hotfix` branch
