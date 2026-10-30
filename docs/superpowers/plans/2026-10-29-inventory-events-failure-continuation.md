# Inventory Events Failure Continuation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Defer failed inventory events and their same-system successors into ordered continuation jobs, while allowing other systems in the batch to proceed and preserving exhausted work for operator recovery.

**Architecture:** Extract synchronous event dispatch and canonical system-ID resolution into a small processor that invokes import/delete jobs' `perform` directly, so the coordinator observes failures without triggering their standalone `retry_on` callbacks. The batch job groups blocked suffixes per system and switches to one partition-scoped unresolved suffix if a failed event has no identity; a continuation job processes one unresolved suffix at a time, carrying a next-attempt marker per entry and raising custom unhandled errors on exhaustion or enqueue failure.

**Tech Stack:** Ruby 3.3.12, Rails 8.1 / ActiveJob, Karafka, GoodJob 4.19, RSpec, RuboCop, Brakeman.

**Spec:** `docs/superpowers/specs/2026-10-29-inventory-events-failure-continuation-design.md`

## Global Constraints

- Preserve the failed event and later events for the same system in their original order; continue attempting entries for other systems.
- Unknown identity on a failed processable event defers the remaining entries in that partition.
- Use three maximum automatic processing attempts per event; unattempted suffix events do not consume an attempt. Schedule every continuation with a fixed 30-second backoff.
- After exhaustion, raise an unhandled error with the unresolved sequence still present in the preserved GoodJob arguments; the existing GoodJob cleanup window is 14 days.
- Make processing failures observable to the batch/continuation coordinator without changing standalone import/delete retry behavior.
- Accept at-least-once side effects; do not promise cross-batch FIFO or policy/report side-effect ordering.
- Do not change schema, dependencies, deployment, CI, APIs, or unrelated files; do not generate or run migrations.
- Do not commit, push, update Jira, trigger CI, publish, release, merge, or deploy without separate explicit approval.
- Every changed application-code file must have a passing unit spec under the repository's `AGENTS.md` rule.

## File Structure

- `app/services/inventory_events_processor.rb` — dispatch one existing batch entry synchronously and resolve its canonical system ID; terminal import attempt sets the existing `SystemImportJob` terminal-metric context without invoking ActiveJob retry callbacks.
- `spec/services/inventory_events_processor_spec.rb` — unit coverage for import/delete/report/skip dispatch, error visibility, identity extraction, and terminal import context.
- `app/jobs/inventory_events_continuation_job.rb` — process an ordered unresolved suffix, advance only the failed entry's next-attempt marker, enqueue the unresolved suffix, or raise an unhandled terminal error.
- `spec/jobs/inventory_events_continuation_job_spec.rb` — unit coverage for order, suffix preservation, attempts, exhausted failure, concurrency scope, and enqueue failure.
- `app/jobs/inventory_events_batch_job.rb` — defer blocked systems while processing others, merge already-deferred entries into a partition suffix if an unidentifiable event fails, and enqueue continuations after batch traversal.
- `spec/jobs/inventory_events_batch_job_spec.rb` — focused regression coverage for deferral, ordering, isolation, identity fallback, and propagation of continuation-enqueue failures.
- `spec/jobs/system_import_job_spec.rb` and `spec/jobs/system_delete_job_spec.rb` — standalone retry compatibility tests only; no changes to those job implementations are planned.
- `docs/superpowers/specs/2026-10-29-inventory-events-failure-continuation-design.md` — record that written-spec review is approved and keep scope/acceptance aligned.

## Review Focus

1. **A failed system followed by same-system and other-system events:** same-system suffix is not dispatched; unrelated systems still are. Test in Task 3.
2. **A known-identity failure followed later by an unknown-identity failure:** merge the previously buffered sequence and partition remainder exactly once, in original order, into one partition continuation. Test in Task 3.
3. **A continuation enqueue throws or returns false:** wrap it as an unhandled continuation enqueue error, leaving the current batch/continuation record's original serialized payload available for GoodJob preservation; do not allow inherited database `retry_on` to replay the entire batch automatically. Test in Tasks 2 and 3.
4. **An event fails on its third attempt:** raise a custom terminal error, not the original retryable database exception, so `ApplicationJob` does not start a fourth automatic retry. Preserve the failed event plus suffix in current job arguments. Test in Task 2.
5. **Existing standalone import/delete jobs:** still use `perform_now` and their configured `retry_on` when used independently; only the coordinator calls their `perform` directly. Test in Task 1.

