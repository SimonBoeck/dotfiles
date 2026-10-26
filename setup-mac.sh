#!/usr/bin/env bash
#
# Sets up a freshly reinstalled Mac:
#   1. Installs Homebrew if needed
#   2. Installs everything listed in ./Brewfile (brew bundle)
#   3. Clones every GitHub repo under SimonBoeck into ~/Documents/Workspace
#
# Keep this script and Brewfile together in the same directory.
#
# Usage:
#   chmod +x setup-mac.sh
#   ./setup-mac.sh              # actually install everything + clone repos
#   ./setup-mac.sh --dry-run    # show what would happen, change nothing
#
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$SCRIPT_DIR/Brewfile"
GITHUB_USER="SimonBoeck"
WORKSPACE_DIR="$HOME/Documents/Workspace"

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

FAILED=()

log()        { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
ok()         { printf '\033[1;32m  ✓\033[0m %s\n' "$1"; }
warn()       { printf '\033[1;31m  ✗\033[0m %s\n' "$1"; }
would_clone(){ printf '\033[1;33m  →\033[0m would clone %s\n' "$1"; }

if [ ! -f "$BREWFILE" ]; then
  echo "Brewfile not found next to this script ($BREWFILE) — aborting." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Homebrew itself
# ---------------------------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry run] would install Homebrew (not found on this machine)"
  else
    log "Installing Homebrew (official installer from brew.sh)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  log "Homebrew already installed"
fi

[ "$DRY_RUN" -eq 1 ] && log "DRY RUN — nothing will be installed, downloaded, or cloned"

# ---------------------------------------------------------------------------
# 2. Everything in the Brewfile (formulae, casks, Mac App Store apps)
# ---------------------------------------------------------------------------
log "Packages from Brewfile"
if [ "$DRY_RUN" -eq 1 ]; then
  if command -v brew >/dev/null 2>&1; then
    brew bundle check --file="$BREWFILE" --no-upgrade --verbose || true
  else
    echo "  (Homebrew isn't installed yet, so nothing can be checked — see Brewfile for the full list)"
  fi
else
  brew update
  if ! brew bundle install --file="$BREWFILE"; then
    warn "brew bundle reported failures — see output above"
    FAILED+=("brew-bundle")
  fi
fi

echo
echo "Not available via Homebrew/App Store — install by hand:"
echo "  - Metashape — commercial license, download from agisoft.com"
echo "  - loch — no known Homebrew cask; install from wherever you originally got it"
echo "  - DecoPlanner — no known Homebrew cask; install from the vendor's site"
echo "  - Python 3.14 standalone installer — only if some app specifically wants the official python.org Framework build; get it from python.org/downloads if so"

# ---------------------------------------------------------------------------
# 3. GitHub projects (SimonBoeck) -> ~/Documents/Workspace
#    Uses gh (installed via the Brewfile above). 'gh auth login' opens the
#    interactive sign-in if needed, so private repos are included. Without
#    signing in, only public repos are cloned.
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
    if [ "$DRY_RUN" -eq 1 ]; then
      would_clone "signing in to GitHub first (gh auth login) — needed to include private repos"
    elif [ -t 0 ]; then
      log "Not signed in to GitHub yet — opening 'gh auth login' (sign in as $GITHUB_USER to include private repos)"
      gh auth login || true
    else
      warn "Not signed in to GitHub and not running interactively — only public repos will be cloned"
    fi
  fi

  if gh auth status >/dev/null 2>&1; then
    REPO_NAMES=$(gh repo list "$GITHUB_USER" --limit 1000 --json name -q '.[].name' 2>/dev/null)
  else
    warn "Still not signed in — falling back to public repos only"
    REPO_NAMES=$(curl -fsSL "https://api.github.com/users/$GITHUB_USER/repos?per_page=100" \
      | python3 -c "import json,sys; [print(r['name']) for r in json.load(sys.stdin)]" 2>/dev/null)
  fi

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
      elif gh auth status >/dev/null 2>&1; then
        if gh repo clone "$GITHUB_USER/$name" "$dest" >/dev/null 2>&1; then
          ok "$name"
        else
          warn "$name"
          FAILED+=("repo:$name")
        fi
      else
        if git clone "https://github.com/$GITHUB_USER/$name.git" "$dest" >/dev/null 2>&1; then
          ok "$name"
        else
          warn "$name"
          FAILED+=("repo:$name")
        fi
      fi
    done <<< "$REPO_NAMES"
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
