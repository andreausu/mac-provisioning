# Nix Darwin Home Manager Brew Bundle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Ansible macOS provisioning workflow with nix-darwin, Home Manager, and explicit Homebrew Bundle files while preserving separate `home` and `work` profiles.

**Architecture:** The flake exports `darwinConfigurations.home` and `darwinConfigurations.work`; nix-darwin owns system activation and macOS settings; Home Manager owns generated zsh configuration; Homebrew Bundle remains explicit through `Brewfile.common`, `Brewfile.home`, and `Brewfile.work`. Shell scripts coordinate bootstrap, apply, and verification.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager, Homebrew Bundle, Bash, zsh, macOS `defaults`/`pmset`/`systemsetup`.

---

## File Structure

Create:

- `Brewfile.common`: shared taps, formulae, and casks.
- `Brewfile.home`: home-only taps, formulae, and casks.
- `Brewfile.work`: work-only taps, formulae, and casks.
- `flake.nix`: flake inputs and `home`/`work` darwin configurations.
- `modules/darwin/common.nix`: shared nix-darwin system configuration.
- `modules/darwin/home.nix`: home-only nix-darwin differences.
- `modules/darwin/work.nix`: work-only nix-darwin activation for helper tools.
- `modules/home/common.nix`: shared Home Manager zsh configuration.
- `modules/home/home.nix`: home-only Home Manager configuration.
- `modules/home/work.nix`: work-only Home Manager configuration.
- `scripts/bootstrap.sh`: first-run installer and dispatcher.
- `scripts/apply.sh`: repeatable profile application.
- `scripts/verify.sh`: local static and optional state checks.

Modify:

- `README.md`: document the new workflow.
- `files/cleanup`: preserve as the installed cleanup command; adjust only if shell syntax validation requires it.

Delete:

- `playbook.yml`
- `galaxy-roles.yml`
- `local`
- `run.sh`
- `files/.zshrc_home`
- `files/.zshrc_work`
- `files/macos-settings.sh`
- `files/paths`

---

### Task 1: Add Verification Script

**Files:**

- Create: `scripts/verify.sh`

- [ ] **Step 1: Create the failing verification script**

```bash
#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "Brewfile.common"
  "Brewfile.home"
  "Brewfile.work"
  "flake.nix"
  "modules/darwin/common.nix"
  "modules/darwin/home.nix"
  "modules/darwin/work.nix"
  "modules/home/common.nix"
  "modules/home/home.nix"
  "modules/home/work.nix"
  "scripts/apply.sh"
  "scripts/bootstrap.sh"
)

obsolete_files=(
  "playbook.yml"
  "galaxy-roles.yml"
  "local"
  "run.sh"
  "files/.zshrc_home"
  "files/.zshrc_work"
  "files/macos-settings.sh"
  "files/paths"
)

fail=0

for file in "${required_files[@]}"; do
  if [[ ! -f "$ROOT_DIR/$file" ]]; then
    printf 'missing required file: %s\n' "$file" >&2
    fail=1
  fi
done

for file in "${obsolete_files[@]}"; do
  if [[ -e "$ROOT_DIR/$file" ]]; then
    printf 'obsolete file still exists: %s\n' "$file" >&2
    fail=1
  fi
done

for file in "$ROOT_DIR"/scripts/*.sh "$ROOT_DIR/files/cleanup"; do
  if [[ -f "$file" ]]; then
    bash -n "$file"
  fi
done

if grep -RInE 'ansible|ansible-playbook|ansible-galaxy|homebrew_cask|homebrew:' \
  --exclude-dir=.git \
  --exclude-dir=docs \
  "$ROOT_DIR"; then
  printf 'obsolete Ansible references remain outside docs\n' >&2
  fail=1
fi

if command -v nix >/dev/null 2>&1; then
  nix --extra-experimental-features "nix-command flakes" flake check "$ROOT_DIR"
else
  printf 'skip: nix is not available, flake check not run\n'
fi

if [[ "${CHECK_BREW_STATE:-0}" == "1" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    printf 'brew is required when CHECK_BREW_STATE=1\n' >&2
    fail=1
  else
    brew bundle check --file "$ROOT_DIR/Brewfile.common"
    brew bundle check --file "$ROOT_DIR/Brewfile.home"
    brew bundle check --file "$ROOT_DIR/Brewfile.work"
  fi
fi

exit "$fail"
```

