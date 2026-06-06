# Koban Agent Architecture

This document describes the internal engine that turns filesystem change into menu-bar
signal. It complements the [README](../README.md) (what Koban does) and
[CLAUDE.md](../CLAUDE.md) (the engineering charter). If the two ever disagree with the code,
the tests in `Koban AgentTests/` are the source of truth.

## The one pipeline

Every monitored surface follows the same path. FSEvents only says *when* something under a
watched path changed; it gives no process attribution and no detail. So the signal is
recovered by re-reading each tool's own on-disk metadata after a trigger:

```
FSEvents trigger -> debounce -> collector.snapshot() -> diff vs stored -> heuristics -> persist -> publish to UI
```

Pure logic (diffing, rule evaluation) takes inputs and returns outputs. IO (collectors,
persistence, watchers) lives at the edges. The `MonitoringEngine` actor orchestrates the two.

## Why user-level only

This is a deliberate, defended choice, not a limitation we are working around:

- **No EndpointSecurity.** The ES entitlement is granted only per-Team-ID by Apple, and a
  System Extension needs user/MDM approval. Both are fatal for an open-source tool anyone must
  be able to build and run. ES clients also sit in the kernel critical path and can hang or
  panic a fleet.
- **FSEvents is passive and best-effort.** The worst case is a missed event, never a wedged
  machine, which fits "visibility, not blocking."
- **No TCC / Full Disk Access prompt.** Every path Koban reads is user-readable configuration
  and package metadata. If a feature would require a TCC prompt, it is out of scope.
- **Constrained capability is a trust feature.** Koban *cannot* read keystrokes or inspect
  every process. That bound is part of the pitch, and the code is read by strangers evaluating
  us.

The cost we accept: no real-time latency, no process attribution, possible missed fast churn.
These are mitigated by debounced rescans, metadata provenance, and safety-net polling, and
surfaced honestly in surface health. ES may return later as an optional enterprise add-on
behind the entitlement; it never enters the open-source core. Because the pipeline sits above
the event source, swapping the source stays a localized change.

## Operational limits

| Limit | Why | Mitigation |
| --- | --- | --- |
| Best-effort event delivery | FSEvents may coalesce or drop under load | Drops surface as a watch degradation reason; safety-net polling rescans on an interval |
| No process attribution | FSEvents reports paths, not processes | Provenance is read from each tool's metadata instead |
| Possible missed fast churn | Debounce collapses bursts | The next scan still captures the final state; the diff is against stored state, not per-event |
| First scan is a silent baseline | Existing software should not flood the feed as "added" | Baseline is recorded without events; only later changes raise events |

## Lifecycle and the generation gate

`MonitoringEngine` is an actor: the one place mutable monitoring state lives. Everything it
calls is either pure or a value-typed repository.

The hardest correctness problem is the asynchronous callback that outlives a `stop()`: an
FSEvents signal, a debounced rescan, a poll tick, or an in-flight publish that resolves after
monitoring has been torn down (and possibly restarted). `MonitoringLifecycleGate` solves this
with a **generation**: `start()` mints a fresh UUID and records it as active; `stop()` clears
it. Every callback captures the generation it was scheduled under and guards on
`lifecycle.isActive(generation)` before doing work. A callback from a dead generation is
dropped. This is what the lifecycle soak gate
(`MonitoringEngineSoakTests`) exercises: repeated start/stop, a callback after stop, and
stop-followed-by-immediate-start (which is also how macOS sleep/wake appears to the engine).

### Startup primer

`MonitoringStartupCoordinator.prime` establishes or catches up each surface before the UI goes
live. It fans collectors out through a task group, but routes each through the
`SurfaceScanScheduler` (via `scheduleAndWait`) so priming shares the same coalescing and
cancellation as steady-state scans. `MonitoringPrimer` decides per surface: establish a silent
baseline if none exists, otherwise run the normal pipeline to catch up changes made while the
agent was not running.

### Poller

`MonitoringPoller` is the safety net for missed FSEvents. It sleeps for the configured
interval, then asks the engine to rescan every surface. It is a single cancellable task;
`stop()` cancels it, and the rescan it triggers is generation-gated like any other callback.

### Watch setup and the signal dispatcher

`MonitoringWatchSetup` compiles a `WatchPlan` (canonicalised, de-duplicated paths with ancestor
pruning) and starts one coordinated FSEvents stream through `WatchCoordinator`. Raw events
become a `WatchSignal` (affected surfaces plus an optional degradation reason) and are handed
to `WatchSignalDispatcher`.

The dispatcher exists to keep watcher bursts bounded. It runs **at most one drain task**;
while that task is delivering a signal, further events merge into a single pending signal
(`WatchSignal.merged`, which unions affected surfaces and keeps the strongest degradation
reason). A lock and a per-drain UUID guard against a stale drain clearing newer pending work.
The watcher burst gate (`WatchSignalDispatcherStressTests`) proves: handler concurrency stays
at one regardless of burst size, coalescing never drops a surface, and dropped/wrapped/
root-changed reasons survive merging.

