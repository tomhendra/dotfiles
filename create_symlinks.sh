#!/bin/sh

symlink () {
  dotfiles_path="${HOME}/.dotfiles/$1"
  home_path="${HOME}/$2"

  ln -sf ${dotfiles_path} ${home_path}
  echo "th: ${home_path}: Symlink created"
}

# bat
symlink bat/bat.conf .config/bat/bat.conf

# git
symlink git/.gitconfig .gitconfig
symlink git/.gitignore_global .gitignore_global

# Starship
symlink starship.toml .config/starship.toml

# Ghostty
symlink ghostty .config/ghostty

# zsh
symlink zsh/.zshrc .zshrc
symlink zsh/.zprofile .zprofile

# vscode
# symlink vscode/custom.css .config/vscode/custom.css
