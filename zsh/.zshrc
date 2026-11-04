# default language
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Environment variables
export JAVA_HOME="/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home"
export DEVELOPER="${HOME}/Developer"
export DOTFILES="${HOME}/.dotfiles"
export OBSIDIAN="${HOME}/Library/Mobile Documents/iCloud~md~obsidian/Documents/"
export ANDROID_HOME="${HOME}/Library/Android/sdk"
export ANDROID_NDK="${ANDROID_HOME}/ndk/27.1.12297006"
export BAT_CONFIG_PATH="${HOME}/.config/bat/bat.conf"
export GHOSTTY_CONFIG_PATH="${HOME}/.config/ghostty/config"

# Start SSH agent & add all SSH keys
eval "$(ssh-agent -s)" >/dev/null
ssh-add -A 2>/dev/null

# Path configurations
typeset -U path  # Ensures unique entries in PATH

path=(
    "$HOME/.rbenv/bin"
    "./node_modules/.bin"
    "./vendor/bin"
    "$HOME/.local/share/solana/install/active_release/bin"
    "$ANDROID_HOME/emulator"
    "$ANDROID_HOME/platform-tools"
    "/usr/local/sbin"
    "$HOME/.local/bin"
    $path
)

export PATH

# Ruby version management init
eval "$(rbenv init -)"

# Aliases
source "${DOTFILES}/zsh/zsh_aliases.zsh"

# Starship init
eval "$(starship init zsh)"

# bun completions
[ -s "${HOME}/.bun/_bun" ] && source "${HOME}/.bun/_bun"

# fnm
FNM_PATH="/opt/homebrew/opt/fnm/bin"
if [ -d "$FNM_PATH" ]; then
  eval "`fnm env`"
fi

# flashlight
export PATH="/Users/tomhendra/.flashlight/bin:$PATH"

# inshellisense: ctrl-L runs zsh's clear-screen widget, which erases the screen and
# redraws the prompt without firing zle-line-init, so inshellisense never gets its
# prompt-start/end marks and stops suggesting until the next command. Re-emit them.
if [[ -n "$ISTERM" ]]; then
  __is_clear_screen() {
    zle .clear-screen
    zle -R   # flush the erase + prompt redraw now, so the marks land after it
    if (( ${+functions[__is_prompt_start]} )); then
      __is_prompt_start
      __is_prompt_end
    fi
  }
  zle -N clear-screen __is_clear_screen
fi

# inshellisense (must stay the last line)
[[ -f "${HOME}/.local/share/inshellisense/init/zsh/init.zsh" ]] && source "${HOME}/.local/share/inshellisense/init/zsh/init.zsh"