---

### Task 1: Synchronous inventory event processor

**Files:**
- Create: `app/services/inventory_events_processor.rb`
- Test: `spec/services/inventory_events_processor_spec.rb`
- Test: `spec/jobs/system_import_job_spec.rb`
- Test: `spec/jobs/system_delete_job_spec.rb`

**Interfaces:**
- Consumes: `InventoryEventsProcessor.new(entry, attempt: Integer)` where `entry` is `{ 'type' => String, 'payload' => Hash, 'metadata' => Hash }`.
- Produces: `#process` dispatches one entry and returns normally on success; it raises processing exceptions unchanged so batch/continuation can observe them. `#system_id` returns the canonical system ID or `nil`.
- Import/delete dispatch uses `SystemImportJob.new(payload, metadata).perform(payload, metadata)` / `SystemDeleteJob.new(payload, metadata).perform(payload, metadata)`, not `perform_now`.
- For an import at attempt 3, assign `exception_executions` on the child job to `{ SystemImportJob::DATABASE_RETRY_HANDLER => 2 }` before `perform`, preserving existing terminal import metrics. Do not set this for attempts 1 or 2.

- [x] **Step 1: Add processor tests for each dispatch path and failure visibility.**

Test created/updated dispatch to `SystemImportJob#perform`, delete dispatch to `SystemDeleteJob#perform`, compliance dispatch to `Kafka::ReportParser#parse_reports`, and unknown non-compliance skip logging. Make each child processor raise a representative exception and assert `#process` propagates it. Assert the job instance's `perform_now` is never called, preventing nested retry callbacks.

- [x] **Step 2: Add tests for canonical identity and terminal import context.**

Assert import and compliance-report entries resolve `payload.dig('host', 'id')`, delete entries resolve `payload['id']`, and missing/blank identifiers return `nil`. Assert attempt 3 sets the import child job's `exception_executions` to `{ SystemImportJob::DATABASE_RETRY_HANDLER => 2 }`; attempts 1 and 2 do not set a terminal marker.

- [x] **Step 3: Add standalone retry-compatibility specs.**

In each existing import/delete job spec, temporarily use an `ActiveJob::QueueAdapters::TestAdapter`, make the underlying database operation raise `ActiveRecord::Deadlocked`, invoke the job with `perform_now`, and assert exactly one retry job is enqueued. Restore the original queue adapter in `ensure`. These tests protect the standalone path while the coordinator uses direct `perform`.

- [x] **Step 4: Attempt the new processor spec before implementation (blocked before RSpec by missing locked `yabeda-activejob`).**

Attempted `bundle exec rspec spec/services/inventory_events_processor_spec.rb`; Bundler stopped before RSpec because the locked `yabeda-activejob` checkout is missing. No test result was produced.

- [x] **Step 5: Implement the synchronous processor.**

Create `InventoryEventsProcessor` with the constructor and public methods in the interface above. Use this dispatch shape, allowing exceptions to propagate unchanged:

```ruby
def process
  case @entry.fetch('type')
  when 'delete'
    SystemDeleteJob.new(payload, metadata).perform(payload, metadata)
  when 'created', 'updated'
    job = SystemImportJob.new(payload, metadata)
    job.exception_executions = { SystemImportJob::DATABASE_RETRY_HANDLER => 2 } if @attempt == 3
    job.perform(payload, metadata)
  else
    if payload.dig('platform_metadata', 'service') == 'compliance'
      Kafka::ReportParser.new(payload, Rails.logger).parse_reports
    else
      Rails.logger.debug "Skipped message of type '#{@entry.fetch('type')}'"
    end
  end
end

def system_id
  case @entry.fetch('type')
  when 'delete' then payload['id']
  when 'created', 'updated' then payload.dig('host', 'id')
  else payload.dig('host', 'id') if payload.dig('platform_metadata', 'service') == 'compliance'
  end
end
```