- [ ] **Step 2: Make the verification script executable**

Run:

```bash
chmod +x scripts/verify.sh
```

Expected: no output.

- [ ] **Step 3: Run verification and confirm it fails before migration files exist**

Run:

```bash
scripts/verify.sh
```

Expected: FAIL with missing `Brewfile.common`, `flake.nix`, and module files, plus obsolete Ansible files still present.

- [ ] **Step 4: Commit**

```bash
git add scripts/verify.sh
git commit -m "test: add provisioning migration verification"
```

---

### Task 2: Add Homebrew Bundle Files

**Files:**

- Create: `Brewfile.common`
- Create: `Brewfile.home`
- Create: `Brewfile.work`
- Test: `scripts/verify.sh`

- [ ] **Step 1: Create `Brewfile.common`**

```ruby
tap "teamookla/speedtest"

brew "1password-cli"
brew "automake"
brew "awscli"
brew "cloudflared"
brew "coreutils"
brew "curl"
brew "diff-pdf"
brew "dos2unix"
brew "elixir"
brew "excel-compare"
brew "exiftool"
brew "fdupes"
brew "ffmpeg"
brew "fswatch"
brew "git"
brew "go"
brew "gnu-sed"
brew "helm"
brew "iperf3"
brew "jq"
brew "jsonnet"
brew "jsonpp"
brew "k9s"
brew "krew"
brew "kubernetes-cli"
brew "mitmproxy"
brew "mtr"
brew "netcat"
brew "nmap"
brew "node"
brew "openssl"
brew "optipng"
brew "p7zip"
brew "poetry"
brew "pulumi"
brew "pwgen"
brew "python"
brew "redis"
brew "rsync"
brew "shellcheck"
brew "speedtest-cli"
brew "sqlite"
brew "streamlink"
brew "teamookla/speedtest/speedtest"
brew "telnet"
brew "terminal-notifier"
brew "tor"
brew "tree"
brew "vim"
brew "watch"
brew "wget"
brew "xz"
brew "yamllint"
brew "yarn"
brew "yq"
brew "yt-dlp"
brew "zip"

cask "1password"
cask "appcleaner"
cask "betterdisplay"
cask "bruno"
cask "discord"
cask "firefox"
cask "geekbench"
cask "google-chrome"
cask "sublime-text"
cask "tableplus"
cask "the-unarchiver"
cask "visual-studio-code"
cask "vlc"
cask "wireshark"
cask "zoom"
```

- [ ] **Step 2: Create `Brewfile.home`**

```ruby
tap "siderolabs/tap"

brew "siderolabs/tap/talosctl"

cask "balenaetcher"
cask "calibre"
cask "mediainfo"
cask "mullvadvpn"
cask "orbstack"
cask "tor-browser"
cask "whatsapp"
```

- [ ] **Step 3: Create `Brewfile.work`**

```ruby
tap "birdayz/kaf"
tap "common-fate/granted"
tap "hashicorp/tap"
tap "k8sgpt-ai/k8sgpt"

brew "birdayz/kaf/kaf"
brew "common-fate/granted/granted"
brew "gitleaks"
brew "hashicorp/tap/terraform"
brew "hashicorp/tap/vault"
brew "k8sgpt-ai/k8sgpt/k8sgpt"
brew "mysql"
brew "steampipe"

cask "amazon-chime"
cask "aws-vault"
cask "cloudflare-warp"
cask "grammarly-desktop"
cask "meetingbar"
cask "rancher"
```

- [ ] **Step 4: Run static verification**

Run:

```bash
scripts/verify.sh
```

Expected: FAIL because Nix files and scripts are still missing and obsolete Ansible files still exist. It should no longer report missing Brewfiles.

- [ ] **Step 5: Commit**

```bash
git add Brewfile.common Brewfile.home Brewfile.work
git commit -m "feat: add homebrew bundle profiles"
```

---

### Task 3: Add Flake And nix-darwin Modules

**Files:**

- Create: `flake.nix`
- Create: `modules/darwin/common.nix`
- Create: `modules/darwin/home.nix`
- Create: `modules/darwin/work.nix`
- Test: `scripts/verify.sh`

- [ ] **Step 1: Create `flake.nix`**

