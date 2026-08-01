#!/usr/bin/env bash

# Tomdot Installer - installation step functions

DOTFILES_DIR="${HOME}/.dotfiles"

# Pipe command output through ui_detail for live progress
_progress() {
    while IFS= read -r line; do
        [[ -n "$line" ]] && ui_detail "$line"
    done
}

# --- Step functions ---

step_ssh() {
    local desc="Set up SSH keys"
    local ssh_dir="${HOME}/.ssh"
    local key_personal="${ssh_dir}/id_ed25519_personal"
    local key_work="${ssh_dir}/id_rsa_silicondali"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        ui_detail "ssh/config -> ~/.ssh/config"
        [[ -f "$key_personal" ]] && ui_detail "personal key exists" || ui_detail "would generate id_ed25519_personal (ed25519)"
        [[ -f "$key_work" ]] && ui_detail "silicondali key exists" || ui_detail "would generate id_rsa_silicondali (rsa — ADO requires it)"
        ui_detail "would test github + azure devops connections"
        return 0
    fi

    # Nothing to do if both keys exist and the config is already linked.
    if [[ -f "$key_personal" && -f "$key_work" \
          && "$(readlink "${ssh_dir}/config" 2>/dev/null)" == "${DOTFILES_DIR}/ssh/config" ]]; then
        ui_step_skip "$desc"
        return 0
    fi

    ui_step_start "$desc"

    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    # Config is tracked in the repo; keys never are.
    rm -f "${ssh_dir}/config"
    ln -sf "${DOTFILES_DIR}/ssh/config" "${ssh_dir}/config"
    ui_detail "ssh/config -> ~/.ssh/config"

    # Passphrases are prompted for interactively, then stored in the keychain.
    # Personal key is ed25519; work key must be RSA because Azure DevOps
    # rejects ed25519 ("invalid keys will start with ssh-rsa").
    # Only newly generated keys need registering — existing ones are assumed done.
    local key comment new_keys=()
    for key in "$key_personal" "$key_work"; do
        if [[ "$key" == "$key_personal" ]]; then
            comment="tom.hendra@outlook.com"
        else
            comment="thomas.hendra@silicondali.com"
        fi

        if [[ -f "$key" ]]; then
            ui_detail "$(basename "$key") exists, skipping"
        else
            echo ""
            echo "  Generating $(basename "$key") — enter a passphrase when prompted."
            if [[ "$key" == "$key_personal" ]]; then
                ssh-keygen -t ed25519 -f "$key" -C "$comment"
            else
                ssh-keygen -t rsa -b 4096 -f "$key" -C "$comment"
            fi
            new_keys+=("$key")
        fi
        ssh-add --apple-use-keychain "$key" 2>/dev/null || ssh-add "$key" 2>/dev/null || true
    done

    # Register only the keys generated in this run.
    local url urls
    for key in "${new_keys[@]:-}"; do
        [[ -z "$key" ]] && continue
        command -v pbcopy >/dev/null 2>&1 && pbcopy < "${key}.pub"
        echo ""
        echo "  $(basename "${key}.pub") copied to clipboard."
        if [[ "$key" == "$key_personal" ]]; then
            urls="https://github.com/settings/keys"
            echo "  Add it to your personal GitHub account:"
        else
            urls="https://github.com/settings/keys https://dev.azure.com/SiliconDali/_usersSettings/keys"
            echo "  Add it to the work GitHub account AND Azure DevOps:"
        fi
        for url in $urls; do
            echo "    $url"
            open "$url" 2>/dev/null || true
        done
        echo "  Press Enter when done..."
        read -r
    done

    # Connection tests are diagnostics, not pass/fail criteria: a key that
    # exists locally but isn't registered with a remote yet is a normal
    # intermediate state, not a broken step.
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        ui_detail "github: ok"
    else
        ui_detail "github: not authenticated — add ~/.ssh/id_ed25519_personal.pub"
    fi
    if ssh -T git@ssh.dev.azure.com 2>&1 | grep -qi "authenticated\|shell access"; then
        ui_detail "azure devops: ok"
    else
        ui_detail "azure devops: not authenticated — add ~/.ssh/id_rsa_silicondali.pub"
    fi

    ui_step_ok "$desc"
}

step_homebrew() {
    local desc="Install Homebrew"

    # brew may be installed but absent from PATH (fresh shell, .zprofile not
    # yet linked). Eval shellenv so later steps can find brew-installed tools.
    if [[ -x /opt/homebrew/bin/brew ]] && ! command -v brew >/dev/null 2>&1; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    if command -v brew >/dev/null 2>&1; then
        ui_step_skip "$desc"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        ui_detail "would install homebrew"
        ui_detail "would add to PATH"
        return 0
    fi

    ui_step_start "$desc"

    # Homebrew installer is interactive (sudo prompt), don't pipe through _progress
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    ui_step_ok "$desc"
}

