# Koban Agent - developer tasks.
# The quality gate is `make verify`: zero warnings, zero lint/format violations, green tests.

SCHEME := Koban Agent
PROJECT := Koban Agent.xcodeproj
DESTINATION := platform=macOS,arch=arm64

.PHONY: lint format format-check analyze build test verify release

## Run all linters in check mode (fails on any violation). Mirrors CI.
lint:
	swiftlint lint --strict
	swiftformat --lint .

## Auto-fix formatting in place.
format:
	swiftformat .

## Check formatting only (no writes).
format-check:
	swiftformat --lint .

## Run SwiftLint analyzer rules (needs a compiler log).
analyze:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -destination "$(DESTINATION)" \
		clean build > build.log 2>&1
	swiftlint analyze --strict --compiler-log-path build.log

## Build the app (warnings are errors).
build:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -destination "$(DESTINATION)" build

## Run the test suite.
test:
	xcodebuild -project "$(PROJECT)" -scheme "$(SCHEME)" -destination "$(DESTINATION)" test

## Full gate: lint + build + test.
verify: lint build test

## Cut a signed, notarized release and publish it to the Sparkle update feed.
## Usage: make release VERSION=1.1.0   (see RELEASING.md for one-time setup)
release:
	@test -n "$(VERSION)" || { echo "usage: make release VERSION=1.1.0"; exit 1; }
	./scripts/release.sh "$(VERSION)"
