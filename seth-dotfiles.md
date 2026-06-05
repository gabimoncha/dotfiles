Directory structure:
└── sethwebster-dotfiles/
    ├── README.md
    ├── AGENT-WORKSPACE.md
    ├── aliases.zsh
    ├── auth-setup.sh
    ├── bootstrap.sh
    ├── brew-update.sh
    ├── Brewfile
    ├── Brewfile.backup
    ├── CHANGELOG.md
    ├── check-updates.zsh
    ├── com.seth.brew-update.plist
    ├── DECISIONS.md
    ├── docker-compose.yml
    ├── functions.zsh
    ├── install.sh
    ├── MACKUP.md
    ├── macos.sh
    ├── path.zsh
    ├── prepare-sync.sh
    ├── prompt.zsh
    ├── QUICKSTART.md
    ├── SECURITY.md
    ├── .env.example
    ├── .gitconfig
    ├── .mackup.cfg
    ├── .nanorc
    ├── .tool-versions
    ├── AGENTS.md -> AGENTS.md
    ├── CLAUDE.md -> CLAUDE.md
    ├── scripts/
    │   └── domain-info.ts
    └── .codex/
        └── environments/
            └── environment.toml


Files Content:

================================================
FILE: README.md
================================================
<div align="center">

# ✦ DOTFILES ✦

### *Intelligent macOS Environment Automation*

---

**One Command** · **Zero Friction** · **Absolute Precision**

---

```bash
./bootstrap.sh
```

*Your complete development environment in 15 minutes*

</div>

---

## 🎬 Why This Exists

I've set up **14 Macs** over 5 years.

The **first** took 2 weeks. Multiple documentation tabs, forgotten auth steps, broken configs.

The **second** took 3 days. I wrote a script. It failed halfway. Debugging took longer than manual setup.

The **third** broke my Homebrew installation. "App already exists" errors everywhere. Lost a full day debugging adoption conflicts.

**That's when I built this system.**

The goal was simple: **Clone a Mac in under 20 minutes with zero manual steps.**

But it evolved into something bigger:
- **Knowledge base** of my preferred tools and why I chose them
- **Forcing function** to document every decision
- **Reproducible environment** I can trust completely
- **System I can share** with teammates

**The breakthrough moment:** My MacBook Pro died last month during a conference talk prep (Friday night, 6 PM). Walked to Apple Store, bought new Mac, ran bootstrap. **18 minutes later I was back to work.** That confidence is what this repo gives you.

---

## ⚡️ The Philosophy

Most dotfiles are glorified file copiers. **This is an intelligent orchestration system.**

Every aspect is designed around three principles:

<table>
<tr>
<td width="33%" align="center">

**🧠 Intelligence**

Detects existing installs
Prevents adoption conflicts
Runs idempotently forever

</td>
<td width="33%" align="center">

**⚙️ Automation**

Self-healing scripts
Smart sudo keepalive
Guided auth setup

</td>
<td width="33%" align="center">

**📐 Precision**

No placeholders ever
Triple-verified configs
Explicit error handling

</td>
</tr>
</table>

---

## 🎯 What Makes This Different

### Smart Application Detection

The bootstrap script **scans `/Applications`** before running `brew bundle`, building a filtered Brewfile that excludes manually-installed apps. This prevents Homebrew adoption errors that plague traditional dotfile setups.

```mermaid
graph LR
    A[Read Brewfile] --> B{App in /Applications?}
    B -->|Yes| C[Skip Installation]
    B -->|No| D[Add to Queue]
    C --> E[Log Warning]
    D --> F[Install via Homebrew]
    style C fill:#ffc107
    style D fill:#4caf50
```

### Automatic Update System

Your shell checks GitHub for dotfile updates **once per 24 hours** (non-blocking, background process). No manual checking, no surprise auto-updates.

```
╔═══════════════════════════════════════════════════════════╗
║  📦 Dotfiles Update Available                             ║
╚═══════════════════════════════════════════════════════════╝

  New updates are available for your dotfiles!

  To update, run:
    dotfiles-update
```

### Zero-Friction Authentication

After bootstrap, run `auth-setup.sh` for guided setup:

- 🔑 GitHub CLI authentication (`gh auth login`)
- 🚀 Expo CLI login (`npx expo login`)
- 🔐 SSH key generation + GitHub upload
- ✅ Validation with real API calls

No more hunting through READMEs wondering what you forgot.

---

## 🔄 Cloning Your Mac to a New Machine

### On Your Current Mac (Sending Mode)

Before setting up a new Mac, capture your current system state:

```bash
cd ~/dotfiles
./prepare-sync.sh
```

**This script:**
1. ✅ Regenerates `Brewfile` from currently installed apps
2. ✅ Updates `.tool-versions` from current asdf installations
3. ✅ Runs `mackup backup` to sync app settings to iCloud
4. ✅ Shows diff of changes before updating
5. ✅ Commits and pushes changes to GitHub

**Result:** Your dotfiles repo now perfectly reflects your current Mac's state.

### On Your New Mac (Receiving Mode)

Then on the new Mac, just run bootstrap:

```bash
git clone https://github.com/sethwebster/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

The new Mac will automatically receive:
- 📦 All apps from the updated Brewfile
- 🔧 Tool versions from .tool-versions
- ⚙️ App settings via `mackup restore` (from iCloud)
- 🎨 Shell configuration and aliases

**Perfect clone.** Every time.

---

## 🚀 Quickstart

<table>
<tr>
<td>

### Fresh macOS Installation

```bash
# Clone dotfiles
git clone https://github.com/sethwebster/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Make executable
chmod +x *.sh

# Run bootstrap
./bootstrap.sh
```

**Prompts for:**
- Git name & email (if not configured)
- macOS defaults confirmation (first run only)

**Then installs:**
- Xcode Command Line Tools
- Homebrew + 40+ applications
- asdf + Node/Python
- Symlinks all dotfiles

**Finally offers:**
- Auth setup walkthrough (`./auth-setup.sh`)

</td>
</tr>
</table>

---

## 📦 The Complete Inventory

<details>
<summary><b>🎨 Applications (40+)</b></summary>

### Browsers & AI
| Category | Tools |
|----------|-------|
| Browsers | Chrome, Firefox, Arc, Brave |
| AI Assistants | Claude (desktop), ChatGPT, Claude Code CLI, Cursor |

### Development
| Category | Tools |
|----------|-------|
| Editors | VS Code, Cursor |
| Terminals | iTerm2, Warp |
| Infrastructure | Docker, Postman, pgAdmin4, Expo Orbit |
| Version Control | GitHub CLI (`gh`) |

### Productivity
| Category | Tools |
|----------|-------|
| Communication | Slack, Discord, Signal, WhatsApp, Beeper, Zoom |
| Knowledge | Notion, Obsidian, Bear |
| Organization | Things 3, Fantastical |
| Launchers | Raycast, Alfred |

### Utilities
| Category | Tools |
|----------|-------|
| Security | 1Password |
| Window Mgmt | Rectangle |
| Screenshots | CleanShot X |
| Storage | Dropbox, Cyberduck, DaisyDisk |
| System | iStat Menus, The Unarchiver, Amphetamine |

### Creative & Media
| Category | Tools |
|----------|-------|
| Design | Figma, Blender |
| Media | Spotify, VLC |

</details>

<details>
<summary><b>🛠 CLI Tools & Replacements</b></summary>

| Modern Tool | Replaces | Purpose |
|-------------|----------|---------|
| `bat` | `cat` | Syntax-highlighted file viewer |
| `eza` | `ls` | Git-aware directory listing |
| `ripgrep` (`rg`) | `grep` | Blazing-fast search |
| `fzf` | `find` + manual selection | Fuzzy finder for files/commands |
| `zoxide` (`z`) | `cd` | Frecency-based navigation |
| `tldr` | `man` | Simplified command examples |
| `gh` | Browser GitHub | GitHub CLI for issues/PRs |
| `asdf` | `nvm`, `pyenv`, etc. | Universal version manager |
| `mackup` | Manual backup | App settings sync via iCloud |

</details>

<details>
<summary><b>🔧 Development Environments</b></summary>

- **Node.js** (via asdf) - Current LTS configured
- **Python** (via asdf) - Python 3.x
- **Bun** - Ultra-fast JS runtime
- **Docker & Docker Compose** - Containerization
- **PostgreSQL & Redis** - Via docker-compose.yml for local dev

```bash
# Start dev databases
cd ~/dotfiles && docker compose up -d

# Connection strings
postgresql://postgres:postgres@localhost:5432/dev
redis://localhost:6379
```

</details>

---

## 🏗 Architecture Overview

```mermaid
graph TD
    A[bootstrap.sh] --> B{Xcode Installed?}
    B -->|No| C[Install Xcode Tools]
    B -->|Yes| D{Homebrew Installed?}
    C --> D
    D -->|No| E[Install Homebrew]
    D -->|Yes| F[Scan /Applications]
    E --> F
    F --> G[Filter Brewfile]
    G --> H[Install Apps]
    H --> I[Setup asdf]
    I --> J[Run install.sh]
    J --> K{macOS Defaults?}
    K -->|Yes| L[Apply macos.sh]
    K -->|No| M[Offer auth-setup.sh]
    L --> M
    M --> N[Complete]

    style A fill:#2196f3
    style N fill:#4caf50
    style F fill:#ff9800
```

### File Structure

```
dotfiles/
├── 🚀 bootstrap.sh          # Main orchestrator (intelligent app detection)
├── 🔗 install.sh             # Symlink manager (idempotent)
├── 🔐 auth-setup.sh          # Guided authentication setup
├── 🔄 prepare-sync.sh        # Sending mode (capture current state)
├── 🎨 macos.sh               # System preferences automation
├── 📦 Brewfile               # All Homebrew packages/casks
├── 🐳 docker-compose.yml     # PostgreSQL & Redis for dev
│
├── 🐚 .zshrc                 # ZSH orchestrator (loads modules)
├── 🛤  path.zsh              # PATH configuration
├── ⚡️ aliases.zsh            # Command shortcuts
├── 🔧 functions.zsh          # Custom shell functions
├── 📡 check-updates.zsh      # Auto-update checker (24hr interval)
│
├── 🔀 .gitconfig             # Git configuration (aliases, defaults)
├── 📌 .tool-versions         # asdf version pins
├── ☁️  .mackup.cfg            # App settings sync config
└── 🚫 .gitignore             # Git ignore rules
```

---

## ⚙️ Core Features Deep Dive

### 1️⃣ Idempotent Execution

Every script is **safe to run multiple times**:

```bash
# Run as many times as you want
./bootstrap.sh  # Skips installed tools, re-applies configs
./install.sh    # Only updates changed symlinks
```

**On re-run:**
- ✅ Skips already-installed packages
- ✅ Creates timestamped backups before overwriting
- ✅ Only prompts for missing information
- ✅ Checks for `~/.macos-defaults-applied` flag (asks before re-applying)

**Force macOS defaults re-application:**
```bash
rm ~/.macos-defaults-applied && ./bootstrap.sh
```

### 2️⃣ Intelligent App Detection

The core innovation:

```bash
# Bootstrap scans /Applications before brew bundle
if [ -d "/Applications/Docker.app" ]; then
  # Skip docker cask, preventing adoption error
fi
```

**Prevents:**
- Homebrew adoption errors
- Manual resolution of conflicts
- Failed brew bundle runs

**Maps 40+ cask names to actual app bundles:**
```
cursor → "Cursor.app"
visual-studio-code → "Visual Studio Code.app"
google-chrome → "Google Chrome.app"
# ... and 37 more
```

### 3️⃣ Smart Update Checking

```mermaid
sequenceDiagram
    participant Shell
    participant Checker
    participant GitHub
    participant User

    Shell->>Checker: New terminal opened
    Checker->>Checker: Check .last-update-check
    alt < 24 hours
        Checker-->>Shell: Skip (too soon)
    else ≥ 24 hours
        Checker->>GitHub: git fetch (background)
        GitHub-->>Checker: Compare commits
        alt Behind
            Checker->>User: Show notification
            User->>Shell: dotfiles-update
        end
    end
```

**Features:**
- Non-blocking (runs in background)
- Respects `DOTFILES_SKIP_UPDATE_CHECK=1`
- Timestamp tracking in `.last-update-check`
- Elegant notification with box drawing

**Disable:**
```bash
# Add to ~/.zshrc.local
DOTFILES_SKIP_UPDATE_CHECK=1
```

### 4️⃣ Guided Authentication

```bash
./auth-setup.sh
```

Interactive setup for:

| Service | Action | Validation |
|---------|--------|-----------|
| **GitHub CLI** | `gh auth login` | Tests with `gh api user` |
| **Expo CLI** | `npx expo login` | Confirms via `npx expo whoami` |
| **SSH Keys** | Generates ed25519 key | Uploads to GitHub via API |

**Smart behavior:**
- Skips if already authenticated
- Offers to configure each service individually
- Validates setup with real API calls
- Provides clear next steps

---

## 🌟 Standout Features You'll Love

### 🔧 Network Diagnostic Tool

Ever had mysterious connection issues? **`fix-my-network`** is your new best friend.

**Real Example:**
My WiFi stopped working after disconnecting from VPN. Chrome showed "No internet", but WiFi was connected. Running `fix-my-network` found stale proxy environment variables, cleared them automatically → instant fix.

**What it does:**
```bash
fix-my-network
```

- ✅ Checks DNS resolution
- ✅ Tests connectivity (IP + domain)
- ✅ Scans for proxy conflicts
- ✅ Diagnoses routing issues
- ✅ **Automatically fixes** common problems
- ✅ Beautiful table output showing all tests

**Before this tool:**
- 30 minutes Googling "Mac WiFi connected but no internet"
- Trying random Terminal commands from Stack Overflow
- Restarting Mac as last resort

**After:**
```bash
fix-my-network  # 15 seconds, fixed
```

---

### 📦 Port Management Made Simple

**The Problem:**
```
Error: Port 3000 is already in use
```
Who's using it? No idea.

**Old way:**
```bash
lsof -i :3000          # Find PID
# Read through output
kill -9 <PID>          # Manually kill
```

**New way:**
```bash
portkill 3000          # Done
```

**Real Example:**
Starting 5 different Next.js projects throughout the day. Port 3000 always in use from previous session. Instead of debugging, just `portkill 3000` and move on.

**Bonus:** `portfind 3000` to see what's running before killing.

---

### 🤖 AI Development Setup

Working on AI-assisted projects? **`ai init`** sets up best practices instantly.

```bash
cd my-new-project
ai init
```

**What you get:**
- 📄 `AGENTS.md` - Claude prompt patterns and best practices
- 🔗 `CLAUDE.md` symlink for compatibility
- 📖 Instructions for AI-native development
- ⚙️ Auto-synced from [github.com/sethwebster/AI](https://github.com/sethwebster/AI)

**Why this matters:**
Without this, your AI assistant doesn't understand your codebase structure, coding standards, or project context. You spend the first 30 minutes of each session explaining your setup.

With `ai init`, Claude immediately understands:
- Project architecture
- File organization patterns
- Development workflow
- Testing strategy

**Use case:** Start new project → `ai init` → Your AI assistant knows how to help from message one.

---

### 📖 Interactive Command Menu

Forgot a command? **`use-my-mac`** opens an interactive searchable menu of every alias and function.

```bash
use-my-mac
```

**Features:**
- 🔍 Fuzzy search through 100+ commands
- 📋 Copy to clipboard
- ⚡️ Execute immediately
- 📝 Categorized by function

**Real Example:**
Teammate asks "How do I kill Docker containers?" → `use-my-mac` → type "docker" → shows all Docker commands with descriptions.

**Before:**
- Open README
- Scroll through aliases
- Copy command
- Paste in terminal

**After:**
- `use-my-mac`
- Type 3 letters
- Enter
- Done

---

### ⚡️ Smart Update Notifications

Your shell checks GitHub for dotfiles updates **once per 24 hours** (non-blocking).

When updates available:
```
╔═══════════════════════════════════════════════════════╗
║  📦 Dotfiles Update Available                         ║
╚═══════════════════════════════════════════════════════╝

  New updates are available for your dotfiles!

  To update, run:
    dotfiles-update
```

**Why daily vs weekly:**
Critical bug fix pushed on Tuesday → Everyone notified by Wednesday.

Original implementation checked weekly → Took 7 days to reach all machines → Unacceptable for urgent fixes.

**Disable if annoying:**
```bash
# Add to ~/.zshrc.local
DOTFILES_SKIP_UPDATE_CHECK=1
```

---

### 🎯 One-Command Brewfile Sync

Installed new app manually? Update Brewfile automatically:

```bash
cd ~/dotfiles
./prepare-sync.sh
```

**What it does:**
1. Scans your `/Applications` folder
2. Generates updated Brewfile from current installs
3. Shows diff of what changed
4. Commits and pushes to GitHub

**Why this matters:**
Without this, Brewfile drifts from reality. You install Figma, forget to add to Brewfile. Next Mac setup → Figma missing.

With `prepare-sync.sh`, your Brewfile always reflects current state. **Perfect synchronization.**

---

## 🎨 ZSH Configuration

### Modular Architecture

```mermaid
graph LR
    A[.zshrc] --> B[path.zsh]
    A --> C[aliases.zsh]
    A --> D[functions.zsh]
    A --> E[check-updates.zsh]
    A --> F[.zshrc.local]

    style A fill:#2196f3
    style F fill:#4caf50,stroke-dasharray: 5 5
```

### Shell Aliases Reference

<details>
<summary><b>📂 Navigation & Files</b></summary>

```bash
ll          # eza -lah --git (detailed list)
ls          # eza --icons (pretty list)
cat         # bat (syntax highlighted)
z           # zoxide (smart cd)
mkcd        # mkdir + cd in one command
```

</details>

<details>
<summary><b>🔀 Git Shortcuts</b></summary>

```bash
gs          # git status
ga          # git add
gc          # git commit
gp          # git push
gl          # git pull
gd          # git diff
gco         # git checkout
gb          # git branch
glog        # git log --graph --oneline
```

</details>

<details>
<summary><b>🐳 Docker Shortcuts</b></summary>

```bash
dc          # docker compose
dcu         # docker compose up
dcd         # docker compose down
dcb         # docker compose build
dps         # docker ps --format table
```

</details>

<details>
<summary><b>🛠 Custom Functions</b></summary>

```bash
mkcd <dir>          # Create directory and cd into it
extract <file>      # Smart extraction (zip/tar/gz/etc)
serve [port]        # Quick HTTP server (default: 8000)
dotfiles-update     # Update dotfiles + Homebrew
```

</details>

### Local Overrides

Create `~/.zshrc.local` for machine-specific config (not tracked):

```bash
# ~/.zshrc.local - Machine-specific config
export WORK_PROJECT_PATH="/path/to/work"
alias deploy-staging="..."

# Disable update checks
DOTFILES_SKIP_UPDATE_CHECK=1
```

---

## 🎯 macOS System Configuration

```bash
./macos.sh  # Run standalone or via bootstrap
```

<table>
<tr>
<td width="50%">

### Finder
- Show all file extensions
- Show hidden files
- Display full path in title bar
- Show path bar & status bar
- Disable warnings for file changes
- Search current directory by default

</td>
<td width="50%">

### Dock
- Auto-hide enabled
- Remove app open indicators
- Faster show/hide animation
- No recent apps in Dock
- Custom icon size

</td>
</tr>
<tr>
<td>

### Screenshots
- Save to `~/Screenshots`
- Format: PNG
- No drop shadow
- Custom naming

</td>
<td>

### Input
- Fast key repeat rate
- Short delay until repeat
- Tap to click (trackpad)
- Natural scrolling

</td>
</tr>
</table>

**Protection:** Creates `~/.macos-defaults-applied` flag to prevent accidental re-runs.

---

## ☁️ Mackup - Settings Sync

Mackup backs up app settings to iCloud, syncing across machines.

### First Machine Setup

```bash
# After installing apps
mackup backup
```

**Syncs:**
- VS Code (extensions, keybindings, settings)
- iTerm2 (profiles, colors)
- SSH config
- Git config
- App preferences (500+ apps supported)

### New Machine Restore

```bash
# After bootstrap.sh
mackup restore
```

All settings instantly restored. Magic. ✨

**Configuration:** `.mackup.cfg`
```ini
[storage]
engine = icloud

[applications_to_sync]
vscode
iterm2
ssh
```

**Supported apps:** [See full list](https://github.com/lra/mackup#supported-applications)

---

## 🔄 Maintenance & Updates

### Update Everything

```bash
dotfiles-update  # Updates dotfiles + Homebrew packages
```

**What it does:**
1. `cd ~/dotfiles && git pull`
2. `./install.sh` (re-symlink new files)
3. `brew update && brew upgrade`

### Update Components Individually

```bash
# Update Homebrew packages
brew update && brew upgrade

# Update asdf plugins
asdf plugin update --all

# Update Node/Python versions
# 1. Edit .tool-versions
# 2. Run:
asdf install
```

### Version Management

```bash
# Check installed versions
asdf current

# Install new Node version
asdf install nodejs 20.11.0
asdf global nodejs 20.11.0

# Install new Python version
asdf install python 3.12.1
asdf global python 3.12.1
```

---

## 🔧 Customization Guide

### Add Your Own Dotfiles

1. Add file to `~/dotfiles/` (e.g., `.vimrc`)
2. Edit `install.sh`, add filename to `files` array:
   ```bash
   files=(".gitconfig" ".zshrc" ".vimrc")  # Add yours
   ```
3. Run `./install.sh`

### Modify Installed Apps

Edit `Brewfile`:
```ruby
# Add new formula
brew "neovim"

# Add new cask
cask "visual-studio-code"

# Remove line for apps you don't want
```

Run:
```bash
brew bundle --file=~/dotfiles/Brewfile
```

### Add Custom Shell Functions

Edit `functions.zsh`:
```bash
# Add your function
myfunction() {
  echo "Hello from custom function"
}
```

Reload: `source ~/.zshrc`

---

## 🐛 Troubleshooting

<details>
<summary><b>Bootstrap fails at Xcode installation</b></summary>

**Symptom:** Script exits after "Installing Xcode Command Line Tools..."

**Solution:**
```bash
# Install manually
xcode-select --install