```nix
{
  description = "macOS provisioning with nix-darwin, Home Manager, and Homebrew Bundle";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      user = "andreausuelli";
      system = "aarch64-darwin";

      profiles = {
        home = {
          darwinModule = ./modules/darwin/home.nix;
          homeModule = ./modules/home/home.nix;
        };
        work = {
          darwinModule = ./modules/darwin/work.nix;
          homeModule = ./modules/home/work.nix;
        };
      };

      mkDarwin =
        role:
        let
          profile = profiles.${role};
        in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = {
            inherit inputs role user;
          };
          modules = [
            ./modules/darwin/common.nix
            profile.darwinModule
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs role user;
              };
              home-manager.users.${user} = {
                imports = [
                  ./modules/home/common.nix
                  profile.homeModule
                ];
              };
            }
          ];
        };
    in
    {
      darwinConfigurations = {
        home = mkDarwin "home";
        work = mkDarwin "work";
      };

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
```

- [ ] **Step 2: Create `modules/darwin/common.nix`**

```nix
{ pkgs, user, ... }:

let
  homeDirectory = "/Users/${user}";
  cleanup = pkgs.writeShellScriptBin "cleanup" (builtins.readFile ../../files/cleanup);
in
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.primaryUser = user;
  system.stateVersion = 6;

  users.users.${user} = {
    name = user;
    home = homeDirectory;
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  environment.shells = [ pkgs.zsh ];
  environment.systemPackages = [
    cleanup
    pkgs.curl
    pkgs.git
  ];

  system.activationScripts.macDefaults.text = ''
    set -euo pipefail

    user_defaults() {
      /usr/bin/sudo -u ${user} /usr/bin/defaults "$@"
    }

    user_host_defaults() {
      /usr/bin/sudo -u ${user} /usr/bin/defaults -currentHost "$@"
    }

    /usr/bin/osascript -e 'tell application "System Settings" to quit' || true
    /usr/bin/osascript -e 'tell application "System Preferences" to quit' || true

    user_defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
    /usr/bin/defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

    user_defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
    user_defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
    user_defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
    user_defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
    user_defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

    user_defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    user_host_defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
    user_defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

    user_defaults write NSGlobalDomain NSToolbarTitleViewRolloverDelay -float 0
    user_defaults write NSGlobalDomain KeyRepeat -int 1
    user_defaults write NSGlobalDomain InitialKeyRepeat -int 20

    user_defaults write NSGlobalDomain AppleLanguages -array "en" "it"
    user_defaults write NSGlobalDomain AppleLocale -string "en_US@currency=EUR"
    user_defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
    user_defaults write NSGlobalDomain AppleMetricUnits -bool true

    user_defaults write com.apple.screensaver askForPassword -int 1
    user_defaults write com.apple.screensaver askForPasswordDelay -int 0
    user_defaults write NSGlobalDomain AppleFontSmoothing -int 1

    user_defaults write com.apple.finder AppleShowAllFiles -bool true
    user_defaults write NSGlobalDomain AppleShowAllExtensions -bool true
    user_defaults write com.apple.finder ShowStatusBar -bool true
    user_defaults write com.apple.finder ShowPathbar -bool true
    user_defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
    user_defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
    user_defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
    user_defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

    /usr/bin/sudo -u ${user} /usr/bin/chflags nohidden "${homeDirectory}/Library" || true
    /usr/bin/chflags nohidden /Volumes || true

    user_defaults write com.apple.dock tilesize -int 36
    user_defaults write com.apple.dock size-immutable -bool true
    user_defaults write com.apple.dock magnification -bool false
    user_defaults write com.apple.dock launchanim -bool false
    user_defaults write com.apple.dock mru-spaces -bool false
    user_defaults write com.apple.dock autohide-delay -float 0
    user_defaults write com.apple.dock autohide -bool true
    user_defaults write com.apple.dock show-recents -bool false

    user_defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
    user_defaults write com.apple.Safari HomePage -string "about:blank"
    user_defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true
    user_defaults write com.apple.Safari ShowFavoritesBar -bool false
    user_defaults write com.apple.Safari ShowSidebarInTopSites -bool false
    user_defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
    user_defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
    user_defaults write com.apple.Safari IncludeDevelopMenu -bool true
    user_defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
    user_defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
    user_defaults write NSGlobalDomain WebKitDeveloperExtras -bool true
    user_defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true
    user_defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false
    user_defaults write com.apple.Safari AutoFillFromAddressBook -bool false
    user_defaults write com.apple.Safari AutoFillPasswords -bool false
    user_defaults write com.apple.Safari AutoFillCreditCardData -bool false
    user_defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false
    user_defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true
    user_defaults write com.apple.Safari WebKitPluginsEnabled -bool false
    user_defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2PluginsEnabled -bool false
    user_defaults write com.apple.Safari WebKitJavaEnabled -bool false
    user_defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled -bool false
    user_defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles -bool false
    user_defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true
    user_defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true
    user_defaults write com.apple.Safari NewTabBehavior -int 1
    user_defaults write com.apple.Safari NewWindowBehavior -int 1

    user_defaults write com.apple.mail DisableReplyAnimations -bool true
    user_defaults write com.apple.mail DisableSendAnimations -bool true
    user_defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
    user_defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
    user_defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
    user_defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"
    user_defaults write com.apple.mail DisableInlineAttachmentViewing -bool true
    user_defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"

    user_defaults write com.apple.terminal SecureKeyboardEntry -bool true
    user_defaults write com.apple.Terminal ShowLineMarks -int 0
    user_defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
    user_defaults write com.apple.ActivityMonitor IconType -int 6
    user_defaults write com.apple.ActivityMonitor ShowCategory -int 0
    user_defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
    user_defaults write com.apple.ActivityMonitor SortDirection -int 0

    user_defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
    user_defaults write com.apple.DiskUtility advanced-image-options -bool true
    user_defaults write com.apple.QuickTimePlayerX MGPlayMovieOnOpen -bool true

    user_defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
    user_defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
    user_defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
    user_defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
    user_defaults write com.apple.commerce AutoUpdate -bool true

    user_defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false
    user_defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "automaticQuoteSubstitutionEnabled" -bool false
    user_defaults write com.apple.messageshelper.MessageController SOInputLineSettings -dict-add "continuousSpellCheckingEnabled" -bool false

    user_defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
    user_defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false
    user_defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false
    user_defaults write com.google.Chrome.canary AppleEnableMouseSwipeNavigateWithScrolls -bool false

    user_defaults write "${homeDirectory}/Library/Preferences/org.gpgtools.gpgmail" SignNewEmailsByDefault -bool false

    /usr/bin/pmset -a lidwake 1
    /usr/bin/pmset -a autorestart 1
    /usr/sbin/systemsetup -setrestartfreeze on
    /usr/bin/pmset -a displaysleep 15
    /usr/bin/pmset -c sleep 0
    /usr/bin/pmset -b sleep 5
    /usr/bin/pmset -a standbydelay 86400
    /usr/sbin/systemsetup -setcomputersleep Off >/dev/null

    user_defaults write AppleInterfaceStyle -string "Dark"
    user_defaults write "Default Window Settings" -string "Pro"
    user_defaults write "Startup Window Settings" -string "Pro"

    /usr/bin/killall Finder >/dev/null 2>&1 || true
    /usr/bin/killall Dock >/dev/null 2>&1 || true

    if /opt/homebrew/bin/terminal-notifier -help >/dev/null 2>&1; then
      /opt/homebrew/bin/terminal-notifier \
        -sound default \
        -group "terminal-nix-darwin" \
        -title "nix-darwin" \
        -subtitle "Finished" \
        -message "Mac successfully provisioned!" \
        -activate "com.apple.Terminal"
    elif /usr/local/bin/terminal-notifier -help >/dev/null 2>&1; then
      /usr/local/bin/terminal-notifier \
        -sound default \
        -group "terminal-nix-darwin" \
        -title "nix-darwin" \
        -subtitle "Finished" \
        -message "Mac successfully provisioned!" \
        -activate "com.apple.Terminal"
    fi
  '';
}
```

