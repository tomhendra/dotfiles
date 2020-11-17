#!/bin/sh

dotfiles="${HOME}/.dotfiles"

# bat
rm -rf ${HOME}/.config/bat/config
ln -s ${dotfiles}/bat.cfg ${HOME}/.config/bat/config

# git
rm -rf ${HOME}/.gitconfig ${HOME}/.gitignore_global
ln -s ${dotfiles}/.gitconfig ${HOME}/.gitconfig
ln -s ${dotfiles}/.gitignore_global ${HOME}/.gitignore_global

# Starship
rm -rf ${HOME}/.config/starship.toml
ln -s ${dotfiles}/starship.toml ${HOME}/.config/starship.toml

# zsh
cat ${HOME}/.zshrc >> ${dotfiles}/zsh/.zshrc.bak
rm -rf ${HOME}/.zshrc
ln -s ${dotfiles}/zsh/.zshrc ${HOME}/.zshrc