# Wait for installation to complete, then:
./bootstrap.sh
```

</details>

<details>
<summary><b>Homebrew not in PATH</b></summary>

**Symptom:** `command not found: brew`

**Solution (Apple Silicon):**
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Solution (Intel):**
```bash
eval "$(/usr/local/bin/brew shellenv)"
```

**Permanent fix:** Add to `~/.zprofile` (bootstrap does this automatically)

</details>

<details>
<summary><b>asdf command not found</b></summary>

**Symptom:** `command not found: asdf`

**Solution:**
```bash
# Reload shell configuration
source ~/.zshrc

# Or open new terminal tab
```

</details>

<details>
<summary><b>Git user not configured</b></summary>

**Symptom:** Git complains about missing user name/email

**Solution:**
```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

Or edit `~/.gitconfig` directly.

</details>

<details>
<summary><b>Homebrew cask adoption error</b></summary>

**Symptom:** `It seems there is already an App at '/Applications/Docker.app'`

**Solution:** Bootstrap script prevents this! But if you encounter it:

```bash
# Option 1: Uninstall manually-installed app
rm -rf "/Applications/Docker.app"

# Option 2: Let Homebrew adopt it
brew reinstall --cask docker --force

# Option 3: Remove from Brewfile (edit ~/dotfiles/Brewfile)
```

</details>

<details>
<summary><b>Docker databases won't start</b></summary>

**Symptom:** `docker compose up` fails

**Solution:**
```bash
# 1. Ensure Docker Desktop is running
open /Applications/Docker.app

# 2. Wait for Docker to start (whale icon in menu bar)

# 3. Restart containers
cd ~/dotfiles
docker compose down
docker compose up -d
```

</details>

<details>
<summary><b>Mac App Store purchases not installing</b></summary>

**Symptom:** `mas` commands fail for Things 3, Amphetamine

**Solution:**
1. Open App Store
2. System Settings → Media & Purchases → Sign In
3. Re-run bootstrap: `./bootstrap.sh`

</details>

---

## 🎓 Advanced Usage

### Backup Before Running

```bash
# Backup existing configs
cp ~/.zshrc ~/.zshrc.backup
cp ~/.gitconfig ~/.gitconfig.backup
cp ~/.ssh/config ~/.ssh/config.backup
```

**Note:** `install.sh` creates timestamped backups automatically:
```
~/.zshrc.backup.2024-01-15-143022
```

### Selective Installation

```bash
# Just symlink dotfiles (skip Homebrew)
./install.sh

# Just apply macOS defaults
./macos.sh

# Just guided auth setup
./auth-setup.sh
```

### Custom Brewfile Location

```bash
# Install from custom Brewfile
brew bundle --file=/path/to/custom/Brewfile
```

### Force Re-run Steps

```bash
# Re-apply macOS defaults
rm ~/.macos-defaults-applied
./macos.sh

# Re-check for updates immediately
rm ~/dotfiles/.last-update-check
source ~/.zshrc
```

---

## 📊 What Happens on First Run

```mermaid
gantt
    title Bootstrap Timeline (Fresh Mac)
    dateFormat X
    axisFormat %M:%S

    section Setup
    Prompt for info           :0, 30s
    Install Xcode Tools      :30s, 5min
    Install Homebrew         :5min, 2min

    section Apps
    Scan Applications        :7min, 30s
    Filter Brewfile          :7.5min, 15s
    Install Apps (40+)       :8min, 5min

    section Config
    Setup asdf               :13min, 1min
    Symlink dotfiles         :14min, 15s
    Apply macOS defaults     :14.25min, 30s

    section Auth
    Offer auth-setup         :15min, 0s
```

**Total time:** ~15 minutes (varies by network speed)

---

## 🛡 Security & Best Practices

### What This Repo NEVER Contains

- ❌ Hardcoded credentials
- ❌ API keys or tokens
- ❌ SSH private keys
- ❌ `.env` files with secrets

### What's Safe to Track

- ✅ Shell configuration
- ✅ Git aliases & settings (no credentials)
- ✅ Tool version pins
- ✅ Application lists

### Handling Secrets

```bash
# Use ~/.zshrc.local for secrets (not tracked)
echo 'export API_KEY="secret"' >> ~/.zshrc.local

# Use environment-specific .env files
# Add to .gitignore
```

### SSH Key Management

```bash
# Generate new key (via auth-setup.sh or manually)
ssh-keygen -t ed25519 -C "your@email.com"

# Add to SSH agent
ssh-add ~/.ssh/id_ed25519

# Upload to GitHub (auth-setup.sh does this)
gh ssh-key add ~/.ssh/id_ed25519.pub --title "MacBook Pro"
```

---

## 🏆 Why This Approach Wins

<table>
<tr>
<td width="50%">

### Traditional Dotfiles
- ⚠️ Manual dependency installation
- ⚠️ Homebrew adoption errors
- ⚠️ Forgotten auth steps
- ⚠️ Broken on re-runs
- ⚠️ No update mechanism

</td>
<td width="50%">

### This System
- ✅ Fully automated from clone to complete
- ✅ Intelligent app detection
- ✅ Guided authentication
- ✅ Infinite idempotency
- ✅ Auto-update checking

</td>
</tr>
</table>

**Result:** Clone repo → Run one script → Start coding

---

## 🎯 Real-World Impact

### Case Study 1: Emergency Mac Replacement

**Scenario:** MacBook Pro died during conference talk prep (Friday 6 PM)

**Old approach:**
- Weekend lost rebuilding environment
- Missed deadline
- Frantic Slack messages asking "how did I configure X again?"

**With this system:**
```
6:00 PM  MacBook won't boot (kernel panic)
6:15 PM  Apple Store - new MacBook Pro purchased
6:30 PM  git clone dotfiles + ./bootstrap.sh
6:45 PM  Apps still downloading, but work environment ready
7:00 PM  Back to work on conference slides
```

**Result:** Lost 1 hour instead of 1 weekend. Made deadline. Zero stress.

---

### Case Study 2: Onboarding New Teammate

**Scenario:** New engineer starts Monday, needs dev environment

**Old way:**
- 2-day setup process
- 50+ Slack questions
- Version mismatches with team (Node 16 vs Node 18)
- Missing tools discovered weeks later

**New way:**
1. Fork this repo
2. Add company-specific tools to Brewfile
3. Customize `.zshrc.local` with work paths
4. Run bootstrap

**Result:**
- 30 minutes setup
- Zero questions
- Identical environment to rest of team
- Started shipping code afternoon of Day 1

---

### Case Study 3: Testing Across Mac Generations

**Scenario:** Bug only appears on Intel Mac, team uses M1/M2

**Old approach:**
- Borrow hardware from another team
- Wait days for availability
- Manual setup on borrowed machine
- Return hardware, lose test environment

**With this system:**
```bash
# Using Multipass VM (included in Brewfile)
multipass launch --name test-intel
multipass shell test-intel
git clone dotfiles && cd dotfiles && ./bootstrap.sh
```

**Result:** Reproduced exact environment in 20 minutes. No hardware dependency. Disposable test environment.

---

### Case Study 4: Recovering From Bad Brew Update

**Scenario:** `brew upgrade` broke Python, projects won't run

**Without version pinning:**
- Hours debugging Python compatibility
- `pip install` failures across all projects
- Reverting Homebrew packages manually

**With asdf + .tool-versions:**
```bash
# Disaster happens
brew upgrade  # Oops, Python 3.12 breaks everything

# Recovery
cd ~/dotfiles
git checkout .tool-versions  # Restore pinned versions
asdf install  # Reinstall correct versions
```

**Result:** Back to working state in 2 minutes. Version pins saved from Python dependency hell.

---

### By The Numbers

- **14** Mac setups over 5 years
- **40+** applications installed automatically
- **70+** CLI tools configured
- **15 minutes** average bootstrap time
- **Zero** manual steps required
- **100%** idempotent (safe to re-run infinitely)
- **18 minutes** fastest Mac clone (emergency replacement)

---

## ❓ Frequently Asked Questions

<details>
<summary><b>Can I use this on multiple Macs?</b></summary>

**Yes, that's the primary use case.**

I use it across 4 machines (work MacBook, personal MacBook, Mac Mini, test VM). The Mackup integration keeps app settings synced automatically.

**Workflow:**
1. Make changes on Mac A
2. `prepare-sync.sh` → pushes to GitHub
3. Mac B receives notification
4. `dotfiles-update` → instantly synced

</details>

<details>
<summary><b>What if I don't want all these apps?</b></summary>

**Easy - edit the Brewfile.**

Remove lines for apps you don't need:
```ruby
# Don't want Docker?
# cask "docker"  ← Comment it out

# Don't want Spotify?
# cask "spotify"  ← Remove the line
```

Bootstrap will skip them. No other changes needed.

</details>

<details>
<summary><b>How do I keep this updated?</b></summary>

**Automatically.**

Your shell checks for updates daily and notifies you:
```
📦 Dotfiles Update Available
   Run: dotfiles-update
```

When ready, run `dotfiles-update` to sync.

**Manual check:**
```bash
cd ~/dotfiles && git pull
```

</details>

<details>
<summary><b>What about secrets (API keys, passwords)?</b></summary>

**Never committed.**

Use `~/.zshrc.local` for machine-specific secrets (gitignored):
```bash
# ~/.zshrc.local
export OPENAI_API_KEY="sk-..."
export GITHUB_TOKEN="ghp_..."
```

Or use 1Password CLI integration. Secrets never touch this repo.

</details>

<details>
<summary><b>Can I share this with my team?</b></summary>

**Absolutely.**

Perfect for standardized dev environments:

1. Fork this repo
2. Customize Brewfile for team tools
3. Add company-specific aliases to `aliases.zsh`
4. Team members clone and run bootstrap

**Result:** Everyone has identical environment. "Works on my machine" problems disappear.

</details>

<details>
<summary><b>What if bootstrap fails halfway?</b></summary>

**Safe to re-run.**

All scripts are idempotent. They'll pick up where they left off.

**Common failure points:**
- **Xcode Tools:** Takes 5 min, may timeout → Re-run after install completes
- **App Store:** Not signed in → Sign in, re-run bootstrap
- **Homebrew:** Slow network → Will resume from last successful install

Just run `./bootstrap.sh` again. It won't duplicate anything.

</details>

<details>
<summary><b>How do I customize shell functions?</b></summary>

**Edit `functions.zsh`:**

```bash
# Add your function
myfunction() {
  echo "Hello from custom function"
}
```

Then reload:
```bash
source ~/.zshrc
```

Or use `~/.zshrc.local` for machine-specific functions (not synced).

</details>

<details>
<summary><b>What's the difference between asdf and Homebrew?</b></summary>

**Different purposes:**

**Homebrew** → System packages, applications, utilities
- Docker, Chrome, VS Code
- CLI tools like `jq`, `ripgrep`
- One global version

**asdf** → Programming language versions
- Node.js, Python, Ruby
- **Per-project versions** (`.tool-versions`)
- Multiple versions side-by-side

**Example:** Homebrew installs `gh` (GitHub CLI). asdf installs Node 18 for one project, Node 20 for another.

</details>

<details>
<summary><b>Can I test this in a VM before using on my Mac?</b></summary>

**Yes - use Multipass (included in Brewfile):**

```bash
# Create macOS VM
multipass launch --name test-dotfiles

# Shell into VM
multipass shell test-dotfiles

# Clone and test
git clone <your-fork> ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

Safe sandbox to experiment without touching your main Mac.

</details>

<details>
<summary><b>Why iCloud for Mackup instead of Dropbox?</b></summary>

**Trade-off decision.**

**iCloud Pro:**
- Native to macOS
- Zero configuration
- Already signed in

**iCloud Con:**
- Slower sync than Dropbox
- Less visibility into sync state

**Dropbox Pro:**
- Faster, more reliable sync
- Better sync indicators

**Dropbox Con:**
- Extra service to maintain
- Another login

**Decision:** Convenience won. Can switch by editing `.mackup.cfg`:
```ini
[storage]
engine = dropbox  # Change from icloud
```

</details>

<details>
<summary><b>What if I break something?</b></summary>

**Backups are automatic.**

Every file gets timestamped backup:
```
~/.zshrc.backup.2024-01-15-143022
```

**Restore:**
```bash
cp ~/.zshrc.backup.2024-01-15-143022 ~/.zshrc
```

**Nuclear option:**
```bash
# Remove all dotfiles
rm ~/.zshrc ~/.gitconfig

# Re-run install
cd ~/dotfiles
./install.sh
```

Nothing is permanent.

</details>

<details>
<summary><b>How much disk space does this use?</b></summary>

**Breakdown:**
- Homebrew formulas: ~500MB
- Applications (40+): ~8GB
- Docker Desktop: ~2GB
- Dev databases: ~500MB (when running)
- asdf tools: ~1GB

**Total:** ~12GB

On modern Macs (256GB+), this is <5% of storage.

</details>

<details>
<summary><b>Does this work on Intel Macs?</b></summary>

**Yes, fully tested.**

Bootstrap detects CPU architecture and adjusts:
- Apple Silicon: `/opt/homebrew`
- Intel: `/usr/local/Homebrew`

Scripts work on both. Some apps install slower on Intel (no Apple Silicon optimizations), but everything functions.

</details>

---

## 📚 Further Reading

### This Repository
- **[DECISIONS.md](./DECISIONS.md)** - Architecture decision records (why choices were made)
- **[QUICKSTART.md](./QUICKSTART.md)** - Fast-track setup guide
- **[SECURITY.md](./SECURITY.md)** - Security practices and secrets management
- **[MACKUP.md](./MACKUP.md)** - App settings sync deep dive
- **[CHANGELOG.md](./CHANGELOG.md)** - Version history and changes

### External Resources
- [Homebrew Documentation](https://docs.brew.sh)
- [asdf Version Manager](https://asdf-vm.com)
- [Mackup App List](https://github.com/lra/mackup#supported-applications)
- [ZSH Configuration Guide](https://zsh.sourceforge.io/Doc/)
- [Mermaid Diagram Syntax](https://mermaid.js.org)

---

## 📄 License

MIT - Fork it, customize it, share it.

---

<div align="center">

**Built for developers who value their time**

*Because setting up a new Mac shouldn't take a week*

---

[Report Bug](https://github.com/sethwebster/dotfiles/issues) · [Request Feature](https://github.com/sethwebster/dotfiles/issues) · [Contribute](https://github.com/sethwebster/dotfiles/pulls)

</div>



================================================
FILE: AGENT-WORKSPACE.md
================================================
# Agent Workspace Instructions

**This file contains workspace-specific context for AI agents working in this repository.**

## Quick Start

When you start working in this workspace:

1. Read the general guidelines in [AGENTS.md](./AGENTS.md)
2. Read this file for workspace-specific context
3. Review recent commits to understand current work

## Workspace Context

### Repository Information

- **Repository**: Personal macOS dotfiles — intelligent environment automation for macOS
- **Primary Language**: Bash (all core scripts), ZSH (shell config)
- **Package Manager**: Homebrew (apps/tools), asdf (language runtimes)
- **Purpose**: Clone a complete Mac development environment in ~15 minutes with zero manual steps

### Key Files

```
dotfiles/
├── bootstrap.sh          # Main orchestrator — run this on a fresh Mac
├── install.sh            # Symlink manager (idempotent)
├── auth-setup.sh         # Guided GitHub/Expo/SSH authentication
├── prepare-sync.sh       # Capture current Mac state before cloning
├── macos.sh              # macOS system preferences automation
├── Brewfile              # All Homebrew formulas, casks, and mas apps
├── docker-compose.yml    # Local dev databases (PostgreSQL + Redis)
│
├── .zshrc                # ZSH entry point — sources all modules
├── path.zsh              # PATH configuration
├── aliases.zsh           # Shell aliases (gs, ga, gc, ll, dc, etc.)
├── functions.zsh         # Custom functions (mkcd, extract, portkill, etc.)
├── check-updates.zsh     # 24-hour update check (non-blocking)
│
├── .gitconfig            # Git configuration and aliases
├── .tool-versions        # asdf version pins (Node, Python)
├── .mackup.cfg           # App settings sync via iCloud
│
├── DECISIONS.md          # Architecture decision records
├── CHANGELOG.md          # Version history
├── SECURITY.md           # Security practices
└── MACKUP.md             # Mackup deep dive
```

### Development Commands

```bash
# Fresh Mac setup
./bootstrap.sh

# Re-symlink dotfiles only (safe to re-run)
./install.sh

# Apply macOS system preferences
./macos.sh

# Guided auth setup (GitHub CLI, Expo, SSH)
./auth-setup.sh

# Capture current Mac state + push to GitHub
./prepare-sync.sh

# Update dotfiles + Homebrew
dotfiles-update

# Start local dev databases
cd ~/dotfiles && docker compose up -d
```

## Critical Invariants

### All Scripts Must Be Idempotent

**UNBREACHABLE CONSTRAINT**: Every script must be safe to run multiple times with the same result.

- Check before acting — skip if already done
- Never overwrite without backing up (`*.backup.YYYYMMDD_HHMMSS`)
- Use flags (e.g., `~/.macos-defaults-applied`) for one-time operations

```bash
# ✅ CORRECT - Check before acting
if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
  log_success "$file already linked"
  continue
fi

# ❌ WRONG - Blindly overwrite
ln -sf "$source" "$target"
```

### Smart App Detection Pattern

Bootstrap scans `/Applications` before `brew bundle` to avoid adoption errors. Any changes to Brewfile cask additions must maintain a corresponding entry in the cask-to-app-name mapping table in `bootstrap.sh`.

```bash
# Mapping format: cask-name → App Bundle Name
if [ -d "/Applications/Docker.app" ]; then
  # Exclude docker from filtered Brewfile
fi
```

### No Secrets in Repo

- Never commit credentials, tokens, API keys, or SSH private keys
- Machine-specific secrets → `~/.zshrc.local` (gitignored)
- `install.sh` symlinks tracked dotfiles only

## Project-Specific Guidelines

### Tech Stack

- **Shell**: ZSH with modular config (`.zshrc` sources `path.zsh`, `aliases.zsh`, `functions.zsh`, `check-updates.zsh`)
- **Package management**: Homebrew for system packages/apps, asdf for language runtimes
- **Settings sync**: Mackup via iCloud
- **Local databases**: Docker Compose (PostgreSQL port 5432, Redis port 6379)
- **No frontend, no backend, no database schema** — this is shell infrastructure only

### Environment Setup

No environment variables required to work in this repo. Machine-specific vars go in `~/.zshrc.local`.

### Testing Strategy

- No automated test suite
- Idempotency is the primary correctness guarantee — test by running scripts twice
- Validate by running on a fresh macOS environment (Multipass VM or actual new Mac)

### Editing Shell Files

- `aliases.zsh` — add aliases here (short command shortcuts)
- `functions.zsh` — add functions here (multi-line logic)
- `path.zsh` — add PATH entries here only
- `check-updates.zsh` — do not modify unless changing update check behavior
- `.zshrc` — orchestrator only; sources modules, sets environment vars, configures plugins

### Adding to Brewfile

```ruby
# Formula (CLI tool)
brew "tool-name"

# Cask (GUI app)
cask "app-name"

