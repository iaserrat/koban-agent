# Koban Agent - Engineering Charter

Koban is a macOS-only, EDR-*like* monitoring tray app that gives IT and secops teams
visibility into what employees install (Homebrew, Claude config, npm, …). This file is
the contract every change is held to. It is short on purpose. Read it before you write code.

## Mission & wedge

- We provide **visibility, indicators of compromise, and inventory/provenance**. We do
  **not block** anything. Blocking is an explicit non-goal.
- We do **not** use the EndpointSecurity entitlement and we do **not** ship a System
  Extension. Our edge is staying user-level: **FSEvents + user-level heuristics**.
- We never trigger a TCC / Full Disk Access prompt. If a feature would require one, it is
  out of scope until we decide otherwise deliberately.
- Koban is open source, licensed under Apache-2.0 (see LICENSE). Assume every line is read
  by strangers evaluating us. The code is part of the pitch.

## How the agent works (the one mental model)

FSEvents only tells us **when** something changed - it gives no process attribution and no
detail. So every surface follows the same pipeline:

```
FSEvents trigger → debounce → collector.snapshot() → diff vs stored → heuristics → persist → publish to UI
```

Provenance and IOC signal come from reading each package manager's own on-disk metadata
(e.g. Homebrew install receipts, `~/.claude.json`) - never from kernel events.

### Why FSEvents and not EndpointSecurity (a deliberate, defended choice)

The ES entitlement is granted only per-Team-ID by Apple and a System Extension needs
user/MDM approval - both fatal for an *open-source* tool anyone must be able to build and
run. ES clients also sit in the kernel critical path and can hang or panic a fleet; FSEvents
is passive and best-effort, so the worst case is a missed event, never a wedged machine -
which fits "visibility, not blocking". Constrained capability (we *cannot* read keystrokes or
every process) is a trust feature, not a limitation. The cost we accept: no real-time latency,
no process attribution, possible missed fast churn - mitigated by debounced rescans, metadata
provenance, and safety-net polling. ES may return *later* as an optional enterprise add-on
behind the entitlement; it never enters the open-source core. The pipeline sits above the event
source, so that stays a localized change.

## Configuration - Koban is an engine, not a fixed program

The agent is a small **rule engine**: it watches, snapshots, diffs, and evaluates a *ruleset*
that is data, not code. Heuristics, watched intervals, paths, and tap/token lists are all
declared in YAML (`~/.config/koban/koban.yaml`, parsed with Yams); the built-in behaviour is
just the default ruleset, also shipped as a documented `koban.default.yaml`. Absent or invalid
user config falls back to the typed defaults.

The rule vocabulary is **closed and bounded** - `match` is one of a fixed set
(`always`, `fieldContainsAny`, `fieldNotInList`, `fieldHasURLScheme`, `flagEquals`) over a fixed
set of fields. This is the line we hold: rich enough to call it an engine, not a Turing-complete
DSL (which would be the "clever abstraction" this charter forbids). Collectors stay in Swift -
reading a package manager's on-disk format is inherently code, not config. The `Constants/`
values are the *defaults* the YAML overrides; literals still live only there.

## Code principles

- **Simplest, most idiomatic Swift possible.** No clever abstractions. No hacks. No
  duplication. If a junior reader needs a comment to follow control flow, simplify the flow.
- **No compatibility work before users exist.** Unless explicitly stated otherwise, assume
  Koban has no users yet. Do not add database migrations, backfills, legacy shims, or
  backwards-compatible transition paths. Change the current model/schema/config directly and
  keep the codebase clean. Compatibility work starts only when we deliberately say users exist.
- **One type per file.** Prefer dozens or hundreds of small files over god-files. The file
  name is the type name.
- **No magic values - ever.** Every literal path, string token, threshold, and number lives
  as a named constant in `Constants/`. A bare `"npx"` or `5` in logic is a defect, not a style nit.
- **Value types by default.** Structs and enums first; reach for a `class`/`actor` only for
  identity or shared mutable state. Make illegal states unrepresentable.
- **Isolate side effects.** Pure logic (diffing, parsing, rule evaluation) takes inputs and
  returns outputs - no IO, no clock, no globals - so it is trivially testable. IO lives at
  the edges (collectors, persistence, watchers).
