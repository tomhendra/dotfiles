<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1696166377/tomhendra-logo/tomhendra-avatar.png" width="100" />
<h1>tomdot</h1>
</div>

**TL;DR:** Run `curl -ssL https://git.io/tomdot | sh` on a clean macOS installation.

**Disclaimer:** Dotfiles are personal things, and as such I would advise against rolling these ones unmodified — they are specific to my dev setup and would likely need to be tweaked to fit yours.

## What is tomdot?

On a fresh macOS system, tomdot will do the following:

1. Generate SSH keys and configure GitHub authentication.
2. Install Homebrew.
3. Install packages, casks, and App Store apps via Brewfile.
4. Install Zed Mono Extended fonts.
5. Install Rust via rustup.
6. Install Node.js 22 via fnm, enable Corepack, install global npm packages.
7. Install Claude Code CLI.
8. Symlink config files (bat, git, ghostty, zed, starship, zsh) and clone repos.

## Preparation

There is some preparation to be done before performing a clean install of macOS to ensure smooth sailing.

- Backup fonts to iCloud: `cp -r ~/Library/Fonts ~/Library/Mobile\ Documents/com~apple~CloudDocs/Fonts`.
- Backup any desired app preference files to iCloud.
- Ensure all repos that you want to be cloned from GitHub are included in the `repos` array in `~/.dotfiles/git/get_repos.sh`.
- Ensure local `~/.dotfiles` and repos are up-to-date & pushed to GitHub.
- Ensure VS Code is signed into and synced.
- Ensure Chrome is signed into and synced.
- Login to iCloud with a browser and ensure all backed-up fonts and preferences have actually been uploaded.
- Update MacOS to the [latest version](https://support.apple.com/en-us/HT201541).

## Installation

1. Perform a clean install of macOS. See Apple Support article [here](https://support.apple.com/en-gb/guide/mac-help/mchl7676b710/15.0/mac/15.0) for instructions.
2. Ensure you are logged into the App Store (`mas signin` has been [broken for many years](https://github.com/mas-cli/mas/issues/164)).
3. Install Xcode + CLT [manually](https://developer.apple.com/download/all/) to avoid Homebrew errors.
4. Run Software update from system settings to ensure CLT is the latest version.
5. Run `curl -ssL https://git.io/tomdot | sh` in the terminal.
6. Grab a coffee and let tomdot do its thing!

## Post-Installation

- Enable Desktop & Documents Folders in Apple menu  > System Settings > iCloud > iCloud Drive.
- Install fonts backed-up to iCloud.
- Launch Raycast & setup.
- Install apps unavailable via Homebrew / App Store (e.g. IdeaShare).
- Login to Chrome & enable sync.
- Add SSH public key to Azure DevOps.
- Install Android studio Emulator.
- Restart computer.

## Credit

The tomdot repo was assembled with many thanks to these smart folks:

- [Dries Vints](https://github.com/driesvints/dotfiles)
- [Kent C Dodds](https://github.com/kentcdodds/dotfiles)
- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Paul Irish](https://github.com/paulirish/dotfiles)
- [Paul Miller](https://github.com/paulmillr/dotfiles)
- [Zach Holman](https://github.com/holman/dotfiles)

## TODO

Consider GNU Stow or Ansible over manual symlinks.