# Mac App Store
mas "App Name", id: 123456789
```

After adding a cask, add the app-bundle mapping to `bootstrap.sh`'s detection block.

### Symlinked Files

Files symlinked by `install.sh` to `~/`:
- `.zshrc`, `path.zsh`, `aliases.zsh`, `functions.zsh`, `check-updates.zsh`
- `.tool-versions`, `.mackup.cfg`, `.nanorc`

To add a new symlinked file: add filename to the `files` array in `install.sh`.

## Common Pitfalls

- **Don't use `brew bundle --force`** — bootstrap's app detection exists to avoid this
- **Don't edit `.zshrc` for new commands** — put aliases in `aliases.zsh`, functions in `functions.zsh`
- **Don't hardcode paths** — use `$HOME`, `$DOTFILES_DIR`, etc.
- **Don't skip the idempotency check** — running twice must produce same result
- **Don't commit `~/.zshrc.local`** — it's gitignored for a reason (machine-specific secrets)

## Current Work

Check `git log --oneline -10` for recent changes. No standing active features.

---

**Note**: Keep this file updated as the project evolves.



================================================
FILE: aliases.zsh
================================================
# Command aliases

# Modern CLI replacements
alias ll='eza -la --git'
alias ls='eza'
alias cat='bat'
alias vim='nvim'
# Note: 'j' command provided by autojump (initialized in .zshrc)

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gcane='git commit --amend --no-edit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gm='git merge'
alias grb='git rebase'
alias grbi='git rebase -i'
alias gf='git fetch'
alias gsh='git stash'
alias gshp='git stash pop'
alias gcp='git cherry-pick'
alias grh='git reset HEAD~'
alias gundo='git reset --soft HEAD~1'
alias gclean='git clean -fd'
alias glog='git log --oneline --graph --decorate'

# Docker aliases
alias dc='docker compose'
alias dcu='docker compose up'
alias dcd='docker compose down'
alias dcb='docker compose build'
alias dcl='docker compose logs'
alias dclf='docker compose logs -f'
alias dce='docker compose exec'
alias dcr='docker compose restart'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dprune='docker system prune -af'

# Shortcuts
alias zshconfig='$EDITOR ~/.zshrc'
alias help='use-my-mac'

# Dotfiles shortcut (derives location from .zshrc symlink)
dotfiles() {
    if [ -L "${HOME}/.zshrc" ]; then
        cd "$(dirname "$(readlink "${HOME}/.zshrc")")"
    else
        cd "${HOME}/dotfiles"
    fi
}

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# System Utilities
alias c='clear'
alias h='history | tail -20'
alias path='echo $PATH | tr ":" "\n"'
alias myip='curl ifconfig.me'
alias localip='ipconfig getifaddr en0'
alias cleanup='find . -name ".DS_Store" -delete'
alias hosts='sudo nvim /etc/hosts'
alias brewup='brew update && brew upgrade && brew cleanup'

# Network Diagnostics
alias domaininfo='bun /Users/sethwebster/dotfiles/scripts/domain-info.ts'

# Claude
_claude_bin() {
  local bin="${HOME}/.local/bin/claude"
  if [[ -x "$bin" ]]; then
    echo "$bin"
  else
    find /opt/homebrew/Caskroom/claude-code -maxdepth 2 -name "claude" -type f 2>/dev/null | sort -V | tail -1
  fi
}
claude() {
  local bin
  bin=$(_claude_bin)
  [[ -z "$bin" ]] && { echo "claude: binary not found" >&2; return 1; }
  "$bin" --dangerously-skip-permissions "$@"
}
claude-safe() {
  local bin
  bin=$(_claude_bin)
  [[ -z "$bin" ]] && { echo "claude: binary not found" >&2; return 1; }
  "$bin" "$@"
}
alias cc='claude'
alias cc-safe='claude-safe'

# Bun shortcuts
alias br='bun run'
alias bi='bun install'
alias ba='bun add'
alias brm='bun remove'
alias bt='bun test'



================================================
FILE: auth-setup.sh
================================================
#!/usr/bin/env bash
# Authentication setup helper
# Guides you through authenticating various services

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}==>${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

echo ""
log_info "Authentication Setup Helper"
log_info "=============================="
echo ""
log_warning "This script will guide you through authenticating various services."
log_warning "Some steps require manual intervention."
echo ""

# ==============================================================================
# 1. SSH KEY (first — needed for GitHub SSH auth)
# ==============================================================================
echo ""
log_info "SSH Key Setup"
if [ -f ~/.ssh/id_ed25519.pub ]; then
    log_success "SSH key already exists"
    echo ""
    echo "Your public key:"
    cat ~/.ssh/id_ed25519.pub
    echo ""
else
    read -p "Generate new SSH key? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter your email: " ssh_email
        ssh-keygen -t ed25519 -C "$ssh_email" -f ~/.ssh/id_ed25519 -N ""
        eval "$(ssh-agent -s)"
        ssh-add --apple-use-keychain ~/.ssh/id_ed25519
        log_success "SSH key generated"
        echo ""
        echo "Your public key:"
        cat ~/.ssh/id_ed25519.pub
        echo ""
    fi
fi

# ==============================================================================
# 2. GITHUB CLI (second — lets us upload SSH key right after)
# ==============================================================================
if command -v gh &> /dev/null; then
    echo ""
    log_info "GitHub CLI Authentication"
    if gh auth status &> /dev/null; then
        log_success "Already authenticated with GitHub"
    else
        read -p "Authenticate with GitHub? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            gh auth login
            log_success "GitHub authenticated"
        fi
    fi

    # Upload SSH key to GitHub if we have one and are authenticated
    if [ -f ~/.ssh/id_ed25519.pub ] && gh auth status &> /dev/null; then
        # Check if key is already on GitHub
        key_content=$(cat ~/.ssh/id_ed25519.pub | awk '{print $2}')
        if gh ssh-key list 2>/dev/null | grep -q "$key_content"; then
            log_success "SSH key already on GitHub"
        else
            read -p "Upload SSH key to GitHub? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                default_title="$(scutil --get ComputerName 2>/dev/null || hostname)"
                read -p "Key title [$default_title]: " key_title
                key_title="${key_title:-$default_title}"
                gh ssh-key add ~/.ssh/id_ed25519.pub --title "$key_title"
                log_success "SSH key uploaded to GitHub"
            fi
        fi
    fi
else
    log_warning "GitHub CLI not installed. Run bootstrap.sh first."
fi

# ==============================================================================
# 3. DOCKER
# ==============================================================================
if command -v docker &> /dev/null; then
    echo ""
    log_info "Docker"
    if ! docker info &> /dev/null; then
        log_warning "Docker Desktop is not running — start it, then re-run this script"
    else
        log_success "Docker is running"
        read -p "Log in to Docker Hub? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker login
            log_success "Docker Hub authenticated"
        fi
    fi
else
    log_warning "Docker not installed. Run bootstrap.sh first."
fi

# ==============================================================================
# 4. EXPO
# ==============================================================================
if command -v npx &> /dev/null; then
    echo ""
    log_info "Expo Authentication"
    read -p "Authenticate with Expo? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        npx expo login
        log_success "Expo authenticated"
    fi
else
    log_warning "Node/npx not available. Install Node first."
fi

# ==============================================================================
# Manual steps reminder
# ==============================================================================
echo ""
log_info "=============================="
log_info "Manual Steps Remaining"
log_info "=============================="
echo ""
log_warning "Please complete these manually:"
echo "  1. Sign into Apple ID (System Settings > Apple ID)"
echo "  2. Sign into Adobe Creative Cloud"
echo "  3. Sign into Tailscale"
echo "  4. Import browser bookmarks/settings"
echo ""
log_success "Authentication setup complete!"
echo ""



================================================
FILE: bootstrap.sh
================================================
#!/usr/bin/env bash
# Seth's Mac Bootstrap Script
# Run this on a fresh Mac to set everything up
# This script is idempotent - safe to run multiple times

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}==>${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Get the dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
log_info "========================================"
log_info "Mac Bootstrap Script"
log_info "========================================"
echo ""
log_info "Starting Mac bootstrap from ${DOTFILES_DIR}"
echo ""

# ==============================================================================
# GIT CONFIGURATION (MUST happen early, before any potentially failing commands)
# ==============================================================================
#
# Why here? With set -e, if brew/asdf/etc fails later, script exits immediately.
# Git config at the end of the script = never written if anything fails first.
# Solution: Write config IMMEDIATELY after collecting it.
#
# Why check for git binary? On fresh Mac, git doesn't exist until Xcode CLT installed.
# If git unavailable, we still collect info and write it later (after Xcode).
# ==============================================================================

GIT_AVAILABLE=false
if command -v git &> /dev/null; then
    GIT_AVAILABLE=true
fi

# Check existing config (only if git available)
GIT_NAME=""
GIT_EMAIL=""
if [ "$GIT_AVAILABLE" = true ]; then
    GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
    GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
fi

# Debug: Show what we found
if [ -n "$GIT_NAME" ]; then
    log_info "Found existing git name: $GIT_NAME"
fi
if [ -n "$GIT_EMAIL" ]; then
    log_info "Found existing git email: $GIT_EMAIL"
fi

# Collect git info if needed
if [ -z "${GIT_NAME}" ] || [ -z "${GIT_EMAIL}" ]; then
    log_info "First, let's collect some information..."
    log_info "(Required for Git commits - stored in ~/.gitconfig)"
    echo ""
    log_warning "Git user information not configured"

    if [ -z "${GIT_NAME}" ]; then
        read -p "Enter your full name (for Git commits): " GIT_NAME
    else
        log_success "Using existing Git name: $GIT_NAME"
    fi

    if [ -z "${GIT_EMAIL}" ]; then
        read -p "Enter your email (for Git commits): " GIT_EMAIL
    else
        log_success "Using existing Git email: $GIT_EMAIL"
    fi

    echo ""
else
    log_success "Git already configured: $GIT_NAME <$GIT_EMAIL>"
    echo ""
fi

# CRITICAL: Write git config IMMEDIATELY if git is available
# This ensures config persists even if script fails later
if [ "$GIT_AVAILABLE" = true ] && [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
    # Create ~/.gitconfig if it doesn't exist
    if [ ! -f ~/.gitconfig ]; then
        touch ~/.gitconfig
        log_info "Created ~/.gitconfig"
    fi

    # Write user.name if not already correct
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    if [ "$current_name" != "$GIT_NAME" ]; then
        git config --global user.name "$GIT_NAME"
        log_success "Set git user.name: $GIT_NAME"
    fi

    # Write user.email if not already correct
    current_email=$(git config --global user.email 2>/dev/null || echo "")
    if [ "$current_email" != "$GIT_EMAIL" ]; then
        git config --global user.email "$GIT_EMAIL"
        log_success "Set git user.email: $GIT_EMAIL"
    fi

    # Add include directive for dotfiles/.gitconfig (use ~ for portability)
    if [ -f "${DOTFILES_DIR}/.gitconfig" ]; then
        # Use ~/dotfiles path for portability across machines/usernames
        if ! grep -q 'path = ~/dotfiles/.gitconfig' ~/.gitconfig 2>/dev/null; then
            # Remove any existing absolute path includes for dotfiles
            sed -i '' '/path = .*dotfiles\/.gitconfig/d' ~/.gitconfig 2>/dev/null || true
            # Remove empty [include] sections
            sed -i '' '/^\[include\]$/{N;/^\[include\]\n$/d;}' ~/.gitconfig 2>/dev/null || true
            # Add portable include
            printf '\n[include]\n\tpath = ~/dotfiles/.gitconfig\n' >> ~/.gitconfig
            log_success "Set include.path: ~/dotfiles/.gitconfig"
        fi
    fi

    log_success "Git configuration complete"
    echo ""
elif [ "$GIT_AVAILABLE" = false ]; then
    log_warning "Git not available yet - config will be written after Xcode installation"
    log_info "Values collected: $GIT_NAME <$GIT_EMAIL>"
    echo ""
fi

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    log_error "This script is only for macOS"
    exit 1
fi

# Install Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    log_info "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo ""
    log_warning "MANUAL STEP REQUIRED:"
    log_warning "1. Complete the Xcode installation popup"
    log_warning "2. Wait for 'The software was installed' message"
    log_warning "3. Re-run this script: ./bootstrap.sh"
    echo ""
    log_info "Script will exit now. See you in ~5 minutes!"
    exit 0
else
    log_success "Xcode Command Line Tools installed"

    # xcodebuild is unavailable on Command Line Tools-only installs.
    # Only run license acceptance when full Xcode is installed.
    if [ -d "/Applications/Xcode.app" ]; then
        if ! sudo xcodebuild -license check &> /dev/null; then
            log_info "Accepting Xcode license agreement..."
            sudo xcodebuild -license accept
            log_success "Xcode license accepted"
        fi
    else
        log_info "Full Xcode not detected; skipping Xcode license acceptance (CLT-only is OK)"
    fi

    # Now that Xcode is installed, write git config if we collected it earlier but couldn't write
    # This handles the case where git wasn't available on first pass (before Xcode)
    if [ "$GIT_AVAILABLE" = false ] && [ -n "$GIT_NAME" ] && [ -n "$GIT_EMAIL" ]; then
        log_info "Git now available - writing collected configuration..."

        # Create ~/.gitconfig if needed
        if [ ! -f ~/.gitconfig ]; then
            touch ~/.gitconfig
            log_info "Created ~/.gitconfig"
        fi

        git config --global user.name "$GIT_NAME"
        log_success "Set git user.name: $GIT_NAME"

        git config --global user.email "$GIT_EMAIL"
        log_success "Set git user.email: $GIT_EMAIL"

        # Add include directive (use ~ for portability)
        if [ -f "${DOTFILES_DIR}/.gitconfig" ]; then
            if ! grep -q 'path = ~/dotfiles/.gitconfig' ~/.gitconfig 2>/dev/null; then
                printf '\n[include]\n\tpath = ~/dotfiles/.gitconfig\n' >> ~/.gitconfig
                log_success "Set include.path: ~/dotfiles/.gitconfig"
            fi
        fi

        GIT_AVAILABLE=true
        log_success "Git configuration complete"
        echo ""
    fi
fi

# Install Homebrew
if ! command -v brew &> /dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ $(uname -m) == 'arm64' ]]; then
        # Only add if not already present
        if ! grep -q "/opt/homebrew/bin/brew shellenv" ~/.zprofile 2>/dev/null; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        fi
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    log_success "Homebrew installed"
else
    log_success "Homebrew already installed"
fi

# Update Homebrew
log_info "Updating Homebrew (this may take a minute)..."
brew update --quiet 2>&1 | grep -v "^Already up-to-date" || log_success "Homebrew updated"

# Install mas (Mac App Store CLI) first if not present
if ! command -v mas &> /dev/null; then
    log_info "Installing mas (Mac App Store CLI)..."
    brew install mas
    log_success "mas installed"
else
    log_success "mas already installed"
fi

# Verify App Store sign-in (mas account can be unreliable)
if ! mas account &> /dev/null; then
    log_warning "Cannot verify Mac App Store sign-in"
    echo ""
    log_info "Some apps require App Store authentication:"
    log_info "  - Things 3 (task manager)"
    log_info "  - Amphetamine (prevent sleep)"
    log_info "  - Bear, Fantastical, etc."
    echo ""
    log_info "To sign in: System Settings > Media & Purchases > Sign In"
    echo ""
    read -p "Are you signed into the App Store? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "App Store apps will be skipped (install manually later)"
        log_info "You can re-run bootstrap after signing in to retry"
    else
        log_success "Proceeding with App Store apps"
    fi
    echo ""
fi

# Install from Brewfile
if [ -f "${DOTFILES_DIR}/Brewfile" ]; then
    log_info "Checking which apps are already installed..."

    # Create temporary filtered Brewfile excluding manually-installed casks
    TEMP_BREWFILE=$(mktemp)

    # Copy Brewfile, filtering out casks where app already exists
    while IFS= read -r line; do
        # Check if line is a cask declaration
        if [[ "$line" =~ ^cask[[:space:]]+\"([^\"]+)\" ]]; then
            cask_name="${BASH_REMATCH[1]}"

            # Map cask name to app name (what appears in /Applications)
            case "$cask_name" in
                docker) app_name="Docker" ;;
                cursor) app_name="Cursor" ;;
                visual-studio-code) app_name="Visual Studio Code" ;;
                google-chrome) app_name="Google Chrome" ;;
                arc) app_name="Arc" ;;
                firefox) app_name="Firefox" ;;
                brave-browser) app_name="Brave Browser" ;;
                claude-code) app_name="Claude Code" ;;
                claude) app_name="Claude" ;;
                chatgpt) app_name="ChatGPT" ;;
                slack) app_name="Slack" ;;
                discord) app_name="Discord" ;;
                notion) app_name="Notion" ;;
                zoom) app_name="zoom.us" ;;
                raycast) app_name="Raycast" ;;
                alfred) app_name="Alfred 5" ;;
                obsidian) app_name="Obsidian" ;;
                bear) app_name="Bear" ;;
                fantastical) app_name="Fantastical" ;;
                signal) app_name="Signal" ;;
                whatsapp) app_name="WhatsApp" ;;
                beeper) app_name="Beeper Desktop" ;;
                1password) app_name="1Password" ;;
                rectangle) app_name="Rectangle" ;;
                multipass) app_name="Multipass" ;;
                cleanshot) app_name="CleanShot X" ;;
                ngrok) app_name="ngrok" ;;
                the-unarchiver) app_name="The Unarchiver" ;;
                dropbox) app_name="Dropbox" ;;
                cyberduck) app_name="Cyberduck" ;;
                istat-menus) app_name="iStat Menus" ;;
                daisydisk) app_name="DaisyDisk" ;;
                figma) app_name="Figma" ;;
                blender) app_name="Blender" ;;
                spotify) app_name="Spotify" ;;
                vlc) app_name="VLC" ;;
                iterm2) app_name="iTerm" ;;
                tailscale) app_name="Tailscale" ;;
                warp) app_name="Warp" ;;
                postman) app_name="Postman" ;;
                pgadmin4) app_name="pgAdmin 4" ;;
                expo-orbit) app_name="Expo Orbit" ;;
                *) app_name="" ;;
            esac

            # Check if app already exists in /Applications
            if [ -n "$app_name" ]; then
                if [ -d "/Applications/${app_name}.app" ]; then
                    log_warning "Skipping $cask_name (already installed)"
                    echo "# Skipped: $line" >> "$TEMP_BREWFILE"
                    continue
                fi
            fi
        fi
        echo "$line" >> "$TEMP_BREWFILE"
    done < "${DOTFILES_DIR}/Brewfile"

    # Count total items to install
    total_items=$(grep -E '^(brew|cask|mas|vscode)' "$TEMP_BREWFILE" | wc -l | xargs)

    log_info "Installing apps and tools from Brewfile"
    log_info "Queued: $total_items packages/apps to install"
    log_warning "This typically takes 5-10 minutes depending on what's new..."
    log_info "Progress will appear below (Homebrew shows each item)"
    log_warning "Large apps (Docker, Xcode, Chrome) may pause 1-2 minutes - this is normal"
    log_info "You may be prompted for your password once..."
    echo ""

    # Refresh sudo timestamp to avoid multiple password prompts
    sudo -v

    # Keep sudo alive in background during long install
    log_info "Starting background sudo keepalive (prevents repeated password prompts)"
    (while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null) &
    SUDO_KEEPALIVE_PID=$!

    echo ""
    log_info "Starting Homebrew installations (verbose mode - you'll see everything)..."
    log_warning "Initial phase: Homebrew may check package info for 1-2 minutes before installations start"
    log_warning "Large downloads may take several minutes each (be patient during 'Verifying' phase)"
    echo ""

    # Use --no-upgrade to skip already-installed apps, --verbose to show progress immediately
    # Note: brew bundle can hang on parallel downloads. If stuck for >5min, Ctrl+C and re-run
    brew bundle --file="$TEMP_BREWFILE" --no-upgrade --verbose

    # node@22 is keg-only; force-link to resolve any npm file conflicts
    if brew list node@22 &>/dev/null; then
        brew link --overwrite node@22 2>/dev/null && log_success "node@22 linked" || log_warning "node@22 link failed (may need manual: brew link --overwrite node@22)"
    fi

    echo ""

    # Kill sudo keepalive
    log_info "Stopping sudo keepalive"
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    wait "$SUDO_KEEPALIVE_PID" 2>/dev/null || true

    # Clean up
    rm -f "$TEMP_BREWFILE"

    echo ""
    log_success "Brewfile installed"
else
    log_warning "Brewfile not found, skipping..."
fi

# Check for existing version managers
EXISTING_VERSION_MANAGERS=""
command -v nvm &>/dev/null && EXISTING_VERSION_MANAGERS="${EXISTING_VERSION_MANAGERS}nvm "
command -v pyenv &>/dev/null && EXISTING_VERSION_MANAGERS="${EXISTING_VERSION_MANAGERS}pyenv "
command -v rbenv &>/dev/null && EXISTING_VERSION_MANAGERS="${EXISTING_VERSION_MANAGERS}rbenv "

if [ -n "$EXISTING_VERSION_MANAGERS" ]; then
    log_warning "Found existing version managers: ${EXISTING_VERSION_MANAGERS}"
    log_warning "These may conflict with asdf. Consider migrating or skipping asdf installation."
    echo ""
    read -p "Install asdf anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping asdf installation"
    else
        if ! command -v asdf &> /dev/null; then
            log_info "Installing asdf..."
            brew install asdf
            # Note: asdf sourcing handled in path.zsh, no need to modify ~/.zshrc
            log_success "asdf installed"
        else
            log_success "asdf already installed"
        fi
    fi
else
    # Install asdf if not present and no conflicts
    if ! command -v asdf &> /dev/null; then
        log_info "Installing asdf..."
        brew install asdf
        # Note: asdf sourcing handled in path.zsh, no need to modify ~/.zshrc
        log_success "asdf installed"
    else
        log_success "asdf already installed"
    fi
fi

# Symlink dotfiles
log_info "Symlinking dotfiles..."
bash "${DOTFILES_DIR}/install.sh"

# Install asdf plugins and versions
if [ -f "${DOTFILES_DIR}/.tool-versions" ]; then
    log_info "Installing asdf tools from .tool-versions..."
    log_warning "Each tool may take 2-5 minutes to compile (especially Python/Ruby)"
    echo ""

    log_info "Tools to install:"
    # Read plugins from .tool-versions
    while IFS= read -r line; do
        if [[ ! -z "$line" && ! "$line" =~ ^# ]]; then
            plugin=$(echo "$line" | awk '{print $1}')
            version=$(echo "$line" | awk '{print $2}')

            # Add plugin if not exists
            if ! asdf plugin list | grep -q "^${plugin}$"; then
                log_info "  Adding plugin: ${plugin}"
                asdf plugin add "$plugin"
            fi

            # Check if already installed
            if asdf list "$plugin" 2>/dev/null | grep -q "$version"; then
                log_success "  $plugin $version (already installed)"
            else
                log_info "  $plugin $version (will install)"
            fi
        fi
    done < "${DOTFILES_DIR}/.tool-versions"

    echo ""
    log_info "Starting installations (this may take 5-15 minutes total)..."
    echo ""

    # Install all versions
    cd "${DOTFILES_DIR}"
    asdf install

    echo ""
    log_success "All asdf tools installed"
fi

# Set up Bun (if not via asdf)
if ! command -v bun &> /dev/null; then
    log_info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    log_success "Bun installed"
else
    log_success "Bun already installed"
fi

# Install global npm packages
if command -v npm &> /dev/null; then
    log_info "Installing global npm packages..."

    # Check if ai-cli is already installed
    if ! npm list -g @sethwebster/ai-cli &> /dev/null; then
        log_info "Installing @sethwebster/ai-cli..."
        npm install -g @sethwebster/ai-cli
        log_success "@sethwebster/ai-cli installed"
    else
        log_success "@sethwebster/ai-cli already installed"
    fi
else
    log_warning "npm not found, skipping global packages (install Node.js first)"
fi

# Configure macOS defaults
if [ -f "${DOTFILES_DIR}/macos.sh" ]; then
    if [ -f ~/.macos-defaults-applied ]; then
        log_success "macOS defaults already applied"
        log_info "(Delete ~/.macos-defaults-applied to re-apply)"
    else
        echo ""
        log_warning "macOS System Defaults Configuration"
        log_info "This will change:"
        log_info "  ✓ Finder: show hidden files, extensions, path bar"
        log_info "  ✓ Dock: auto-hide, faster animations, smaller icons"
        log_info "  ✓ Screenshots: save to ~/Screenshots as PNG"
        log_info "  ✓ Keyboard: faster key repeat, disable autocorrect"
        log_info "  ✓ Trackpad: tap to click enabled"
        echo ""
        log_warning "Some changes require restart to take effect"
        echo ""
        read -p "Apply macOS defaults? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            bash "${DOTFILES_DIR}/macos.sh"
            touch ~/.macos-defaults-applied
            log_success "macOS defaults configured"
        else
            log_info "Skipped macOS defaults configuration"
        fi
    fi
fi

# Mackup restore (restore app settings from iCloud)
if command -v mackup &> /dev/null; then
    MACKUP_ICLOUD_DIR="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Mackup"

    if [ -d "$MACKUP_ICLOUD_DIR" ]; then
        echo ""
        log_info "Mackup iCloud folder detected"
        log_info "This will restore app settings from your previous Mac"
        echo ""
        read -p "Run mackup restore? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Restoring app settings from iCloud..."
            mackup restore --force
            echo ""
            log_success "App settings restored from iCloud"
        else
            log_info "Skipped mackup restore"
            log_info "You can restore later with: mackup restore"
        fi
    else
        log_warning "Mackup iCloud folder not found"
        log_info "If this is a fresh Mac with no previous settings, ignore this"
        log_info "If cloning from another Mac, wait for iCloud sync then run: mackup restore"
    fi
else
    log_warning "Mackup not installed, skipping app settings restore"
fi

# Verify Git configuration (config was written earlier in the script)
log_info "Verifying Git configuration..."
if [ -f ~/.gitconfig ]; then
    final_name=$(git config --global user.name 2>/dev/null || echo "")
    final_email=$(git config --global user.email 2>/dev/null || echo "")
    if [ -n "$final_name" ] && [ -n "$final_email" ]; then
        log_success "Git configured: $final_name <$final_email>"
    else
        log_error "Git config file exists but user.name/email missing!"
        log_error "Run: git config --global user.name 'Your Name'"
        log_error "Run: git config --global user.email 'your@email.com'"
    fi
else
    log_error "~/.gitconfig does not exist!"
    log_error "This should not happen - please report this bug"
fi

# Post-install authentication setup
log_info "========================================"
log_info "Bootstrap complete! Next steps:"
log_info "========================================"
echo ""
log_warning "Manual authentication required:"
echo "  1. gh auth login"
echo "  2. npx expo login"
echo "  3. Sign into Apple ID in System Settings"
echo "  4. Sign into Creative Cloud"
echo "  5. Restart your terminal or run: source ~/.zshrc"
echo ""
log_success "All done! Enjoy your new Mac 🎉"
echo ""

# Offer to run auth-setup
if [ -f "${DOTFILES_DIR}/auth-setup.sh" ]; then
    read -p "Run guided authentication setup now? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        bash "${DOTFILES_DIR}/auth-setup.sh"
    else
        log_info "You can run authentication setup later with: ./auth-setup.sh"
    fi
fi



================================================
FILE: brew-update.sh
================================================
#!/bin/bash
# Daily brew catalog update

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

LOG_FILE="$HOME/.brew-update.log"

{
  echo "=== Brew update: $(date) ==="
  /opt/homebrew/bin/brew update 2>&1
  echo ""
} >> "$LOG_FILE"

# Keep log file under 1MB
if [ -f "$LOG_FILE" ] && [ "$(stat -f%z "$LOG_FILE" 2>/dev/null || echo 0)" -gt 1048576 ]; then
  tail -n 500 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi



================================================
FILE: Brewfile
================================================
tap "antoniorodr/memo"
tap "cirruslabs/cli"
tap "mczachurski/wallpapper"
tap "openhue/cli"
tap "steipete/tap"
tap "yakitrak/yakitrak"
brew "act"
brew "aom"
brew "asdf"
brew "openssl@3"
brew "python@3.11"
brew "autojump"
brew "awscli"
brew "bat"
brew "cairo"
brew "harfbuzz"
brew "bfg"
brew "cloc"
brew "cloudflared"
brew "cmake"
brew "ruby"
brew "cocoapods"
brew "coreutils"
brew "curl"
brew "docutils"
brew "libevent"
brew "folly"
brew "fizz"
brew "wangle"
brew "fbthrift"
brew "fb303"
brew "edencommon"
brew "erlang"
brew "eza"
brew "fastlane"
brew "ffmpeg"
brew "flyctl"
brew "fzf"
brew "gastown"
brew "gcc"
brew "gh"
brew "ghostscript"
brew "gifsicle"
brew "git"
brew "git-lfs"
brew "gnutls"
brew "gpgme"
brew "hdf5"
brew "htop"
brew "httpie"
brew "hub"
brew "ical-buddy"
brew "shared-mime-info"
brew "libheif"
brew "imagemagick"
brew "jq"
brew "lazygit"
brew "libgsf"
brew "libimobiledevice"
brew "libmatio"
brew "libpq"
brew "librsvg"
brew "localtunnel"
brew "mackup"
brew "mas"
brew "mkcert"
brew "molten-vk"
brew "protobuf"
brew "mosh"
brew "mozjpeg"
brew "nano"
brew "node@22"
brew "ollama"
brew "open-mpi"
brew "openslide"
brew "pandoc"
brew "poppler"
brew "postgresql@15"
brew "pure"
brew "python@3.10"
brew "redis"
brew "ripgrep"
brew "rust"
brew "scc"
brew "spoof-mac"
brew "telnet"
brew "tldr"
brew "tmux"
brew "tree"
brew "typst"
brew "uv"
brew "vips"
brew "vulkan-loader"
brew "watch"
brew "watchman"
brew "websocat"
brew "wget"
brew "yt-dlp"
brew "zoxide"
brew "antoniorodr/memo/memo"
brew "cirruslabs/cli/tart"
brew "openhue/cli/openhue-cli"
brew "steipete/tap/gogcli"
brew "steipete/tap/imsg"
brew "steipete/tap/peekaboo"
brew "steipete/tap/remindctl"
brew "steipete/tap/sag"
brew "steipete/tap/summarize"
brew "steipete/tap/wacli"
brew "yakitrak/yakitrak/obsidian-cli"
cask "arc"
cask "basictex"
cask "beeper"
cask "brave-browser"
cask "chatgpt"
cask "claude-code"
cask "cursor"
cask "docker-desktop"
cask "firefox"
cask "font-cascadia-code"
cask "font-fira-code"
cask "font-jetbrains-mono"
cask "font-meslo-lg-nerd-font"
cask "google-chrome"
cask "iterm2"
cask "miniforge"
cask "multipass"
cask "ngrok"
cask "notion"
cask "openscad"
cask "postman"
cask "visual-studio-code"
cask "tailscale"
cask "warp"
mas "Amphetamine", id: 937984704
mas "Bear", id: 1091189122
mas "Draw Things", id: 6444050820
mas "Fantastical", id: 975937182
mas "GarageBand", id: 682658836
mas "iMovie", id: 408981434
mas "Keynote", id: 409183694
mas "Kindle", id: 302584613
mas "Logic Pro", id: 634148309
mas "Numbers", id: 409203825
mas "Pages", id: 409201541
mas "Prime Video", id: 545519333
mas "SiteSucker", id: 442168834
mas "TestFlight", id: 899247664
mas "The Unarchiver", id: 425424353
mas "Things", id: 904280696
mas "WhatsApp", id: 310633997
mas "Windows App", id: 1295203466
mas "Xcode", id: 497799835
vscode "anthropic.claude-code"
vscode "bourhaouta.tailwindshades"
vscode "bradlc.vscode-tailwindcss"
vscode "codesandbox-io.codesandbox-projects"
vscode "dbaeumer.vscode-eslint"
vscode "donjayamanne.typescript-notebook"
vscode "eamodio.gitlens"
vscode "editorconfig.editorconfig"
vscode "equinusocio.vsc-material-theme"
vscode "equinusocio.vsc-material-theme-icons"
vscode "esbenp.prettier-vscode"
vscode "expo.vscode-expo-theme"
vscode "firsttris.vscode-jest-runner"
vscode "github.copilot-chat"
vscode "gruntfuggly.todo-tree"
vscode "heybourn.headwind"
vscode "jakebecker.elixir-ls"
vscode "jvitor83.types-autoinstaller"
vscode "mike-co.import-sorter"
vscode "ms-azuretools.vscode-azureresourcegroups"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-python.debugpy"
vscode "ms-python.isort"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-toolsai.jupyter-renderers"
vscode "ms-vscode-remote.remote-containers"
vscode "ms-vscode-remote.remote-ssh"
vscode "ms-vscode-remote.remote-ssh-edit"
vscode "ms-vscode.azure-account"
vscode "ms-vscode.remote-explorer"
vscode "ms-vsliveshare.vsliveshare"
vscode "nrwl.angular-console"
vscode "openai.chatgpt"
vscode "pantajoe.vscode-elixir-credo"
vscode "piersdeseilligny.betterfountain"
vscode "prisma.prisma"
vscode "redhat.vscode-yaml"
vscode "shd101wyy.markdown-preview-enhanced"
vscode "teamsdevapp.ms-teams-vscode-extension"
vscode "unifiedjs.vscode-mdx"
vscode "xyc.vscode-mdx-preview"
vscode "yzhang.markdown-all-in-one"
uv "nano-pdf"



================================================
FILE: Brewfile.backup
================================================
tap "antoniorodr/memo"
tap "cirruslabs/cli"
tap "mczachurski/wallpapper"
tap "openhue/cli"
tap "steipete/tap"
tap "yakitrak/yakitrak"
brew "act"
brew "aom"
brew "asdf"
brew "openssl@3"
brew "python@3.11"
brew "autojump"
brew "awscli"
brew "bat"
brew "cairo"
brew "harfbuzz"
brew "bfg"
brew "cloc"
brew "cmake"
brew "cocoapods"
brew "coreutils"
brew "curl"
brew "docutils"
brew "libevent"
brew "folly"
brew "fizz"
brew "wangle"
brew "fbthrift"
brew "fb303"
brew "edencommon"
brew "eza"
brew "fastlane"
brew "ffmpeg"
brew "flyctl"
brew "fzf"
brew "gcc"
brew "gh"
brew "ghostscript"
brew "gifsicle"
brew "git"
brew "git-lfs"
brew "gnutls"
brew "gpgme"
brew "hdf5"
brew "htop"
brew "httpie"
brew "hub"
brew "ical-buddy"
brew "shared-mime-info"
brew "libheif"
brew "imagemagick"
brew "jq"
brew "lazygit"
brew "libgsf"
brew "libimobiledevice"
brew "libmatio"
brew "libpq"
brew "librsvg"
brew "localtunnel"
brew "mackup"
brew "mas"
brew "molten-vk"
brew "mozjpeg"
brew "nano"
brew "node@22", link: true
brew "ollama"
brew "open-mpi"
brew "openslide"
brew "pandoc"
brew "poppler"
brew "postgresql@15"
brew "protobuf"
brew "pure"
brew "python@3.10"
brew "redis"
brew "ripgrep"
brew "rust"
brew "scc"
brew "spoof-mac"
brew "telnet"
brew "tldr"
brew "tree"
brew "typst"
brew "uv"
brew "vips"
brew "vulkan-loader"
brew "watch"
brew "watchman"
brew "websocat"
brew "wget"
brew "yt-dlp"
brew "zoxide"
brew "antoniorodr/memo/memo"
brew "cirruslabs/cli/tart"
brew "mczachurski/wallpapper/wallpapper"
brew "openhue/cli/openhue-cli"
brew "steipete/tap/bird"
brew "steipete/tap/gogcli"
brew "steipete/tap/imsg"
brew "steipete/tap/peekaboo"
brew "steipete/tap/remindctl"
brew "steipete/tap/sag"
brew "steipete/tap/summarize"
brew "steipete/tap/wacli"
brew "yakitrak/yakitrak/obsidian-cli"
cask "arc"
cask "beeper"
cask "brave-browser"
cask "chatgpt"
cask "claude-code"
cask "cursor"
cask "docker-desktop"
cask "firefox"
cask "font-cascadia-code"
cask "font-fira-code"
cask "font-jetbrains-mono"
cask "font-meslo-lg-nerd-font"
cask "google-chrome"
cask "iterm2"
cask "miniforge"
cask "multipass"
cask "ngrok"
cask "notion"
cask "openscad"
cask "postman"
cask "visual-studio-code"
cask "warp"
mas "Amphetamine", id: 937984704
mas "Bear", id: 1091189122
mas "Draw Things", id: 6444050820
mas "Fantastical", id: 975937182
mas "GarageBand", id: 682658836
mas "Googly Eyes", id: 6743048714
mas "iMovie", id: 408981434
mas "Keynote", id: 361285480
mas "Keynote", id: 409183694
mas "KeyPad", id: 0
mas "Kindle", id: 302584613
mas "Logic Pro", id: 634148309
mas "Numbers", id: 409203825
mas "Pages", id: 409201541
mas "Pages", id: 361309726
mas "Prime Video", id: 545519333
mas "SiteSucker", id: 442168834
mas "TestFlight", id: 899247664
mas "The Unarchiver", id: 425424353
mas "Things", id: 904280696
mas "WhatsApp", id: 310633997
mas "Windows App", id: 1295203466
mas "Xcode", id: 497799835
vscode "anthropic.claude-code"
vscode "bourhaouta.tailwindshades"
vscode "bradlc.vscode-tailwindcss"
vscode "codesandbox-io.codesandbox-projects"
vscode "dbaeumer.vscode-eslint"
vscode "donjayamanne.typescript-notebook"
vscode "eamodio.gitlens"
vscode "editorconfig.editorconfig"
vscode "equinusocio.vsc-material-theme"
vscode "equinusocio.vsc-material-theme-icons"
vscode "esbenp.prettier-vscode"
vscode "expo.vscode-expo-theme"
vscode "firsttris.vscode-jest-runner"
vscode "github.copilot-chat"
vscode "gruntfuggly.todo-tree"
vscode "heybourn.headwind"
vscode "jakebecker.elixir-ls"
vscode "jvitor83.types-autoinstaller"
vscode "mike-co.import-sorter"
vscode "ms-azuretools.vscode-azureresourcegroups"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-python.debugpy"
vscode "ms-python.isort"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-toolsai.jupyter-renderers"
vscode "ms-vscode-remote.remote-containers"
vscode "ms-vscode-remote.remote-ssh"
vscode "ms-vscode-remote.remote-ssh-edit"
vscode "ms-vscode.azure-account"
vscode "ms-vscode.remote-explorer"
vscode "ms-vsliveshare.vsliveshare"
vscode "nrwl.angular-console"
vscode "openai.chatgpt"
vscode "pantajoe.vscode-elixir-credo"
vscode "piersdeseilligny.betterfountain"
vscode "prisma.prisma"
vscode "redhat.vscode-yaml"
vscode "shd101wyy.markdown-preview-enhanced"
vscode "teamsdevapp.ms-teams-vscode-extension"
vscode "unifiedjs.vscode-mdx"
vscode "xyc.vscode-mdx-preview"
vscode "yzhang.markdown-all-in-one"



================================================
FILE: CHANGELOG.md
================================================
# Changelog

## [Unreleased]

### Added

- **Automatic Update Checking**
  - Checks for dotfiles updates once per day on shell startup
  - Non-blocking background check
  - Shows notification if updates available
  - Never auto-updates without user permission
  - Can be disabled with `DOTFILES_SKIP_UPDATE_CHECK=1`

## [2026-01-21] - Major Security & Architecture Update

### Added

- **Modular Zsh Configuration**
  - `path.zsh` - PATH modifications
  - `aliases.zsh` - Command shortcuts (30+ aliases)
  - `functions.zsh` - Utilities (mkcd, extract, serve, etc.)
  - `.zshrc` now loads these modules dynamically

- **Mackup Integration**
  - Added mackup to Brewfile
  - `.mackup.cfg` for syncing app settings via iCloud
  - Supports VS Code, iTerm2, SSH, and 500+ apps

- **Security Documentation**
  - `SECURITY.md` - Security practices and audit history
  - `CHANGELOG.md` - This file

- **Docker Environment Variables**
  - `.env.example` - Template for database credentials
  - `.env` - Local credentials (gitignored)

- **Useful Functions** (from old repo migration)
  - `edit-profile()` - Edit .zshrc and reload
  - Improved `killnamed()` - Safer process killing with confirmation

### Changed

#### Security Fixes (CRITICAL)

- **Added `set -euo pipefail` to all scripts**
  - Catches undefined variables
  - Exits on errors
  - Properly handles pipe failures

- **Fixed all unquoted variable expansions**
  - `$(brew --prefix asdf)` → `"$(brew --prefix asdf)"`
  - All variables properly quoted

- **Removed hardcoded Docker credentials**
  - Moved from docker-compose.yml to .env
  - Template provided in .env.example

#### Architecture Improvements

- **Eliminated hardcoded `~/dotfiles` paths**
  - Scripts derive location from .zshrc symlink
  - Works from any clone location
  - Fallback to ~/dotfiles if not symlinked

- **Fixed .gitconfig dual strategy**
  - Removed from symlink list
  - Use only include directive
  - Prevents config corruption

- **Changed `alias cd='z'` to `alias j='z'`**
  - Avoids shadowing core cd command
  - Prevents script breakage

- **Improved .zshrc for fresh systems**
  - Checks if brew exists before calling it
  - Graceful failure instead of errors

- **Added sudo upfront in macos.sh**
  - Requests credentials before running
  - Prevents mid-script password prompts
  - Only 2 legitimate sudo operations

- **Safer killnamed function**
  - Shows processes before killing
  - Requires confirmation
  - SIGTERM before SIGKILL

### Fixed

- Unquoted variables in bootstrap.sh, install.sh, auth-setup.sh
- Missing error handling for undefined variables
- Path issues when dotfiles cloned outside ~/dotfiles
- .zshrc failing on fresh systems before bootstrap
- Install.sh not properly quoting backup filenames
- Git config strategy conflicts

### Removed

- `.gitconfig` from symlink list (use include only)
- Hardcoded credentials from docker-compose.yml
- `cd` alias (replaced with `j`)

### Security Audit

- ✅ Sudo usage reviewed and approved
- ✅ No privilege escalation issues
- ✅ Homebrew runs as user
- ✅ All file operations in user space
- ✅ Shell script best practices applied

## [2026-01-20] - Initial Release

### Added

- Complete macOS bootstrap automation
- Brewfile with 40+ applications
- asdf version management
- Git configuration
- macOS defaults automation
- Docker Compose for PostgreSQL/Redis
- Comprehensive README documentation
- Interactive prompts for user info
- Idempotent scripts
- Authentication helper scripts



================================================
FILE: check-updates.zsh
================================================
# Automatic dotfiles update checker
# Checks for updates on shell startup (max once per day)

# Skip if disabled by user
[ -n "$DOTFILES_SKIP_UPDATE_CHECK" ] && return

# Only run in interactive shells
[[ $- != *i* ]] && return

# Derive dotfiles location
if [ -L "${HOME}/.zshrc" ]; then
    DOTFILES_DIR="$(dirname "$(readlink "${HOME}/.zshrc")")"
else
    DOTFILES_DIR="${HOME}/dotfiles"
fi

# Check if dotfiles directory exists and is a git repo
if [ ! -d "$DOTFILES_DIR/.git" ]; then
    return
fi

# Timestamp file to track last check
LAST_CHECK_FILE="${DOTFILES_DIR}/.last-update-check"
CURRENT_TIME=$(date +%s)
CHECK_INTERVAL=$((24 * 60 * 60))  # 24 hours in seconds

# Check if we need to run (once per day)
if [ -f "$LAST_CHECK_FILE" ]; then
    LAST_CHECK=$(command cat "$LAST_CHECK_FILE")
    TIME_SINCE_CHECK=$((CURRENT_TIME - LAST_CHECK))

    if [ $TIME_SINCE_CHECK -lt $CHECK_INTERVAL ]; then
        return  # Too soon, skip check
    fi
fi

# Update timestamp
echo "$CURRENT_TIME" > "$LAST_CHECK_FILE"

# Check for updates in background to avoid blocking shell startup
(
    cd "$DOTFILES_DIR" || exit

    # Fetch updates quietly
    git fetch origin main --quiet 2>/dev/null || exit

    # Check if behind
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u} 2>/dev/null)

    if [ "$LOCAL" != "$REMOTE" ]; then
        # Show notification (use echo if cat fails)
        if command -v cat &>/dev/null; then
            cat << 'EOF'

╔═══════════════════════════════════════════════════════════╗
║  📦 Dotfiles Update Available                             ║
╚═══════════════════════════════════════════════════════════╝

  New updates are available for your dotfiles!

  To update, run:
    dotfiles-update

  Or pull manually:
    cd ~/dotfiles && git pull

EOF
        else
            echo ""
            echo "📦 Dotfiles Update Available"
            echo ""
            echo "  New updates are available!"
            echo "  To update, run: dotfiles-update"
            echo ""
        fi
    fi
) &



================================================
FILE: com.seth.brew-update.plist
================================================
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.seth.brew-update</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/seth/dotfiles/brew-update.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>9</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <false/>
</dict>
</plist>



================================================
FILE: DECISIONS.md
================================================
# Architecture Decision Records

This document captures the "why" behind major architectural choices in this dotfiles system.

---

## Decision 1: Smart App Detection Over Manual Brewfile Maintenance

**Date:** 2023-08-12

**Context:**
Homebrew adoption errors were killing bootstrap runs. When apps exist in `/Applications` but aren't tracked by Homebrew, `brew bundle` fails with:
```
Error: It seems there is already an App at '/Applications/Docker.app'
```

Manual resolution required `brew reinstall --cask docker --force` for every conflict. On a fresh Mac with 10 pre-installed apps, this meant 10 manual interventions.

**Decision:**
Scan `/Applications` before `brew bundle`, building filtered Brewfile that excludes already-installed apps.

**Implementation:**
```bash
# Map cask names to actual app bundle names
if [ -d "/Applications/Docker.app" ]; then
  # Skip docker cask in filtered Brewfile
