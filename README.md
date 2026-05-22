# ClaudeStatus

A tiny macOS menubar app that watches the Claude status page and colours its pixel Claude Code-style icon by severity.

## Behaviour

- Polls `https://status.claude.ai/api/v2/summary.json` once per minute.
- Shows a monochrome template icon when Claude is operational.
- Shows a yellow icon when the service is degraded, under maintenance, or unreachable.
- Shows a red icon when Statuspage reports a major or critical outage.
- Uses the tooltip for the current headline and detail.
- The dropdown shows the latest check time, affected components, active incidents, a manual refresh action, an optional status-text toggle, and a link to `https://status.claude.ai`.

`status.claude.ai` currently redirects to Anthropic's Statuspage-hosted `status.claude.com` domain. The app intentionally uses the `status.claude.ai` URL from the product-facing spec and lets URLSession follow the redirect.

## Requirements

- macOS 13 or newer
- Xcode command line tools
- Swift 6

## Build And Test

```bash
swift test
./build.sh
```

The build script creates:

```text
build/ClaudeStatus.app
```

To install and launch it locally:

```bash
./build.sh --install
```

The app is unsigned apart from an ad-hoc local signature when `codesign` is available.

## Development Notes

- AppKit UI lives in `Sources/ClaudeStatusApp`.
- Statuspage decoding and severity mapping live in `Sources/ClaudeStatusCore` so they can be tested without launching a menubar app.
- The app has no API key and stores only the local `Show Status Text` preference.
