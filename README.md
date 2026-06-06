# Koban Agent

Koban Agent is the open-source macOS sensor for Koban. It inventories software and
developer-tool configuration from disk, records what changed over time, and raises advisory
findings when those changes match a local YAML ruleset.

Koban reports. It does not block installs, quarantine files, run remote commands, intercept
network traffic, or sit in the kernel path. The agent is deliberately user-level: FSEvents,
debounced rescans, package-manager metadata, local heuristics, and a native menu-bar UI.

The commercial Koban Fleet control plane is optional. The agent can run locally without Fleet,
or sync to any backend that implements the open Koban Sensor Protocol v1.

## Current State

- macOS menu-bar app, dark mode only, no Dock icon.
- Open source under Apache-2.0.
- Sync is disabled by default, so the agent is useful as a local sensor.
- Fleet enrollment and sync are implemented through the JSON sensor protocol.
- Signed, notarized releases auto-update in place via Sparkle; see [RELEASING.md](RELEASING.md).
  The Homebrew tap is not assumed by this repository yet.
- The current source build targets macOS 26.5 and Xcode 26 with Swift 6.

## What Koban Watches

| Surface | Inventory |
| --- | --- |
| Homebrew | Formulae, casks, tap provenance, requested-vs-dependency receipt state |
| Claude | MCP servers, settings, permission lists, agents, commands, hooks, skills, plugins, instructions |
| Codex | TOML profiles, MCP servers, hooks, rules, skills |
| Pi | Shared and Pi-owned MCP files, imports, settings, package metadata |
| Cursor | Global and project MCP files, `.cursor/rules`, `AGENTS.md`, `.cursorrules` |
| OpenCode | JSON/JSONC config, MCP, agents, commands, plugins, instructions |
| JavaScript | npm, pnpm, Yarn, and Bun lockfiles |
| Python | uv, pyproject, pylock, requirements, and constraints metadata |

## How It Works

Every surface follows the same pipeline:

```text
FSEvents trigger -> debounce -> snapshot -> diff vs stored -> rules -> persist -> UI
```

FSEvents only tells Koban that something changed under a watched path. It does not provide
process attribution or command history. Koban gets useful signal by rereading public,
user-readable metadata such as Homebrew receipts, agent config files, and package lockfiles,
then comparing the new snapshot to the previous stored state.

Koban can answer questions such as:

- What packages and agent configuration items are present?
- Which Homebrew tap or receipt did an item come from?
- Was a Homebrew item explicitly installed or pulled in as a dependency?
- Which MCP servers, hooks, skills, rules, commands, and plugins changed?
- Does a config item use a remote transport, ephemeral runner, or suspicious shell pattern?

Koban does not attribute a change to a process, inspect runtime execution, read prompts or
keystrokes, crawl all of `$HOME` by default, or guarantee real-time detection. The first scan
of each surface is a silent baseline, so existing software does not generate "added" events.

Local state is stored at:

```text
~/Library/Application Support/Koban Agent/koban.sqlite
```

## Build From Source

Requirements for the current checkout:

- macOS 26.5 or later
- Xcode 26 or later
- SwiftLint and SwiftFormat for `make lint` / `make verify`

Build:

```sh
xcodebuild -project "Koban Agent.xcodeproj" -scheme "Koban Agent" -destination 'platform=macOS,arch=arm64' build
```

Or use the Makefile:

```sh
make build
make test
make verify
```

The app runs as an `LSUIElement` menu-bar agent. Quit from the popover.

## Local Code Signing

The checked-in Xcode project does not contain a personal Apple Team ID. Signing reads
`KOBAN_DEVELOPMENT_TEAM` from [Config/Signing.xcconfig](Config/Signing.xcconfig), which
optionally includes a git-ignored local override.

Create your local override when you want Xcode to remember your team:

```sh
printf 'KOBAN_DEVELOPMENT_TEAM = YOURTEAMID\n' > Config/Signing.local.xcconfig
```

`Config/Signing.local.xcconfig` is ignored by Git. Do not commit provisioning profiles,
certificates, archives, or Xcode `xcuserdata`.

For CI or release builds, pass signing values through the environment or `xcodebuild`
arguments, and keep notarization credentials in secret storage.