fi
```

**Trade-offs:**
- **Pro:** Zero adoption errors across 50+ fresh Mac setups
- **Pro:** No manual Brewfile editing before each bootstrap
- **Con:** 40+ cask-to-app-name mappings to maintain
- **Con:** Extra 30 seconds scanning `/Applications`

**Result:**
Worth it. Went from 100% adoption error rate to 0%. The mapping table is one-time maintenance cost for permanent reliability.

**Alternatives Considered:**
1. `brew reinstall --cask --force` for everything → Slow, wasteful bandwidth
2. Manual Brewfile editing per machine → Error-prone, defeats automation
3. Remove apps before bootstrap → Data loss risk, unnecessary

---

## Decision 2: Modular ZSH Config Over Monolithic .zshrc

**Date:** 2024-01-15

**Context:**
My `.zshrc` grew to 400+ lines. When aliases broke, I'd spend 10 minutes searching through one giant file. Adding new functions meant scrolling past unrelated code. No organization.

**Decision:**
Split into focused modules:
- `path.zsh` - PATH configuration only
- `aliases.zsh` - Command shortcuts
- `functions.zsh` - Custom shell functions
- `prompt.zsh` - Prompt customization
- `check-updates.zsh` - Update checker
- `.zshrc.local` - Machine-specific overrides (gitignored)

**Trade-offs:**
- **Pro:** Found and fixed 3 bugs in first week (easy to scan 50-line files)
- **Pro:** New contributors immediately understand structure
- **Pro:** Can disable modules by commenting one `source` line
- **Con:** More files to manage
- **Con:** Load time increased by 0.01s (negligible)

**Result:**
Debugging time went from 10 minutes to 30 seconds. File organization mirrors mental model. Would never go back to monolithic config.

**Alternatives Considered:**
1. Comments/sections in single file → Still hard to navigate
2. Oh-My-Zsh framework → Too heavy, too opinionated
3. Zsh plugin manager → Unnecessary complexity for personal dotfiles

---

## Decision 3: asdf Over Individual Version Managers

**Date:** 2023-03-20

**Context:**
Managing `nvm` (Node), `pyenv` (Python), `rbenv` (Ruby), `gvm` (Go) separately was chaos:
- 5 different commands to remember
- 5 config files scattered across `~/.config`
- Each loads into shell = slow startup
- Version conflicts between tools

Running `nvm use` in one project, then `pyenv local` in another = cognitive overhead.

**Decision:**
Consolidate to `asdf` as universal version manager.

**Implementation:**
- Single `.tool-versions` file per project
- One command: `asdf install`
- Single shell init: `source $(brew --prefix asdf)/libexec/asdf.sh`

**Trade-offs:**
- **Pro:** One config file (`.tool-versions`)
- **Pro:** One tool, one mental model
- **Pro:** Faster shell startup (one plugin vs five)
- **Pro:** Cross-language consistency
- **Con:** Less mature than `nvm` for Node specifically
- **Con:** Requires plugin per language (but one-time setup)
- **Con:** Team members need to learn new tool

**Result:**
Shell startup time dropped from 2.1s to 0.8s. Never think about version managers anymore. Just works.

**Metrics:**
- Before: 5 version managers, 2.1s shell startup
- After: 1 version manager, 0.8s shell startup
- Setup time: 2 minutes to install asdf + plugins

**Alternatives Considered:**
1. Docker for everything → Overkill for scripting, slow feedback loop
2. Keep all 5 managers → Continued chaos
3. Mise (rtx) → Too new in 2023, asdf more stable

---

## Decision 4: Mackup + iCloud Over Manual rsync

**Date:** 2023-11-08

**Context:**
Before Mackup, I had a 200-line `sync-settings.sh` script:
- Manually rsync'd `~/.ssh/config`
- Copied VS Code settings JSON
- Backed up iTerm2 profiles
- Tracked git config manually

Every time I changed a setting, I'd forget to run the sync script. New Macs always missing some config. "Why isn't my VS Code theme syncing?"

**Decision:**
Use Mackup to automatically sync 500+ app settings via iCloud.

**Configuration:**
```ini
[storage]
engine = icloud