- [ ] **Step 3: Create `modules/darwin/home.nix`**

```nix
{ ... }:

{
}
```

- [ ] **Step 4: Create `modules/darwin/work.nix`**

```nix
{ ... }:

{
  system.activationScripts.workTools.text = ''
    set -euo pipefail

    /bin/mkdir -p /usr/local/bin

    if [[ ! -x /usr/local/bin/biscuit ]]; then
      tmpdir="$(/usr/bin/mktemp -d)"
      /usr/bin/curl -fsSL \
        "https://github.com/primait/biscuit/releases/download/v0.1.7/biscuit-darwin_amd64.tgz" \
        -o "$tmpdir/biscuit-darwin_amd64.tgz"
      /usr/bin/tar -xzf "$tmpdir/biscuit-darwin_amd64.tgz" -C "$tmpdir"
      /bin/mv "$tmpdir/biscuit" /usr/local/bin/biscuit
      /bin/chmod 0755 /usr/local/bin/biscuit
      /bin/rm -rf "$tmpdir"
    fi

    /usr/bin/curl -fsSL \
      "https://raw.githubusercontent.com/aleinside/dotfiles/master/future/electro-future.sh" \
      -o /usr/local/bin/electro
    /bin/chmod 0755 /usr/local/bin/electro
  '';
}
```

