# Koban Agent SOTA-Readiness Audit

This is a standing audit of the readiness areas in the project's pending checklist. Each item
records what was checked and how it is verified. "Verified by tests" means a deterministic test
in `Koban AgentTests/` asserts it; "verified by inspection" means it was confirmed by reading
the code and no automated assertion is practical (or it is enforced by lint/build). Items that
genuinely require a human at a machine (visual QA, notarization on real hardware) are called
out as **manual** so they are never silently assumed done.

## Security and privacy

### No TCC / Full Disk Access / EndpointSecurity / System Extension

- **Verified by inspection.** Collectors read only user-readable configuration and package
  metadata under the user's home, configured project roots, and Homebrew prefixes. There is no
  `EndpointSecurity` import, no System Extension target, and no entitlement requesting Full Disk
  Access, Accessibility, Contacts, or Calendar. The app is `LSUIElement`.
- The home signal scan is opt-in and bounded (depth, file, directory, wall-clock, symlink, and
  protected-folder budgets); it is not a general `$HOME` crawl.

### No private or undocumented API

- **Verified by inspection.** Platform integration uses public, documented API: FSEvents for
  watching, GRDB/SQLite for storage, AppKit/SwiftUI for the menu-bar agent. Dark appearance is
  forced once at the app level (`NSApp.appearance = .darkAqua`).

### Secret handling

- **Verified by inspection.** The strongest redaction is not reading the secret at all:
  `MCPServerSpec` decodes `command`, `args`, `type`, `url`, and `headersHelper` only. The `env`
  dictionary, where stdio MCP servers carry API keys and tokens, is never decoded, so it cannot
  be persisted or shown.
- A dynamic auth helper is represented as a presence token
  (`HeuristicConstants.dynamicAuthHelperToken`), not its configured value.
- Collectors capture configuration *shape* and provenance, not secret values. Findings preserve
  evidence (path, matched field, matched value) without copying token-bearing payloads.
- **Residual risk to keep in view:** a remote MCP `url` is captured verbatim as the item detail.
  Tokens normally live in headers (handled above), but a URL that embeds a query-string token
  would be persisted. This is acceptable for V1 and noted here so it is a deliberate, tracked
  decision rather than an oversight.

### Provenance

- **Verified by inspection.** Every inventory item carries `Provenance` (origin, optional
  `installedOnRequest`, optional detail) so its source is explainable: Homebrew tap/receipt
  state, agent config origin labels, package manager and registry for lockfile entries.
- User-visible copy states visibility, not blocking (see README "Koban reports; it does not
  block").

## Persistence readiness

- **Verified by tests.** WAL journal mode, `synchronous = NORMAL`, bounded reader count, and
  shutdown WAL truncation (`AppDatabaseTests`). Hot-path indexes and the FTS search projection
  exist and are maintained by triggers (`AppDatabaseTests`).
- **Verified by tests.** Corruption recovery: an invalid database file throws on plain `open`,
  `openRecoveringFromCorruption` recreates a clean schema from a corrupt file, a valid database
  is never recreated, non-corruption failures rethrow rather than triggering a destructive
  recreate, and a failed write transaction rolls back completely (`AppDatabaseRecoveryTests`).
- **Verified by tests.** A failed read model query records the error and preserves the last good
  UI state (`MonitoringPublisherTests`, `PublishContentionStressTests`).
- **Verified by inspection.** No migration/backfill/compatibility code exists; the schema is a
  single migration, consistent with "no users yet."

## Concurrency and architecture

- **Verified by build.** Swift 6 complete strict concurrency, warnings-as-errors. Cross-actor
  values are `Sendable`.
- **Verified by inspection.** The three remaining `@unchecked Sendable` types each carry a
  justification comment describing their internal synchronization: `WatchSignalDispatcher` (all
  mutable state under an `NSLock`), `WatchCoordinator` (mutation confined to the owning engine
  actor), and `FSEventsWatcher` (stream mutated only under its lock).
- **Verified by tests.** Stale-completion guards across the dispatcher, scan scheduler, publish
  scheduler, and lifecycle gate (the stress and soak suites).
- **Verified by inspection + lint.** One type per file (the rule-flag, time-constant, and
  rule-id types were split into their own files); `Constants/` holds the literals.

## Collector readiness

- **Verified by tests.** Each collector has unit coverage for profiles, MCP servers, hooks,
  rules, skills, oversized and malformed files, and cancellation (see the per-collector test
  files). Package collectors cover npm/pnpm/yarn/bun and shrinkwrap precedence, and Python
  covers pyproject/requirements/includes/constraints with depth, file, and wall-clock budgets.
- **Verified by tests.** End-to-end behaviour over a large, adverse tree: many projects, deep
  nesting beyond `maxDepth`, excluded directories, oversized and malformed metadata, and an
  unreadable directory, all staying within budget and turning adverse input into recorded
  issues (`LargeHomeFixtureTests`).

## Watcher readiness

- **Verified by tests.** Watch-plan canonicalization/de-duplication and signal coalescing
  (dropped/wrapped/root-changed reasons survive). Watch health is separate from scan health and
  watch-path counts are recorded per surface.
- **Verified by tests.** Safety-net polling stops cleanly and cannot publish after lifecycle
  stop (the soak suite's generation-gate assertions).

## UX readiness

- **Verified by inspection.** The menu-bar agent is `LSUIElement` (no Dock icon, no app-switcher
  entry), dark appearance forced once at app level, and quit is one action in the popover. The
  charter's "one component, many contexts" rule (a `DisplayContext`-driven view rendered in both
  the panel and the extended window) is followed in `UI/`.
- **Manual.** Visual QA of every state (empty, healthy, scanning, queued, stale, degraded, watch
  degraded, read-model failure, large inventory, many findings), screenshot review at desktop
  and small-window sizes, long-text and dark-mode contrast review. These require running the app
  and a human eye; the data-model invariants behind them are covered by `WindowDataModelTests`
  and `ReadModelStoreInventorySearchTests`.

## Packaging and release readiness

- **Verified by inspection.** First run seeds `~/.config/koban/koban.yaml` without overwriting
  an existing file; invalid/partial config falls back to typed defaults section by section
  (`ConfigurationSeederTests`, `ConfigurationLoaderTests`, `ConfigurationDecodingTests`). State
  lives at `~/Library/Application Support/Koban Agent/koban.sqlite`. License is Apache-2.0 with a
  matching `NOTICE`.
- **Manual / decision pending.** App signing and hardened-runtime settings, the notarization
  path, `LSUIElement` behaviour in a packaged (not Xcode-run) build, the release artifact format,
  and the update story all require a signing identity and real distribution and are out of scope
  for the test gates. They are tracked as deliberate release-time decisions.