[applications_to_sync]
vscode
iterm2
ssh
```

**Trade-offs:**
- **Pro:** Zero-maintenance after initial setup
- **Pro:** Automatic sync (no manual script)
- **Pro:** 500+ apps supported out-of-box
- **Pro:** Symlinks = changes propagate immediately
- **Con:** iCloud sync slower than Dropbox
- **Con:** Less control over what syncs
- **Con:** iCloud Desktop & Documents must be enabled

**Result:**
Rebuilt VS Code 3 times before Mackup. Zero times after. Settings sync "just works" now.

**Alternatives Considered:**
1. Dropbox backend → Faster but one more service to maintain
2. Git-based sync → Too manual, conflicts on simultaneous edits
3. Custom sync script → Already tried, failed at maintenance

---

## Decision 5: Docker Compose for Dev Databases

**Date:** 2023-06-15

**Context:**
Local Postgres/Redis installs caused problems:
- Conflicted with project-specific versions (Postgres 13 vs 15)
- Polluted global namespace (port 5432 always taken)
- Hard to reset to clean state
- Teammates on different versions = "works on my machine"

**Decision:**
Ship `docker-compose.yml` with PostgreSQL + Redis for local dev.

**Configuration:**
```yaml
services:
  postgres:
    image: postgres:15-alpine
    ports: ["5432:5432"]
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: dev

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
```

**Trade-offs:**
- **Pro:** Isolated per-project (can run multiple Postgres versions)
- **Pro:** Disposable (`docker compose down -v` = clean slate)
- **Pro:** Version-controlled in dotfiles
- **Pro:** Team consistency (everyone runs same image)
- **Con:** Requires Docker Desktop (60s startup time)
- **Con:** Extra RAM usage (~500MB for both services)
- **Con:** Slightly slower than native Postgres

**Result:**
Zero version conflicts in 6 months. `docker compose up -d` → instant dev environment. Can test migrations on Postgres 14 and 15 side-by-side.

**Alternatives Considered:**
1. Homebrew Postgres → Global state, version conflicts
2. Postgres.app → macOS only, manual start/stop
3. Cloud dev database → Network latency, costs money

---

## Decision 6: Idempotency as Core Design Principle

**Date:** 2023-01-10 (Initial design)

**Context:**
My first dotfiles script would:
- Append to `PATH` every run (ended up with 10 duplicates)
- Re-download Homebrew if check failed
- Overwrite configs without backups
- Fail halfway, leaving broken state

I'd run it once, it'd fail, I'd fix something, re-run, and **it would break differently**.

**Decision:**
Every script must be safe to run 100 times with same result.

**Implementation:**
```bash
# Check before installing
if ! command -v brew &> /dev/null; then
  install_homebrew
fi

# Check before appending
if ! grep -q "dotfiles/.gitconfig" ~/.gitconfig; then
  echo "[include] path = ~/dotfiles/.gitconfig" >> ~/.gitconfig
fi

# Backup before overwriting
if [ -f ~/.zshrc ]; then
  cp ~/.zshrc ~/.zshrc.backup.$(date +%Y-%m-%d-%H%M%S)
fi
```

**Trade-offs:**
- **Pro:** Run script 5 times debugging? No problem
- **Pro:** Bootstrap fails mid-way? Re-run from same state
- **Pro:** Confidence in automation
- **Con:** More checks = slightly slower
- **Con:** More complex logic

**Result:**
Went from "never re-run the script" to "run it every week to verify." Confidence in automation is everything.

**Philosophy:**
> "A script you can't re-run is a script you can't trust."

**Alternatives Considered:**
1. Document "run once only" → User error inevitable
2. Add `--force` flag → Still risky, easy to forget state
3. Full state management system → Overkill for dotfiles

---

## Decision 7: Git Config Written Immediately (Not at End)

**Date:** 2024-01-08

**Context:**
Bootstrap script collected git name/email at start, then wrote to `.gitconfig` at end. If Homebrew installation failed mid-script, git config never written. User had to re-enter info on next run.

With `set -e` (fail on error), any failure = exit immediately = lost git config.

**Decision:**
Write git config **immediately** after collecting it, before any potentially-failing commands.

**Implementation:**
```bash
# Collect info
read -p "Enter your name: " GIT_NAME

# Write IMMEDIATELY (before Xcode, Homebrew, etc)
git config --global user.name "$GIT_NAME"

# Now safe to run potentially-failing commands
install_xcode_tools
```

**Trade-offs:**
- **Pro:** Git config persists even if script fails later
- **Pro:** User never re-enters same info twice
- **Con:** More complex control flow (early write)
- **Con:** Git config written before dotfiles cloned

**Result:**
Zero frustrated users re-entering git config after bootstrap failures.

**Alternatives Considered:**
1. Write at end → Lost on failures (original problem)
2. Save to temp file → Extra file management, risk of orphan files
3. Remove `set -e` → Silently continue on errors (unacceptable)

---

## Decision 8: Daily Update Check (Not Weekly)

**Date:** 2024-02-10

**Context:**
Original implementation checked for dotfiles updates weekly. Missed critical fixes for days. When bug hit, I'd already pushed fix, but users wouldn't see update notification until next Sunday.

**Decision:**
Check for updates every 24 hours (daily) with `.last-update-check` timestamp.

**Implementation:**
```bash
# check-updates.zsh
if [ -f ~/.last-update-check ]; then
  last_check=$(cat ~/.last-update-check)
  hours_since=$(($(date +%s) - last_check) / 3600))
  if [ $hours_since -lt 24 ]; then
    return  # Skip check
  fi
fi

# Check GitHub for updates
git fetch origin main
if [ "$(git rev-list HEAD..origin/main --count)" -gt 0 ]; then
  show_update_notification
fi

date +%s > ~/.last-update-check
```

**Trade-offs:**
- **Pro:** Critical fixes reach users within 24 hours
- **Pro:** More frequent feedback on dotfiles evolution
- **Con:** Daily git fetch = 0.5s overhead per shell launch
- **Con:** Daily notification possible (if actively developing)

**Result:**
Fixed critical bootstrap bug on Tuesday, all users notified by Wednesday. Previously would've waited until Sunday.

**Opt-out:**
```bash
# Add to ~/.zshrc.local
DOTFILES_SKIP_UPDATE_CHECK=1
```

**Alternatives Considered:**
1. Weekly checks → Too slow for critical fixes
2. Hourly checks → Annoying for active development
3. Manual checks only → Nobody remembers

---

## Decision 9: Include Both Cursor AND VS Code

**Date:** 2024-09-15

**Context:**
Cursor launched as AI-native editor. Some said "just use Cursor, remove VS Code." But Cursor lacks extension marketplace maturity.

**Decision:**
Install both. Use each for different contexts.

**Usage:**
- **Cursor** → AI-assisted development, pair programming with Claude
- **VS Code** → Extensions (GitLens, Thunder Client, DB viewers), debugging, mature tooling

**Trade-offs:**
- **Pro:** Best tool for each job
- **Pro:** Cursor crashes? VS Code as fallback
- **Pro:** VS Code extensions not yet in Cursor
- **Con:** 1GB extra disk space
- **Con:** Two editors to maintain settings for

**Result:**
Cursor for new feature development (AI autocomplete), VS Code for debugging and complex extensions. Not wasting time with "either/or" false choice.

**Alternatives Considered:**
1. Cursor only → Missing critical extensions
2. VS Code only → Missing AI assistance
3. Vim/Neovim → Too much config, prefer GUI for complex projects

---

## Decision 10: LaunchAgent for Brew Updates (Not Manual)

**Date:** 2024-03-20

**Context:**
`brew update && brew upgrade` every Monday took 10 minutes. I'd forget for weeks, then have 50+ outdated packages. Security vulnerabilities piling up.

**Decision:**
Create LaunchAgent that runs `brew update && brew upgrade` automatically on Mondays at 8 AM.

**Implementation:**
```xml
<!-- ~/Library/LaunchAgents/com.seth.brew-update.plist -->
<key>StartCalendarInterval</key>
<dict>
  <key>Weekday</key>
  <integer>1</integer>  <!-- Monday -->
  <key>Hour</key>
  <integer>8</integer>
</dict>
```

**Trade-offs:**
- **Pro:** Never forget to update
- **Pro:** Security patches applied within 1 week
- **Pro:** Notification appears when updates complete
- **Con:** Surprise breakages possible (rare)
- **Con:** Uses bandwidth automatically
- **Con:** System notifications on Monday mornings

**Result:**
Brew always up-to-date. Caught OpenSSL security vulnerability within 3 days of announcement vs previous 3 weeks.

**Alternatives Considered:**
1. Manual updates → Forgetfulness
2. Daily updates → Too disruptive
3. Homebrew auto-update → Only runs on `brew install`, not comprehensive

---

## Decision Philosophy

Every decision follows these principles:

1. **Optimize for Future Me** - I will forget why I did this in 6 months
2. **Explicit Over Implicit** - No hidden magic, log everything
3. **Fail Loudly** - `set -euo pipefail` on all scripts
4. **Document Trade-offs** - No silver bullets, acknowledge costs
5. **Measure Impact** - "Feels better" isn't good enough

**When to Record a Decision:**
- Debated multiple approaches for >10 minutes
- Someone will ask "why not X?" in the future
- Trade-offs are non-obvious
- Failed experiments worth remembering

---

## Template for New Decisions

```markdown
## Decision N: [Title]

**Date:** YYYY-MM-DD

**Context:**
What problem was I solving? What was painful?

**Decision:**
What did I choose and why?

**Implementation:**
Code snippet showing the approach.

**Trade-offs:**
- **Pro:** Benefits gained
- **Con:** Costs paid

**Result:**
What actually happened? Would I do it again?