- [ ] **Step 5: Run static verification**

Run:

```bash
scripts/verify.sh
```

Expected: FAIL because Home Manager modules and orchestration scripts are still missing and obsolete Ansible files still exist. It should no longer report missing `flake.nix` or `modules/darwin/*.nix`.

- [ ] **Step 6: Commit**

```bash
git add flake.nix modules/darwin
git commit -m "feat: add nix darwin profiles"
```

---

### Task 4: Add Home Manager Modules

**Files:**

- Create: `modules/home/common.nix`
- Create: `modules/home/home.nix`
- Create: `modules/home/work.nix`
- Test: `scripts/verify.sh`

- [ ] **Step 1: Create `modules/home/common.nix`**

```nix
{ user, ... }:

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
    };
    initExtra = ''
      export ERL_AFLAGS="-kernel shell_history enabled"
      export PATH="$PATH:$HOME/.cargo/bin"

      sudo() {
        unset -f sudo
        if [[ "$(uname)" == "Darwin" ]] && ! grep "pam_tid.so" /etc/pam.d/sudo --silent; then
          command sudo sed -i -e "1s;^;auth       sufficient     pam_tid.so\n;" /etc/pam.d/sudo
        fi
        command sudo "$@"
      }
    '';
  };
}
```

- [ ] **Step 2: Create `modules/home/home.nix`**

```nix
{ ... }:

{
  programs.zsh.oh-my-zsh.plugins = [
    "gitfast"
    "sudo"
  ];
}
```

- [ ] **Step 3: Create `modules/home/work.nix`**

```nix
{ ... }:

{
  programs.zsh.oh-my-zsh.plugins = [
    "aws"
    "git"
    "kube-ps1"
    "kubectl"
    "poetry"
  ];

  programs.zsh.initExtra = ''
    export PATH="$HOME/bin:/usr/local/bin:$PATH"
    export PATH="$HOME/.local/bin:/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
    export PATH="''${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
    export PATH="/Users/andreausuelli/Library/Python/3.12/bin:$PATH"

    export OP_ACCOUNT="prima.1password.eu"
    export AWS_REGION="eu-west-1"
    PROMPT='$(kube_ps1)'$PROMPT

    export PATH="$PATH:$HOME/.rd/bin"

    unalias brew 2>/dev/null
    if command -v brew >/dev/null 2>&1; then
      brewser=$(/usr/bin/stat -f "%Su" "$(command -v brew)")
      alias brew='sudo -Hu '$brewser' brew'
    fi
  '';
}
```

- [ ] **Step 4: Run static verification**

Run:

```bash
scripts/verify.sh
```

Expected: FAIL because `scripts/apply.sh` and `scripts/bootstrap.sh` are missing and obsolete Ansible files still exist. It should no longer report missing Home Manager modules.

- [ ] **Step 5: Commit**

```bash
git add modules/home
git commit -m "feat: add home manager profiles"
```

---

### Task 5: Add Bootstrap And Apply Scripts

**Files:**

- Create: `scripts/bootstrap.sh`
- Create: `scripts/apply.sh`
- Test: `scripts/verify.sh`

- [ ] **Step 1: Create `scripts/apply.sh`**

