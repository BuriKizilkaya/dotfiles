FROM ubuntu:24.04

WORKDIR /dotfiles

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
ENV USER=root
ENV PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo curl git zsh unzip curl wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy dotfiles repo into the image
COPY . /dotfiles

# Run bootstrap — GITHUB_TOKEN is mounted as a secret so it is never stored
# in the image layer. mise uses it automatically to avoid API rate limits.
# DOTFILES_ENV=devcontainer is set to handle docker image as devcontainer environment
RUN --mount=type=secret,id=github_token \
    GITHUB_TOKEN="$(cat /run/secrets/github_token 2>/dev/null || true)" \
    DOTFILES_ENV=devcontainer \
    bash /dotfiles/bootstrap_devcontainer.sh

# Default: run the test assertions
CMD ["bash", "/dotfiles/tests/assert.sh"]