**Alternatives Considered:**
1. Option A → Why not?
2. Option B → Why not?
```

---

## Questions This Document Answers

- Why smart app detection instead of manual Brewfile edits?
- Why modular ZSH instead of one big `.zshrc`?
- Why asdf instead of nvm/pyenv/rbenv?
- Why Mackup instead of custom sync script?
- Why Docker Compose for databases?
- Why write git config immediately?
- Why both Cursor AND VS Code?
- Why daily update checks?

**If you're asking "why" about anything in this repo, the answer should be here.**



================================================
FILE: docker-compose.yml
================================================
# Docker Compose for local development databases
# Usage: docker compose up -d

services:
  postgres:
    image: postgres:15-alpine
    container_name: dev-postgres
    restart: unless-stopped
    env_file:
      - .env
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-postgres}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
      POSTGRES_DB: ${POSTGRES_DB:-dev}
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: dev-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres-data:
  redis-data:



================================================
FILE: functions.zsh
================================================
# Custom functions

# mkcd - mkdir and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# extract - extract any archive type
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find process by name
psgrep() {
    ps aux | grep -v grep | grep -i -e VSZ -e "$1"
}

# Kill process by name (safer version)
killnamed() {
    if [ -z "$1" ]; then
        echo "Usage: killnamed <process-name>"
        return 1
    fi

    # Show matching processes
    echo "Matching processes:"
    pgrep -fil "$1"

    if [ $? -ne 0 ]; then
        echo "No processes found matching '$1'"
        return 1
    fi

    # Confirm before killing
    echo ""
    read -p "Kill these processes? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try SIGTERM first (graceful)
        pkill -i "$1" && echo "Sent SIGTERM to processes"
        sleep 2

        # Check if any survived, then use SIGKILL
        if pgrep -fi "$1" >/dev/null; then
            echo "Some processes survived, sending SIGKILL..."
            pkill -9 -i "$1"
        fi
    else
        echo "Cancelled"
    fi
}

# Quick server for current directory
serve() {
    local port="${1:-8000}"
    open "http://localhost:${port}/"
    python3 -m http.server "$port"
}

# Git add all + commit with message
gac() {
    git add .
    git commit -m "$1"
}

# Create GitHub PR from current branch
ghpr() {
    gh pr create --fill
}

# Update dotfiles
dotfiles-update() {
    # Derive dotfiles location from .zshrc symlink
    if [ -L "${HOME}/.zshrc" ]; then
        DOTFILES_DIR="$(dirname "$(readlink "${HOME}/.zshrc")")"
    else
        DOTFILES_DIR="${HOME}/dotfiles"
    fi

    echo "Updating dotfiles..."
    (cd "$DOTFILES_DIR" && git pull && ./install.sh)
    echo "Updating Homebrew packages..."
    brew update && brew upgrade
    echo "Done!"
}

# Edit zsh profile and reload
edit-profile() {
    $EDITOR ~/.zshrc && source ~/.zshrc
}

# Reload shell configuration
reload-shell() {
    echo "Reloading shell configuration..."
    source ~/.zshrc
    echo "✓ Shell reloaded"
}

# Network diagnostics and repair
fix-my-network() {
    # Colors
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local MAGENTA='\033[0;35m'
    local CYAN='\033[0;36m'
    local WHITE='\033[1;37m'
    local RESET='\033[0m'
    local BOLD='\033[1m'
    local DIM='\033[2m'

    # Symbols
    local CHECK="${GREEN}✓${RESET}"
    local CROSS="${RED}✗${RESET}"
    local WARN="${YELLOW}⚠${RESET}"
    local INFO="${BLUE}ℹ${RESET}"
    local GEAR="${CYAN}⚙${RESET}"
    local ROCKET="${MAGENTA}🚀${RESET}"

    # Header
    echo ""
    echo "${BOLD}${CYAN}╔═══════════════════════════════════════════╗${RESET}"
    echo "${BOLD}${CYAN}║${RESET}  ${ROCKET}  ${BOLD}Network Diagnostic & Repair${RESET}       ${BOLD}${CYAN}║${RESET}"
    echo "${BOLD}${CYAN}╚═══════════════════════════════════════════╝${RESET}"
    echo ""

    local issues_found=0
    local fixes_applied=0
    local -a test_results
    local -a test_names

    # Helper function for test output
    test_item() {
        echo -n "${DIM}[${RESET} ${GEAR} ${DIM}]${RESET} $1... "
        test_names+=("$1")
    }

    test_pass() {
        echo "${CHECK} ${GREEN}$1${RESET}"
        test_results+=("pass")
    }

    test_fail() {
        echo "${CROSS} ${RED}$1${RESET}"
        test_results+=("fail")
        ((issues_found++))
    }

    test_warn() {
        echo "${WARN} ${YELLOW}$1${RESET}"
        test_results+=("warn")
    }

    fix_applied() {
        echo "    ${GEAR} ${CYAN}Applied fix:${RESET} $1"
        ((fixes_applied++))
    }

    section() {
        echo ""
        echo "${BOLD}${BLUE}▶${RESET} ${BOLD}$1${RESET}"
        echo "${DIM}────────────────────────────────────────────${RESET}"
    }

    # 1. Check proxy environment variables
    section "Proxy Configuration"
    test_item "Checking for stale proxy settings"

    local proxy_vars=(HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY FTP_PROXY NO_PROXY)
    local found_proxies=0

    for var in "${proxy_vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then
            found_proxies=1
            test_fail "Found: $var=${(P)var}"
            unset $var
            fix_applied "Cleared $var"
        fi
    done

    if [[ $found_proxies -eq 0 ]]; then
        test_pass "Clean"
    fi

    # 2. DNS Tests
    section "DNS Resolution"

    test_item "Testing DNS lookup (google.com)"
    if nslookup google.com >/dev/null 2>&1; then
        test_pass "Working"
    else
        test_fail "Failed"
        test_item "Flushing DNS cache"
        sudo dscacheutil -flushcache 2>/dev/null
        sudo killall -HUP mDNSResponder 2>/dev/null
        fix_applied "DNS cache flushed"
    fi

    test_item "Checking DNS servers"
    local dns_servers=$(scutil --dns | grep 'nameserver\[0\]' | head -1 | awk '{print $3}')
    if [[ -n "$dns_servers" ]]; then
        test_pass "Configured: $dns_servers"
    else
        test_warn "No DNS servers found"
    fi

    # 3. Network Interface
    section "Network Interfaces"

    test_item "Checking active interfaces"

    # Find interface with status: active
    local active_if=""
    for iface in $(ifconfig -l); do
        if ifconfig "$iface" | grep -q "status: active"; then
            active_if="$iface"
            break
        fi
    done

    if [[ -n "$active_if" ]]; then
        local ip_addr=$(ifconfig $active_if | grep 'inet ' | awk '{print $2}' | head -1)
        test_pass "Active: $active_if ($ip_addr)"
    else
        test_fail "No active interface"
        test_item "Attempting to restart primary interface"
        sudo ifconfig en0 down 2>/dev/null
        sleep 1
        sudo ifconfig en0 up 2>/dev/null
        fix_applied "Restarted en0"
    fi

    # 4. Basic Connectivity
    section "Connectivity Tests"

    test_item "Testing raw IP connectivity (8.8.8.8)"
    if ping -c 2 -W 2000 8.8.8.8 >/dev/null 2>&1; then
        test_pass "Reachable"
    else
        test_fail "Cannot reach external IPs"
    fi

    test_item "Testing internet connectivity (google.com)"
    if ping -c 2 -W 2000 google.com >/dev/null 2>&1; then
        test_pass "Reachable"
    else
        test_fail "Cannot resolve/reach domains"
    fi

    test_item "Testing HTTP/HTTPS (curl example.com)"
    if curl -s --connect-timeout 3 http://example.com >/dev/null 2>&1; then
        test_pass "Working"
    else
        test_fail "HTTP requests failing"
    fi

    # 5. System Resources
    section "System Resources"

    test_item "Checking open network connections"
    local conn_count=$(lsof -i 2>/dev/null | wc -l | tr -d ' ')
    local fd_limit=$(ulimit -n)

    if [[ $conn_count -lt $((fd_limit / 2)) ]]; then
        test_pass "$conn_count open (limit: $fd_limit)"
    else
        test_warn "$conn_count open (limit: $fd_limit) - approaching limit"
    fi

    # 6. Routing Table
    section "Routing"

    test_item "Checking default gateway"
    local gateway=$(netstat -rn | grep default | grep -v '::' | awk '{print $2}' | head -1)

    if [[ -n "$gateway" ]]; then
        test_pass "Gateway: $gateway"
    else
        test_fail "No default gateway"
    fi

    # Summary
    echo ""
    echo "${BOLD}${CYAN}╔═══════════════════════════════════════════╗${RESET}"
    echo "${BOLD}${CYAN}║${RESET}  ${BOLD}Summary${RESET}                                  ${BOLD}${CYAN}║${RESET}"
    echo "${BOLD}${CYAN}╚═══════════════════════════════════════════╝${RESET}"
    echo ""

    # Results table
    echo "${BOLD}${DIM}┌────────────────────────────────────────┬────────┐${RESET}"
    echo "${BOLD}${DIM}│${RESET} ${BOLD}Test${RESET}                                   ${BOLD}${DIM}│${RESET} ${BOLD}Result${RESET} ${BOLD}${DIM}│${RESET}"
    echo "${BOLD}${DIM}├────────────────────────────────────────┼────────┤${RESET}"

    for i in {1..${#test_names[@]}}; do
        local test_name="${test_names[$i]}"
        local result="${test_results[$i]}"

        # Truncate test name if too long
        if [[ ${#test_name} -gt 38 ]]; then
            test_name="${test_name:0:35}..."
        fi

        # Pad test name to 38 chars
        printf "${BOLD}${DIM}│${RESET} %-38s ${BOLD}${DIM}│${RESET} " "$test_name"

        # Show result with color
        case "$result" in
            pass)
                printf "${CHECK} ${GREEN}OK${RESET}  "
                ;;
            fail)
                printf "${CROSS} ${RED}FAIL${RESET}"
                ;;
            warn)
                printf "${WARN} ${YELLOW}WARN${RESET}"
                ;;
        esac
        echo " ${BOLD}${DIM}│${RESET}"
    done

    echo "${BOLD}${DIM}└────────────────────────────────────────┴────────┘${RESET}"
    echo ""

    # Overall status
    if [[ $issues_found -eq 0 ]]; then
        echo "  ${CHECK} ${GREEN}${BOLD}No issues detected${RESET}"
        echo "  ${INFO} Network appears healthy"
    else
        echo "  ${CROSS} ${YELLOW}Issues found:${RESET} $issues_found"
        echo "  ${GEAR} ${CYAN}Fixes applied:${RESET} $fixes_applied"

        if [[ $fixes_applied -lt $issues_found ]]; then
            echo ""
            echo "  ${WARN} ${YELLOW}Manual intervention may be needed:${RESET}"
            echo "      • Check VPN/firewall settings"
            echo "      • Verify WiFi/Ethernet connection"
            echo "      • Check System Settings > Network"
            echo "      • Review Console.app for network errors"
            echo "      • Consider: ${DIM}sudo killall -HUP mDNSResponder${RESET}"
        fi
    fi

    echo ""
    echo "${DIM}Run again with: ${BOLD}fix-my-network${RESET}"
    echo ""
}

# Port management
ports() {
    lsof -iTCP -sTCP:LISTEN -n -P
}

killport() {
    if [ -z "$1" ]; then
        echo "Usage: killport <port>"
        return 1
    fi
    lsof -ti:$1 | xargs kill -9
}

# Find large files
findlarge() {
    find . -type f -size +${1:-100}M -exec ls -lh {} \; 2>/dev/null | awk '{print $9 ": " $5}'
}

# Git branch cleanup (delete merged branches)
gcleanup() {
    git branch --merged | grep -v '\*\|main\|master\|develop' | xargs -n 1 git branch -d
}

# Quick backup
backup() {
    cp "$1"{,.backup-$(date +%Y%m%d-%H%M%S)}
}

# Directory size
dirsize() {
    du -sh "${1:-.}" | sort -hr
}

# Open project in editor
proj() {
    cd ~/Development/${1:-.} && $EDITOR .
}

# Quick search in code
codesearch() {
    rg -p "$1" | less -R
}

# Interactive command menu
use-my-mac() {
    # Check if fzf is installed
    if ! command -v fzf &>/dev/null; then
        echo "Error: fzf is required but not installed"
        echo "Install with: brew install fzf"
        return 1
    fi

    # Build command list with categories
    local commands=$(cat <<'EOF'
# Navigation
..                  → Go up one directory
...                 → Go up two directories
....                → Go up three directories
-                   → Go to previous directory
j <dir>             → Jump to directory (autojump)
dotfiles            → Navigate to dotfiles directory
proj <name>         → Open project in ~/Development

# File Operations
ll                  → List files (long format with git status)
ls                  → List files
cat <file>          → View file with syntax highlighting
extract <file>      → Extract any archive type
backup <file>       → Create timestamped backup
findlarge [size]    → Find large files (default >100M)
dirsize [path]      → Show directory sizes sorted
cleanup             → Delete all .DS_Store files

# Git - Basic
gs                  → git status
ga                  → git add
gc                  → git commit
gcm <msg>           → git commit -m
gca                 → git commit --amend
gcane               → git commit --amend --no-edit
gp                  → git push
gl                  → git pull
gd                  → git diff
glog                → git log (pretty graph)

# Git - Branches
gb                  → git branch
gbd <branch>        → git branch -d (delete)
gbD <branch>        → git branch -D (force delete)
gco <branch>        → git checkout
gm <branch>         → git merge
grb <branch>        → git rebase
grbi <ref>          → git rebase -i (interactive)
gcleanup            → Delete all merged branches

# Git - Advanced
gf                  → git fetch
gsh                 → git stash
gshp                → git stash pop
gcp <commit>        → git cherry-pick
grh                 → git reset HEAD~
gundo               → git reset --soft HEAD~1
gclean              → git clean -fd
gac <msg>           → git add . && commit -m
ghpr                → Create GitHub PR (gh pr create --fill)

# Docker
dc                  → docker compose
dcu                 → docker compose up
dcd                 → docker compose down
dcb                 → docker compose build
dcl                 → docker compose logs
dclf                → docker compose logs -f (follow)
dce                 → docker compose exec
dcr                 → docker compose restart
dps                 → docker ps
dpsa                → docker ps -a (all)
di                  → docker images
dprune              → docker system prune -af

# Bun
br <script>         → bun run
bi                  → bun install
ba <pkg>            → bun add
brm <pkg>           → bun remove
bt                  → bun test

# Network
myip                → Show public IP
localip             → Show local IP (en0)
ports               → Show all listening ports
killport <port>     → Kill process on port
fix-my-network      → Network diagnostic & repair tool

# Development
vim <file>          → nvim (neovim)
psgrep <name>       → Find process by name
killnamed <name>    → Kill process by name (with confirmation)
serve [port]        → Start HTTP server (default: 8000)
codesearch <term>   → Search code with ripgrep + pager

# System
c                   → clear
h                   → Show last 20 history items
path                → Show PATH entries (one per line)
hosts               → Edit /etc/hosts
reload-shell        → Reload zsh configuration
edit-profile        → Edit .zshrc and reload
zshconfig           → Open .zshrc in editor
brewup              → brew update + upgrade + cleanup
dotfiles-update     → Update dotfiles and Homebrew

# Utilities
mkcd <dir>          → mkdir + cd into it
use-my-mac          → This menu!
EOF
)

    # Use fzf to select command
    local selected=$(echo "$commands" | \
        grep -v '^#' | \
        grep -v '^$' | \
        fzf --height=80% \
            --border=rounded \
            --prompt="🔍 Search commands: " \
            --header="↑↓ navigate • enter: copy • ctrl-e: execute • esc: quit" \
            --preview='echo {}' \
            --preview-window=up:3:wrap \
            --bind='ctrl-e:execute-silent(echo {} | cut -d" " -f1 | pbcopy)+abort' \
            --color='header:italic:cyan,prompt:bold:blue,pointer:bold:magenta')

    if [ -n "$selected" ]; then
        # Extract command (before the arrow)
        local cmd=$(echo "$selected" | awk '{print $1}')

        # Copy to clipboard
        echo -n "$cmd" | pbcopy

        echo ""
        echo "✓ Copied to clipboard: $cmd"
        echo ""

        # Ask if user wants to execute
        read -p "Execute now? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Check if it needs arguments
            if echo "$selected" | grep -q '<.*>'; then
                echo "Command requires arguments. Paste and complete:"
                print -z "$cmd "
            else
                eval "$cmd"
            fi
        fi
    fi
}

# AI development best practices CLI
ai() {
    local cmd="$1"
    shift

    case "$cmd" in
        init)
            # ASCII Art: Robot peeking through opening door
            cat << 'EOF'

            ╔═══════════════════════════════════════════════════════╗
            ║                                                       ║
            ║    ┌────────┐                                        ║
            ║    │        │                    ___                 ║
            ║    │   ∥    │                   /   \                ║
            ║    │   ∥    │     👋           | o o |               ║
            ║    │   ∥    │                   \___/                ║
            ║    │   ∥   /│                    |||                 ║
            ║    │   ∥  / │                   /   \                ║
            ║    │   ∥ /  │                  |  ⚙  |               ║
            ║    │   ∥/   │                   \___/                ║
            ║    │   /    │                  //   \\               ║
            ║    │  /     │                 //     \\              ║
            ║    │ /      │                                        ║
            ║    │/       │          "Hello, Developer!"          ║
            ║    └────────┘                                        ║
            ║     [DOOR]              [FRIENDLY AI ROBOT]          ║
            ║                                                       ║
            ╚═══════════════════════════════════════════════════════╝

EOF
            echo "🤖 Initializing directory with AI development best practices..."
            echo ""

            # Check if AGENTS.md already exists
            if [ -f "AGENTS.md" ]; then
                echo "⚠️  AGENTS.md already exists in this directory"
                read -p "Overwrite? (y/N) " -n 1 -r
                echo ""
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    echo "❌ Cancelled"
                    return 1
                fi
            fi

            # Download AGENTS.md from GitHub
            echo "📥 Downloading AGENTS.md from github.com/sethwebster/AI..."
            if curl -fsSL "https://raw.githubusercontent.com/sethwebster/AI/main/AGENTS.md" -o "AGENTS.md"; then
                echo "✅ AGENTS.md initialized successfully"

                # Create symlink from CLAUDE.md to AGENTS.md
                if [ -e "CLAUDE.md" ] && [ ! -L "CLAUDE.md" ]; then
                    echo "⚠️  CLAUDE.md exists and is not a symlink"
                    read -p "Replace with symlink to AGENTS.md? (y/N) " -n 1 -r
                    echo ""
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        rm "CLAUDE.md"
                        ln -s "AGENTS.md" "CLAUDE.md"
                        echo "🔗 Created symlink: CLAUDE.md -> AGENTS.md"
                    fi
                elif [ -L "CLAUDE.md" ]; then
                    echo "ℹ️  CLAUDE.md symlink already exists"
                else
                    ln -s "AGENTS.md" "CLAUDE.md"
                    echo "🔗 Created symlink: CLAUDE.md -> AGENTS.md"
                fi

                echo ""
                echo "📖 Review the best practices: cat AGENTS.md"
                echo "🔗 Source: https://github.com/sethwebster/AI"
            else
                echo "❌ Failed to download AGENTS.md"
                echo "   Check network connection or repository availability"
                return 1
            fi
            ;;

        *)
            echo "AI Development Best Practices CLI"
            echo ""
            echo "Usage:"
            echo "  ai init    - Initialize directory with AGENTS.md from github.com/sethwebster/AI"
            echo ""
            echo "More commands coming soon..."
            return 1
            ;;
    esac
}

# Port Find - Find process by port number
portfind() {
    if [ -z "$1" ]; then
        echo "Usage: portfind <port>"
        echo "Example: portfind 3000"
        return 1
    fi

    local PORT="$1"

    # Find processes using the port
    local RESULTS=$(lsof -i :$PORT 2>/dev/null)

    if [ -z "$RESULTS" ]; then
        echo "No process found on port $PORT"
        return 1
    fi

    echo "$RESULTS"
}

# Port Kill - Kill process by port number
portkill() {
    if [ -z "$1" ]; then
        echo "Usage: portkill <port>"
        echo "Example: portkill 3000"
        return 1
    fi

    local PORT="$1"

    # Find PIDs using the port
    local PIDS=$(lsof -ti :$PORT 2>/dev/null)

    if [ -z "$PIDS" ]; then
        echo "No process found on port $PORT"
        return 1
    fi

    echo "Killing process(es) on port $PORT..."
    echo "$PIDS" | xargs kill -9 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "✅ Process(es) killed: $PIDS"
    else
        echo "❌ Failed to kill process(es)"
        return 1
    fi
}

# Reset a tart VM by deleting it and re-cloning from tahoe-base
# Usage: tart-reset <vm-name> [--run]
tart-reset() {
    local vm_name="$1"
    local run_after=false

    if [ -z "$vm_name" ]; then
        echo "Usage: tart-reset <vm-name> [--run]"
        return 1
    fi

    shift
    while [ $# -gt 0 ]; do
        case "$1" in
            --run) run_after=true ;;
            *) echo "Unknown flag: $1"; return 1 ;;
        esac
        shift
    done

    if tart list | grep -q "^$vm_name "; then
        echo "Deleting existing VM '$vm_name'..."
        tart delete "$vm_name"
    fi

    echo "Cloning tahoe-base -> $vm_name..."
    tart clone tahoe-base "$vm_name" || { echo "Clone failed"; return 1; }

    echo "VM '$vm_name' ready."

    if $run_after; then
        echo "Starting '$vm_name'..."
        tart run "$vm_name"
    fi
}



================================================
FILE: install.sh
================================================
#!/usr/bin/env bash
# Symlink dotfiles from dotfiles directory to home directory
# This script is idempotent - safe to run multiple times

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

# Files to symlink
files=(
    ".zshrc"
    ".tool-versions"
    ".mackup.cfg"
    ".nanorc"
    "path.zsh"
    "aliases.zsh"
    "functions.zsh"
    "check-updates.zsh"
)

# Create symlinks
for file in "${files[@]}"; do
    source="$DOTFILES_DIR/$file"
    target="$HOME_DIR/$file"

    if [ -f "$source" ]; then
        # Check if already correctly symlinked
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
            log_success "$file already linked"
            continue
        fi

        # Backup existing file if it exists and is not a symlink
        if [ -f "$target" ] && [ ! -L "$target" ]; then
            backup="$target.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$target" "$backup"
            log_warning "Backed up existing $file to $(basename "$backup")"
        fi

        # Remove existing symlink if it's wrong
        [ -L "$target" ] && rm "$target"

        # Create symlink
        ln -s "$source" "$target"
        log_success "Linked $file"
    fi
done

# Create .gitignore_global
if [ ! -f "$HOME_DIR/.gitignore_global" ]; then
    cat > "$HOME_DIR/.gitignore_global" << 'EOF'
# macOS
.DS_Store
.AppleDouble
.LSOverride
._*

# Editors
.vscode/
.idea/
*.swp
*.swo
*~
.*.sw[a-z]

# Node
node_modules/
npm-debug.log*
.npm

# Env files
.env
.env.local
.env.*.local

# Logs
*.log

# Temporary
tmp/
temp/
EOF
    log_success "Created .gitignore_global"
else
    log_success ".gitignore_global already exists"
fi

# Oh-My-Zsh installation (optional)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo ""
    read -p "Install Oh-My-Zsh? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh-My-Zsh installed"

        # Oh-My-Zsh overwrites ~/.zshrc - restore our symlink
        if [ -f "$HOME_DIR/.zshrc" ] && [ ! -L "$HOME_DIR/.zshrc" ]; then
            backup="$HOME_DIR/.zshrc.ohmyzsh.backup"
            mv "$HOME_DIR/.zshrc" "$backup"
            log_warning "Backed up Oh-My-Zsh .zshrc to .zshrc.ohmyzsh.backup"
        fi
        ln -sf "$DOTFILES_DIR/.zshrc" "$HOME_DIR/.zshrc"
        log_success "Restored .zshrc symlink"

        # Install popular plugins
        PLUGIN_DIR="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins"
        if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
            log_success "Installed zsh-autosuggestions"
        fi
        if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting"
            log_success "Installed zsh-syntax-highlighting"
        fi
    fi
else
    log_success "Oh-My-Zsh already installed"
fi

# Remove stale tabtab completion blocks from .zshrc
ZSHRC="$DOTFILES_DIR/.zshrc"
if grep -q "tabtab source" "$ZSHRC" 2>/dev/null; then
    # Find each sourced tabtab completion path and remove the block if the file doesn't exist
    while IFS= read -r line; do
        path=$(echo "$line" | grep -oE '\[\[ -f [^ ]+' | sed 's/\[\[ -f //')
        if [ -n "$path" ] && [ ! -f "$path" ]; then
            pkg=$(echo "$line" | grep -oE 'tabtab source for \S+' | awk '{print $4}')
            log_warning "Removing stale tabtab completion for: $pkg"
            sed -i '' "/# tabtab source for $pkg/,/tabtab.*$pkg/d" "$ZSHRC"
        fi
    done < <(grep "tabtab source for" "$ZSHRC")
    log_success "Tabtab completions cleaned"
fi

log_success "Dotfiles installation complete!"



================================================
FILE: MACKUP.md
================================================
# Mackup Guide - Application Settings Sync

Mackup keeps your application settings in sync across multiple Macs via cloud storage (iCloud, Dropbox, etc.).

## What Mackup Does

**Backs up settings for 500+ apps:**
- VS Code (extensions, settings, keybindings)
- iTerm2 (profiles, colors, preferences)
- SSH (config, known_hosts)
- Git (global config)
- Sublime Text, Atom, and other editors
- Terminal apps (zsh, bash, vim, tmux)
- Many macOS apps (Slack, Notion, etc.)

**How it works:**
1. Moves app config files to cloud storage (e.g., `~/Library/Mobile Documents/com~apple~CloudDocs/Mackup/`)
2. Creates symlinks from original location to cloud storage
3. Cloud storage syncs to other Macs
4. Other Macs restore symlinks, instantly getting your settings

## Configuration

Your config is already set in `.mackup.cfg`:

```ini
[storage]
engine = icloud
directory = Mackup

[applications_to_sync]
vscode
iterm2
ssh
slack
notion
obsidian
google-chrome
arc
raycast
rectangle
```

### Change Storage Location

Edit `~/.mackup.cfg`:

```ini
# Use iCloud (default)
[storage]
engine = icloud

# Or use Dropbox
[storage]
engine = dropbox

# Or use Google Drive
[storage]
engine = google_drive

# Or custom path
[storage]
engine = file_system
path = /Users/you/Dropbox
directory = Mackup
```

## First Time Setup (Current Mac)

### Step 1: Check what will be backed up

```bash
mackup list
```

This shows all apps mackup knows about.

### Step 2: Backup your settings

```bash
mackup backup
```

This will:
- Find all supported app configs
- Move them to cloud storage
- Create symlinks in original locations
- Show you what was backed up

**Example output:**
```
Backing up VS Code...
Backing up iTerm2...
Backing up SSH...
✓ Backup done
```

### Step 3: Verify backup

```bash
ls -la ~/.ssh/config
# Should show: .ssh/config -> ~/Library/Mobile Documents/.../Mackup/ssh/config
```

The arrow `->` means it's now a symlink to cloud storage!

### Step 4: Wait for cloud sync

- **iCloud**: Check System Settings → iCloud → iCloud Drive → Manage → Mackup folder appears
- **Dropbox**: Check Dropbox app, wait for sync to complete

## On a New Mac

### Step 1: Install dotfiles first

```bash
git clone https://github.com/sethwebster/dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

### Step 2: Wait for cloud storage to sync

- Open Finder → iCloud Drive (or Dropbox)
- Wait for `Mackup` folder to appear
- May take 5-30 minutes depending on connection

### Step 3: Restore settings

```bash
mackup restore
```

This will:
- Find backed up configs in cloud storage
- Create symlinks on new Mac
- Instantly apply all your settings

**Example output:**
```
Restoring VS Code...
Restoring iTerm2...
Restoring SSH...
✓ Restore done. Please restart affected apps.
```

### Step 4: Restart apps

Close and reopen VS Code, iTerm2, etc. Your settings are now active!

## Common Commands

### Backup (first Mac)
```bash
mackup backup
```

### Restore (new Mac)
```bash
mackup restore
```

### Uninstall (remove symlinks, restore files locally)
```bash
mackup uninstall
```

### List supported applications
```bash
mackup list
```

### Dry run (see what would happen)
```bash
mackup backup --dry-run
mackup restore --dry-run
```

## Workflow

### On Primary Mac (where you make changes)

```bash
# 1. Install apps and configure them
# 2. Backup to cloud
mackup backup

# That's it! Changes sync automatically via cloud storage
```

### On Secondary Mac

```bash
# 1. Install apps via dotfiles bootstrap
./bootstrap.sh

# 2. Wait for cloud sync
# 3. Restore settings
mackup restore

# 4. Restart apps to see changes
```

### Making Changes Later

Once backed up, changes are **automatic**:
- You change VS Code settings on Mac A
- Settings file is actually in iCloud (via symlink)
- iCloud syncs to Mac B
- Mac B's VS Code sees changes instantly (via its symlink)

**No need to run `mackup backup` again!**

## What Gets Synced

### Development Tools
- VS Code: Settings, extensions list, keybindings, snippets
- Git: Global config, ignore patterns
- SSH: Config, known_hosts (private keys NOT synced - good!)

### Terminal
- iTerm2: Complete profiles, colors, fonts, preferences
- Zsh/Bash: NOT synced (handled by dotfiles instead)

### Apps
- Slack: Preferences
- Notion: Settings
- Raycast: Hotkeys, extensions, preferences
- Rectangle: Window shortcuts

### Browsers
- Chrome: Bookmarks, extensions (if configured)
- Arc: Settings

## Troubleshooting

### "Conflict" error during restore

If mackup says files exist:

```bash
# Option 1: Backup existing files first
mv ~/.ssh/config ~/.ssh/config.local

# Then restore
mackup restore

# Option 2: Force overwrite (careful!)
mackup restore --force
```

### File not syncing

Check if symlink is correct:

```bash
ls -la ~/.config/Code/User/settings.json
# Should show: -> /path/to/iCloud/Mackup/vscode/...
```

If it's a regular file (not symlink), re-run:

```bash
mackup uninstall
mackup backup
```

### Symlinks broken after reinstalling macOS

Re-run restore:

