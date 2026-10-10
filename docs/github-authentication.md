# GitHub CLI authentication

Policy date: 2026-10-09. Scope: future macOS and Omarchy bootstrap.
Existing devices keep their credentials, SSH keys, agents, and repository remotes.
Michael's existing web passkey needs no change.

## Future-machine setup

Follow the [new-device walkthrough](../README.md#new-device-walkthrough).
The standalone Mac bootstrap installs and checks developer tools before cloning dotfiles through HTTPS.
Omarchy supplies Git; clone through HTTPS and run its platform bootstrap.
Both bootstraps call `bash scripts/github-auth.sh setup` after installing `gh` and linking configuration.
The helper performs these steps:

1. Check active GitHub authentication. Inspect the JSON state, not only the command's exit code.
2. Reuse valid authentication. Request browser authorization for missing or rejected credentials in an interactive terminal.
3. Verify that the API identifies `michaeltheitking`. Set `GITHUB_USERNAME` only when another account is intentional.
4. Require the native credential store. Stop on plaintext fallback or environment-supplied bootstrap credentials.
5. Set `gh`'s Git protocol to HTTPS and configure its GitHub credential helper.
6. Confirm that Git does not rewrite the private URL, then test authenticated read access. Empty repositories remain valid.

The first browser authorization requires human interaction. Use the existing web passkey when GitHub requests sign-in.
The helper never logs out, revokes credentials, copies tokens, or enrolls SSH keys.
It does not rewrite other repositories or configure automatic pulls.
Remote-machine SSH access remains separate; enroll its device key only when needed.

Use the helper separately when needed:

```sh
bash scripts/github-auth.sh setup
bash scripts/github-auth.sh check
```

`setup` changes GitHub's CLI protocol and Git credential-helper configuration after account and storage checks.
`check` is read-only. Exit `0` means checks pass; `1` means failure; `2` means an advisory result.
No private repository produces an advisory check result. Bootstrap stops because authenticated Git access remains unverified.
Private Git reads prove read access only. They do not prove write permission for every repository.

## Credential storage

Use macOS Keychain or an available Linux Secret Service credential store.
The Linux service must be available and unlocked in the intended desktop session.
If `gh` falls back to `hosts.yml`, setup stops and reports the storage issue without displaying credentials.
Enable or unlock the native store, then run:

```sh
gh auth login --hostname github.com --git-protocol https --web
bash scripts/github-auth.sh setup
```

Do not log out first or copy `hosts.yml` between devices.
Keep working credentials until replacement authentication succeeds.
The vendor can leave its fallback credential locally; the helper does not delete it automatically.
Never use `gh auth token`, `--show-token`, or `--insecure-storage` in verification or captured output.

## Existing devices and scheduled jobs

`verify.sh` reads the configured `gh` Git protocol. HTTPS machines do not need GitHub SSH keys or trust files.
SSH-selected machines retain route, pinned trust, and SSH client-authentication checks.
Use `DOTFILES_GITHUB_TRANSPORT=ssh ./verify.sh` for an explicit optional SSH audit.
Setup still links optional pinned SSH trust for users who select SSH.
The default HTTPS bootstrap never contacts GitHub through SSH.

Verification reports legacy plaintext or environment credential storage as an advisory result.
It does not change credentials or attempt browser login.
Network or service errors do not trigger automatic reauthorization.
For private Git failures, check credential-helper configuration, repository permissions, and network access separately.
URL rewrites that change the transport or repository stop the check. The helper preserves the conflicting configuration.
An existing SSH checkout keeps its remote. Inspect `git remote -v` before deliberately changing that remote during repair.

Scheduled jobs need their own operating check under the actual account and environment.
Test API identity and a noninteractive private Git read before relying on a new scheduled job.
Desktop terminal success does not prove access after logout, reboot, or credential-store locking.
Do not move existing launchd credentials or enable new jobs during bootstrap.

## Verification evidence

On 2026-10-09, the Mac mini's API identity and noninteractive private HTTPS Git read pass.
Its 13 inspected GitHub repository origins use HTTPS. Its existing file-backed CLI credential remains unchanged.
The updated health check reports no failures and one storage warning.
Isolated tests cover first login, reuse, wrong accounts, rejected credentials, network failure, Git failure, and storage fallback.
They also cover empty repositories, conflicting URL rewrites, and legacy SSH verification failures.
Native Omarchy credential-store setup and full bootstrap remain unverified.

## References

- [Accepted transport decision](decisions/0003-route-github-ssh-over-port-443.md)
- [GitHub CLI login and storage fallback](https://cli.github.com/manual/gh_auth_login)
- [GitHub CLI status JSON exit semantics](https://cli.github.com/manual/gh_auth_status)
- [Git credential-helper setup](https://cli.github.com/manual/gh_auth_setup-git)
- [macOS credential-store implementation](https://github.com/cli/cli/blob/trunk/docs/macos-keyring.md)
