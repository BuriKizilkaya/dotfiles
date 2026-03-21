#!/usr/bin/env bash
# Run dotfiles tests inside a fresh Ubuntu Docker container.
# Usage: bash tests/run-tests.sh [--no-cache]
#
# Set GITHUB_TOKEN to avoid GitHub API rate limits, either via a .env file
# in the repo root or directly in your environment:
#   echo "GITHUB_TOKEN=ghp_..." > .env
#   bash tests/run-tests.sh

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="dotfiles-test"
NO_CACHE=""
SECRET_ARG=""

if [[ "$1" == "--no-cache" ]]; then
    NO_CACHE="--no-cache"
fi

# Load .env from repo root if it exists (does not override already-set vars)
if [[ -f "$DOTFILES_DIR/.env" ]]; then
    set -o allexport
    source "$DOTFILES_DIR/.env"
    set +o allexport
fi

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    SECRET_ARG="--secret id=github_token,env=GITHUB_TOKEN"
    echo "==> Using GITHUB_TOKEN for GitHub API requests."
fi

echo "==> Building test image..."
docker build $NO_CACHE $SECRET_ARG \
    -f "$DOTFILES_DIR/tests/Dockerfile" \
    -t "$IMAGE" \
    "$DOTFILES_DIR"

echo ""
echo "==> Running tests..."
docker run --rm "$IMAGE"

echo ""
echo "All tests passed."