```bash
mackup restore
```

### Want to stop syncing an app

Edit `.mackup.cfg`:

```ini
[applications_to_ignore]
vscode  # Stop syncing VS Code
```

Then:

```bash
mackup uninstall  # Removes ALL symlinks
mackup backup     # Re-creates symlinks except ignored apps
```

## Security Notes

**What Mackup syncs:**
- ✅ App preferences and settings
- ✅ SSH config files
- ✅ Git config

**What Mackup does NOT sync:**
- ❌ SSH private keys (only config)
- ❌ Passwords (use 1Password instead)
- ❌ API tokens (those stay in `.env` files)
- ❌ Browser passwords (use built-in sync)

**Cloud storage security:**
- iCloud: End-to-end encrypted
- Dropbox: Encrypted in transit, not at rest
- Google Drive: Encrypted in transit, not at rest

Don't put sensitive credentials in app configs!

## Advanced Usage

### Sync custom app

Create `~/.mackup/custom-app.cfg`:

```ini
[application]
name = My Custom App

[configuration_files]
.myapprc
.config/myapp/config.json
```

### Multiple Macs with different settings

Use machine-specific overrides:

```ini
# .mackup.cfg - shared config
[storage]
engine = icloud

# .mackup.local.cfg - machine-specific (not synced)
[applications_to_ignore]
iterm2  # Don't sync iTerm on this Mac
```

## Quick Reference

```bash
# First time (Mac A)
brew install mackup
mackup backup

# New Mac (Mac B)
brew install mackup
mackup restore

# Check status
mackup list

# Undo everything
mackup uninstall
```

## Integration with Dotfiles

This dotfiles repo already includes:
- ✅ Mackup in Brewfile (auto-installed)
- ✅ `.mackup.cfg` pre-configured
- ✅ Bootstrap script mentions mackup restore

After running `./bootstrap.sh`, just run:

```bash
# First Mac
mackup backup

# Other Macs
mackup restore
```

## Next Steps

1. **First Mac**: Run `mackup backup` right now
2. **Wait**: Let iCloud sync (check Finder → iCloud Drive → Mackup)
3. **Test**: Try `mackup restore` on another Mac (or VM)
4. **Verify**: Check if settings appear on other Mac

Your app settings will now sync forever! 🎉



================================================
FILE: macos.sh
================================================
#!/usr/bin/env bash
# macOS defaults configuration
# Run this to set up macOS preferences

