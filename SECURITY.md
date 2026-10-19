# Security policy

## Reporting a vulnerability

Please report vulnerabilities privately through [GitHub's private vulnerability reporting](https://github.com/pict0/aws-switch/security/advisories/new), not in a public issue.

Include what you found, how to reproduce it, and the version (`AWS Switch` → About). You should get a reply within a week.

Never include real credentials, SSO cache files, account IDs or the contents of `~/.aws/config` or `~/.kube/config` in a report. Redact them.

## Supported versions

Only the latest release gets security fixes.

## Scope

AWS Switch reads `~/.aws/config`, the SSO cache (`startUrl` and `expiresAt` only) and `kubectl config view` output, and writes `~/.aws/current-context`. Issues that let any of these inputs inject commands into a shell, expose credentials, or modify files outside that set are in scope. See the security model in the [README](README.md#security-model).
