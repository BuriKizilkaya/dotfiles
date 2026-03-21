#!/usr/bin/env bash
# Assertion script — runs inside the Docker container after bootstrap.
# Checks that all dotfiles are applied and tools are available.

set -e

PASS=0
FAIL=0
ERRORS=()

# ── Helpers ────────────────────────────────────────────────────────────────

pass() {
    echo "  [PASS] $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "  [FAIL] $1"
    FAIL=$((FAIL + 1))
    ERRORS+=("$1")
}

assert_file() {
    local path="$1"
    if [ -f "$path" ]; then
        pass "File exists: $path"
    else
        fail "File missing: $path"
    fi
}

assert_file_contains() {
    local path="$1"
    local pattern="$2"
    if [ -f "$path" ] && grep -q "$pattern" "$path"; then
        pass "File $path contains '$pattern'"
    else
        fail "File $path does not contain '$pattern'"
    fi
}

assert_command() {
    local cmd="$1"
    if command -v "$cmd" &>/dev/null; then
        pass "Command available: $cmd"
    else
        fail "Command not found: $cmd"
    fi
}

assert_symlink() {
    local path="$1"
    if [ -L "$path" ]; then
        pass "Symlink exists: $path"
    else
        fail "Symlink missing: $path"
    fi
}

# ── Tests ──────────────────────────────────────────────────────────────────

echo ""
echo "── Dotfiles (chezmoi) ────────────────────────────────────────────────"

assert_file "$HOME/.gitconfig"
assert_file_contains "$HOME/.gitconfig" "defaultBranch = main"
assert_file_contains "$HOME/.gitconfig" "autocrlf = false"

assert_file "$HOME/.zshrc"
assert_file_contains "$HOME/.zshrc" "oh-my-zsh"
assert_file_contains "$HOME/.zshrc" "starship init zsh"
assert_file_contains "$HOME/.zshrc" "mise activate"

assert_file "$HOME/.profile.dev"
assert_file_contains "$HOME/.profile.dev" "groot"
assert_file_contains "$HOME/.profile.dev" "alias isodate"

assert_file "$HOME/.config/starship/starship.toml"
assert_file_contains "$HOME/.config/starship/starship.toml" "add_newline"

assert_file "$HOME/.config/mise/config.toml"
assert_file_contains "$HOME/.config/mise/config.toml" "just"
assert_file_contains "$HOME/.config/mise/config.toml" "opencode"

assert_file "$HOME/.config/terminator/config"
assert_file_contains "$HOME/.config/terminator/config" "background_color"

echo ""
echo "── Tools ─────────────────────────────────────────────────────────────"

assert_command "chezmoi"
assert_command "zsh"
assert_command "git"
assert_command "mise"
assert_command "just"
assert_command "starship"

# ── Summary ────────────────────────────────────────────────────────────────

echo ""
echo "──────────────────────────────────────────────────────────────────────"
echo "  Results: $PASS passed, $FAIL failed"

if [ ${#ERRORS[@]} -gt 0 ]; then
    echo ""
    echo "  Failed checks:"
    for e in "${ERRORS[@]}"; do
        echo "    - $e"
    done
    echo ""
    exit 1
fi

echo ""