### Scan scheduler

`SurfaceScanScheduler` coalesces per surface. A scan already running for a surface causes the
new trigger to be recorded as a single pending operation (older pending work is discarded, and
a coalesced-trigger count is kept for the UI). Different surfaces run concurrently. A per-scan
UUID ensures a cancelled scan's completion cannot tear down a newer running scan. The scan
burst gate (`SurfaceScanSchedulerStressTests`) proves peak concurrency is bounded by the
surface count, same-surface bursts collapse to one pending scan, and a cancellation storm never
clears a newer scan.

### Publish scheduler and the read-model publisher

`PublishScheduler` coalesces UI publishes the same way: one running publish, one pending bit,
a per-publish UUID guarding stale completion. The expensive part of a publish is the read-model
snapshot, so coalescing directly bounds read load under contention.

`MonitoringPublisher` reads a `PublishedStateSnapshot` from `ReadModelStore`, builds one
`SurfaceSummary` per collector via `SurfaceSummaryFactory`, and pushes events, findings, and
summaries to `AppState` (the `@MainActor`, `@Observable` source of UI truth). If the read fails,
it records the error and **leaves the last good state untouched** rather than blanking the UI.
The publish contention gate (`PublishContentionStressTests`) proves the storm-to-bounded-reads
behaviour, the stale-completion guard, and last-good-state preservation under repeated failure.

## Health model

Surface health has two independent axes that must not erase each other:

- **Scan health** (`ScanHealthRecorder`): success, failure, staleness, and per-scan telemetry
  (durations, counts).
- **Watch health** (`WatchHealthRecorder`): FSEvents degradation (dropped events, wrapped IDs,
  root changed) and watch-path counts.

A successful scan must not erase the last watch issue, and vice versa. They are stored
separately on `SurfaceHealth` and combined only for display by `SurfaceFreshnessPolicy`.

## Persistence

`AppDatabase` owns the GRDB connection (a `DatabasePool` in WAL mode, `synchronous = NORMAL`, a
bounded busy timeout and reader count). The schema is created by a single migration; there is
no migration/backfill compatibility code because Koban has no users yet (per the charter).

The store is a **materialised view of on-disk state, not the source of truth**: inventory is
re-derived by scanning. That is why `openRecoveringFromCorruption` discards a corrupt database
file and recreates it rather than wedging the agent, and only for corruption-class failures
(`SQLITE_CORRUPT`, `SQLITE_NOTADB`) so a permissions or disk error is surfaced instead of
masked by a destructive retry. Writes use GRDB transactions, so a failed write rolls back fully
with no partial commit. Shutdown truncates the WAL via `checkpointForShutdown`. These are
covered by `AppDatabaseTests` (WAL/settings/checkpoint/indexes) and `AppDatabaseRecoveryTests`
(invalid file, recreation, valid-DB preservation, non-corruption rethrow, transaction
rollback).

## The rules engine

Koban is a small rule engine, not a fixed program. Heuristics, intervals, paths, and tap/token
lists are declared in YAML (`~/.config/koban/koban.yaml`, parsed with Yams); the built-in
behaviour is the default ruleset, also shipped as `koban.default.yaml`. Absent or invalid user
config falls back to the typed `DefaultConfiguration` section by section, so a partial file is
always valid.

The rule vocabulary is **closed and bounded** on purpose, to stay an engine without becoming a
Turing-complete DSL:

- `match` is one of `always`, `fieldContainsAny`, `fieldNotInList`, `fieldHasURLScheme`,
  `flagEquals`.
- Fields are the closed `RuleField` set (`kind`, `name`, `version`, `origin`, `detail`, `path`,
  `packageManager`, `registry`, `sourceURL`, `command`, `dependencyScope`, `fileHash`).
- Flags are the closed `RuleFlag` set (e.g. `installedOnRequest`, `usesEphemeralRunner`,
  `usesRemote`, `usesDynamicAuthHelper`).

Collectors stay in Swift: reading a package manager's on-disk format is inherently code, not
config. The `Constants/` values are the defaults the YAML overrides; literals live only there.

## Where things live

```
App/           @main, AppDelegate, AppState (UI truth)
Model/         value types: surfaces, inventory, events, findings, severity, health
Watching/      FSEvents wrapper, debounce, watch plan, signal dispatcher
Collectors/    per-surface snapshot() providers (IO at the edge)
Diffing/       pure old -> new snapshot differ
Heuristics/    rule fields/flags, rules, engine (pure)
Persistence/   GRDB database, repositories, read model, retention
Engine/        MonitoringEngine actor and its collaborators (this document)
Constants/     every path, token, threshold - the only home for literals
UI/            SwiftUI menu-bar and extended-window views
Configuration/ YAML config model, defaults, loader, seeder
```
