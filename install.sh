#!/usr/bin/env bash
# One-line installer for the Epiphan Edge × Claude Code kit (macOS, Linux, WSL).
#   curl -fsSL https://raw.githubusercontent.com/ScientiaCapital/epiphan-edge-claude-kit/main/install.sh | bash
# Safe to re-run. Installs or updates Claude Code (Anthropic's official installer), downloads
# this kit into ~/epiphan-edge-claude-kit, points it at your Epiphan region, then opens Claude Code.
# No admin rights needed. Optional: EPIPHAN_KIT_DIR (folder), EPIPHAN_REGION (na, eu or au).
set -euo pipefail

REPO="https://github.com/ScientiaCapital/epiphan-edge-claude-kit"
CLONE="${EPIPHAN_KIT_CLONE:-$REPO.git}"  # override is only for CI tests of unpublished changes
DIR="${EPIPHAN_KIT_DIR:-$HOME/epiphan-edge-claude-kit}"
MARKER=".epiphan-kit"  # left in folders that were downloaded without git

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mProblem: %s\033[0m\n' "$1" >&2; exit 1; }
interactive() { [ -z "${CI:-}" ] && { : </dev/tty; } 2>/dev/null; }
# Real git, not the placeholder macOS ships before the developer tools are installed.
have_git() { git --version >/dev/null 2>&1; }

download_tarball() {
  local tmp
  tmp=$(mktemp -d)
  curl -fsSL "$REPO/archive/refs/heads/main.tar.gz" | tar -xz -C "$tmp"
  mkdir -p "$DIR"
  cp -R "$tmp/epiphan-edge-claude-kit-main/." "$DIR/"  # copy over, so your own files stay
  rm -rf "$tmp"
  touch "$DIR/$MARKER"
}

say "Step 1 of 4: Claude Code"
if command -v claude >/dev/null 2>&1; then
  echo "Already installed: $(claude --version 2>/dev/null || echo ok). Checking for updates..."
  claude update >/dev/null 2>&1 || echo "(Couldn't check for updates. That's OK, carrying on.)"
else
  echo "Installing Claude Code with Anthropic's official installer..."
  curl -fsSL https://claude.ai/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
  command -v claude >/dev/null 2>&1 \
    || fail "Claude Code installed, but this terminal can't find it yet. Close the terminal, open a new one, and paste the install line again."
fi

say "Step 2 of 4: The kit"
origin=$( (have_git && git -C "$DIR" remote get-url origin) 2>/dev/null || true)
if [ -d "$DIR/.git" ] && [ -n "$origin" ] && [ "${origin%.git}" = "${CLONE%.git}" ]; then
  echo "Found it in $DIR. Updating..."
  git -C "$DIR" pull --ff-only --quiet || echo "Couldn't update (did you change files?). Keeping your copy as is."
elif [ -f "$DIR/$MARKER" ]; then
  echo "Found it in $DIR. Updating..."
  download_tarball
elif [ -e "$DIR" ]; then
  fail "$DIR already exists but isn't this kit. Rename that folder, then paste the install line again."
elif have_git; then
  git clone --quiet --depth 1 "$CLONE" "$DIR"
  echo "Downloaded to $DIR"
else
  download_tarball
  echo "Downloaded to $DIR"
fi

say "Step 3 of 4: Your Epiphan region"
region="${EPIPHAN_REGION:-}"
if [ -z "$region" ] && interactive; then
  echo "Which Epiphan Cloud region is your account on? (Not sure? It's the one you sign in to.)"
  echo "  1) North America  (go.epiphan.cloud)"
  echo "  2) Europe         (eu.epiphan.cloud)"
  echo "  3) Australia      (au.epiphan.cloud)"
  printf 'Type 1, 2 or 3 and press Enter [1]: '
  read -r choice </dev/tty || choice=""
  case "$choice" in 2) region=eu ;; 3) region=au ;; *) region=na ;; esac
fi
case "${region:-na}" in
  eu) url="https://eu.epiphan.cloud/mcp" ;;
  au) url="https://au.epiphan.cloud/mcp" ;;
  *)  url="https://go.epiphan.cloud/mcp" ;;
esac
# North America is the default in .mcp.json. Other regions get a private override for this
# folder (stored in ~/.claude.json), so the shared files never change and updates keep working.
(
  cd "$DIR"
  claude mcp remove --scope local epiphan >/dev/null 2>&1 || true
  if [ "$url" != "https://go.epiphan.cloud/mcp" ]; then
    claude mcp add --scope local --transport http epiphan "$url" >/dev/null
  fi
)
echo "Using $url"

say "Step 4 of 4: Open Claude Code"
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
if interactive; then
  cd "$DIR"
  exec claude </dev/tty
fi