## Configuration

On first launch, Koban writes:

```text
~/.config/koban/koban.yaml
```

It never overwrites an existing file. Omitted fields fall back to typed defaults from
[Koban Agent/Resources/koban.default.yaml](Koban%20Agent/Resources/koban.default.yaml).

Rules use a closed vocabulary. `match` is one of `always`, `fieldContainsAny`,
`fieldNotInList`, `fieldHasURLScheme`, or `flagEquals`. Rules inspect normalized fields such
as `kind`, `name`, `version`, `origin`, `detail`, and `path`, plus the
`installedOnRequest` flag.

Example:

```yaml
rules:
  - id: agent.config.suspicious-command
    surface: claudeConfig
    triggers: [added, modified]
    match: fieldContainsAny
    field: detail
    values: [curl, wget, "| sh", eval, base64]
    severity: suspicious
    title: Suspicious command
    rationale: This agent configuration fetches and executes remote code.
```

Project-scoped surfaces use bounded roots by default:

```yaml
watch:
  projectRoots:
    - ~/src
    - ~/Code
    - ~/Developer
    - ~/Projects
  maxDepth: 5
```

The opt-in home signal scan is disabled by default. When enabled, it is a targeted scan for
known signal file names with depth, file, directory, wall-clock, symlink, and protected-folder
budgets. It is not a general home-directory crawl.

## Sync And Backends

Sync is disabled by default:

```yaml
sync:
  enabled: false
  protocol: kobanSensorV1
  endpoint: null
  enrollmentToken: null
  sensorToken: null
```

When enrolled, the agent speaks Koban Sensor Protocol v1:

- `POST /api/sensor/v1/enroll`
- `POST /api/sensor/v1/config`
- `POST /api/sensor/v1/check-in`
- `POST /api/sensor/v1/sync`

Enrollment uses a short-lived token. Production sync uses a device client certificate stored
with identity material in the macOS Keychain. `sensorToken` is a development fallback for
self-hosted backends that have not enabled mTLS.

Fleet is Koban's commercial backend and control plane. It is not required to run the agent.
See the website docs for the protocol, authentication model, and compatible backend contract:

- [Documentation](https://kobanhq.com/docs)
- [Authentication](https://kobanhq.com/docs/authentication)
- [Sensor protocol](https://kobanhq.com/docs/protocol)
- [Compatible backends](https://kobanhq.com/docs/compatible-backends)
- [Fleet rules](https://kobanhq.com/docs/fleet-rules)

## Privacy And Limits

Collectors read configuration shape and provenance, not secret values. Token-bearing fields
such as environment variables, authorization headers, bearer tokens, and OAuth client secrets
are represented as references or presence signals instead of persisted values.

Koban does not:

- Block, quarantine, uninstall, or edit anything.
- Use EndpointSecurity or ship a System Extension.
- Require Full Disk Access, Accessibility, Contacts, Calendar, or similar TCC prompts.
- Attribute changes to a process or shell command.
- Inspect browser content, prompts, keystrokes, or private app databases.
- Make network requests from collectors.
- Let a backend run commands or request arbitrary filesystem reads.

## Development

```sh
make lint     # swiftlint --strict + swiftformat --lint
make test
make verify   # lint + build + test
```

Swift 6 complete strict concurrency is enabled. Warnings are errors. Public behaviour should
be covered by deterministic tests.

Read [AGENTS.md](AGENTS.md) before contributing. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
for engine internals and [docs/AUDIT.md](docs/AUDIT.md) for the readiness audit.

## Layout

```text
App/            entry point, app state, menu-bar shell
Model/          value types for inventory, events, findings, severity
Watching/       FSEvents wrapper, watch planning, debounce
Collectors/     per-surface snapshot providers
Diffing/        pure snapshot differ
Heuristics/     closed rule engine
Persistence/    GRDB store and repositories
Engine/         MonitoringEngine actor
Configuration/  YAML config model, defaults, loader
Constants/      paths, tokens, labels, thresholds
Sync/           enrollment, check-in, config fetch, upload
UI/             SwiftUI menu-bar and extended window views
```

## License

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