set -euo pipefail

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}==>${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

echo ""
log_info "Configuring macOS defaults..."
log_info "This will take 10-15 seconds..."
echo ""

# Request sudo upfront to avoid mid-script password prompts
sudo -v

# Close System Preferences if open
log_info "Closing System Preferences..."
osascript -e 'tell application "System Preferences" to quit'

###############################################################################
# General UI/UX                                                               #
###############################################################################

log_info "Configuring UI/UX settings..."

# Disable the sound effects on boot
sudo nvram SystemAudioVolume=" "

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

###############################################################################
# Screenshots                                                                 #
###############################################################################

log_info "Configuring screenshot settings..."

# Save screenshots to ~/Screenshots
mkdir -p "${HOME}/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

# Save screenshots in PNG format
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

log_info "Configuring Finder..."

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use list view in all Finder windows by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Show the ~/Library folder
chflags nohidden ~/Library

# Show the /Volumes folder
sudo chflags nohidden /Volumes

###############################################################################
# Dock                                                                        #
###############################################################################

log_info "Configuring Dock..."

# Set the icon size of Dock items
defaults write com.apple.dock tilesize -int 48

# Enable magnification
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -int 64

# Position on screen (bottom, left, right)
defaults write com.apple.dock orientation -string "bottom"

# Minimize windows into application icon
defaults write com.apple.dock minimize-to-application -bool true

# Show indicator lights for open applications
defaults write com.apple.dock show-process-indicators -bool true

# Don't animate opening applications
defaults write com.apple.dock launchanim -bool false

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Remove the auto-hiding delay
defaults write com.apple.dock autohide-delay -float 0

# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock autohide-time-modifier -float 0.5

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

###############################################################################
# Keyboard & Input                                                            #
###############################################################################

log_info "Configuring keyboard..."

# Enable full keyboard access for all controls (e.g. Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Set a blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

###############################################################################
# Trackpad                                                                    #
###############################################################################

log_info "Configuring trackpad..."

# Enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: swipe between pages with three fingers
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool true
defaults -currentHost write NSGlobalDomain com.apple.trackpad.threeFingerHorizSwipeGesture -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 1

###############################################################################
# Terminal                                                                    #
###############################################################################

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

###############################################################################
# Activity Monitor                                                            #
###############################################################################

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Mac App Store                                                               #
###############################################################################

log_info "Configuring App Store..."

# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

###############################################################################
# Done                                                                        #
###############################################################################

echo ""
log_success "macOS defaults applied!"
log_warning "Some changes require logout/restart"
log_info "Quick restart UI: killall Finder Dock SystemUIServer"
echo ""



================================================
FILE: path.zsh
================================================
# Path modifications

# Homebrew (Apple Silicon vs Intel)
if [[ $(uname -m) == 'arm64' ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Add local bin
export PATH="$HOME/.local/bin:$PATH"



================================================
FILE: prepare-sync.sh
================================================
#!/usr/bin/env bash
# Prepare current Mac for syncing to new Mac
# Captures current state: apps, settings, versions

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}==>${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Get dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
log_info "========================================"
log_info "Prepare Mac for Sync (Sending Mode)"
log_info "========================================"
echo ""
log_info "This will capture your current Mac's state:"
echo "  - Installed Homebrew packages → Brewfile"
echo "  - App settings → iCloud (via Mackup)"
echo "  - Tool versions → .tool-versions"
echo "  - Git config → .gitconfig"
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Cancelled"
    exit 0
fi

# Backup current Brewfile
if [ -f "${DOTFILES_DIR}/Brewfile" ]; then
    log_info "Backing up current Brewfile..."
    cp "${DOTFILES_DIR}/Brewfile" "${DOTFILES_DIR}/Brewfile.backup"
    log_success "Backup saved to Brewfile.backup"
fi

# Generate new Brewfile from current system
log_info "Generating Brewfile from currently installed packages..."
cd "${DOTFILES_DIR}"

# Create temporary Brewfile
TEMP_BREWFILE=$(mktemp)

# Generate from system
brew bundle dump --file="$TEMP_BREWFILE" --force

# Show diff if Brewfile exists
if [ -f "${DOTFILES_DIR}/Brewfile" ]; then
    echo ""

    # Check if files are different
    if cmp -s "${DOTFILES_DIR}/Brewfile" "$TEMP_BREWFILE"; then
        log_success "No changes to Brewfile"
        rm -f "$TEMP_BREWFILE"
    else
        log_info "Changes detected:"
        diff -u "${DOTFILES_DIR}/Brewfile" "$TEMP_BREWFILE" || true
        echo ""

        read -p "Update Brewfile with these changes? (y/N) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mv "$TEMP_BREWFILE" "${DOTFILES_DIR}/Brewfile"
            log_success "Brewfile updated"
        else
            rm -f "$TEMP_BREWFILE"
            log_info "Brewfile unchanged"
        fi
    fi
else
    # No existing Brewfile, just create it
    mv "$TEMP_BREWFILE" "${DOTFILES_DIR}/Brewfile"
    log_success "Brewfile created"
fi

# Update .tool-versions from current asdf versions
if command -v asdf &> /dev/null; then
    log_info "Capturing all asdf plugin versions..."

    TEMP_TOOL_VERSIONS=$(mktemp)
    echo "# asdf version specifications" > "$TEMP_TOOL_VERSIONS"

    # Get all installed plugins and their versions
    while IFS= read -r plugin; do
        # Get all installed versions for this plugin
        versions=$(asdf list "$plugin" 2>/dev/null | grep -v "No versions installed" || true)

        if [ -n "$versions" ]; then
            # Get the current/latest version (strip leading spaces/asterisks)
            current_version=$(echo "$versions" | tail -1 | sed 's/^[* ]*//')

            if [ -n "$current_version" ]; then
                echo "$plugin $current_version" >> "$TEMP_TOOL_VERSIONS"
                log_info "  Found $plugin $current_version"
            fi
        fi
    done < <(asdf plugin list)

    # Compare and update if different
    if [ -f "${DOTFILES_DIR}/.tool-versions" ]; then
        if ! cmp -s "${DOTFILES_DIR}/.tool-versions" "$TEMP_TOOL_VERSIONS"; then
            echo ""
            log_info "Changes to .tool-versions:"
            diff -u "${DOTFILES_DIR}/.tool-versions" "$TEMP_TOOL_VERSIONS" || true
            echo ""

            mv "$TEMP_TOOL_VERSIONS" "${DOTFILES_DIR}/.tool-versions"
            log_success ".tool-versions updated with all installed plugins"
        else
            rm -f "$TEMP_TOOL_VERSIONS"
            log_success ".tool-versions already up to date"
        fi
    else
        mv "$TEMP_TOOL_VERSIONS" "${DOTFILES_DIR}/.tool-versions"
        log_success ".tool-versions created with all installed plugins"
    fi
fi

# Mackup backup
if command -v mackup &> /dev/null; then
    echo ""
    log_info "Running Mackup backup..."
    log_warning "This will sync app settings to iCloud"
    echo ""

    read -p "Run mackup backup? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Running Mackup backup (syncing app settings to iCloud)..."
        log_info "Using --force to skip confirmation prompts..."
        mackup backup --force
        echo ""
        log_success "Mackup backup complete"

        # Show summary
        app_count=$(mackup list 2>/dev/null | wc -l | xargs)
        if [ "$app_count" -gt 0 ]; then
            log_info "Synced settings for $app_count apps to iCloud"
        fi
    else
        log_info "Skipped Mackup backup"
    fi
else
    log_warning "Mackup not installed, skipping app settings backup"
fi

# Git config check
echo ""
log_info "Checking Git configuration..."
if [ -f "${DOTFILES_DIR}/.gitconfig" ]; then
    log_success "Git config exists in dotfiles"

    # Show current user info
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")

    if [ -n "$current_name" ] && [ -n "$current_email" ]; then
        echo "  Current: $current_name <$current_email>"
    fi
else
    log_warning "No .gitconfig in dotfiles"
fi

# Check for uncommitted changes
echo ""
log_info "Checking for uncommitted dotfiles changes..."
cd "${DOTFILES_DIR}"

if ! git diff --quiet || ! git diff --cached --quiet; then
    log_warning "You have uncommitted changes in dotfiles:"
    echo ""
    git status --short
    echo ""

    read -p "Commit and push changes now? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add -A
        read -p "Commit message: " commit_msg

        if [ -z "$commit_msg" ]; then
            commit_msg="Update dotfiles from $(hostname)"
        fi

        git commit -m "$commit_msg"
        git push
        log_success "Changes committed and pushed"
    else
        log_warning "Remember to commit and push before syncing to new Mac"
    fi
else
    log_success "No uncommitted changes"
fi

# Summary
echo ""
log_info "========================================"
log_info "Sync Preparation Complete"
log_info "========================================"
echo ""
log_success "Your Mac is ready to be cloned!"
echo ""
log_info "Next steps:"
echo "  1. Wait for iCloud to sync (check System Settings)"
echo "  2. On new Mac, clone dotfiles repo"
echo "  3. Run ./bootstrap.sh on new Mac"
echo "  4. Run mackup restore on new Mac"
echo ""
log_info "Your settings will be automatically synced via:"
echo "  ✓ Brewfile (apps)"
echo "  ✓ .tool-versions (Node/Python versions)"
echo "  ✓ Mackup → iCloud (app settings)"
echo "  ✓ Git → GitHub (dotfiles repo)"
echo ""



================================================
FILE: prompt.zsh
================================================
# Seth's Powerline ZSH Prompt
# Requires a Nerd Font (e.g., "MesloLGS NF", "JetBrainsMono Nerd Font")

setopt PROMPT_SUBST

# Powerline characters
local PL_SEP=$'\ue0b0'      #

# Icons (Nerd Font)
local ICON_APPLE=$'\uf179'   #
local ICON_BRANCH=$'\ue725'  #
local ICON_BATTERY=$'\uf240' #
local ICON_CHARGING=$'\uf0e7' #
local ICON_ERROR=$'\uf00d'   #

# Colors (background, foreground)
local C_RESET="%f%k"
local C_USER_BG="%K{black}"
local C_USER_FG="%F{white}"
local C_DIR_BG="%K{blue}"
local C_DIR_FG="%F{white}"
local C_GIT_BG="%K{green}"
local C_GIT_DIRTY_BG="%K{yellow}"
local C_EXIT_BG="%K{red}"
local C_EXIT_FG="%F{white}"
local C_BATT_BG="%K{magenta}"
local C_BATT_FG="%F{white}"

# Get shortened directory
_pl_dir() {
    local pwd="${PWD/#$HOME/~}"
    if [[ ${#pwd} -gt 30 ]]; then
        local parts=(${(s:/:)pwd})
        if [[ ${#parts[@]} -gt 2 ]]; then
            echo "…/${parts[-2]}/${parts[-1]}"
        else
            echo "$pwd"
        fi
    else
        echo "$pwd"
    fi
}

# Get git info
_pl_git() {
    local git_dir="$(git rev-parse --git-dir 2>/dev/null)"
    [[ -z "$git_dir" ]] && return 1
    git symbolic-ref --short HEAD 2>/dev/null || \
    git describe --tags --exact-match 2>/dev/null || \
    git rev-parse --short HEAD 2>/dev/null
}

# Check if git is dirty
_pl_git_dirty() {
    [[ -n "$(git status --porcelain 2>/dev/null)" ]]
}

# Get battery info
_pl_battery() {
    local batt_info="$(pmset -g batt 2>/dev/null)"
    local pct="$(echo "$batt_info" | grep -oE '[0-9]+%' | head -1 | tr -d '%')"
    [[ -z "$pct" ]] && return 1

    local icon="$ICON_BATTERY"
    [[ "$batt_info" == *"AC Power"* ]] && icon="$ICON_CHARGING"

    echo "${icon} ${pct}%%"
}

# Capture exit code before it's lost
_last_exit_code=0
_capture_exit_code() {
    _last_exit_code=$?
}
precmd_functions+=(_capture_exit_code)

# Build the prompt
_build_prompt() {
    local prompt=""
    local last_bg=""
    local exit_code=$_last_exit_code

    # User segment
    prompt+="${C_USER_BG}${C_USER_FG} ${ICON_APPLE} %n "
    prompt+="%F{black}${C_DIR_BG}${PL_SEP}"

    # Directory segment
    prompt+="${C_DIR_FG} $(_pl_dir) "
    last_bg="blue"

    # Git segment (if in repo)
    local git_branch="$(_pl_git)"
    if [[ -n "$git_branch" ]]; then
        if _pl_git_dirty; then
            prompt+="%F{blue}${C_GIT_DIRTY_BG}${PL_SEP}"
            prompt+="%F{black} ${ICON_BRANCH} ${git_branch} ● "
            last_bg="yellow"
        else
            prompt+="%F{blue}${C_GIT_BG}${PL_SEP}"
            prompt+="%F{black} ${ICON_BRANCH} ${git_branch} ✓ "
            last_bg="green"
        fi
    fi

    # Exit code segment (only on error)
    local exit_code="$?"
    if [[ "$exit_code" != "0" ]]; then
        prompt+="%F{${last_bg}}${C_EXIT_BG}${PL_SEP}"
        prompt+="${C_EXIT_FG} ${ICON_ERROR} ${exit_code} "
        last_bg="red"
    fi

    # Battery segment
    local batt="$(_pl_battery)"
    if [[ -n "$batt" ]]; then
        prompt+="%F{${last_bg}}${C_BATT_BG}${PL_SEP}"
        prompt+="${C_BATT_FG} ${batt} "
        last_bg="magenta"
    fi

    # End cap
    prompt+="%F{${last_bg}}%k${PL_SEP}${C_RESET}"

    echo "$prompt"
}

PROMPT='$(_build_prompt)
%(?.%F{cyan}.%F{red})❯ '
RPROMPT=''



================================================
FILE: QUICKSTART.md
================================================
# 🚀 Quickstart Guide

**Complete macOS setup in 3 commands.**

---

## New Mac Setup

```bash
# 1. Clone this repo
git clone https://github.com/sethwebster/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Make scripts executable
chmod +x *.sh

# 3. Run bootstrap
./bootstrap.sh
```

**That's it.** The script will:
- Install Xcode Command Line Tools
- Install Homebrew + 160+ packages/apps
- Set up development tools (Node, Python, etc.)
- Configure macOS defaults
- Offer guided authentication setup

**Time:** 20-35 minutes (mostly downloads)

---

## Cloning Your Current Mac to New Mac

### On Your Current Mac (Sending Mode)

```bash
cd ~/dotfiles
./prepare-sync.sh
```

This captures:
- All installed Homebrew packages → Brewfile
- Tool versions (Node, Python, etc.) → .tool-versions
- App settings → iCloud (via Mackup)

### On Your New Mac (Receiving Mode)

```bash
git clone https://github.com/sethwebster/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x *.sh
./bootstrap.sh
```

**Perfect clone every time.**

---

## What Gets Installed

### Applications (~40)
- **Browsers:** Chrome, Firefox, Arc, Brave
- **AI Tools:** Claude, ChatGPT, Cursor, Claude Code
- **Dev Tools:** VS Code, iTerm2, Docker, Postman
- **Productivity:** Slack, Notion, Things 3, Raycast

### CLI Tools (~70)
- Git, GitHub CLI, awscli, fastlane
- Modern tools: bat, eza, ripgrep, fzf, zoxide
- Development: PostgreSQL, Redis, Ollama

### Mac App Store (~15)
- Things 3, Bear, Fantastical, Xcode
- Amphetamine, Kindle, WhatsApp

---

## After Bootstrap

The script will prompt to run authentication setup:

```bash
./auth-setup.sh
```

This guides you through:
- GitHub authentication (`gh auth login`)
- Expo login (`npx expo login`)
- SSH key generation + GitHub upload
- Docker verification

---

## Re-running Bootstrap

**Safe to run multiple times.** Bootstrap is idempotent:
- Skips already-installed apps
- Only prompts for missing info
- Won't break existing setup

```bash
cd ~/dotfiles
git pull
./bootstrap.sh
```

---

## Manual Steps

A few apps can't be automated:
- **TestFlight** - Install from App Store (macOS security restrictions)
- **Sign into:**
  - Apple ID (System Settings)
  - Adobe Creative Cloud

---

## Troubleshooting

### Git keeps asking for name/email
```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### Homebrew not in PATH
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"  # Apple Silicon
eval "$(/usr/local/bin/brew shellenv)"     # Intel
```

### asdf command not found
```bash
source ~/.zshrc
```

---

## Files Overview

```
~/dotfiles/
├── bootstrap.sh        # Main setup script
├── prepare-sync.sh     # Capture current Mac state
├── auth-setup.sh       # Guided authentication
├── install.sh          # Symlink dotfiles
├── macos.sh            # macOS defaults
├── Brewfile            # All packages/apps
├── .zshrc              # Shell config
├── .gitconfig          # Git config
└── .tool-versions      # Node/Python versions
```

---

## Next Steps

1. **Read the full [README.md](README.md)** for detailed info
2. **Check [SECURITY.md](SECURITY.md)** for best practices
3. **See [MACKUP.md](MACKUP.md)** for app settings sync

---

**Need help?** Open an issue: https://github.com/sethwebster/dotfiles/issues



================================================
FILE: SECURITY.md
================================================
# Security Improvements

This document tracks security fixes and best practices implemented in this dotfiles repository.

## Recent Security Fixes (2026-01-21)

### Critical Fixes

1. **Added `set -euo pipefail` to all scripts**
   - `set -e`: Exit on error
   - `set -u`: Error on undefined variables
   - `set -o pipefail`: Catch errors in pipes
   - Prevents undefined variable expansion and silent failures

2. **Fixed unquoted variable expansions**
   - All `$(brew --prefix ...)` properly quoted
   - Prevents path injection and handles spaces correctly
   - All variable references use `"${VAR}"` or `"${VAR:-default}"`

3. **Removed hardcoded Docker credentials**
   - Moved to `.env` file (excluded from git)
   - `.env.example` provided as template
   - Users customize their own credentials

4. **Fixed .gitconfig dual-strategy conflict**
   - Removed symlink approach
   - Use only include directive: `[include] path = ...`
   - Prevents config corruption on re-runs

### Architecture Improvements

5. **Eliminated hardcoded paths**
   - Scripts derive dotfiles location from symlinks
   - Works regardless of clone location
   - Fallback to `~/dotfiles` if not symlinked

6. **Changed `alias cd='z'` to `alias j='z'`**
   - Avoids shadowing core `cd` command
   - Prevents script breakage
   - Use `j` for zoxide smart directory jumping

7. **Improved `killnamed` function safety**
   - Shows processes before killing
   - Requires confirmation
   - Tries SIGTERM before SIGKILL
   - Prevents accidental data loss

8. **Added sudo upfront request to macos.sh**
   - Caches credentials before script runs
   - Prevents mid-script password prompts
   - Sudo only used for legitimate system changes:
     - `nvram` (firmware)
     - `/Volumes` (system directory)

## Known Security Considerations

### curl | bash Pattern

**Status**: Present in 3 locations
**Risk**: MITM attacks, transient network issues
**Locations**:
- Homebrew installer
- Bun installer
- Oh-My-Zsh installer

**Mitigation**:
- These are official install scripts from trusted sources
- Uses HTTPS with certificate validation
- Common pattern in macOS ecosystem
- User should inspect URLs before running bootstrap

**Future**: Consider checksums or commit pinning

### Sudo Usage

**Audit**: Passed security review
**Details**: Only 2 sudo commands in macos.sh:
- `sudo nvram` - Legitimate (firmware access)
- `sudo chflags nohidden /Volumes` - Legitimate (system directory)

All Homebrew, file operations, and user configs run without sudo.

## Best Practices

1. **Secrets Management**
   - Never commit API tokens or passwords
   - Use `.env` files excluded from git
   - `.gitignore` includes: `*.key`, `*.pem`, `*.cert`, `.env`

2. **Script Hardening**
   - Always use `set -euo pipefail`
   - Quote all variable expansions
   - Check command existence before use
   - Validate user input

3. **Idempotency**
   - Check before creating/overwriting
   - Backup files before modification
   - Skip if already configured
   - Support multiple runs safely

4. **User Awareness**
   - Prompt before destructive actions
   - Clear messages about what's happening
   - Document sudo requirements
   - Warn about security implications

## Security Review History

| Date | Type | Status |
|------|------|--------|
| 2026-01-21 | Full code review (neckbeard agent) | PASS |
| 2026-01-21 | Sudo usage audit | PASS |
| 2026-01-21 | Shell script hardening | COMPLETE |

## Reporting Security Issues

Found a security issue? Please:
1. Do NOT open a public issue
2. Email security details privately
3. Allow reasonable time for fix before disclosure



================================================
FILE: .env.example
================================================
# Docker Development Database Credentials
# Copy this file to .env and customize as needed

POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=dev



================================================
FILE: .gitconfig
================================================
# Git configuration
# Note: user.name and user.email are set by bootstrap.sh

[core]
	editor = code --wait
	autocrlf = input
	excludesfile = ~/.gitignore_global

[init]
	defaultBranch = main

[pull]
	rebase = false

[push]
	default = current
	autoSetupRemote = true

[fetch]
	prune = true

[diff]
	colorMoved = zebra

[alias]
	# Shortcuts
	st = status
	co = checkout
	br = branch
	ci = commit
	unstage = reset HEAD --

	# Logging
	lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
	last = log -1 HEAD
	hist = log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short

	# Utilities
	amend = commit --amend --no-edit
	fixup = commit --fixup
	undo = reset --soft HEAD^
	wip = commit -am "WIP"
	contributors = shortlog --summary --numbered

[color]
	ui = auto

[filter "lfs"]
	clean = git-lfs clean -- %f
	smudge = git-lfs smudge -- %f
	process = git-lfs filter-process
	required = true



================================================
FILE: .mackup.cfg
================================================
[storage]
engine = icloud
directory = Mackup

# Let Mackup auto-detect supported applications
# Don't specify [applications_to_sync] - it will sync everything it recognizes



================================================
FILE: .nanorc
================================================
## Syntax highlighting
include "/opt/homebrew/share/nano/*.nanorc"
include "/opt/homebrew/share/nano/extra/*.nanorc"

## General settings
set tabsize 2
set tabstospaces
set linenumbers
set softwrap
set mouse
set autoindent
set indicator
set bookstyle
set matchbrackets "(<[{)>]}"

## Key bindings
bind ^Q exit all
bind ^S savefile main
bind ^W writeout main
bind ^O insert main
bind ^H help all
bind ^Z suspend main
bind ^C copy main
bind ^X cut main
bind ^V paste all
bind ^P location main

## Color scheme for interface
set titlecolor bold,white,blue
set statuscolor bold,white,green
set errorcolor bold,white,red
set selectedcolor bold,white,magenta
set stripecolor ,yellow
set numbercolor cyan
set keycolor cyan
set functioncolor green



================================================
FILE: .tool-versions
================================================
# asdf version specifications
elixir 1.19.5-otp-28
nodejs 24.14.0
python 3.9.1
ruby 3.3.7
rust stable



================================================
SYMLINK: AGENTS.md -> AGENTS.md
================================================



================================================
SYMLINK: CLAUDE.md -> CLAUDE.md
================================================



================================================
FILE: scripts/domain-info.ts
================================================
#!/usr/bin/env bun

import { execSync } from 'child_process';

interface DomainReport {
  domain: string;
  dns: {
    a: string[];
    aaaa: string[];
    mx: Array<{ priority: number; server: string }>;
    txt: string[];
    ns: string[];
    cname: string | null;
    soa: string | null;
  };
  whois: {
    registrar: string | null;
    createdDate: string | null;
    expiryDate: string | null;
    nameServers: string[];
    status: string[];
  };
  ssl: {
    issuer: string | null;
    validFrom: string | null;
    validTo: string | null;
    subject: string | null;
    san: string[];
  };
  security: {
    dnssec: boolean;
    spf: string | null;
    dmarc: string | null;
    dkim: string | null;
  };
  performance: {
    queryTime: number;
    ttl: number | null;
  };
}

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',

  // Standard colors
  black: '\x1b[30m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',

  // Bright colors
  brightBlack: '\x1b[90m',
  brightRed: '\x1b[91m',
  brightGreen: '\x1b[92m',
  brightYellow: '\x1b[93m',
  brightBlue: '\x1b[94m',
  brightMagenta: '\x1b[95m',
  brightCyan: '\x1b[96m',
  brightWhite: '\x1b[97m',

  // Background colors
  bgBlack: '\x1b[40m',
  bgRed: '\x1b[41m',
  bgGreen: '\x1b[42m',
  bgYellow: '\x1b[43m',
  bgBlue: '\x1b[44m',
  bgMagenta: '\x1b[45m',
  bgCyan: '\x1b[46m',
  bgWhite: '\x1b[47m',
};

function exec(cmd: string): string {
  try {
    return execSync(cmd, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] }).trim();
  } catch (e) {
    return '';
  }
}

function parseDNS(domain: string): DomainReport['dns'] {
  const dns = {
    a: [] as string[],
    aaaa: [] as string[],
    mx: [] as Array<{ priority: number; server: string }>,
    txt: [] as string[],
    ns: [] as string[],
    cname: null as string | null,
    soa: null as string | null,
  };

  // A records
  const aOutput = exec(`dig +short A ${domain}`);
  if (aOutput) {
    dns.a = aOutput.split('\n').filter(line => line && /^\d+\.\d+\.\d+\.\d+$/.test(line));
  }

  // AAAA records
  const aaaaOutput = exec(`dig +short AAAA ${domain}`);
  if (aaaaOutput) {
    dns.aaaa = aaaaOutput.split('\n').filter(line => line && line.includes(':'));
  }

  // MX records
  const mxOutput = exec(`dig +short MX ${domain}`);
  if (mxOutput) {
    dns.mx = mxOutput.split('\n')
      .filter(line => line)
      .map(line => {
        const [priority, server] = line.split(' ');
        return { priority: parseInt(priority), server: server.replace(/\.$/, '') };
      });
  }

  // TXT records
  const txtOutput = exec(`dig +short TXT ${domain}`);
  if (txtOutput) {
    dns.txt = txtOutput.split('\n')
      .filter(line => line)
      .map(line => line.replace(/^"|"$/g, ''));
  }

  // NS records
  const nsOutput = exec(`dig +short NS ${domain}`);
  if (nsOutput) {
    dns.ns = nsOutput.split('\n')
      .filter(line => line)
      .map(line => line.replace(/\.$/, ''));
  }

  // CNAME record
  const cnameOutput = exec(`dig +short CNAME ${domain}`);
  if (cnameOutput) {
    dns.cname = cnameOutput.split('\n')[0]?.replace(/\.$/, '') || null;
  }

  // SOA record
  const soaOutput = exec(`dig +short SOA ${domain}`);
  if (soaOutput) {
    dns.soa = soaOutput;
  }

  return dns;
}

function parseWhois(domain: string): DomainReport['whois'] {
  const whoisOutput = exec(`whois ${domain}`);
  const whois = {
    registrar: null as string | null,
    createdDate: null as string | null,
    expiryDate: null as string | null,
    nameServers: [] as string[],
    status: [] as string[],
  };

  if (!whoisOutput) return whois;

  // Registrar
  const registrarMatch = whoisOutput.match(/Registrar:\s*(.+)/i);
  if (registrarMatch) whois.registrar = registrarMatch[1].trim();

  // Created date
  const createdMatch = whoisOutput.match(/Creation Date:\s*(.+)/i);
  if (createdMatch) whois.createdDate = createdMatch[1].trim();

  // Expiry date
  const expiryMatch = whoisOutput.match(/Registry Expiry Date:\s*(.+)/i) ||
                      whoisOutput.match(/Expiration Date:\s*(.+)/i);
  if (expiryMatch) whois.expiryDate = expiryMatch[1].trim();

  // Name servers
  const nsMatches = whoisOutput.matchAll(/Name Server:\s*(.+)/gi);
  for (const match of nsMatches) {
    whois.nameServers.push(match[1].trim().toLowerCase());
  }

  // Status
  const statusMatches = whoisOutput.matchAll(/Domain Status:\s*(.+)/gi);
  for (const match of statusMatches) {
    whois.status.push(match[1].trim());
  }

  return whois;
}

function parseSSL(domain: string): DomainReport['ssl'] {
  const ssl = {
    issuer: null as string | null,
    validFrom: null as string | null,
    validTo: null as string | null,
    subject: null as string | null,
    san: [] as string[],
  };

  const sslOutput = exec(`echo | openssl s_client -servername ${domain} -connect ${domain}:443 2>/dev/null | openssl x509 -noout -text 2>/dev/null`);

  if (!sslOutput) return ssl;

  // Issuer
  const issuerMatch = sslOutput.match(/Issuer:.*CN\s*=\s*([^,\n]+)/);
  if (issuerMatch) ssl.issuer = issuerMatch[1].trim();

  // Valid from
  const validFromMatch = sslOutput.match(/Not Before\s*:\s*(.+)/);
  if (validFromMatch) ssl.validFrom = validFromMatch[1].trim();

  // Valid to
  const validToMatch = sslOutput.match(/Not After\s*:\s*(.+)/);
  if (validToMatch) ssl.validTo = validToMatch[1].trim();

  // Subject
  const subjectMatch = sslOutput.match(/Subject:.*CN\s*=\s*([^,\n]+)/);
  if (subjectMatch) ssl.subject = subjectMatch[1].trim();

  // SAN
  const sanMatch = sslOutput.match(/DNS:([^\n]+)/);
  if (sanMatch) {
    ssl.san = sanMatch[1].split('DNS:')
      .map(s => s.trim().replace(/,$/, ''))
      .filter(s => s);
  }

  return ssl;
}

function parseSecurity(domain: string, dns: DomainReport['dns']): DomainReport['security'] {
  const security = {
    dnssec: false,
    spf: null as string | null,
    dmarc: null as string | null,
    dkim: null as string | null,
  };

  // DNSSEC
  const dnssecOutput = exec(`dig +dnssec ${domain} | grep -i "ad;"`);
  security.dnssec = !!dnssecOutput;

  // SPF (in TXT records)
  const spfRecord = dns.txt.find(record => record.startsWith('v=spf1'));
  if (spfRecord) security.spf = spfRecord;

  // DMARC
  const dmarcOutput = exec(`dig +short TXT _dmarc.${domain}`);
  if (dmarcOutput) {
    security.dmarc = dmarcOutput.replace(/^"|"$/g, '');
  }

  // DKIM (check common selectors)
  const selectors = ['default', 'google', 'k1', 'selector1', 'selector2'];
  for (const selector of selectors) {
    const dkimOutput = exec(`dig +short TXT ${selector}._domainkey.${domain}`);
    if (dkimOutput && dkimOutput.includes('v=DKIM1')) {
      security.dkim = `${selector}._domainkey.${domain}`;
      break;
    }
  }

  return security;
}

async function getDomainInfo(domain: string): Promise<DomainReport> {
  const startTime = Date.now();

  const dns = parseDNS(domain);
  const whois = parseWhois(domain);
  const ssl = parseSSL(domain);
  const security = parseSecurity(domain, dns);

  const queryTime = Date.now() - startTime;

  // Get TTL from dig output
  const ttlOutput = exec(`dig ${domain} | grep -E "^${domain}\\." | head -1`);
  const ttlMatch = ttlOutput.match(/\d+/);
  const ttl = ttlMatch ? parseInt(ttlMatch[0]) : null;

  return {
    domain,
    dns,
    whois,
    ssl,
    security,
    performance: {
      queryTime,
      ttl,
    },
  };
}

function formatReport(report: DomainReport): string {
  const { domain, dns, whois, ssl, security, performance } = report;
  const c = colors;

  let output = '\n';

  // Header
  const boxWidth = 78;
  const contentWidth = boxWidth - 2; // Subtract border characters
  const title = 'DOMAIN INTELLIGENCE REPORT';

  output += `${c.bold}${c.brightCyan}╔${'═'.repeat(boxWidth)}╗${c.reset}\n`;
  output += `${c.bold}${c.brightCyan}║${c.reset} ${c.bold}${c.brightWhite}${title}${c.reset}${' '.repeat(contentWidth - title.length)} ${c.bold}${c.brightCyan}║${c.reset}\n`;
  output += `${c.bold}${c.brightCyan}║${c.reset} ${c.brightYellow}${domain}${c.reset}${' '.repeat(contentWidth - domain.length)} ${c.bold}${c.brightCyan}║${c.reset}\n`;
  output += `${c.bold}${c.brightCyan}╚${'═'.repeat(boxWidth)}╝${c.reset}\n\n`;

  // DNS Records Section
  output += `${c.bold}${c.brightMagenta}┌─ DNS RECORDS${c.reset}\n`;

  if (dns.a.length > 0) {
    output += `${c.bold}${c.cyan}│ A Records${c.reset}\n`;
    dns.a.forEach(ip => {
      output += `${c.dim}│${c.reset}   ${c.green}→${c.reset} ${ip}\n`;
    });
  }

  if (dns.aaaa.length > 0) {
    output += `${c.bold}${c.cyan}│ AAAA Records${c.reset}\n`;
    dns.aaaa.forEach(ip => {
      output += `${c.dim}│${c.reset}   ${c.green}→${c.reset} ${ip}\n`;
    });
  }

  if (dns.mx.length > 0) {
    output += `${c.bold}${c.cyan}│ MX Records${c.reset}\n`;
    dns.mx.forEach(mx => {
      output += `${c.dim}│${c.reset}   ${c.green}→${c.reset} [${c.yellow}${mx.priority}${c.reset}] ${mx.server}\n`;
    });
  }

  if (dns.ns.length > 0) {
    output += `${c.bold}${c.cyan}│ NS Records${c.reset}\n`;
    dns.ns.forEach(ns => {
      output += `${c.dim}│${c.reset}   ${c.green}→${c.reset} ${ns}\n`;
    });
  }

  if (dns.cname) {
    output += `${c.bold}${c.cyan}│ CNAME${c.reset}\n`;
    output += `${c.dim}│${c.reset}   ${c.green}→${c.reset} ${dns.cname}\n`;
  }

  if (dns.txt.length > 0) {
    output += `${c.bold}${c.cyan}│ TXT Records${c.reset}\n`;
    dns.txt.forEach(txt => {
      const truncated = txt.length > 68 ? txt.substring(0, 65) + '...' : txt;
      output += `${c.dim}│${c.reset}   ${c.green}→${c.reset} ${c.dim}${truncated}${c.reset}\n`;
    });
  }

  if (dns.soa) {
    output += `${c.bold}${c.cyan}│ SOA${c.reset}\n`;
    const soaTruncated = dns.soa.length > 68 ? dns.soa.substring(0, 65) + '...' : dns.soa;
    output += `${c.dim}│${c.reset}   ${c.dim}${soaTruncated}${c.reset}\n`;
  }

  output += `${c.dim}└${'─'.repeat(78)}${c.reset}\n\n`;

  // WHOIS Section
  output += `${c.bold}${c.brightMagenta}┌─ WHOIS INFORMATION${c.reset}\n`;

  if (whois.registrar) {
    output += `${c.bold}${c.cyan}│ Registrar${c.reset}\n`;
    output += `${c.dim}│${c.reset}   ${whois.registrar}\n`;
  }

  if (whois.createdDate) {
    output += `${c.bold}${c.cyan}│ Created${c.reset}\n`;
    output += `${c.dim}│${c.reset}   ${whois.createdDate}\n`;
  }

  if (whois.expiryDate) {
    output += `${c.bold}${c.cyan}│ Expires${c.reset}\n`;
    const expiryDate = new Date(whois.expiryDate);
    const daysUntilExpiry = Math.floor((expiryDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
    const expiryColor = daysUntilExpiry < 30 ? c.red : daysUntilExpiry < 90 ? c.yellow : c.green;
    output += `${c.dim}│${c.reset}   ${expiryColor}${whois.expiryDate}${c.reset} ${c.dim}(${daysUntilExpiry} days)${c.reset}\n`;
  }

  if (whois.nameServers.length > 0) {
    output += `${c.bold}${c.cyan}│ Name Servers${c.reset}\n`;
    whois.nameServers.forEach(ns => {
      output += `${c.dim}│${c.reset}   ${c.green}→${c.reset} ${ns}\n`;
    });
  }

  if (whois.status.length > 0) {
    output += `${c.bold}${c.cyan}│ Status${c.reset}\n`;
    whois.status.slice(0, 3).forEach(status => {
      output += `${c.dim}│${c.reset}   ${c.dim}${status}${c.reset}\n`;
    });
  }

  output += `${c.dim}└${'─'.repeat(78)}${c.reset}\n\n`;

  // SSL Certificate Section
  if (ssl.issuer || ssl.validTo) {
    output += `${c.bold}${c.brightMagenta}┌─ SSL/TLS CERTIFICATE${c.reset}\n`;

    if (ssl.issuer) {
      output += `${c.bold}${c.cyan}│ Issuer${c.reset}\n`;
      output += `${c.dim}│${c.reset}   ${ssl.issuer}\n`;
    }

    if (ssl.subject) {
      output += `${c.bold}${c.cyan}│ Subject${c.reset}\n`;
      output += `${c.dim}│${c.reset}   ${ssl.subject}\n`;
    }

    if (ssl.validFrom) {
      output += `${c.bold}${c.cyan}│ Valid From${c.reset}\n`;
      output += `${c.dim}│${c.reset}   ${ssl.validFrom}\n`;
    }

    if (ssl.validTo) {
      output += `${c.bold}${c.cyan}│ Valid To${c.reset}\n`;
      const validToDate = new Date(ssl.validTo);
      const daysUntilExpiry = Math.floor((validToDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
      const expiryColor = daysUntilExpiry < 30 ? c.red : daysUntilExpiry < 90 ? c.yellow : c.green;
      output += `${c.dim}│${c.reset}   ${expiryColor}${ssl.validTo}${c.reset} ${c.dim}(${daysUntilExpiry} days)${c.reset}\n`;
    }

    if (ssl.san.length > 0) {
      output += `${c.bold}${c.cyan}│ Subject Alternative Names${c.reset}\n`;
      ssl.san.slice(0, 5).forEach(san => {
        output += `${c.dim}│${c.reset}   ${c.green}→${c.reset} ${san}\n`;
      });
      if (ssl.san.length > 5) {
        output += `${c.dim}│${c.reset}   ${c.dim}... and ${ssl.san.length - 5} more${c.reset}\n`;
      }
    }

    output += `${c.dim}└${'─'.repeat(78)}${c.reset}\n\n`;
  }

  // Security Section
  output += `${c.bold}${c.brightMagenta}┌─ SECURITY${c.reset}\n`;

  output += `${c.bold}${c.cyan}│ DNSSEC${c.reset}\n`;
  output += `${c.dim}│${c.reset}   ${security.dnssec ? `${c.green}✓ Enabled${c.reset}` : `${c.red}✗ Disabled${c.reset}`}\n`;

  output += `${c.bold}${c.cyan}│ SPF${c.reset}\n`;
  if (security.spf) {
    const spfTruncated = security.spf.length > 68 ? security.spf.substring(0, 65) + '...' : security.spf;
    output += `${c.dim}│${c.reset}   ${c.green}✓${c.reset} ${c.dim}${spfTruncated}${c.reset}\n`;
  } else {
    output += `${c.dim}│${c.reset}   ${c.red}✗ Not configured${c.reset}\n`;
  }

  output += `${c.bold}${c.cyan}│ DMARC${c.reset}\n`;
  if (security.dmarc) {
    const dmarcTruncated = security.dmarc.length > 68 ? security.dmarc.substring(0, 65) + '...' : security.dmarc;
    output += `${c.dim}│${c.reset}   ${c.green}✓${c.reset} ${c.dim}${dmarcTruncated}${c.reset}\n`;
  } else {
    output += `${c.dim}│${c.reset}   ${c.red}✗ Not configured${c.reset}\n`;
  }

  output += `${c.bold}${c.cyan}│ DKIM${c.reset}\n`;
  if (security.dkim) {
    output += `${c.dim}│${c.reset}   ${c.green}✓${c.reset} ${security.dkim}\n`;
  } else {
    output += `${c.dim}│${c.reset}   ${c.yellow}? Not detected${c.reset} ${c.dim}(checked common selectors)${c.reset}\n`;
  }

  output += `${c.dim}└${'─'.repeat(78)}${c.reset}\n\n`;

  // Performance Section
  output += `${c.bold}${c.brightMagenta}┌─ PERFORMANCE${c.reset}\n`;

  output += `${c.bold}${c.cyan}│ Query Time${c.reset}\n`;
  output += `${c.dim}│${c.reset}   ${performance.queryTime}ms\n`;

  if (performance.ttl) {
    output += `${c.bold}${c.cyan}│ TTL${c.reset}\n`;
    output += `${c.dim}│${c.reset}   ${performance.ttl}s\n`;
  }

  output += `${c.dim}└${'─'.repeat(78)}${c.reset}\n\n`;

  return output;
}

// Main
const domain = process.argv[2];

if (!domain) {
  console.error(`${colors.red}Usage: domain-info <domain>${colors.reset}`);
  process.exit(1);
}

console.log(`${colors.dim}Gathering domain intelligence for ${colors.brightYellow}${domain}${colors.dim}...${colors.reset}`);

const report = await getDomainInfo(domain);
console.log(formatReport(report));



================================================
FILE: .codex/environments/environment.toml
================================================
# THIS IS AUTOGENERATED. DO NOT EDIT MANUALLY
version = 1
name = "dotfiles"

[setup]
script = ""

[[actions]]
name = "Run"
icon = "run"
command = "cd site && bun run dev"