Keep `payload` and `metadata` as private accessors for the entry fields. Do not add a rescue to `process`.

- [x] **Step 6: Attempt processor and compatibility specs (blocked before RSpec by missing locked `yabeda-activejob`).**

Run: `bundle exec rspec spec/services/inventory_events_processor_spec.rb spec/jobs/system_import_job_spec.rb spec/jobs/system_delete_job_spec.rb`
Attempted the focused processor/compatibility RSpec command; Bundler stopped before RSpec because the locked `yabeda-activejob` checkout is missing. No test result was produced.

---

### Task 2: Persisted continuation and retry accounting

**Files:**
- Create: `app/jobs/inventory_events_continuation_job.rb`
- Test: `spec/jobs/inventory_events_continuation_job_spec.rb`

**Interfaces:**
- `InventoryEventsContinuationJob.enqueue(work_items, kafka_metadata)` calls `set(wait: BACKOFF).perform_later(work_items, kafka_metadata)` where `BACKOFF = 30.seconds`; raises `EnqueueError` if enqueue raises or returns false. The wrapper must convert enqueue exceptions—including ActiveRecord connection errors—into a custom StandardError subclass so `ApplicationJob`'s database `retry_on` cannot hide the failed enqueue or restart work invisibly. The batch-to-continuation enqueue and every continuation retry use the same backoff.
- `perform(work_items, kafka_metadata)` receives an ordered array of `{ 'entry' => entry, 'next_attempt' => Integer }`; the metadata hash is the final argument and supplies the existing partition concurrency key.
- `MAX_ATTEMPTS = 3`, `BACKOFF = 30.seconds`. `next_attempt` is the attempt about to be made. Initial batch failure sets the failed item's next attempt to 2; not-yet-attempted suffix entries carry 1.
- On failure below the limit, enqueue the failed item with `next_attempt + 1` followed by the untouched suffix. On the third failed attempt, raise `AttemptsExhausted` without enqueueing; include the failed entry and suffix in the serialized arguments of the running job.

- [x] **Step 1: Write continuation tests for ordered processing and successful completion.**

Use processor doubles to prove entries are processed in order and all-successful sequences enqueue nothing. For a sequence whose head succeeds and second entry fails on attempt 1, assert only the failed second entry and remaining suffix are enqueued, in their original order; assert the second entry's next attempt is 2 and later unattempted entries retain 1.

- [x] **Step 2: Write retry-limit and terminal-preservation tests.**

For a failed entry with `next_attempt` 2, assert it is re-enqueued with 3. For a failure at `next_attempt` 3, assert `AttemptsExhausted` propagates, no continuation is enqueued, and serializing the job shows the failed entry and every later unresolved entry remain in its arguments. Assert the terminal error is not handled by the inherited `ApplicationJob` `retry_on` handlers.

- [x] **Step 3: Write enqueue-failure tests.**

Test the configured enqueue returning `false` and raising `ActiveRecord::ConnectionFailed`; both must raise `EnqueueError`, preserve the original exception as cause when present, and not match the inherited database retry handlers. Assert the enqueued continuation has a scheduled time 30 seconds later and only the work items and metadata in its serialized perform arguments. This leaves GoodJob to record the current job as unhandled with its original unresolved arguments.

- [x] **Step 4: Write queue and concurrency tests.**

Assert the continuation uses the inventory queue and the same topic-partition concurrency key/`perform_limit: 1` as the batch. Do not change GoodJob initializer configuration; verify the existing preservation callback and 14-day cleanup value during final scope review.

- [x] **Step 5: Attempt the continuation spec before implementation (blocked before RSpec by missing locked `yabeda-activejob`).**

Attempted `bundle exec rspec spec/jobs/inventory_events_continuation_job_spec.rb`; Bundler stopped before RSpec because the locked `yabeda-activejob` checkout is missing. No test result was produced.

- [x] **Step 6: Implement the continuation job using the tested state transition.**

Implement `enqueue` so it calls `set(wait: BACKOFF).perform_later(work_items, kafka_metadata)`, raises `EnqueueError` when the result is false/nil, re-raises an existing `EnqueueError`, and wraps every other `StandardError` as `EnqueueError` with the original error as cause. The class body must define `AttemptsExhausted < StandardError`, `EnqueueError < StandardError`, and `MAX_ATTEMPTS = 3`.

