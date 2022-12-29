# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Fix the Insecure completition-dependent directories and files
ZSH_DISABLE_COMPFIX=true

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh
eval "$(oh-my-posh init zsh --config /home/burak/.poshthemes/ohmyposh_theme.omp.json)"

# Start Docker daemon automatically when logging in if not running.
RUNNING=`ps aux | grep dockerd | grep -v grep`
if [ -z "$RUNNING" ]; then
  echo "Starting Docker daemon..."
  sudo dockerd > /dev/null 2>&1 &
  disown
fi

# Source all profile files
for file in $HOME/.profile*; do
  source "$file"
done