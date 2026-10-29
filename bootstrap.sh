#!/usr/bin/env bash
#
# Fully sets up this machine in one pass — macOS, Debian, and Ubuntu:
#   1. Generates the en_US.UTF-8 locale on Linux, so SSH logins from macOS
#      (which forwards $LANG/$LC_*) don't hit setlocale warnings
#   2. Installs Homebrew if needed, then everything listed in ./Brewfile
#      (cask/mas entries and anything marked `if OS.mac?` are skipped on
#      Linux automatically)
#   3. Symlinks these dotfiles into $HOME (the original dotfiles flow)
#   4. Sets the default login shell to Homebrew's bash
#   5. Clones every GitHub repo under SimonBoeck into ~/Documents/Workspace
#
# Usage:
#   ./bootstrap.sh                 # prompts before overwriting $HOME files
#   ./bootstrap.sh --force | -f    # skip that confirmation
#   ./bootstrap.sh --dry-run       # show what would happen, change nothing
#
set -u

cd "$(dirname "${BASH_SOURCE[0]}")"
DOTFILES_DIR="$(pwd)"
BREWFILE="$DOTFILES_DIR/Brewfile"
GITHUB_USER="SimonBoeck"
WORKSPACE_DIR="$HOME/Documents/Workspace"

case "$(uname -s)" in
  Darwin) IS_MACOS=1; IS_LINUX=0 ;;
  Linux)  IS_MACOS=0; IS_LINUX=1 ;;
  *)      IS_MACOS=0; IS_LINUX=0 ;;
esac

DRY_RUN=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --force|-f) FORCE=1 ;;
  esac
done

FAILED=()

