FROM ubuntu:24.04

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

# Run bootstrap
RUN bash /dotfiles/scripts/bootstrap.sh

# Default: run the test assertions
CMD ["bash", "/dotfiles/tests/assert.sh"]
