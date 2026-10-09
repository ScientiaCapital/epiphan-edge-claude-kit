#!/usr/bin/env bash
# One-line installer for the Epiphan Edge × Claude Code kit (macOS, Linux, WSL).
#   curl -fsSL https://raw.githubusercontent.com/ScientiaCapital/epiphan-edge-claude-kit/main/install.sh | bash
# Safe to re-run. Installs or updates Claude Code (Anthropic's official installer), downloads
# this kit into ~/epiphan-edge-claude-kit, points it at your Epiphan region, then opens Claude Code.
# No admin rights needed. Optional: EPIPHAN_KIT_DIR (folder), EPIPHAN_REGION (na, eu or au),
# EPIPHAN_KIT_REF (a tag, branch or commit; default: the latest release, never the tip of main).
set -euo pipefail

REPO="https://github.com/ScientiaCapital/epiphan-edge-claude-kit"
CLONE="${EPIPHAN_KIT_CLONE:-$REPO.git}"  # override is only for CI tests of unpublished changes
DIR="${EPIPHAN_KIT_DIR:-$HOME/epiphan-edge-claude-kit}"
REF="${EPIPHAN_KIT_REF:-}"
MARKER=".epiphan-kit"  # left in folders that were downloaded without git

say() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mProblem: %s\033[0m\n' "$1" >&2; exit 1; }
interactive() { [ -z "${CI:-}" ] && { : </dev/tty; } 2>/dev/null; }
# Real git, not the placeholder macOS ships before the developer tools are installed.
have_git() { git --version >/dev/null 2>&1; }

latest_release() { # prints the latest release tag; bash only, since the no-git path may have no sed or grep
  local json re='"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)"'
  json=$(curl -fsSL -m 15 "https://api.github.com/repos/ScientiaCapital/epiphan-edge-claude-kit/releases/latest") || return 1
  [[ $json =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}
checkout_ref() { # checkout_ref <dir>: switch an existing clone to $REF (a tag, branch or commit)
  git -C "$1" fetch --quiet --depth 1 origin "$REF" && git -C "$1" checkout --quiet --detach FETCH_HEAD
}
download_tarball() {
  local tmp
  tmp=$(mktemp -d)
  if ! curl -fsSL "$REPO/archive/${REF:-main}.tar.gz" | tar -xz -C "$tmp"; then
    rm -rf "$tmp"
    fail "The download failed. Check your internet connection, then paste the install line again."
  fi
  mkdir -p "$DIR"
  cp -R "$tmp"/epiphan-edge-claude-kit-*/. "$DIR/"  # copy over, so your own files stay
  rm -rf "$tmp"
  touch "$DIR/$MARKER"
  printf '%s\n' "${REF:-main}" > "$DIR/$MARKER"
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
# The published kit is installed at its latest release, so a re-run never picks up unreviewed changes on main.
if [ -z "$REF" ] && [ -z "${EPIPHAN_KIT_CLONE:-}" ]; then
  REF=$(latest_release || true)
  [ -n "$REF" ] || echo "(Couldn't look up the latest release. Using the newest files on main.)"
fi
origin=$( (have_git && git -C "$DIR" remote get-url origin) 2>/dev/null || true)
if [ -d "$DIR/.git" ] && [ -n "$origin" ] && [ "${origin%.git}" = "${CLONE%.git}" ]; then
  echo "Found it in $DIR. Updating..."
  if [ -n "$REF" ]; then checkout_ref "$DIR" || echo "Couldn't update to $REF (did you change files?). Keeping your copy as is."
  else git -C "$DIR" pull --ff-only --quiet || echo "Couldn't update (did you change files?). Keeping your copy as is."; fi
elif [ -f "$DIR/$MARKER" ]; then
  echo "Found it in $DIR. Updating..."
  download_tarball
elif [ -e "$DIR" ]; then
  fail "$DIR already exists but isn't this kit. Rename that folder, then paste the install line again."
elif have_git; then
  git clone --quiet --depth 1 "$CLONE" "$DIR"
  if [ -n "$REF" ]; then checkout_ref "$DIR" || fail "Couldn't fetch $REF. Check EPIPHAN_KIT_REF, then paste the install line again."; fi
  echo "Downloaded to $DIR"
else
  download_tarball
  echo "Downloaded to $DIR"
fi
if [ -n "$REF" ]; then version="$REF"
elif [ -d "$DIR/.git" ] && have_git; then version=$(git -C "$DIR" describe --tags --always 2>/dev/null || true)
else version=$(cat "$DIR/$MARKER" 2>/dev/null || true); fi
echo "Kit version: ${version:-main}"

say "Step 3 of 4: Your Epiphan region"
region="${EPIPHAN_REGION:-}"
if [ -z "$region" ] && interactive; then
  echo "Where is your Epiphan Edge account? Check the web address you sign in at. (Not sure? Press Enter for 1.)"
  echo "  1) North America  (go.epiphan.cloud)"
  echo "  2) Europe         (eu.epiphan.cloud)"
  echo "  3) Australia      (au.epiphan.cloud)"
  printf 'Type 1, 2 or 3 and press Enter [1]: '
  read -r choice </dev/tty || choice=""
  case "$choice" in 2) region=eu ;; 3) region=au ;; *) region=na ;; esac
fi
if [ -z "$region" ]; then
  # No keyboard to ask (run from a script) and no EPIPHAN_REGION: leave the region as it was.
  # A new install has no override, so that's North America.
  echo "No region given. Keeping the current one (North America unless you picked another before)."
else
  case "$region" in  # any letter case; no external tools (macOS bash 3.2, minimal PATH)
    [Nn][Aa]) url="https://go.epiphan.cloud/mcp" ;;
    [Ee][Uu]) url="https://eu.epiphan.cloud/mcp" ;;
    [Aa][Uu]) url="https://au.epiphan.cloud/mcp" ;;
    *)        fail "EPIPHAN_REGION is '$region'. Use na, eu or au." ;;
  esac
  # North America is the default in .mcp.json. Other regions get a private override for this
  # folder (stored in ~/.claude.json), so the shared files never change and updates keep working.
  (
    cd "$DIR" || exit 1  # set -e is off inside a subshell on the left of ||
    claude mcp remove --scope local epiphan >/dev/null 2>&1 || true
    if [ "$url" != "https://go.epiphan.cloud/mcp" ]; then
      claude mcp add --scope local --transport http epiphan "$url" >/dev/null
    fi
  ) || fail "Couldn't set the region. Paste the install line again."
  echo "Using $url"
