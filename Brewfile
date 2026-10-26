# Declarative package list for this Mac. Install everything with:
#   brew bundle install --file=Brewfile
# Check what's missing without installing anything:
#   brew bundle check --file=Brewfile --verbose

# --- dev tools & CLI -----------------------------------------------------
brew "git"
brew "gh"
brew "mas"
brew "node"
brew "python@3.13"
brew "python@3.14"
brew "python@3.9"
brew "cmake"
brew "ninja"
brew "wget"
brew "gnupg"
brew "imagemagick"
brew "ffmpeg"
brew "tesseract"
brew "sqlite"
brew "yarn"
brew "corepack"

# no prebuilt bottle — these compile from source on install, can take a while
brew "therion"
brew "therion-studio"

# --- personal apps ---------------------------------------------------
cask "affinity"
cask "anaconda"
cask "artcraft-launcher"
cask "blender"
cask "claude"
cask "discord"
cask "gimp"
cask "jetbrains-toolbox"
cask "mos"
cask "obsidian"
cask "pokemon-tcg-live"
cask "shearwater-cloud"
cask "vlc"
cask "balenaetcher"
cask "pycharm"
cask "webstorm"
cask "writerside"

# --- work apps -------------------------------------------------------
cask "bruno"
cask "camo-studio"
cask "multitouch"
cask "postman"
cask "stoplight-studio"

# --- admin-installed apps -------------------------------------------------
cask "google-chrome"
cask "insta360-studio"
cask "microsoft-teams"
cask "parsec"

# --- Microsoft 365 / OneDrive / Windows App -------------------------------
cask "microsoft-word"
cask "microsoft-excel"
cask "microsoft-powerpoint"
cask "microsoft-outlook"
cask "microsoft-onenote"
cask "onedrive"
cask "windows-app"

# --- Mac App Store apps (Apple's own, MAS-exclusive) ----------------------
# needs: already signed in to the App Store app with your Apple ID
mas "iMovie",  id: 408981434
mas "Keynote", id: 361285480
mas "Numbers", id: 361304891
mas "Pages",   id: 361309726

# --- from mathiasbynens' brew.sh (ported) ---------------------------------
# GNU tools & shell — some .aliases/.functions assume these
brew "coreutils"
brew "moreutils"
brew "findutils"
brew "gnu-sed"
brew "bash"
brew "bash-completion@2"

# newer versions of macOS-bundled tools
brew "vim"
brew "grep"
brew "openssh"
brew "screen"
brew "php"
brew "gmp"

# other useful binaries
brew "ack"
brew "git-lfs"
brew "gs"
brew "lua"
brew "lynx"
brew "p7zip"
brew "pigz"
brew "pv"
brew "rename"
brew "rlwrap"
brew "tree"
brew "vbindiff"
brew "zopfli"

# font tools
brew "woff2"

# security / CTF tools (see https://github.com/ctfs/write-ups)
brew "aircrack-ng"
brew "bfg"
brew "binutils"
brew "binwalk"
brew "cifer"
brew "dex2jar"
brew "dns2tcp"
brew "fcrackzip"
brew "foremost"
brew "hydra"
brew "john"
brew "knock"
brew "netpbm"
brew "nmap"
brew "pngcheck"
brew "socat"
brew "sqlmap"
brew "tcpflow"
brew "tcpreplay"
brew "ucspi-tcp"
brew "xpdf"
brew "xz"
# removed from Homebrew, no longer installable: hashpump, tcptrace,
# sfnt2woff, sfnt2woff-zopfli (the bramstein/webfonttools tap is gone)

# --- not available via Homebrew/App Store — install by hand --------------
# Metashape   — commercial license, agisoft.com
# loch        — no known cask; get it from wherever you originally got it
# DecoPlanner — no known cask; get it from the vendor's site
# Python 3.14 standalone installer — only if some app needs the official
#   python.org Framework build specifically (brew's python@3.14 above
#   covers everything else) — python.org/downloads
