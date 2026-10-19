# AWS Switch

A macOS menu bar app that switches the AWS profile for **every terminal at once**.

## How it works

```
 menu bar app ─┐
               ├─ writes ─▶ ~/.aws/current-context ◀─ read at each prompt ─ zsh precmd hook ─▶ export AWS_PROFILE
 awsswitch CLI ┘
```

- Each terminal picks up the new profile at its next prompt. A command that's already running, such as `terraform apply`, keeps its environment.
- `awsswitch --pin <profile>` opts a single terminal out. `awsswitch --unpin` rejoins the global context.
- Profiles are marked by environment tier, which is inferred from name tokens: a red warning triangle for production, a half-filled circle for pre-production (`staging`, `uat`, `pre-production`, `dev`, `test`, `sandbox`), an empty circle for shared. Only production is coloured, in the menu and as a red menu bar pill.
- Switching to a production profile asks for confirmation, in both the app and the CLI.
- Every switch is logged to `~/Library/Logs/AWSSwitch/switch.log`.
- **kubectl follows along.** When the AWS profile changes (from the menu or `awsswitch`, while the app is running), kubectl switches to the EKS context whose cluster ARN is in that profile's account. This only happens when there's exactly one such context; otherwise kubectl is left alone. The kubectl context is global in `~/.kube/config`, so every terminal sees the switch immediately. Contexts can also be picked directly from the Kubernetes submenu, and production ones ask for confirmation. Auto-switching can be turned off in the menu.

## Security model

- **No network access and no credentials.** The app reads `~/.aws/config` and writes one file. SSO login is handed to `aws sso login`.
- The SSO cache is read for `startUrl` and `expiresAt` only. Token fields are never decoded.
- Profile names are allow-listed (`[A-Za-z0-9._-]`) by the app, the CLI and the hook, so the context file can't inject anything into a shell.
- `~/.aws/config` and the `[default]` profile are never modified.
- kubectl is driven only via `kubectl config view -o json` (credentials are redacted) and `kubectl config use-context`. The app never parses or writes kubeconfig itself.
- No dependencies, no auto-update, no telemetry.

AWS Switch is not affiliated with or endorsed by Amazon Web Services or The Linux Foundation. AWS and Kubernetes are trademarks of their respective owners.

## Install

```sh
swift test                      # run the core tests
scripts/bundle.sh --install     # build, sign ad hoc, copy to ~/Applications
open ~/Applications/AWS\ Switch.app
```

### Installer package

```sh
scripts/package.sh              # → build/AWSSwitch-<version>.pkg (unsigned)
```

Installs `/Applications/AWS Switch.app` and `/usr/local/share/aws-switch/aws-switch.zsh`, then appends
`source /usr/local/share/aws-switch/aws-switch.zsh` to the logged-in user's `~/.zshrc` (backing it up to
`~/.zshrc.bak-aws-switch-<timestamp>` first). It skips this if `.zshrc` already sources an
`aws-switch.zsh`. Open a new terminal afterwards. The package is unsigned: on another Mac, right-click it
and choose Open, or allow it in System Settings → Privacy & Security.

### Shell integration

Replace the old `awsswitch` function in `~/.zshrc` with:

```zsh
source ~/aws-switch/shell/aws-switch.zsh
```

## Development

Open `Package.swift` in Xcode, or use `swift build` / `swift run AWSSwitch`. Launch at login only works from the `.app` bundle.

## Licence

MIT. See [LICENSE](LICENSE).
