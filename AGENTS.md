# AGENTS.md

When changing application code, add a passing unit test for the changed file. This does not apply to manifests or config files.

Rails 8.1 REST API for compliance data. Parses OpenSCAP reports. Kafka for events.

## Processes

1. Rails API (Puma, port 3000) — `/api/compliance/v2/`, `panko_serializer`
2. Karafka consumer — inventory events, including report parsing
3. GoodJob worker — PostgreSQL-backed jobs

## Auto-join

Controllers never write explicit `joins` or `select`. Serializers declare dependencies:

- `derived_attribute(name, association: [:column])` — 1:1 joined table
- `aggregated_attribute(name, association, function)` — aggregate over has-many (`COUNT`, `MAX`, …)

`Resolver` builds SQL at query time:

1. `join_parents` — nested routes scoped by each parent; Pundit per parent
2. `join_associated` — `derived_attribute` joins with `WHERE associated`
3. `join_aggregated` — has-many aggregates as `LEFT OUTER JOIN` subquery
4. `select_fields` — only serializer columns; joined columns aliased `association__column`

`filters_for` omits derived/aggregated attributes whose associations were not joined.

## Report parsing

```
Inventory Event → Kafka → InventoryEventsConsumer
  → Kafka::ReportParser (validate, download XCCDF from S3)
  → ParseReportJob
  → XccdfReportParser.parse() → replace TestResult + RuleResults
  → Kafka notifications, Remediations update
```

## Domain models

- **SecurityGuide** — SCAP benchmark (XCCDF datastream)
- **Profile** — canonical SSG profile
- **Policy** — compliance policy (Profile + many Tailoring)
- **Tailoring** — profile customization per OS minor
- **TestResult** — scan of a system for a policy
- **RuleResult** — rule outcome (pass/fail/error/notchecked/notselected)
- **Report** — aggregated policy stats
- **System** — `systems` table; `system_profile` JSONB (`operating_system.major` / `minor`)

`tags` columns are Insights jsonb: array of hashes. Filter via query params.

## Database

Do not generate or run migrations. A human must do that.

`fx` / `scenic` manage views (`db/views/`), functions (`db/functions/`), triggers (`db/triggers/`). Legacy v1 models are views.

## Auth

Two RBAC systems: V1 (`insights-rbac-api-client`, `Settings.rbac_url`) and V2 Kessel (`kessel-sdk`, gRPC + OAuth2). `User.current` comes from identity-header middleware.

## Commands

Run Ruby inside compose (`podman` or `docker`):

```bash
podman-compose exec rails {command}
docker-compose exec rails {command}
```

```bash
bundle exec rake spec:validate          # specs + static analysis (CI)
bundle exec rake spec
bundle exec rake rswag:specs:swaggerize # OpenAPI from request specs
```

### External Services

- **Inventory** - Ingests host events via Kafka into the `systems` table (via `System` model)
- **RBAC** - `Rbac` service (V1) or `KesselRbac` service (V2)
- **Object Storage** - Reports downloaded via `SafeDownloader` from signed URLs

## Testing Conventions

- [RSpec](https://github.com/rspec/rspec) for API spec generation tests (`spec/integration/`) and model, API, Rake task and Kafka-related unit tests (`spec/*`)
- [FactoryBot](https://github.com/thoughtbot/factory_bot) factories defined in `spec/factories/`
- Mock external services with WebMock
- Kafka testing via [karafka-testing](https://github.com/karafka/karafka-testing) gem
- Never hardcode arbitrary test strings, use the [Faker](https://github.com/faker-ruby/faker) gem.

## Config

`config` gem + `config/settings.yml`. Env overrides (`SETTINGS__KAFKA__BROKERS`). Clowder (`ACG_CONFIG`, `clowder-common-ruby`) wins over all. Local Clowder: `devel.json`.

## Kafka

Consumers: `app/consumers/`, routing in `karafka.rb`. Producers: `app/producers/` (`Notification`, `ReportValidation`, `RemediationUpdates`, `InventoryViews`). Reports from signed URLs via `SafeDownloader`.

Filtering uses `scoped_search` (fields on the model, referenced in the serializer).

Compliance audit logs: `Rails.logger.audit_success` / `audit_fail` (not the standard logger).

## Git

Commit messages follow `.commitlint.yml`. Default branch: `master`. Hotfixes: `hotfix`.

- PR titles and commit subjects use the repository's conventional format and do not include Jira keys.
- Put Jira references in the PR description or commit body only.