step_packages() {
    local desc="Install packages from Brewfile"
    local brewfile="${DOTFILES_DIR}/Brewfile"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        if [[ -f "$brewfile" ]]; then
            local brew_count cask_count
            brew_count=$(grep -c "^brew " "$brewfile" 2>/dev/null) || brew_count=0
            cask_count=$(grep -c "^cask " "$brewfile" 2>/dev/null) || cask_count=0
            ui_detail "${brew_count} brews, ${cask_count} casks"
        else
            ui_detail "Brewfile not found at $brewfile"
        fi
        return 0
    fi

    if [[ ! -f "$brewfile" ]]; then
        ui_step_start "$desc"
        ui_step_fail "$desc"
        return 1
    fi

    ui_step_start "$desc"

    ui_detail "updating homebrew..."
    brew update 2>&1 | _progress
    brew bundle --file="$brewfile" 2>&1 | _progress
    ui_detail "cleaning up..."
    brew cleanup 2>&1 | _progress

    ui_step_ok "$desc"
}

step_languages() {
    local desc="Install Node.js and Rust"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        command -v rustc >/dev/null 2>&1 && ui_detail "rust: installed" || ui_detail "would install rust via rustup"
        command -v fnm >/dev/null 2>&1 && ui_detail "fnm: installed" || ui_detail "fnm: not found (install via homebrew first)"
        command -v node >/dev/null 2>&1 && ui_detail "node: installed" || ui_detail "would install node LTS via fnm"
        ui_detail "would enable corepack (pnpm, yarn)"
        [[ -f "${DOTFILES_DIR}/global_pkg.sh" ]] && ui_detail "would install global npm packages" || ui_detail "global_pkg.sh not found"
        return 0
    fi

    ui_step_start "$desc"

    # brew-installed tools (fnm) may not be on PATH yet when run standalone
    if [[ -x /opt/homebrew/bin/brew ]] && ! command -v brew >/dev/null 2>&1; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # Rust
    if ! command -v rustc >/dev/null 2>&1; then
        ui_detail "installing rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | _progress
        source "$HOME/.cargo/env"
    fi

    # Node.js via fnm
    if ! command -v fnm >/dev/null 2>&1; then
        ui_detail "fnm not found on PATH — is it installed? (brew install fnm)"
        ui_step_fail "$desc"
        return 1
    fi

    eval "$(fnm env --use-on-cd)" >/dev/null 2>&1

    # `fnm install --lts` is idempotent — skips if already installed.
    ui_detail "installing node lts..."
    fnm install --lts 2>&1 | _progress
    fnm use lts-latest >/dev/null 2>&1
    fnm default lts-latest >/dev/null 2>&1

    ui_detail "enabling corepack..."
    corepack enable >/dev/null 2>&1
    corepack enable pnpm >/dev/null 2>&1
    corepack enable yarn >/dev/null 2>&1

    # Global npm packages
    if [[ -f "${DOTFILES_DIR}/global_pkg.sh" ]]; then
        ui_detail "installing global npm packages..."
        sh "${DOTFILES_DIR}/global_pkg.sh" 2>&1 | _progress
    fi

    ui_step_ok "$desc"
}

step_claude_code() {
    local desc="Install Claude Code CLI"

    if command -v claude >/dev/null 2>&1; then
        ui_step_skip "$desc"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        ui_detail "would run: curl -fsSL https://claude.ai/install.sh | bash"
        return 0
    fi

    ui_step_start "$desc"

    ui_detail "downloading..."
    curl -fsSL https://claude.ai/install.sh | bash 2>&1 | _progress

    ui_step_ok "$desc"
}

step_kiro() {
    local desc="Install Kiro CLI"
    local app="/Applications/Kiro CLI.app/Contents/MacOS"
    local bin="${HOME}/.local/bin"

    if [[ -x "${bin}/kiro-cli" ]]; then
        ui_step_skip "$desc"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        ui_detail "would run: curl -fsSL https://cli.kiro.dev/install | bash"
        ui_detail "would symlink kiro-cli{,-chat,-term} -> ~/.local/bin/"
        return 0
    fi

    ui_step_start "$desc"

    ui_detail "downloading..."
    curl -fsSL https://cli.kiro.dev/install | bash 2>&1 | _progress

    mkdir -p "$bin"
    for b in kiro-cli kiro-cli-chat kiro-cli-term; do
        ln -sf "${app}/${b}" "${bin}/${b}"
    done
    ui_detail "linked kiro-cli{,-chat,-term} -> ${bin}/"

    ui_step_ok "$desc"
}

