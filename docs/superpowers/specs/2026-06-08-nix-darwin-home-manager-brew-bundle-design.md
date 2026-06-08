# Nix Darwin Home Manager Brew Bundle Rewrite Design

## Goal

Rewrite this macOS provisioning repository from Ansible to a modern stack composed of nix-darwin, Home Manager, and Homebrew Bundle while preserving separate `home` and `work` profiles.

## Current Behavior To Preserve

The current Ansible project provisions a local macOS machine with:

- A shared Homebrew tap, shared formulas, and shared casks.
- Extra Homebrew taps, formulas, and casks for the `home` profile.
- Extra Homebrew taps, formulas, and casks for the `work` profile.
- Role-specific `.zshrc` content for `home` and `work`.
- A `cleanup` command installed into `/usr/local/bin`.
- A large set of macOS `defaults`, `pmset`, and `systemsetup` settings.
- Work-only `biscuit` and `electro` helper tools.
- A completion notification after provisioning.

The rewrite drops Ansible entirely. It removes `ansible`, `ansible-galaxy`, Ansible inventory, roles, and playbooks from the project workflow.

## Selected Approach

Use separate tools for separate responsibilities:

- nix-darwin owns system-level macOS configuration and exposes two selectable profiles: `home` and `work`.
- Home Manager owns the user shell configuration and role-specific user environment.
- Homebrew Bundle owns Homebrew formulas, taps, and casks through explicit Brewfiles.
- Shell scripts orchestrate first-run bootstrap and repeatable apply commands.

Homebrew packages are intentionally kept in native Brewfile syntax instead of being embedded in nix-darwin `homebrew.*` options. This keeps the package/app inventory easy to scan, lets `brew bundle` remain the explicit package manager action, and avoids hiding Homebrew behavior inside system activation.

## Repository Structure

The rewritten project will use this structure:

```text
.
├── Brewfile.common
├── Brewfile.home
├── Brewfile.work
├── flake.nix
├── README.md
├── modules
│   ├── darwin
│   │   ├── common.nix
│   │   ├── home.nix
│   │   └── work.nix
│   └── home
│       ├── common.nix
│       ├── home.nix
│       └── work.nix
├── scripts
│   ├── apply.sh
│   └── bootstrap.sh
└── files
    └── cleanup
```

The obsolete Ansible files will be removed:

- `playbook.yml`
- `galaxy-roles.yml`
- `local`
- `run.sh`
- `files/.zshrc_home`
- `files/.zshrc_work`
- `files/macos-settings.sh`
- `files/paths`

## Profiles

The flake will export:

- `darwinConfigurations.home`
- `darwinConfigurations.work`

Both profiles target the current macOS user `andreausuelli` and Apple Silicon platform `aarch64-darwin`.

The `home` profile imports:

- Shared nix-darwin module.
- Home-only nix-darwin module.
- Shared Home Manager module.
- Home-only Home Manager module.

The `work` profile imports:

- Shared nix-darwin module.
- Work-only nix-darwin module.
- Shared Home Manager module.
- Work-only Home Manager module.

## Homebrew Bundle Design

`Brewfile.common` contains shared taps, formulas, and casks from the current playbook.

`Brewfile.home` contains:

- `siderolabs/tap`
- `siderolabs/tap/talosctl`
- Home-only casks such as `balenaetcher`, `calibre`, `orbstack`, `mediainfo`, `mullvadvpn`, `tor-browser`, and `whatsapp`.

`Brewfile.work` contains:

- `birdayz/kaf`
- `common-fate/granted`
- `k8sgpt-ai/k8sgpt`
- `hashicorp/tap`
- Work-only formulas such as `k8sgpt`, `kaf`, `gitleaks`, `granted`, `mysql`, `steampipe`, `vault`, and `terraform`.
- Work-only casks such as `amazon-chime`, `aws-vault`, `cloudflare-warp`, `grammarly-desktop`, `meetingbar`, and `rancher`.

The apply command runs Homebrew Bundle explicitly:

```bash
brew bundle --file Brewfile.common
brew bundle --file "Brewfile.${role}"
```

This preserves the requested Homebrew Bundle stack while keeping the profile-specific package split first-class.

