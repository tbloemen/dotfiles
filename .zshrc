# --- Antidote Plugin Manager ---
source ~/.zsh_plugins.zsh

# --- Starship Prompt (optimize via `starship.toml`) ---
eval "$(starship init zsh)"

# --- Interactive Shell Guard ---
if [[ $- == *i* ]]; then

  # Optional: fzf keybindings and completion (comment if not needed)
  source <(fzf --zsh)

  # --- Completion with Caching ---
  export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
  autoload -Uz compinit && compinit -d "$ZSH_COMPDUMP"

  # --- Shell integrations after compinit ---
  eval "$(zoxide init zsh)"
fi

# --- Autoload functions ---
fpath=( ~/.zsh_autoload_functions "${fpath[@]}" )
autoload -Uz load_secrets

# --- History Settings ---
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# --- Completion Styling ---
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:z:*' fzf-preview 'ls --color -a $realpath'

# --- Aliases ---
alias ls='eza'
alias ll='eza -l -a --icons=always'
alias lst='eza -a -T -L 5'
alias vim='nvim'
alias cd='z'

# --- Path Setup ---
export PATH="$PATH:/home/ties/.spicetify"
export PATH="$HOME/miniconda3/bin:$PATH"

# --- Environment ---
export EDITOR=nvim
export GTK_THEME=Adwaita:light

# --- Lazy-load NVM ---
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# --- Lazy-load Conda ---
function conda() {
  unset -f conda
  if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
    conda "$@"
  else
    echo "Conda not found"
  fi
}

# --- Yazi cd Wrapper ---
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
