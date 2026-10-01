#!/usr/bin/env bash
# One-line installer for the Epiphan Edge × Claude Code kit (macOS, Linux, WSL).
#   curl -fsSL https://raw.githubusercontent.com/ScientiaCapital/epiphan-edge-claude-kit/main/install.sh | bash
# Safe to re-run. Installs Claude Code (Anthropic's official installer) if it's missing,
# downloads this kit into ~/epiphan-edge-claude-kit, then opens Claude Code there.
# No admin rights needed. Set EPIPHAN_KIT_DIR to use a different folder.
set -euo pipefail

REPO="https://github.com/ScientiaCapital/epiphan-edge-claude-kit"
DIR="${EPIPHAN_KIT_DIR:-$HOME/epiphan-edge-claude-kit}"

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mProblem: %s\033[0m\n' "$1" >&2; exit 1; }

say "Step 1 of 3: Claude Code"
if command -v claude >/dev/null 2>&1; then
  echo "Already installed: $(claude --version 2>/dev/null || echo ok)"
else
  echo "Installing Claude Code with Anthropic's official installer..."
  curl -fsSL https://claude.ai/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
  command -v claude >/dev/null 2>&1 \
    || fail "Claude Code installed, but this terminal can't find it yet. Close the terminal, open a new one, and paste the install line again."
fi

say "Step 2 of 3: The kit"
if [ -d "$DIR/.git" ]; then
  echo "Found it in $DIR. Updating..."
  git -C "$DIR" pull --ff-only --quiet || echo "Couldn't update (did you change files?). Keeping your copy as is."
elif [ -e "$DIR" ]; then
  fail "$DIR already exists but isn't this kit. Rename that folder, then paste the install line again."
elif command -v git >/dev/null 2>&1; then
  git clone --quiet --depth 1 "$REPO.git" "$DIR"
  echo "Downloaded to $DIR"
else
  tmp=$(mktemp -d)
  curl -fsSL "$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$tmp"
  mv "$tmp/epiphan-edge-claude-kit-main" "$DIR"
  rmdir "$tmp"
  echo "Downloaded to $DIR (no git found, so updates mean re-running this installer)"
fi

say "Step 3 of 3: Open Claude Code"
cat <<EOF
When Claude Code opens:
  1. First time only: sign in to your Claude account in the browser.
  2. "Do you trust the files in this folder?"  ->  Yes
  3. "New MCP server found: epiphan"           ->  choose to use it
  4. Type  /start  and press Enter. It walks you through signing in to Epiphan Edge.

Next time, open a terminal and type:
  cd "$DIR" && claude
EOF

# Open Claude Code right away when there's a real terminal (not in CI or a script).
if [ -z "${CI:-}" ] && { : </dev/tty; } 2>/dev/null; then
  cd "$DIR"
  exec claude </dev/tty
fi
