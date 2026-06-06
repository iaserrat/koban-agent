# Releasing Koban Agent

Koban Agent ships updates with [Sparkle](https://sparkle-project.org). Updates are **full builds
only, never deltas**. Each release is a signed, notarized `.dmg` published as an asset on a single
rolling GitHub release (tag `updates`), alongside the cumulative `appcast.xml` that Sparkle reads.

```
SUFeedURL = https://github.com/iaserrat/koban-agent/releases/download/updates/appcast.xml
```

That URL is baked into every shipped binary (`Config/Info.plist`), so the `updates` release and its
tag must never be deleted or renamed.

## How updates reach users

1. The app embeds `SUFeedURL` and `SUPublicEDKey` (the EdDSA public key) in `Config/Info.plist`.
2. Sparkle checks the appcast on its own schedule, and on demand via the menu-bar **Check for
   Updates** row.
3. For each candidate it verifies the download's EdDSA signature against `SUPublicEDKey` before
   installing. A build signed with the wrong key is refused.

## One-time setup (maintainers)

These secrets live in your keychain and are never committed.

1. **Sparkle signing key.** Generate once with Sparkle's `generate_keys` tool (found under
   `~/Library/Developer/Xcode/DerivedData/*/SourcePackages/artifacts/sparkle/Sparkle/bin/`). The
   private key is stored in your login keychain; the public key it prints must equal
   `SUPublicEDKey` in `Config/Info.plist`. Verify any time with `generate_keys -p`.
2. **Notarization profile.** Store an App Store Connect app-specific password as a keychain
   profile named `notarytool`:
   ```sh
   xcrun notarytool store-credentials notarytool \
     --apple-id <your-apple-id> --team-id <TEAMID> --password <app-specific-password>
   ```
3. **Developer ID identity.** A "Developer ID Application" certificate in your keychain.
4. **Signing team.** Set `KOBAN_DEVELOPMENT_TEAM` (env or `Config/Signing.local.xcconfig`).
5. **GitHub CLI.** `gh auth login` with write access to `iaserrat/koban-agent`.

## Cutting a release

```sh
make release VERSION=1.1.0
```

`scripts/release.sh` runs the whole pipeline:

1. Stamps `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` into `Config/Version.xcconfig`, the single
   source of truth for the version (the app generates its `Info.plist` from those build settings).
   The build number is derived monotonically from the version.
2. Archives Release and exports a Developer ID signed `.app`.
3. Packages it into `Koban-Agent-<version>.dmg`.
4. Notarizes with Apple and staples the ticket.
5. Downloads the previously released DMGs + appcast, then regenerates the cumulative `appcast.xml`
   with `generate_appcast` (which signs the new build with the keychain key). Deltas are disabled
   (`--maximum-deltas 0`).
6. Uploads the new DMG and the regenerated appcast to the `updates` GitHub release.
7. Commits the `Config/Version.xcconfig` bump (only that file) and creates the `v<version>` tag.

Pushing stays manual, so finish with `git push && git push origin v<version>`. The released DMG is
downloadable at
`https://github.com/iaserrat/koban-agent/releases/download/updates/Koban-Agent-<version>.dmg`.

## Notes

- `sparkle:minimumSystemVersion` is taken automatically from the app's `LSMinimumSystemVersion`
  (the deployment target), so bumping the minimum macOS is a project-setting change, not a script
  change.
- The build number encodes the version as `major*100 + minor*10 + patch` (so `1.2.3` -> build
  `123`), which stays monotonic as long as minor and patch each stay below 10. The script refuses a
  version that violates this.