log()        { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
ok()         { printf '\033[1;32m  ✓\033[0m %s\n' "$1"; }
warn()       { printf '\033[1;31m  ✗\033[0m %s\n' "$1"; }
would_clone(){ printf '\033[1;33m  →\033[0m would clone %s\n' "$1"; }

[ "$DRY_RUN" -eq 1 ] && log "DRY RUN — nothing will be written, installed, or cloned"

if command -v git >/dev/null 2>&1; then
  git pull origin main
else
  warn "git not available yet — skipping self-update (it's installed below)"
fi

# ---------------------------------------------------------------------------
# 1. Locale (Linux only)
#    macOS always ships en_US.UTF-8; a minimal Debian/Ubuntu install often
#    only has C/POSIX. ssh's client forwards $LANG/$LC_* by default, so
#    logging in from a Mac pushes "en_US.UTF-8" at this box whether or not
#    it's actually generated here, which makes every command print
#    "setlocale: ... cannot change locale" until it is. Runs regardless of
#    whether Homebrew/Brewfile below is already done.
# ---------------------------------------------------------------------------
if [ "$IS_LINUX" -eq 1 ] && command -v apt-get >/dev/null 2>&1; then
  if locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
    ok "en_US.UTF-8 locale already generated"
  elif [ "$DRY_RUN" -eq 1 ]; then
    log "[dry run] would generate the en_US.UTF-8 locale"
  else
    log "Generating en_US.UTF-8 locale"
    if sudo apt-get update && sudo apt-get install -y locales && sudo locale-gen en_US.UTF-8 && sudo update-locale LANG=en_US.UTF-8; then
      ok "en_US.UTF-8 locale generated"
    else
      warn "couldn't generate en_US.UTF-8 locale"
      FAILED+=("locale-gen")
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 2. Homebrew + everything in ./Brewfile
#    Runs before the dotfiles are copied over, so that by the time
#    .bash_profile gets sourced below, the tools/paths it expects
#    (coreutils, bash-completion@2, brew itself, ...) already exist.
# ---------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry run] would install Homebrew (not found on this machine)"
    if [ "$IS_LINUX" -eq 1 ] && command -v apt-get >/dev/null 2>&1; then
      echo "  (would apt-get install build-essential procps curl file git — Homebrew's Linux prerequisites)"
    fi
  else
    if [ "$IS_LINUX" -eq 1 ] && command -v apt-get >/dev/null 2>&1; then
      log "Installing Homebrew's Linux prerequisites via apt"
      sudo apt-get update && sudo apt-get install -y build-essential procps curl file git
    fi

    log "Installing Homebrew (official installer from brew.sh)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Prefix differs by platform/arch: Apple Silicon, Intel Mac, Linuxbrew.
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
      if [ -x "$brew_bin" ]; then
        eval "$("$brew_bin" shellenv)"
        break
      fi
    done
  fi
else
  log "Homebrew already installed"
fi

log "Packages from Brewfile"
if [ "$DRY_RUN" -eq 1 ]; then
  if command -v brew >/dev/null 2>&1; then
    brew bundle check --file="$BREWFILE" --no-upgrade --verbose || true
  else
    echo "  (Homebrew isn't installed yet, so nothing can be checked — see Brewfile for the full list)"
  fi
else
  brew update
  # --no-upgrade: several casks here (teams, parsec, insta360-studio, ...)
  # self-update and end up owned by root, which breaks brew's upgrade step
  # with "Operation not permitted". Only install what's missing; run
  # `brew upgrade <formula>` by hand for anything you actually want bumped.
  if ! brew bundle install --file="$BREWFILE" --no-upgrade; then
    warn "brew bundle reported failures — see output above"
    FAILED+=("brew-bundle")
  fi
fi

if [ "$IS_MACOS" -eq 1 ]; then
  echo
  echo "Not available via Homebrew/App Store — install by hand:"
  echo "  - Metashape — commercial license, download from agisoft.com"
  echo "  - loch — no known Homebrew cask; install from wherever you originally got it"
  echo "  - DecoPlanner — no known Homebrew cask; install from the vendor's site"
  echo "  - Python 3.14 standalone installer — only if some app specifically wants the official python.org Framework build; get it from python.org/downloads if so"
fi

# ---------------------------------------------------------------------------
# 3. Copy dotfiles into $HOME
# ---------------------------------------------------------------------------
RSYNC_EXCLUDES=(
  --exclude ".git/"
  --exclude ".DS_Store"
  --exclude ".osx"
  --exclude "bootstrap.sh"
  --exclude "Brewfile"
  --exclude "README.md"
  --exclude "LICENSE-MIT.txt"
)

sync_dotfiles() {
  rsync "${RSYNC_EXCLUDES[@]}" -avh --no-perms . ~
  source ~/.bash_profile
}

log "Dotfiles -> \$HOME"
if [ "$DRY_RUN" -eq 1 ]; then
  rsync "${RSYNC_EXCLUDES[@]}" -avhn --no-perms . ~
elif [ "$FORCE" -eq 1 ]; then
  sync_dotfiles
else
  read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1
  echo ""
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sync_dotfiles
  else
    warn "Skipped — dotfiles were not copied to \$HOME"
  fi
fi

# ---------------------------------------------------------------------------
# 4. Default login shell -> Homebrew's bash
#    macOS's bundled /bin/bash is the ancient 3.2 (GPLv2 cutoff); these
#    dotfiles (.bash_profile, bash-completion@2, etc.) expect a modern bash.
# ---------------------------------------------------------------------------
log "Default shell -> Homebrew bash"
if ! command -v brew >/dev/null 2>&1; then
  warn "Homebrew not available — skipping default shell change"
else
  BREW_BASH="$(brew --prefix bash 2>/dev/null)/bin/bash"
  if [ ! -x "$BREW_BASH" ]; then
    warn "Homebrew bash not installed — skipping default shell change"
  elif [ "$DRY_RUN" -eq 1 ]; then
    echo "  (would set default shell to $BREW_BASH if not already)"
  elif [ "$SHELL" = "$BREW_BASH" ]; then
    ok "already the default shell"
  else
    if ! grep -qxF "$BREW_BASH" /etc/shells 2>/dev/null; then
      echo "$BREW_BASH" | sudo tee -a /etc/shells >/dev/null
    fi
    if chsh -s "$BREW_BASH"; then
      ok "default shell set to $BREW_BASH (takes effect in new terminal sessions)"
    else
      warn "couldn't set default shell"
      FAILED+=("chsh")
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 5. GitHub projects (SimonBoeck) -> ~/Documents/Workspace
#    Uses gh (installed via the Brewfile above). 'gh auth login' opens the
#    interactive sign-in if needed. Without it, cloning is skipped entirely —
#    private repos matter, so there's no silent public-only fallback.
# ---------------------------------------------------------------------------
log "GitHub projects ($GITHUB_USER) -> $WORKSPACE_DIR"

if [ "$DRY_RUN" -eq 1 ]; then
  mkdir -p "$WORKSPACE_DIR" 2>/dev/null || true
else
  mkdir -p "$WORKSPACE_DIR"
fi

if ! command -v gh >/dev/null 2>&1; then
  warn "gh not available — skipping repo clone"
else
  if ! gh auth status >/dev/null 2>&1; then
    if [ -t 0 ]; then
      log "Not signed in to GitHub yet — opening 'gh auth login' (sign in as $GITHUB_USER)"
      gh auth login || true
    else
      warn "Not signed in to GitHub and not running interactively"
    fi
  fi

  if ! gh auth status >/dev/null 2>&1; then
    warn "Not signed in to GitHub — skipping repo clone (private repos need 'gh auth login')"
    FAILED+=("gh-auth")
  else
    REPO_NAMES=$(gh repo list "$GITHUB_USER" --limit 1000 --json name -q '.[].name' 2>/dev/null)

    if [ -z "${REPO_NAMES:-}" ]; then
      warn "Couldn't list repos for $GITHUB_USER"
    else
      while IFS= read -r name; do
        [ -z "$name" ] && continue
        dest="$WORKSPACE_DIR/$name"
        if [ -d "$dest/.git" ]; then
          ok "$name (already cloned)"
        elif [ "$DRY_RUN" -eq 1 ]; then
          would_clone "$GITHUB_USER/$name -> $dest"
        elif gh repo clone "$GITHUB_USER/$name" "$dest" >/dev/null 2>&1; then
          ok "$name"
        else
          warn "$name"
          FAILED+=("repo:$name")
        fi
      done <<< "$REPO_NAMES"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log "Done"
if [ "${#FAILED[@]}" -eq 0 ]; then
  echo "Everything succeeded."
else
  echo "These failed and need a look:"
  for f in "${FAILED[@]}"; do echo "  - $f"; done
fi
