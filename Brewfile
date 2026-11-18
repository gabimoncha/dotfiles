# Entries for every Mac, the MacBook Air too. The development Macs add
# apps/devhost.Brewfile, and a profile adds its own entries in
# apps/<profile>.Brewfile, for example apps/macowl.Brewfile. Setup installs all
# of these files. See dotfiles_profile_app_lists in bin/lib/dotfiles-profile.sh.
# Homebrew owns GUI apps, App Store apps, system packages, and CLIs that are not
# already managed by mise or standalone installer exceptions. Runtimes and
# overlapping developer tools stay in mise instead.

# Every third-party tap here has been reviewed as part of this machine setup.
# Persist that approval so later Homebrew commands use the same trust policy.
tap "xykong/tap", trusted: true

# Bash 5 comes first on PATH. The bin/ scripts stay Bash 3.2 compatible,
# because a new Mac runs setup with /bin/bash before Homebrew exists.
brew "bash"
brew "btop"
brew "curl"
# Other apps look for ffmpeg and yt-dlp in /opt/homebrew/bin, so these two
# stay in Homebrew.
brew "ffmpeg"
brew "git"
brew "mole"
brew "openssl@3"
brew "smartmontools"
brew "webp"
brew "yt-dlp"

# Mac App Store
mas "The Unarchiver", id: 425424353

cask "cursor"
cask "font-hack-nerd-font"
cask "ghostty"
cask "google-chrome"
cask "raycast"
cask "tailscale-app"
cask "xykong/tap/flux-markdown"

vscode "anysphere.remote-containers"
vscode "anysphere.remote-ssh"
vscode "typescriptteam.native-preview"
