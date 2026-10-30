# Inventory Events Failure Continuation Design

## Status

- Classification: feature / architectural
- Design path: architectural
- User-approved behavior decisions: yes
- Written spec: approved by user on 2026-10-29
- Implementation plan: approved by user on 2026-10-29; execution method: subagent-driven; implementation approved: yes
- Implementation status: code/specs present; syntax and diff checks pass; runtime test/static checks blocked before execution by the missing locked `yabeda-activejob` Git source checkout
- Related delivered feature: `docs/superpowers/specs/2026-10-29-inventory-events-batch-design.md`
- Current branch/commit at drafting: `feat/inventory-events-batch-job` / `015567fee8a651056b0efa2703df5f6759d5baea`

## Goal

When an inventory event fails during a partition batch, preserve the failed event and every later event for that same system in their original order, without preventing events for other systems from being processed. Retry the unresolved sequence using a persisted per-system continuation job. After three total processing attempts for an event, leave an unhandled GoodJob record with the unresolved sequence for operator recovery.

## Agreed behavior and constraints

1. The batch continues processing entries for unblocked systems after one system's entry fails.
2. Once a system is blocked, do not attempt any later entry for that system in the same batch. Accumulate the failed entry and its later entries in batch order.
3. At batch completion, enqueue a continuation for each held system sequence. A continuation processes its sequence in order and stops at the first failure. Successfully processed prefix entries are removed; only the failed entry and unresolved suffix are carried forward.
4. If an event's system identity cannot be derived, hold that event and the remainder of its partition batch in a partition-scoped continuation. This is fail-closed for that partition remainder; other partitions/systems may proceed.
5. The three-attempt limit is per event-processing attempt: the original batch attempt, if made, plus at most two continuation attempts. A suffix event not yet attempted has not consumed an attempt. Schedule each continuation with a short fixed 30-second backoff. On exhaustion, raise an unhandled terminal error with the failed event and remaining suffix still present in the GoodJob arguments.
6. Existing GoodJob configuration preserves unhandled jobs and cleans preserved records after 14 days. The user accepts this recovery window.
7. The retry/continuation path must observe handler failures. Existing child-job `retry_on` handlers must not hide a failure from the batch/continuation coordinator or create an independent retry path. Standalone import/delete job retry behavior remains unchanged.
8. Processing is at-least-once. If an event partially performs side effects and then fails, retry may repeat those effects; the user accepts this risk.
9. Existing timestamp guards are relied upon for system-row import/delete state. There is no ordering guarantee for policy/report side effects relative to events in later batches. The current partition concurrency lock prevents simultaneous execution but does not promise FIFO between separately enqueued jobs.

## Identity and event handling

Use the same canonical identifiers consumed by the existing handlers:

| Event kind | Continuation identity |
| --- | --- |
| `created` / `updated` | `payload.dig('host', 'id')` |
| `delete` | `payload['id']` |
| Compliance report (the non-import/delete path handled by `Kafka::ReportParser`) | `payload.dig('host', 'id')`, matching `ReportParser#id` |
| Other non-compliance event | Existing skip/debug behavior; it has no processing failure to sequence |

Treat blank/missing identity on a failed processable event as unknown. Do not guess from org/account, payload metadata, or a different ID field. Defer the rest of that partition group because it is not possible to know which later entries share the system.

## Processing and retry lifecycle

- Keep the current batch entry's projected payload, original event discriminator, and Kafka metadata available to any continuation. Do not re-parse or re-project a saved entry differently on retry.
- The batch tracks blocked system IDs while traversing the original entries. For a blocked ID, append later entries without dispatching them. For an unidentifiable failed entry, append the remainder of that partition without dispatching it.
- Enqueue held sequences only after normal batch traversal. Sequence order is the original relative order from the delivery. A partition fallback retains its partition metadata for concurrency coordination.
- A continuation carries an ordered unresolved suffix and per-entry attempt counts. It processes entries in order until all succeed or one fails. On failure, increment only the entry actually attempted; do not charge later, unattempted suffix entries. Re-enqueue the unresolved suffix for another attempt after a fixed 30-second backoff while the failed entry remains below three total attempts. The first continuation enqueued by the batch uses the same delay.
- Once the third attempt for the current failed entry fails, raise an unhandled terminal error. The job's serialized arguments must still include that failed entry and every later unresolved entry so the preserved GoodJob contains the recovery payload.
- A continuation enqueue failure, including `perform_later` returning false, must remain visible; it must not silently discard the unresolved entries. The implementation plan must choose and test a concrete failure path that preserves the current job/arguments for GoodJob recovery without allowing inherited ActiveJob retry handling to hide the failure. Any necessary change to the contract must be returned for approval before implementation.
- Reuse the existing topic-partition concurrency scope for batch and continuation work. It serializes execution for that partition but is not a cross-batch ordering gate.

## Scope contract

### Confidence and assumptions

Confidence: high on the desired behavior and accepted limitations; medium on the exact ActiveJob/GoodJob mechanics needed to expose failures, track retry counts, and preserve enqueue failures. Those mechanics must be verified against the locked Rails/GoodJob versions before implementation.

