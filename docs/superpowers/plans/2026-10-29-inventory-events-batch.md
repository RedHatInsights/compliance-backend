# Inventory Events Batch GoodJob Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace per-message inventory GoodJobs with one sequential GoodJob per topic-partition represented in each Karafka delivery, including compliance report parsing.

**Architecture:** The consumer projects messages, groups them by `(topic, partition)`, enqueues one batch job per group, then marks those messages consumed. The batch job dispatches imports, deletes, compliance report parsing, and skip handling sequentially, logging each message's exception and continuing. All inventory job classes use the same GoodJob concurrency key derived from their Kafka topic and partition, with `perform_limit: 1`; this prevents concurrent execution but does not establish FIFO between jobs.

**Tech Stack:** Ruby 3.3, Rails 8.1 / ActiveJob, Karafka 2.5, GoodJob 4.19, RSpec, RuboCop.

**Spec:** `docs/superpowers/specs/2026-10-29-inventory-events-batch-design.md`

## Global Constraints

- Base implementation on `master` at `676030023ad4460a7d4b0386fc28671963b92f8f` in `feat/inventory-events-batch-job`.
- Do not generate or run database migrations.
- Do not add dependencies or change deployment, CI, API, or schema.
- Preserve message order within a topic-partition group; make no FIFO guarantee between separate GoodJobs.
- Catch/log a processing exception per message and continue with later entries in that batch.
- Keep out of scope the retry/DLQ/checkpoint redesign; do not silently add retry semantics.
- Preserve enqueue-before-Kafka-ack behavior: an enqueue failure must propagate before acknowledging that group's messages.
- Do not touch the pre-existing untracked `.playwright-mcp/` and `docs/` in the `master` worktree; implementation occurs only in this task worktree.
- Do not commit, push, or publish until the user explicitly approves the exact validated commit preview.

## Review Focus

1. **Interleaved partitions:** grouping must retain original per-partition order while emitting separate jobs; test messages interleaved across two topic-partitions.
2. **Mixed message types:** import, delete, compliance report, and unknown messages must be dispatched correctly in one sequential job; test dispatch order and that report parsing is not done in the consumer.
3. **Per-message exception:** one failing entry must log topic/partition/offset and not prevent the next entry; test both the log call and continued dispatch.
4. **Legacy job overlap:** existing queued import/delete jobs must use the same topic-partition key as a batch job after deployment; test equal keys and `perform_limit: 1` across all three job classes.
5. **Enqueue failure / acknowledgement:** if enqueueing a group's job raises, its Kafka messages must not be acknowledged; test no `mark_as_consumed` calls for that group.

---

### Task 1: Shared topic-partition concurrency

**Files:**
- Delete: `app/jobs/concerns/inventory_system_concurrency.rb`
- Create: `app/jobs/concerns/inventory_partition_concurrency.rb`
- Modify: `app/jobs/system_import_job.rb`
- Modify: `app/jobs/system_delete_job.rb`
- Test: `spec/jobs/concerns/inventory_system_concurrency_spec.rb` (rename to `spec/jobs/concerns/inventory_partition_concurrency_spec.rb`)

**Interfaces:**
- Consumes: ActiveJob `arguments`; for existing jobs these are `(payload, kafka_metadata)`.
- Produces: `InventoryPartitionConcurrency#inventory_partition_key`, returning `"inventory-partition:<topic>:<partition>"`; import, delete, and batch job classes share `perform_limit: 1` with no total limit.

- [ ] **Step 1: Write tests for shared topic-partition concurrency.**

Replace system-ID assertions with tests that instantiate `SystemImportJob` and `SystemDeleteJob` using the same Kafka metadata and expect both keys to equal `"inventory-partition:#{metadata.fetch('topic')}:#{metadata.fetch('partition')}"`. Add a test that both classes have `perform_limit == 1` and `total_limit == nil`.

- [ ] **Step 2: Run the focused spec and confirm the new expectation fails.**

Run: `bundle exec rspec spec/jobs/concerns/inventory_partition_concurrency_spec.rb`
Expected: cannot load the renamed/new spec before implementation, or fail on the old system-ID behavior once the file is staged in working tree. Keep the failure focused on the changed contract.

- [ ] **Step 3: Replace the concern and update job includes.**