In `perform`, iterate work items in order. On success, continue. On a processor exception, build the unresolved suffix from the current item plus later items. If its `next_attempt` is 3, raise `AttemptsExhausted` without calling the enqueue wrapper. Otherwise enqueue a new head item with `next_attempt + 1`, followed by untouched later items, then return immediately. Do not mutate `arguments`; preserving their originally serialized suffix is the recovery behavior if enqueue itself fails. Configure `queue_as :inventory` and include `InventoryPartitionConcurrency`.

- [x] **Step 7: Attempt the continuation spec (blocked before RSpec by missing locked `yabeda-activejob`).**

Run: `bundle exec rspec spec/jobs/inventory_events_continuation_job_spec.rb`
Attempted the focused continuation RSpec command; Bundler stopped before RSpec because the locked `yabeda-activejob` checkout is missing. No test result was produced.

---

### Task 3: Batch deferral and missing-identity partition fallback

**Files:**
- Modify: `app/jobs/inventory_events_batch_job.rb`
- Test: `spec/jobs/inventory_events_batch_job_spec.rb`

**Interfaces:**
- Keeps public batch arguments unchanged: `perform(entries, kafka_metadata)` where entries retain current `{ 'type', 'payload', 'metadata' }` shape.
- Tracks original entry indexes locally so held entries can be merged in source order if a later unknown-identity failure requires partition-wide deferral.
- Calls `InventoryEventsProcessor#process` once for each unblocked entry. It does not rescue and advance the sequence past failure; it records the failure and blocks that system.
- Known-ID deferred items use `{ 'entry' => entry, 'next_attempt' => 2 }` for the failed entry and `next_attempt: 1` for later, unattempted entries.
- Calls `InventoryEventsContinuationJob.enqueue` after traversal: one sequence per blocked system unless an unknown-identity failure occurs, in which case all earlier buffered items for that partition plus the failed entry/remainder become one partition-scoped sequence sorted by original index.

- [x] **Step 1: Replace the old continue-after-error expectation with per-system deferral tests.**

Arrange entries `A1, B1, A2, B2`; make `A1` fail. Assert the batch logs the failure with its Kafka topic/partition/offset, `A2` is not attempted, `B1` and `B2` are processed, and a single continuation for A is enqueued after traversal with `[A1(next_attempt: 2), A2(next_attempt: 1)]` and original Kafka metadata. Assert that `InventoryEventsContinuationJob.enqueue` applies the configured fixed backoff when it calls `perform_later` (covered by the continuation job unit spec).

- [x] **Step 2: Add system isolation and order tests for multiple failures.**

Make both A and B fail, include later entries for each, and assert separate per-system sequences preserve each system's relative original order. Assert dispatch for one blocked system never blocks another system.

- [x] **Step 3: Add the unknown-identity fallback test, including previously held entries.**

Arrange `A1, B1, U, A2, B2`; fail `A1`, let `B1` succeed, then fail `U` where identity is missing. Assert one partition-scoped continuation is enqueued in order `[A1(next_attempt: 2), U(next_attempt: 2), A2(next_attempt: 1), B2(next_attempt: 1)]`; assert none of `A2` or `B2` is processed synchronously and no duplicate per-system continuation for A is enqueued.

- [x] **Step 4: Add enqueue-failure behavior coverage.**

Assert a continuation enqueue failure propagates as `InventoryEventsContinuationJob::EnqueueError` and does not get swallowed by the per-entry processing rescue. Confirm no success return/ack-like behavior is inferred from a false enqueue result. Note that a GoodJob replay after partial batch progress can repeat work; this is accepted at-least-once behavior.

- [x] **Step 5: Attempt the batch spec before implementation (blocked before RSpec by missing locked `yabeda-activejob`).**

Run: `bundle exec rspec spec/jobs/inventory_events_batch_job_spec.rb`
Attempted the batch RSpec command; Bundler stopped before RSpec because the locked `yabeda-activejob` checkout is missing. No test result was produced.

- [x] **Step 6: Implement per-system blocking and partition fallback.**