Assumptions:

- Events in the batch retain the original order supplied by Karafka within each topic-partition group.
- Existing SystemImporter/SystemRemover timestamp checks remain unchanged and are sufficient for system-row state under the accepted scope.
- Policy associations, report work, notifications, and other non-system-row side effects can interleave with later batches.
- GoodJob's existing unhandled-job preservation and 14-day cleanup configuration remain unchanged.

### In scope

- Modify `app/jobs/inventory_events_batch_job.rb` to block/collect event suffixes by identity and enqueue continuations after processing other entries.
- Add a per-system continuation job (and partition-remainder mode for unknown identity) using existing partition concurrency coordination.
- Make only the necessary changes to the synchronous import/delete processing path so the coordinator sees failures, while retaining standalone job retry behavior and required existing processing semantics/metrics.
- Add or update focused unit specs for every changed application-code file, including batch behavior, identity extraction, per-system and missing-identity deferral, order, attempt accounting, continuation exhaustion, continuation enqueue failure, and existing job retry compatibility.
- Update this design artifact and add an implementation plan only after written-spec approval.

### Out of scope

- Durable per-system cross-batch gates, sequence numbers, database tables/columns, migrations, or a DLQ service.
- FIFO scheduling among separate GoodJobs or ordering guarantees for policy/report side effects across later batches.
- Exactly-once execution or preventing replay of partial side effects.
- Changes to Kafka ingress, consumer grouping/projection, event schemas, public APIs, dependencies, database schema, deployment, CI, or infrastructure.
- Changing GoodJob retention or the 14-day cleanup window.
- Unrelated cleanup/refactoring.
- Jira/GitHub/GitLab writes, CI triggers, commits, pushes, PRs, releases, merges, or deployment.

### Impact checklist

- Application code: **affected** — batch coordinator, new continuation job, and the minimum required synchronous-dispatch adjustment.
- Tests: **affected** — focused RSpec coverage; every changed application-code file must have a passing unit spec per `AGENTS.md`.
- Database/schema: **unaffected** — no migration or schema change.
- Dependencies: **unaffected** — use locked ActiveJob/GoodJob behavior only.
- Docker/Podman/Compose: **unaffected**.
- CI/Jenkins: **unaffected**.
- OpenShift/deployment: **unaffected**.
- Documentation: **affected** — this spec and, after approval, an implementation plan.
- Jira: **unaffected** — no issue update/create authorized.
- GitHub/GitLab: **unaffected** — no external write authorized.
- Generated artifacts: **unaffected** — none expected.

### Acceptance criteria

1. An event failure blocks that event and every later event for its identified system in the current batch; entries for other systems continue to be attempted.
2. Deferred events retain their relative order and original payload/discriminator/Kafka metadata in the per-system continuation.
3. A continuation stops on its first failure, never advances later events for that sequence, and carries only the unresolved suffix forward.
4. Missing identity on a failed processable event defers the remainder of its partition group; it does not guess identity or continue that partition remainder.
5. Each event receives no more than three processing attempts in the designed failure path; unattempted suffix entries do not consume attempts. Continuation jobs are scheduled with a fixed 30-second backoff.
6. After the third failed attempt, GoodJob receives an unhandled failure while the unresolved sequence remains in the job arguments; existing GoodJob policy preserves the record for the accepted 14-day window.
7. A failed continuation enqueue cannot be mistaken for success or silently lose its unresolved entries. The exact mechanism must be covered by a focused test.
8. Batch/continuation coordination observes processing errors rather than letting child ActiveJob retry handlers enqueue hidden independent retries. Standalone import/delete retry behavior remains intact.
9. Tests demonstrate at-least-once replay is possible and no cross-batch FIFO or policy/report side-effect ordering is claimed.
10. No schema, dependency, deployment, CI, API, or unrelated files change.

### Required validation

- `bundle check` before test execution.
- Focused RSpec for the batch job, new continuation job, any changed import/delete job path, and directly affected existing specs.
- RuboCop on every changed Ruby file.
- `bundle exec brakeman` and repository CI validation (`bundle exec rake spec:validate`) if the locked dependencies are available.
- Broader RSpec suite where local dependencies/services permit.
- `git diff --check`, final status/diff scope review, and confirmation schema/dependency/deployment/generated files are untouched.
- Documentation structural review: no placeholders, conflicting retry statements, unstated FIFO guarantees, or changes to the prior feature's accepted behavior.

Current validation limitation from intake: `bundle check` fails because the locked `yabeda-activejob` git checkout is absent and multiple locally installed gems have missing extensions. No dependency installation has been attempted or authorized. `bundle exec rake spec:validate` therefore also cannot start. Recheck during implementation validation; do not install dependencies without approval.

### External actions and commits

No external action is authorized. No commit is authorized by this contract. If a later stage proposes a commit or any shared/external action, present the exact diff, target, command, and consequences and obtain separate explicit consent immediately before execution.

### Approval status

`approved for implementation by user on 2026-10-29; execution method: subagent-driven`. It does not authorize a commit or external action.
