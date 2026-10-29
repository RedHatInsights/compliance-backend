# Inventory Kafka Batch GoodJob Design

## Status

- Classification: feature / architectural
- Design and work-contract scope approved by user: yes (`implement pls`)
- Implementation plan approved by user; execution method selected: subagent-driven development
- Worktree: `feat/inventory-events-batch-job`, based on `master` at `676030023ad4460a7d4b0386fc28671963b92f8f`

## Goal

Reduce GoodJob scheduling overhead for Inventory Kafka events by moving preparation and dispatch from one GoodJob per Kafka message to one GoodJob per topic-partition group in each Karafka delivery batch, while retaining mutual exclusion for jobs from the same topic and partition.

## Current behavior

`InventoryEventsConsumer` receives a Karafka delivery and `ApplicationConsumer#consume` processes its messages one at a time. Created and updated events enqueue `SystemImportJob`; delete events enqueue `SystemDeleteJob`. Compliance report parsing is also performed synchronously in the consumer for messages not handled by those event types. Import and delete jobs have a shared GoodJob concurrency lock keyed by system ID. Application-level stale-data safeguards prevent older events from overwriting newer system state.

## Proposed behavior

1. Inventory consumer prepares the relevant messages in a delivery and groups them by `(topic, partition)`.
2. It enqueues one batch GoodJob per topic-partition group. Each job receives an ordered list of projected payload/metadata entries. Order within each group is the order in which Karafka provided the messages.
3. A batch GoodJob processes its entries sequentially. It routes `delete` to system removal/cleanup; `created` and `updated` to system import and associated policy/report work; compliance report messages to `Kafka::ReportParser`; and other unrecognized messages to the existing skip/debug behavior.
4. Each message is processed inside an error boundary. On a processing exception, log an error including Kafka topic, partition, and offset, then continue with the next message. This first change deliberately does not re-raise per-message processing exceptions or add a batch retry policy.
5. Batch GoodJobs share a GoodJob concurrency key derived from topic and partition and use `perform_limit: 1`. This prevents simultaneous execution of two batch jobs for the same partition. It does **not** guarantee enqueue-order execution between different jobs; existing stale-data protections remain the defense against out-of-order messages.
6. Kafka messages are marked consumed after their grouped GoodJob enqueue succeeds, retaining the existing enqueue-before-ack behavior. An enqueue exception must remain visible to Karafka rather than acknowledging messages whose batch job was not scheduled.

If a single Karafka delivery ever contains messages for multiple partitions, group and enqueue each partition independently. Preserve ordering within each group. Do not claim ordering across partitions.

## Work contract

### Confidence and assumptions

Confidence: high on the requested behavior; medium on exact Karafka API details pending implementation-time validation against the locked Karafka version and its test helpers.

Assumptions:
- Each system's Kafka events are consistently assigned to one partition, as stated by the user.
- Separate GoodJobs for the same topic-partition may execute in either order; preventing overlap is sufficient for this change.
- The first commit intentionally logs a processing error and proceeds. A more robust failure/retry/replay policy is a separate follow-up.

### In scope

- Inventory consumer batching/preparation and enqueue behavior.
- A batch job that sequentially dispatches projected inventory messages, including report parsing.
- Topic-partition GoodJob mutual exclusion for the batch job.
- Focused unit/spec coverage for grouping, message order, dispatch of imports/deletes/report parsing, error logging and continuing, concurrency key/limit, and enqueue failure not acknowledging Kafka messages.
- A single local conventional commit containing the implementation and directly relevant tests/docs, only after explicit commit authorization is confirmed.

### Out of scope

- FIFO scheduling between separate GoodJobs.
- Changes to existing stale-data protections or system identity partitioning.
- A robust retry, DLQ, partial-batch checkpoint, or exactly-once processing design.
- Kafka-ingress filtering, owned separately by a colleague.
- Database/schema migrations, dependency changes, public APIs, deployment, CI, or infrastructure changes.
- Unrelated refactoring.

### Impact checklist

- [x] Application code — consumer, new batch job, and only required job-processing reuse.
- [x] Tests — consumer/job/concurrency focused RSpec.
- [ ] Database/schema — unaffected; no migrations.
- [ ] Dependencies — unaffected.
- [ ] Docker/Podman/Compose — unaffected.
- [ ] CI/Jenkins — unaffected.
- [ ] OpenShift/deployment — unaffected.
- [x] Documentation — this design and implementation plan are local project documents.
- [x] Jira — implementation task RHINENG-33200 created and linked to RHINENG-33196 before this implementation phase.
- [ ] GitHub/GitLab — no action.
- [ ] Generated artifacts — none expected.

### Acceptance criteria

1. One GoodJob is enqueued for each distinct topic-partition represented in the consumer delivery, rather than one import/delete GoodJob for each message.
2. The batch job retains each group's input message order and processes entries sequentially.
3. Imports, deletes, and compliance report parsing all execute within the batch GoodJob path; unknown messages retain skip behavior.
4. Jobs with the same topic-partition key have `perform_limit: 1`; the implementation makes no FIFO guarantee between separate jobs.
5. A processing exception is logged with Kafka coordinates and does not prevent later entries in that batch from being attempted.
6. A failure to enqueue a partition's batch is not silently acknowledged to Kafka.
7. Focused specs and applicable lint/static checks pass, or any unavailable checks and their risks are explicitly reported.

### Required validation

- `bundle check` to establish dependency availability.
- Focused RSpec specs for the changed consumer and batch job (plus directly changed job specs).
- RuboCop on changed Ruby files.
- Brakeman if the local bundle permits it; changes are background job/consumer code and do not alter authorization or input exposure, but CI config includes Brakeman.
- Broader RSpec suite if local dependencies and services permit it.
- Verify only intended files changed and no schema/generated artifacts changed.

Current baseline note: `bundle check` fails in the new worktree because the locked `yabeda-activejob` git source is not checked out, and Bundler reports locally installed gems with missing extensions. No dependency installation has been attempted.

### External actions and commits

No push, PR, Jira update, CI trigger, release, or deployment is included. Expected single commit (subject to explicit commit approval after validation): `feat(kafka): batch inventory event jobs`. A local commit does not imply permission to publish it.

### Approval status

`approved`; implementation plan and subagent-driven execution approved by user. Implementation is in progress.