Replace the per-entry direct dispatcher with `InventoryEventsProcessor`. Traverse entries with their original indexes. Keep `blocked_by_system` and `held_by_system` maps. For each entry, if the partition fallback is active, append it to the partition list with `next_attempt: 1`; if its system ID is blocked, append it to that system's list with `next_attempt: 1`; otherwise call `processor.process`. On a failure, log the Kafka coordinates. If `processor.system_id` is present, add the failed entry at `next_attempt: 2` and mark that system blocked. If it is blank, activate partition fallback, move all previously buffered system entries (preserving their original indexes and attempt counts) into the partition-held list, add the failed entry at `next_attempt: 2`, and continue walking only to append the rest of the partition as unattempted items.

After traversal, if partition fallback is active, merge held entries by original index and call `InventoryEventsContinuationJob.enqueue` once with the partition metadata. Otherwise enqueue each blocked system's sequence in first-seen order, with entries sorted by original index. Let `EnqueueError` propagate outside the per-entry processing rescue. Do not change the consumer, `ApplicationJob`, or GoodJob initializer.

- [x] **Step 7: Attempt batch and related focused specs (blocked before RSpec by missing locked `yabeda-activejob`).**

Run: `bundle exec rspec spec/jobs/inventory_events_batch_job_spec.rb spec/jobs/inventory_events_continuation_job_spec.rb spec/services/inventory_events_processor_spec.rb spec/jobs/system_import_job_spec.rb spec/jobs/system_delete_job_spec.rb`
Attempted the combined focused RSpec command; Bundler stopped before RSpec because the locked `yabeda-activejob` checkout is missing. No test result was produced.

---

### Task 4: Validation, documentation status, and handoff

**Files:**
- Modify: `docs/superpowers/specs/2026-10-29-inventory-events-failure-continuation-design.md`
- Inspect all files changed in Tasks 1–3; no additional source changes without contract revision.

- [x] **Step 1: Recheck dependencies and attempt focused/broader RSpec (blocked before RSpec by missing locked `yabeda-activejob`).**

Run `bundle check`, then the focused command from Task 3, followed by `bundle exec rake spec` if the local dependencies/services allow. Do not install the missing locked git source or gems without separate approval. Report blocked checks with their exact cause and residual validation risk.

- [x] **Step 2: Attempt repository static/security/CI checks (blocked before checks by missing locked `yabeda-activejob`).**

Run:

```bash
bundle exec rubocop app/services/inventory_events_processor.rb app/jobs/inventory_events_continuation_job.rb app/jobs/inventory_events_batch_job.rb spec/services/inventory_events_processor_spec.rb spec/jobs/inventory_events_continuation_job_spec.rb spec/jobs/inventory_events_batch_job_spec.rb spec/jobs/system_import_job_spec.rb spec/jobs/system_delete_job_spec.rb
bundle exec brakeman
bundle exec rake spec:validate
```

Expected: checks pass with no new offenses/findings. If unavailable due the documented bundle problem, capture the failure output and do not claim the check passed.

- [x] **Step 3: Verify spec/plan alignment and repository scope.**

Review the spec and plan against every acceptance criterion; check for placeholders, retry-count contradictions, or accidental cross-batch/FIFO claims. Run `git diff --check`, inspect `git status --short`, and verify `db/schema.rb`, `Gemfile`, `Gemfile.lock`, deploy/CI/container files, and generated artifacts are unchanged.

- [x] **Step 4: Prepare a read-only completion report.**

List changed paths, acceptance-criterion evidence, tests/lint/security/CI results or blockers, and remaining limitations. No commits, Jira/GitHub actions, CI triggers, releases, or deployment are authorized by this plan.

## Execution Status

Implementation and focused specs are present and reviewed. Ruby syntax and `git diff --check` pass. RSpec, RuboCop, Brakeman, and `spec:validate` remain unverified because Bundler cannot load the locked `yabeda-activejob` Git source checkout; no dependency installation was attempted. The consumer's existing behavior of acknowledging messages after a false batch-job enqueue remains explicitly deferred because consumer changes are out of scope and no revised contract was approved.

## Approval Status

`approved for implementation by user on 2026-10-29; execution method: subagent-driven`. No commit or external action is included; those remain separately gated.
