# ~/.bashrc: interactive configuration for Homebrew Bash on macOS.

[[ $- != *i* ]] && return

# Support shells started directly instead of through ~/.bash_profile.
if ! command -v brew >/dev/null 2>&1 && [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export EDITOR="nvim"
export VISUAL="$EDITOR"
export PAGER="less"
export GOPATH="$HOME/go"
export MANPAGER="sh -c 'col -bx | bat --language man --plain'"

# Keep user-installed tools available without hard-coded runtime versions.
for directory in "$HOME/.local/bin" "$HOME/bin" "$GOPATH/bin" "$HOME/.cargo/bin"; do
  case ":$PATH:" in
    *":$directory:"*) ;;
    *) PATH="$directory:$PATH" ;;
  esac
done
unset directory
export PATH

# Append history promptly and share it between interactive sessions.
HISTFILE="$HOME/.bash_history"
HISTCONTROL="ignoreboth:erasedups"
HISTSIZE=100000
HISTFILESIZE=200000
shopt -s histappend checkwinsize
PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# Homebrew's bash-completion@2 supports the modern Bash installed by Brew.
# Keep Apple's Bash 3 usable as a minimal fallback without sourcing Bash 4 code.
bash_completion="${HOMEBREW_PREFIX:-/opt/homebrew}/etc/profile.d/bash_completion.sh"
if (( BASH_VERSINFO[0] >= 4 )) && [[ -r "$bash_completion" ]]; then
  source "$bash_completion"
fi
unset bash_completion

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons=auto --group-directories-first'
  alias ll='eza --long --header --icons=auto --group-directories-first'
  alias lla='eza --long --all --header --git --icons=auto --group-directories-first'
fi
command -v bat >/dev/null 2>&1 && alias cat='bat'
alias c='clear'
alias g='git'
alias lg='lazygit'
alias tree='tree -I ".git|node_modules"'

mkcd() {
  mkdir -p -- "$@" && cd -- "${!#}"
}

# Open IntelliJ with macOS Launch Services, optionally passing files/directories.
ide() {
  if (( $# == 0 )); then
    open -a "IntelliJ IDEA"
  else
    open -a "IntelliJ IDEA" "$@"
  fi
}

# Let Yazi change the current shell's directory when it exits.
y() {
  local tmp cwd yazi_status
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return 1
  command yazi "$@" --cwd-file="$tmp"
  yazi_status=$?
  if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  command rm -f -- "$tmp"
  return "$yazi_status"
}

system-updater() {
  if ! command -v brew >/dev/null 2>&1; then
    printf 'Homebrew is not installed. Run the dotfiles installer first.\n' >&2
    return 1
  fi
  brew update && brew upgrade && brew cleanup || return
  if command -v mise >/dev/null 2>&1; then
    mise upgrade
  fi
}

# Runtime and interactive integrations are optional during first bootstrap.
command -v mise >/dev/null 2>&1 && eval "$(mise activate bash)"
command -v fzf >/dev/null 2>&1 && eval "$(fzf --bash)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"

# A lightweight prompt for the supported fallback shell.
PS1='\[\e[38;5;35m\]\t \[\e[38;5;33m\]\h:\w\[\e[0m\]\n> '