step_symlinks() {
    local desc="Create dotfiles symlinks"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        ui_detail "bat/bat.conf -> ~/.config/bat/bat.conf"
        ui_detail "git/.gitconfig -> ~/.gitconfig"
        ui_detail "git/.gitignore_global -> ~/.gitignore_global"
        ui_detail "ghostty/config -> ~/.config/ghostty/config"
        ui_detail "ghostty/themes -> ~/.config/ghostty/themes"
        ui_detail "nvim -> ~/.config/nvim"
        ui_detail "zed/settings.json -> ~/.config/zed/settings.json"
        ui_detail "starship.toml -> ~/.config/starship.toml"
        ui_detail "zsh/.zshrc -> ~/.zshrc"
        ui_detail "zsh/.zprofile -> ~/.zprofile"
        ui_detail "claude/settings.json -> ~/.claude/settings.json"
        ui_detail "claude/CLAUDE.md -> ~/.claude/CLAUDE.md"
        ui_detail "claude/statusline.sh -> ~/.claude/statusline.sh"
        return 0
    fi

    ui_step_start "$desc"

    mkdir -p "${HOME}/.config/bat" "${HOME}/.config/ghostty" "${HOME}/.config/zed" "${HOME}/.claude"

    # Only config is linked from ~/.claude — history, credentials, and caches
    # stay local to each machine.
    local links=(
        "bat/bat.conf:.config/bat/bat.conf"
        "git/.gitconfig:.gitconfig"
        "git/.gitignore_global:.gitignore_global"
        "ghostty/config:.config/ghostty/config"
        "ghostty/themes:.config/ghostty/themes"
        "nvim:.config/nvim"
        "zed/settings.json:.config/zed/settings.json"
        "starship.toml:.config/starship.toml"
        "zsh/.zshrc:.zshrc"
        "zsh/.zprofile:.zprofile"
        "claude/settings.json:.claude/settings.json"
        "claude/CLAUDE.md:.claude/CLAUDE.md"
        "claude/statusline.sh:.claude/statusline.sh"
    )

    for entry in "${links[@]}"; do
        local src="${DOTFILES_DIR}/${entry%%:*}"
        local dst="${HOME}/${entry#*:}"
        mkdir -p "$(dirname "$dst")"
        rm -f "$dst"
        ln -sf "$src" "$dst"
        ui_detail "${entry%%:*} -> ~/${entry#*:}"
    done

    # Bat theme
    if command -v bat >/dev/null 2>&1; then
        local bat_themes_dir
        bat_themes_dir="$(bat --config-dir)/themes"
        mkdir -p "$bat_themes_dir"
        if [[ -f "${DOTFILES_DIR}/bat/themes/Enki-Tokyo-Night.tmTheme" ]]; then
            cp "${DOTFILES_DIR}/bat/themes/Enki-Tokyo-Night.tmTheme" "$bat_themes_dir/"
            ui_detail "building bat cache..."
            bat cache --build 2>&1 | _progress
        fi
    fi

    # Clone repos
    if [[ -f "${DOTFILES_DIR}/git/get_repos.sh" ]]; then
        mkdir -p "${HOME}/Developer"
        ui_detail "cloning repos..."
        sh "${DOTFILES_DIR}/git/get_repos.sh" 2>&1 | _progress || true
    fi

    ui_step_ok "$desc"
}

step_neovim() {
    local desc="Set up Neovim plugins"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        ui_detail "Install plugins via lazy.nvim"
        ui_detail "Install LSP servers and tools via Mason"
        return 0
    fi

    ui_step_start "$desc"

    if ! command -v nvim >/dev/null 2>&1; then
        ui_detail "nvim not found, skipping"
        ui_step_fail "$desc"
        return 1
    fi

    ui_detail "installing plugins..."
    nvim --headless "+Lazy! sync" +qa 2>&1 | _progress
    ui_detail "installing LSP servers and tools..."
    nvim --headless "+MasonToolsInstallSync" +qa 2>&1 | _progress

    ui_step_ok "$desc"
}

# --- Runner ---

run_step() {
    local step="$1"
    case "$step" in
        ssh|ssh_setup)   step_ssh ;;
        homebrew|brew)   step_homebrew ;;
        packages|pkg)    step_packages ;;
        languages|lang)  step_languages ;;
        claude_code|claude) step_claude_code ;;
        kiro_cli|kiro)   step_kiro ;;
        symlinks|links)  step_symlinks ;;
        neovim|nvim)     step_neovim ;;
        *)
            echo "Unknown step: $step"
            echo "Available: ssh, homebrew, packages, languages, claude, kiro, symlinks, neovim"
            return 1
            ;;
    esac
}

run_all() {
    ui_header

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        printf "${C_YELLOW}DRY RUN${C_RESET} — no changes will be made\n"
    fi

    printf "${C_DIM}◇${C_RESET} Prerequisites\n"
    ui_detail "Xcode CLI tools, macOS up to date"

    # A failing step must not abort the rest of the run (set -e would).
    local failed=()
    local s
    for s in ssh homebrew packages languages claude_code kiro symlinks neovim; do
        "step_${s}" || failed+=("$s")
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        echo ""
        printf "${C_YELLOW}Failed steps:${C_RESET} %s\n" "${failed[*]}"
        printf "Rerun individually, e.g. ${C_DIM}./install.sh --step %s${C_RESET}\n" "${failed[0]}"
        return 1
    fi

    ui_done
}
