#!/bin/sh

symlink () {
  dotfiles_path="${HOME}/.dotfiles/$1"
  home_path="${HOME}/$2"

  ln -sf ${dotfiles_path} ${home_path}
  echo "th: ${home_path}: Symlink created"
}

# bat
symlink bat.cfg .config/bat/config

# git
symlink git/.gitconfig .gitconfig
symlink git/.gitignore_global .gitignore_global

# Kitty
symlink kitty.conf .config/kitty/kitty.conf

# Starship
symlink starship.toml .config/starship.toml

# zsh
symlink zsh/.zshrc .zshrc
symlink zsh/.zsh_plugins.txt .zsh_plugins.txt