```bash
#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  printf 'Usage: %s home|work\n' "$0" >&2
}

role="${1:-}"
case "$role" in
  home | work) ;;
  *)
    usage
    exit 1
    ;;
esac

sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    printf 'Homebrew is required. Run ./scripts/bootstrap.sh %s first.\n' "$role" >&2
    exit 1
  fi
fi

if ! command -v nix >/dev/null 2>&1; then
  if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
fi

if ! command -v nix >/dev/null 2>&1; then
  printf 'Nix is required. Run ./scripts/bootstrap.sh %s first.\n' "$role" >&2
  exit 1
fi

cd "$ROOT_DIR"

brew bundle --file "$ROOT_DIR/Brewfile.common"
brew bundle --file "$ROOT_DIR/Brewfile.$role"

if command -v darwin-rebuild >/dev/null 2>&1; then
  sudo darwin-rebuild switch --flake "$ROOT_DIR#$role"
else
  sudo nix --extra-experimental-features "nix-command flakes" \
    run nix-darwin/master#darwin-rebuild -- \
    switch --flake "$ROOT_DIR#$role"
fi
```

- [ ] **Step 2: Create `scripts/bootstrap.sh`**

```bash
#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  printf 'Usage: %s home|work\n' "$0" >&2
}

role="${1:-}"
case "$role" in
  home | work) ;;
  *)
    usage
    exit 1
    ;;
esac

sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
  printf 'Xcode Command Line Tools are required. Run xcode-select --install, finish the installer, then rerun this script.\n' >&2
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  sh <(/usr/bin/curl -L https://nixos.org/nix/install) --daemon
fi

if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    NONINTERACTIVE=1 /bin/bash -c "$(/usr/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
fi

"$ROOT_DIR/scripts/apply.sh" "$role"
```

- [ ] **Step 3: Make scripts executable**

Run:

```bash
chmod +x scripts/apply.sh scripts/bootstrap.sh
```

Expected: no output.

- [ ] **Step 4: Run static verification**

Run:

```bash
scripts/verify.sh
```

Expected: FAIL only because obsolete Ansible files still exist.

- [ ] **Step 5: Commit**

```bash
git add scripts/apply.sh scripts/bootstrap.sh
git commit -m "feat: add nix provisioning scripts"
```

---

### Task 6: Replace Documentation And Remove Ansible Files

**Files:**

- Modify: `README.md`
- Delete: `playbook.yml`
- Delete: `galaxy-roles.yml`
- Delete: `local`
- Delete: `run.sh`
- Delete: `files/.zshrc_home`
- Delete: `files/.zshrc_work`
- Delete: `files/macos-settings.sh`
- Delete: `files/paths`
- Test: `scripts/verify.sh`

- [ ] **Step 1: Replace `README.md`**

```markdown
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
```

- [ ] **Step 2: Delete obsolete files**

Use `apply_patch` delete hunks for:

```text
playbook.yml
galaxy-roles.yml
local
run.sh
files/.zshrc_home
files/.zshrc_work
files/macos-settings.sh
files/paths
```

- [ ] **Step 3: Run static verification**

Run:

```bash
scripts/verify.sh
```

Expected: PASS when Nix is unavailable, with a printed `skip: nix is not available, flake check not run`; PASS with `nix flake check` when Nix is available and the flake evaluates.

- [ ] **Step 4: Commit**

```bash
git add README.md playbook.yml galaxy-roles.yml local run.sh files/.zshrc_home files/.zshrc_work files/macos-settings.sh files/paths
git commit -m "refactor: remove ansible provisioning"
```

---

### Task 7: Final Verification

**Files:**

- Test: `scripts/verify.sh`
- Test: `Brewfile.common`
- Test: `Brewfile.home`
- Test: `Brewfile.work`
- Test: `flake.nix`

- [ ] **Step 1: Run static verification**

Run:

```bash
scripts/verify.sh
```

Expected: PASS, or PASS with a Nix skip message if Nix is not installed in the current environment.

- [ ] **Step 2: Run optional Homebrew Bundle state check**

Run:

```bash
CHECK_BREW_STATE=1 scripts/verify.sh
```

Expected after applying a profile: PASS. Expected before applying a profile: Homebrew reports missing formulae or casks; capture that as a provisioning-state result, not a syntax failure.

- [ ] **Step 3: Confirm no Ansible workflow remains**

Run:

```bash
grep -RInE 'ansible|ansible-playbook|ansible-galaxy|homebrew_cask|homebrew:' \
  --exclude-dir=.git \
  --exclude-dir=docs \
  .
```

Expected: no output.

- [ ] **Step 4: Inspect git status**

Run:

```bash
git status --short
```

Expected: no uncommitted changes if all implementation commits were made.