- **Match the surrounding code.** Naming, comment density, and idiom should be consistent
  across the codebase.
- **No leftovers.** Every edit cleans up after itself. When you change a file, check whether
  the change orphaned anything - a now-unused property, constant, import, parameter, type, or
  doc comment - and remove it in the same change. A removed call site means checking its
  callee is still needed. Dead code is a defect, not a follow-up.
- **No em dashes.** Never in comments, doc strings, UI copy, or rationale text. Use a hyphen,
  comma, colon, or rephrase. Enforced by the `no_em_dash` SwiftLint custom rule.
- **Public, documented API only - no reverse-engineering.** Every platform integration uses
  public, documented behaviour, verified against current Apple documentation. Never depend on
  private/undocumented API, internal class names, reflection into framework internals, or
  unverified heuristics about how a framework happens to behave today (a window's level, a
  view's hidden hierarchy). If the supported path is a known AppKit bridge (e.g. reaching an
  `NSWindow` via `NSViewRepresentable`), use it and say so in a comment. If no public API
  exists for what you want, prefer the documented behaviour that achieves the same end, and if
  there is none, surface the limitation rather than shipping a guess. A workaround that relies
  on implementation details is a hack, and hacks are not acceptable.
- **One component, many contexts - never duplicate UI.** A finding row, an activity row, a
  surface summary is defined exactly once. When the same information appears in both the
  menu-bar panel and the extended window, it is the *same view* rendered with a context value
  (e.g. a `DisplayContext` enum), not a copy-pasted variant. The context flag is what dictates
  the view's behavioural invariant - density, truncation, whether a row is tappable, what a tap
  does - and that mapping lives in one place. Two views drawing the same model is a defect.

## Concurrency

- Swift 6 language mode with **complete** strict concurrency. No opting out.
- Actors guard IO and engine boundaries (`MonitoringEngine`, the database). UI state is
  `@MainActor`. Cross-boundary types are `Sendable`.

## UX bar

- More premium than paid alternatives. Obsessive attention to detail, performance, and
  native macOS idioms.
- The app is a menu-bar agent (`LSUIElement`): no Dock icon, no app-switcher entry, no
  gratuitous windows or prompts. Quitting must always be one obvious click away.
- **Dark mode only.** Koban always renders in dark appearance, regardless of the system
  setting. This is forced once at the app level (`NSApp.appearance = .darkAqua`), never
  per-view, so there is one source of truth and no light-mode code paths to maintain. Design
  and review every surface against dark only.

## Quality policy - non-negotiable

- **Zero warnings, zero errors. Always.** Warnings are build failures
  (`SWIFT_TREAT_WARNINGS_AS_ERRORS`). A warning is never "fixed later".
- `swiftlint --strict` and `swiftformat --lint .` must both pass clean. `make lint` runs both.
- Lint rules are not silenced casually. A disabled rule carries an inline comment explaining
  why; blanket disables are not allowed.
- Every change ships with green build + lint + tests.

## Testing

- **Red-green TDD by default.** Unless explicitly stated otherwise, write a failing test
  first, watch it fail for the right reason, then write the minimum code to pass it. New
  behaviour starts with a test.
- **Test behaviour, not implementation.** Assert on observable outcomes through the public
  surface. A test must not restate the implementation, mirror its control flow, or break
  when an internal is refactored without a behaviour change.
- **Tests are the source of truth for what works.** A passing suite is the contract; if a
  behaviour matters, a test captures it, and the test is what we trust over the prose.
- Pure logic (differ, heuristic rules, collector parsers) is unit-tested against fixtures.
- Tests must be deterministic: no real filesystem assumptions, no network, no wall-clock
  dependence. Feed inputs in; assert outputs.

## Layout

```
App/          @main, app shell, AppState
Model/        value types: surfaces, inventory, events, findings, severity
Watching/     FSEvents wrapper + debounce
Collectors/   per-surface snapshot() providers (IO at the edge)
Diffing/      pure old→new snapshot differ
Heuristics/   IOC rules + engine (pure)
Persistence/  GRDB database, repositories
Engine/       MonitoringEngine actor orchestrating the pipeline
Constants/    every path, token, and threshold - the only home for literals
UI/           SwiftUI menu-bar views
```