## nix-darwin Design

`modules/darwin/common.nix` configures:

- Nix experimental features for flakes and `nix-command`.
- The primary user and user home path.
- zsh as an enabled shell.
- Shared macOS system defaults that map cleanly to nix-darwin options.
- Activation scripts for settings that require direct commands, such as `pmset`, `systemsetup`, `chflags`, and custom defaults not covered by nix-darwin options.
- Installation of the `cleanup` command through a generated system script.
- A terminal notification after successful activation when `terminal-notifier` exists.

`modules/darwin/home.nix` remains intentionally small and only contains system-level home-profile differences.

`modules/darwin/work.nix` contains work-only system activation for:

- Installing `biscuit` into `/usr/local/bin` when missing.
- Installing `electro` into `/usr/local/bin`.

The work-only helper downloads stay imperative because they currently come from direct URLs rather than Homebrew or Nix package definitions. The activation script will be idempotent for `biscuit` and overwrite-safe for `electro`.

## Home Manager Design

`modules/home/common.nix` configures shared user shell behavior:

- Home Manager state version.
- zsh enabled for the user.
- oh-my-zsh enabled with the `robbyrussell` theme.
- Shared environment variables, including `ERL_AFLAGS`.
- Shared PATH additions such as `$HOME/.cargo/bin`.
- The Touch ID sudo helper function from the current zsh files.

`modules/home/home.nix` configures the home zsh plugin set:

- `gitfast`
- `sudo`

`modules/home/work.nix` configures the work zsh environment:

- PATH additions for `$HOME/bin`, `$HOME/.local/bin`, coreutils gnubin, krew, Python user scripts, Rancher Desktop, and cargo.
- oh-my-zsh plugins `aws`, `git`, `kube-ps1`, `kubectl`, and `poetry`.
- `OP_ACCOUNT=prima.1password.eu`.
- `AWS_REGION=eu-west-1`.
- kube prompt prefix behavior.
- The existing `brew` alias that runs Homebrew as the brew prefix owner.

The old `.zshrc` templates will no longer be copied directly. Home Manager will generate the zsh configuration instead.

## Scripts

`scripts/bootstrap.sh home|work` handles first-run setup:

- Validate the role argument.
- Ask for sudo upfront.
- Install Nix if `nix` is missing.
- Install Homebrew if `brew` is missing.
- Run `scripts/apply.sh home|work`.

`scripts/apply.sh home|work` handles repeatable provisioning:

- Validate the role argument.
- Ask for sudo upfront.
- Ensure Homebrew is available in the current shell.
- Run `brew bundle --file Brewfile.common`.
- Run `brew bundle --file Brewfile.home` or `brew bundle --file Brewfile.work`.
- Run `darwin-rebuild switch --flake ".#${role}"`.

The old `run.sh` is removed rather than kept as a compatibility wrapper, because its Ansible-specific behavior would be misleading.

## Documentation

`README.md` will describe:

- Required first-run profile command: `./scripts/bootstrap.sh home` or `./scripts/bootstrap.sh work`.
- Repeat apply command: `./scripts/apply.sh home` or `./scripts/apply.sh work`.
- How to update flake inputs.
- How to update Homebrew packages.
- Manual post-install steps that still require sign-in or UI actions.
- The profile split and file responsibilities.

## Error Handling

Scripts will fail fast with `set -euo pipefail`.

Invalid roles will print usage and exit non-zero.

Bootstrap will only install Nix or Homebrew when the corresponding command is missing.

Apply will fail if Homebrew or Nix remains unavailable after bootstrap expectations are met.

The work helper installation will fail the activation if a download or install command fails, so partial work setup is visible.

## Verification

The rewrite will be verified with:

- Shell syntax checks for `scripts/bootstrap.sh`, `scripts/apply.sh`, and `files/cleanup`.
- `brew bundle check --file Brewfile.common`.
- `brew bundle check --file Brewfile.home`.
- `brew bundle check --file Brewfile.work`.
- `nix flake check` when Nix is available.
- A text search confirming no Ansible workflow files or Ansible commands remain.

If Nix is not installed in the current environment, Nix evaluation will be documented as not run, and shell/Brewfile validation will still be performed.
