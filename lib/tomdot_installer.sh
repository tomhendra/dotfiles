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
    local ssh_key="${ssh_dir}/id_rsa"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        [[ -f "$ssh_key" ]] && ui_detail "ssh key exists" || ui_detail "would generate ssh key"
        ui_detail "would test github connection"
        return 0
    fi

    local ssh_output
    ssh_output=$(ssh -T git@github.com -o ConnectTimeout=5 -o StrictHostKeyChecking=no 2>&1 || true)
    if echo "$ssh_output" | grep -q "successfully authenticated"; then
        ui_step_skip "$desc"
        return 0
    fi

    ui_step_start "$desc"

    mkdir -p "$ssh_dir"

    if [[ ! -f "${ssh_dir}/config" ]]; then
        cat > "${ssh_dir}/config" << 'EOF'
Host *
 PreferredAuthentications publickey
 UseKeychain yes
 IdentityFile ~/.ssh/id_rsa
EOF
        chmod 600 "${ssh_dir}/config"
    fi

    if [[ ! -f "$ssh_key" ]]; then
        ui_detail "generating ssh key..."
        ssh-keygen -t rsa -b 4096 -f "$ssh_key" -C "tom.hendra@outlook.com" -N "" 2>&1 | _progress
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add "$ssh_key" >/dev/null 2>&1
    else
        ssh-add -K "$ssh_key" 2>/dev/null || ssh-add "$ssh_key" 2>/dev/null || true
    fi

    if command -v pbcopy >/dev/null 2>&1; then
        pbcopy < "${ssh_key}.pub"
    fi

    ui_detail "SSH public key copied to clipboard"
    open "https://github.com/settings/keys"
    ui_detail "Paste it in the browser window that just opened"
    ui_detail "Press Enter when done..."
    read -r

    ssh_output=$(ssh -T git@github.com 2>&1 || true)
    if echo "$ssh_output" | grep -q "successfully authenticated"; then
        ui_step_ok "$desc"
    else
        ui_step_fail "$desc"
        return 1
    fi
}

step_homebrew() {
    local desc="Install Homebrew"

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

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" 2>&1 | _progress

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
            local brew_count cask_count mas_count
            brew_count=$(grep -c "^brew " "$brewfile" 2>/dev/null || echo 0)
            cask_count=$(grep -c "^cask " "$brewfile" 2>/dev/null || echo 0)
            mas_count=$(grep -c "^mas " "$brewfile" 2>/dev/null || echo 0)
            ui_detail "${brew_count} brews, ${cask_count} casks, ${mas_count} mas apps"
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

step_fonts() {
    local desc="Install Zed Mono Extended fonts"
    local fonts_dir="${HOME}/Library/Fonts"

    if ls "$fonts_dir"/zed-mono-extended*.ttf >/dev/null 2>&1; then
        ui_step_skip "$desc"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        ui_detail "would download zed-mono-1.2.0.zip"
        ui_detail "would install extended variants to ~/Library/Fonts"
        return 0
    fi

    ui_step_start "$desc"

    local temp_dir="/tmp/zed-mono-install"
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"

    ui_detail "downloading..."
    curl -sL "https://github.com/zed-industries/zed-fonts/releases/download/1.2.0/zed-mono-1.2.0.zip" -o "$temp_dir/zed-mono.zip"
    ui_detail "extracting..."
    unzip -q "$temp_dir/zed-mono.zip" -d "$temp_dir"
    cp "$temp_dir"/zed-mono-extended*.ttf "$fonts_dir/"
    rm -rf "$temp_dir"

    ui_step_ok "$desc"
}

step_languages() {
    local desc="Install Node.js and Rust"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        command -v rustc >/dev/null 2>&1 && ui_detail "rust: installed" || ui_detail "would install rust via rustup"
        command -v fnm >/dev/null 2>&1 && ui_detail "fnm: installed" || ui_detail "fnm: not found (install via homebrew first)"
        command -v node >/dev/null 2>&1 && ui_detail "node: installed" || ui_detail "would install node 22 via fnm"
        ui_detail "would enable corepack (pnpm, yarn)"
        [[ -f "${DOTFILES_DIR}/global_pkg.sh" ]] && ui_detail "would install global npm packages" || ui_detail "global_pkg.sh not found"
        return 0
    fi

    ui_step_start "$desc"

    # Rust
    if ! command -v rustc >/dev/null 2>&1; then
        ui_detail "installing rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>&1 | _progress
        source "$HOME/.cargo/env"
    fi

    # Node.js via fnm
    if ! command -v fnm >/dev/null 2>&1; then
        ui_step_fail "$desc"
        return 1
    fi

    eval "$(fnm env --use-on-cd)" >/dev/null 2>&1

    if ! fnm list 2>/dev/null | grep -q "v22"; then
        ui_detail "installing node 22..."
        fnm install 22 2>&1 | _progress
    fi
    fnm use 22 >/dev/null 2>&1
    fnm default 22 >/dev/null 2>&1

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

step_symlinks() {
    local desc="Create dotfiles symlinks"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        ui_step_dry "$desc"
        ui_detail "bat/bat.conf -> ~/.config/bat/bat.conf"
        ui_detail "git/.gitconfig -> ~/.gitconfig"
        ui_detail "git/.gitignore_global -> ~/.gitignore_global"
        ui_detail "ghostty/config -> ~/.config/ghostty/config"
        ui_detail "ghostty/themes -> ~/.config/ghostty/themes"
        ui_detail "zed/settings.json -> ~/.config/zed/settings.json"
        ui_detail "starship.toml -> ~/.config/starship.toml"
        ui_detail "zsh/.zshrc -> ~/.zshrc"
        ui_detail "zsh/.zprofile -> ~/.zprofile"
        return 0
    fi

    ui_step_start "$desc"

    mkdir -p "${HOME}/.config/bat" "${HOME}/.config/ghostty" "${HOME}/.config/zed"

    local links=(
        "bat/bat.conf:.config/bat/bat.conf"
        "git/.gitconfig:.gitconfig"
        "git/.gitignore_global:.gitignore_global"
        "ghostty/config:.config/ghostty/config"
        "ghostty/themes:.config/ghostty/themes"
        "zed/settings.json:.config/zed/settings.json"
        "starship.toml:.config/starship.toml"
        "zsh/.zshrc:.zshrc"
        "zsh/.zprofile:.zprofile"
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

# --- Runner ---

run_step() {
    local step="$1"
    case "$step" in
        ssh|ssh_setup)   step_ssh ;;
        homebrew|brew)   step_homebrew ;;
        packages|pkg)    step_packages ;;
        fonts)           step_fonts ;;
        languages|lang)  step_languages ;;
        claude_code|claude) step_claude_code ;;
        symlinks|links)  step_symlinks ;;
        *)
            echo "Unknown step: $step"
            echo "Available: ssh, homebrew, packages, fonts, languages, claude, symlinks"
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
    ui_detail "Xcode CLI tools, App Store login, macOS up to date"

    step_ssh
    step_homebrew
    step_packages
    step_fonts
    step_languages
    step_claude_code
    step_symlinks

    ui_done
}
