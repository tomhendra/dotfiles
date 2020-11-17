<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1567091669/tomhendra-logo/tomhendra-logo-round-1024.png" width="100" />
<h1>Hola 👋</h1>
</div>

## Disclaimer

Dotfiles are personal and as such I advise against blindly running them yourself. By all means, fill your boots, but I am very much the bash script amateur so please don't rebuke me if your Mac says no.

## What

On a fresh macOS system, the `install.sh` script will install...

1. Xcode Command Line Tools.
2. Applications & fonts via Homebrew & App Store.
3. Configuration for Node.js version management with n.
4. NPM global packages.
5. SSH key pair for authentication.
6. Project repos from GitHub to `~/Dev`.
7. Symlinks from `~/.dotfiles` to OS.
8. macOS system preferences.

## Pre-Installation

- Backup premium fonts to iCloud.
- Backup any required application preferences to `~/.dotfiles/preferences`.
- Ensure `~/.dotfiles` & `~/Dev` repos are up-to-date & pushed to GitHub.

## Installation

- Enter Internet Recovery Mode, by holding <kbd>⌘</kbd> + <kbd>⌥</kbd> + <kbd>R</kbd> on startup.
- Use Disk Utility to delete 'Macintosh - Data volume' and erase 'Macintosh HD'.
- Clean install macOS.
- Install premium fonts not available via Homebrew.
- Login to App Store manually (`mas signin` is [broken](https://github.com/mas-cli/mas#-sign-in)).
- Run dotfiles installation script in terminal: `curl -ssL https://git.io/tomdot | sh`

## Post-Installation

- Install apps purchased outside of App Store (Sketch, Adobe, Affinity...).
- Set iTerm2 preferences to load from `~/.dotfiles/preferences`.
- Restart computer to finalize the process.

## Credit

My dotfiles have been created using snippets and inspiration from others I have discovered, with thanks to these very smart people:

- Kent C Dodds
- Dries Vints
- Mathias Bynens
- Paul Irish
- Paul Miller
- Zach Holman
