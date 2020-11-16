#!/bin/sh

dotfiles="${HOME}/.dotfiles"

# Clone dotfiles repo to .dotfiles in home dir.
git clone git@github.com:tomhendra/dotfiles.git ${dotfiles}

# Symlink bat config.
ln -s ${dotfiles}/bat.cfg ${HOME}/.config/bat/config

# Symlink git files.
ln -s ${dotfiles}/.gitconfig ${HOME}/.gitconfig
ln -s ${dotfiles}/.gitignore_global ${HOME}/.gitignore_global

# Symlink Mackup config.
ln -s ${dotfiles}/.mackup.cfg ${HOME}/.mackup.cfg

# Symlink Starship config.
ln -s ${dotfiles}/starship.toml ${HOME}/.config/starship.toml

# Symlink .zshrc config
cat ${HOME}/.zshrc >> ${dotfiles}/zsh/.zshrc.bak
rm -rf ${HOME}/.zshrc
ln -s ${dotfiles}/zsh/.zshrc ${HOME}/.zshrc