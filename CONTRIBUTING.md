# Contributing

Bug reports, ideas and pull requests are welcome.

## Development

Requires macOS 14+ and Xcode 16+ (Swift 6).

```sh
swift test                      # core tests
swift run AWSSwitch             # run without a bundle (no launch at login)
scripts/bundle.sh --install     # universal .app in ~/Applications
scripts/package.sh              # installer package in build/
```

## Pull requests

- Keep changes focused; one PR per change.
- Add or update tests in `Tests/AWSSwitchCoreTests` for anything in `AWSSwitchCore`.
- The PR title must be a [conventional commit](https://www.conventionalcommits.org/) (`feat: …`, `fix(ui): …`). PRs are squash-merged, and the title drives the changelog and version bump.
- Don't add dependencies, network access or telemetry. The [security model](README.md#security-model) is a feature.
- Use generic placeholder profile names and account IDs (`acme-production`, `111111111111`) in tests and examples, never real ones.

## Releases

[release-please](https://github.com/googleapis/release-please) keeps a release PR open. Merging it tags the version, and CI builds and attaches the `.pkg`.