fi

# jq lets the kit hide stream keys from Claude (.claude/hooks/epiphan-redact.sh). macOS 15+ has it built in.
if ! command -v jq >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
  echo "Installing jq with Homebrew (it hides stream keys, the passwords that let a device stream, from Claude). This can take a minute..."
  HOMEBREW_NO_AUTO_UPDATE=1 brew install jq >/dev/null 2>&1 || true
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "Note: jq isn't installed. Until it is, results that may contain stream keys are withheld from Claude."
  echo "      Mac: brew install jq (or download it from jqlang.github.io/jq)   Linux: install the jq package   Then nothing else to do."
fi

say "Step 4 of 4: Open Claude Code"
cat <<EOF
When Claude Code opens:
  1. First time only: sign in to your Claude account in the browser.
  2. "Do you trust the files in this folder?"  ->  Yes
  3. "New MCP server found in this project: epiphan"  ->  press the up arrow to "Use this MCP server", then Enter
     (the highlight starts on "Continue without", so Enter straight away says no)
  4. Type  /connect-epiphan  and press Enter. It signs you in to Epiphan Edge without leaving Claude.

Next time, open a terminal and type:
  cd "$DIR" && claude
EOF

# Open Claude Code right away when there's a real terminal (not in CI or a script).
if interactive; then
  cd "$DIR"
  exec claude </dev/tty
fi