Implement `InventoryPartitionConcurrency` with `GoodJob::ActiveJobExtensions::Concurrency`, `perform_limit: 1`, and a key based on the last job argument's `topic` and `partition`. Update both existing jobs to include the renamed concern. A common key method should be:

```ruby
def inventory_partition_key
  metadata = arguments.last
  "inventory-partition:#{metadata.fetch('topic')}:#{metadata.fetch('partition')}"
end
```

Use this method from the GoodJob key lambda. Do not infer a system ID or promise FIFO.

- [ ] **Step 4: Run the focused concurrency spec.**

Run: `bundle exec rspec spec/jobs/concerns/inventory_partition_concurrency_spec.rb`
Expected: PASS.

---

### Task 2: Batch job dispatch and per-message logging

**Files:**
- Create: `app/jobs/inventory_events_batch_job.rb`
- Test: `spec/jobs/inventory_events_batch_job_spec.rb`
- Modify: `app/jobs/system_import_job.rb` only if needed to expose/reuse existing per-message behavior without enqueuing nested jobs.

**Interfaces:**
- Consumes: `perform(entries, kafka_metadata)`, where `entries` is an ordered array of hashes `{ 'payload' => Hash, 'metadata' => { 'topic' => String, 'partition' => Integer, 'offset' => Integer, 'timestamp' => ... } }`; `kafka_metadata` contains the group's topic and partition and is the last argument for the shared concurrency key.
- Produces: sequential dispatch for each entry; failures logged with Kafka coordinates and processing continues. The batch job is assigned to `:inventory` and includes `InventoryPartitionConcurrency`.

- [ ] **Step 1: Add dispatch specs before the implementation.**

In `spec/jobs/inventory_events_batch_job_spec.rb`, cover, using doubles:

```ruby
expect(SystemImportJob).to receive(:new).with(import_payload, entry_metadata).ordered.and_return(import_runner)
expect(import_runner).to receive(:perform).with(import_payload, entry_metadata).ordered
expect(SystemDeleteJob).to receive(:new).with(delete_payload, entry_metadata).ordered.and_return(delete_runner)
expect(delete_runner).to receive(:perform).with(delete_payload, entry_metadata).ordered
expect(Kafka::ReportParser).to receive(:new).with(report_payload, Rails.logger).ordered
```

Also assert an unknown non-compliance message logs the existing skip debug text, and assert the batch job shares a metadata-derived key/`perform_limit: 1`.

- [ ] **Step 2: Add per-entry failure continuation spec.**

Make the first entry's runner raise `StandardError`; assert the job logs an error including that entry's topic, partition, and offset, then dispatches the next entry. Keep the exception behavior specific: catch `StandardError` around each entry, not around the entire iteration.

- [ ] **Step 3: Run the new batch-job spec to verify it fails before implementation.**

Run: `bundle exec rspec spec/jobs/inventory_events_batch_job_spec.rb`
Expected: FAIL because `InventoryEventsBatchJob` is not yet defined.

- [ ] **Step 4: Implement the sequential batch dispatcher.**

For each entry, route `delete` to `SystemDeleteJob.new(payload, metadata).perform(payload, metadata)`; route `created` / `updated` to `SystemImportJob.new(payload, metadata).perform(payload, metadata)`; for other types, call `Kafka::ReportParser.new(payload, Rails.logger).parse_reports` when platform service is `compliance`, otherwise log the existing skipped-message debug line. Rescue and log each entry's `StandardError`, including topic/partition/offset, and continue. The consumer must pass import/delete projections but retain the full payload for other events so report parsing has all existing fields. Do not enqueue nested per-message jobs.

- [ ] **Step 5: Run batch-job and existing import/delete job specs.**

Run: `bundle exec rspec spec/jobs/inventory_events_batch_job_spec.rb spec/jobs/system_import_job_spec.rb spec/jobs/system_delete_job_spec.rb spec/jobs/concerns/inventory_partition_concurrency_spec.rb`
Expected: PASS; existing import/delete direct processing and idempotency behavior remains intact.

---

### Task 3: Enqueue per topic-partition batch from Karafka consumer

**Files:**
- Modify: `app/consumers/inventory_events_consumer.rb`
- Test: `spec/consumers/inventory_events_consumer_spec.rb`

