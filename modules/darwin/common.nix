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

  system.activationScripts.postActivation.text = ''
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
