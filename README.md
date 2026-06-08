# macOS Provisioning

Personal macOS provisioning with:

- nix-darwin for system configuration.
- Home Manager for user shell configuration.
- Homebrew Bundle for Homebrew taps, formulae, and casks.

The project exposes two profiles:

- `home`
- `work`

## First Run

```shell
./scripts/bootstrap.sh home
```

or:

```shell
./scripts/bootstrap.sh work
```

The bootstrap script checks for Xcode Command Line Tools, installs Nix when missing, installs Homebrew when missing, and then applies the selected profile.

## Apply An Existing Setup

```shell
./scripts/apply.sh home
```

or:

```shell
./scripts/apply.sh work
```

The apply script runs:

```shell
brew bundle --file Brewfile.common
brew bundle --file Brewfile.home
```

or:

```shell
brew bundle --file Brewfile.common
brew bundle --file Brewfile.work
```

Then it runs `darwin-rebuild switch --flake .#home` or `darwin-rebuild switch --flake .#work`.

## Files

- `flake.nix`: nix-darwin and Home Manager entry point.
- `modules/darwin/common.nix`: shared macOS system settings.
- `modules/darwin/home.nix`: home system profile.
- `modules/darwin/work.nix`: work system profile and work helper tools.
- `modules/home/common.nix`: shared zsh configuration.
- `modules/home/home.nix`: home zsh profile.
- `modules/home/work.nix`: work zsh profile.
- `Brewfile.common`: shared Homebrew packages and apps.
- `Brewfile.home`: home-only Homebrew packages and apps.
- `Brewfile.work`: work-only Homebrew packages and apps.
- `files/cleanup`: cleanup command installed through nix-darwin.

## Update

Update flake inputs:

```shell
nix --extra-experimental-features "nix-command flakes" flake update
```

Update Homebrew packages during an apply:

```shell
brew update
./scripts/apply.sh home
```

or:

```shell
brew update
./scripts/apply.sh work
```

## Verify

Run static checks:

```shell
./scripts/verify.sh
```

After a profile has been applied, verify Homebrew Bundle state:

```shell
CHECK_BREW_STATE=1 ./scripts/verify.sh
```

## Manual Steps

Some setup still needs interactive macOS or app sign-in:

1. Sign in to the Mac App Store.
2. Sign in to Firefox.
3. Enable unlock with Apple Watch.
4. Install Backblaze.
5. Enable App Expose in trackpad settings.
6. Sign in to Music.
7. Enable only Mail for the Gmail account.

## Notes

- Homebrew package inventory intentionally lives in Brewfiles instead of nix-darwin `homebrew.*` options.
- `work` installs `biscuit` and `electro` through nix-darwin activation scripts because they are direct URL installs in the previous workflow.
- The legacy provisioning workflow has been removed.