**Interfaces:**
- Consumes: Karafka `messages`, each with `raw_payload`, `topic`, `partition`, `offset`, and `timestamp`.
- Produces: one `InventoryEventsBatchJob.perform_later(entries, { 'topic' => topic, 'partition' => partition })` call per distinct topic-partition; each message is marked consumed only after its group's enqueue succeeds.

- [ ] **Step 1: Replace single-message enqueue specs with grouped batch expectations.**

Use a consumer delivery with two messages from the same partition and one from a second partition, interleaved in delivery order. Expect two batch enqueue calls; assert the same-partition entries keep their relative order, the correct topic/partition metadata accompanies each, and each projected import/delete payload retains the current projection rules.

- [ ] **Step 2: Cover compliance report and unknown messages in the batch payload.**

Assert the consumer does not call `Kafka::ReportParser` synchronously and passes the full compliance payload to the batch job. Unknown events must also be included for the batch job's skip handling.

- [ ] **Step 3: Cover enqueue failure before acknowledgement.**

Arrange `InventoryEventsBatchJob.perform_later` to raise and assert the error propagates and no messages from the failed group are marked consumed.

- [ ] **Step 4: Run the consumer spec to confirm the new behavior fails against the current consumer.**

Run: `bundle exec rspec spec/consumers/inventory_events_consumer_spec.rb`
Expected: FAIL because the consumer currently enqueues individual jobs / parses compliance messages synchronously.

- [ ] **Step 5: Implement grouping, projection, enqueue, and acknowledgement.**

Override `consume` in `InventoryEventsConsumer` inside `Rails.application.executor.wrap`; retain `log_metadata`, group Karafka `messages` by `[message.topic, message.partition]`, and preserve order using the original enumeration order. Build each entry's metadata and projected payload: use current import projection for `created` / `updated`, current delete projection for `delete`, and full parsed payload for other types. Enqueue one batch job with the group's topic/partition key metadata, then call `mark_as_consumed` for that group's original Karafka messages. Do not acknowledge a group if enqueue raises. Do not change `ApplicationConsumer` for other consumers.

- [ ] **Step 6: Run focused consumer, batch-job, and shared-concurrency specs.**

Run: `bundle exec rspec spec/consumers/inventory_events_consumer_spec.rb spec/jobs/inventory_events_batch_job_spec.rb spec/jobs/concerns/inventory_partition_concurrency_spec.rb`
Expected: PASS.

---

### Task 4: Validate, review scope, and prepare the requested single commit

**Files:**
- Inspect all changed files; no extra application changes.
- Include design and plan docs with implementation in the single commit only if the user approves that exact commit preview.

- [ ] **Step 1: Run bundle availability check and focused test suite.**

Run: `bundle check`
Run: `bundle exec rspec spec/consumers/inventory_events_consumer_spec.rb spec/jobs/inventory_events_batch_job_spec.rb spec/jobs/concerns/inventory_partition_concurrency_spec.rb spec/jobs/system_import_job_spec.rb spec/jobs/system_delete_job_spec.rb`
Expected: dependencies are available and all focused specs pass. If bundle is still unavailable due the missing locked git source/extensions, do not install or modify dependencies without approval; report tests as unavailable and state the limitation.

- [ ] **Step 2: Run repository-configured static checks.**

Run: `bundle exec rubocop app/consumers/inventory_events_consumer.rb app/jobs/inventory_events_batch_job.rb app/jobs/system_import_job.rb app/jobs/system_delete_job.rb app/jobs/concerns/inventory_partition_concurrency.rb spec/consumers/inventory_events_consumer_spec.rb spec/jobs/inventory_events_batch_job_spec.rb spec/jobs/concerns/inventory_partition_concurrency_spec.rb`
Run: `bundle exec brakeman`
Expected: no new offenses/security findings; if dependencies remain unavailable, mark unavailable and report reason.

- [ ] **Step 3: Inspect final diff and ensure generated/schema artifacts are unchanged.**

Run: `git diff --check && git status --short && git diff --stat && git diff -- db/schema.rb Gemfile Gemfile.lock deploy docker-compose.yml`
Expected: no whitespace issues; no schema, dependency, deployment, or generated changes.

- [ ] **Step 4: Perform read-only review and provide the exact commit preview.**

Report changed paths, test/lint/security results, the limitation that partition locking is not FIFO and per-message errors are only logged/continued, and the exact single-commit subject `feat(kafka): batch inventory event jobs`. Wait for explicit approval before creating the commit; do not push or create a PR.
