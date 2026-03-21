#!/usr/bin/env bash
# Run dotfiles tests inside a fresh Ubuntu Docker container.
# Usage: bash tests/run-tests.sh [--no-cache]

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="dotfiles-test"
NO_CACHE=""

if [[ "$1" == "--no-cache" ]]; then
    NO_CACHE="--no-cache"
fi

echo "==> Building test image..."
docker build $NO_CACHE \
    -f "$DOTFILES_DIR/tests/Dockerfile" \
    -t "$IMAGE" \
    "$DOTFILES_DIR"

echo ""
echo "==> Running tests..."
docker run --rm "$IMAGE"

echo ""
echo "==> Cleaning up image..."
docker rmi "$IMAGE" --force > /dev/null 2>&1

echo ""
echo "All tests passed."
