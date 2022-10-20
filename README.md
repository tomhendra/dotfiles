<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1567091669/tomhendra-logo/tomhendra-logo-round-1024.png" width="100" />
<h1>Hola 👋</h1>
</div>

**TL;DR:** For all the web dev things on macOS: `curl -ssL https://git.io/tomdot | sh`

**Disclaimer:** Dotfiles are personal things, and as such I would advise against rolling these ones unmodified. By all means, fill your boots, but I am no shellscript expert so there probably will be misfires. 

## What is Installed

On a fresh macOS system, running `install.sh` script will handle the following:

1. SSH auth for GitHub.
2. Projects from GitHub to local ~/Developer directory.
3. Node.js using pnpm as both version & package manager.
4. Global npm packages.
5. Rust.
6. Homebrew & packages.
7. App Store purchases.
8. Bat syntax colour theme.
9. Symlinks from `~/.dotfiles`.
10. macOS system preferences.

## Pre-Installation

- Access iCloud in terminal: `cd ~/Library/Mobile\ Documents/com~apple~CloudDocs/`
- Backup premium fonts to `iCloud/Fonts` (Operator Mono & Operator Mono Nerd Font).
- Backup any desired app preferences to `iCloud/Preferences`.
- Ensure all active projects are included in `~/.dotfiles/git/projects.sh` to be cloned from GitHub.
- Ensure local `~/.dotfiles` & repos in `~/Developer` are up-to-date & pushed to GitHub.
- Ensure `~/dotfiles/browser-exts.txt` is up-to-date.

## Installation

- To perform a clean install on macOS Monterey or later: 
  - Launch System Preferences & select 'Erase All Content and Settings'.
- To perform a clean install on macOS Big Sur or earlier: 
  - Enter Internet Recovery Mode by holding <kbd>⌘</kbd> + <kbd>⌥</kbd> + <kbd>R</kbd> on startup.
  - Use Disk Utility to delete 'Macintosh - Data volume' and erase 'Macintosh HD' as APFS (for SSD).
- Install fresh copy of macOS using on-screen prompts.
- Login to App Store manually (`mas signin` is [broken](https://github.com/mas-cli/mas/issues/164) 🤕).
- Run this command in terminal: `curl -ssL https://git.io/tomdot | sh`.

## Post-Installation

- Install premium fonts from iCloud backup.
- Launch fig.app with `fig` in console & go through setup.
- Install any apps not purchased from App Store or available via Homebrew.
- Install web browser extensions from `browser-exts.txt`.
- Generate SSH keys for pseudonym.
- Restart computer.

## Credit

Inspiration comes from these very smart people with many thanks:

- [Dries Vints](https://github.com/driesvints/dotfiles)
- [Kent C Dodds](https://github.com/kentcdodds/dotfiles)
- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Paul Irish](https://github.com/paulirish/dotfiles)
- [Paul Miller](https://github.com/paulmillr/dotfiles)
- [Zach Holman](https://github.com/holman/dotfiles)

## Notes
This setup uses Fig for zsh plugin management. If preferable to control this manually then [Antidote](https://getantidote.github.io) has you covered. 

At the time of writing (25/09/22) Fig's Dotfiles feature is lacking – aliases do not appear in Fig's autocomplete.

Mackup was removed from the workflow due to the following considerations. 

There aren't many supported apps that I use for which Mackup would be useful:

- Bat
- Git
- Docker
- NPM
- ripgrep
- Starship
- Vim
- Yarn
- Zsh

Other supported apps that I use would not benefit much from Mackup:

- Homebrew: Not much to configure
- IINA: A media player
- Messages: iCloud backup
- Apple Music: iCloud backup
- WhatsApp Web: Synced to iPhone

**Benefits of Mackup**

- No need to pull dotfiles repo from GitHub to apply changes locally.
- Making changes to dotfiles is more work than running `mackup backup` in terminal. 
- Newly installed apps just need a `mackup.cfg` entry to be backed up, if supported. 

**Drawbacks of Mackup**

- Less control (although specifying which apps to handle in `.cfg` is better than the reverse).
- Zsh / Vim errors (reported) - Common pattern seems to be excluding zsh in `Mackup.cfg`! 
- Moving things away from Mackup due to errors complicates maintenance by requiring additional backup methods.
- Mackup dev team's support list contains apps without official vendor support. 
- Negative comments from vendors requesting removal from Mackup's support list!
- Dropbox file duplicate errors due to devices syncing concurrently (error handling concerns).

Mackup's drawbacks outweigh its benefits. 

The current setup of git and symlinks works, but could scale messily and isn't compatible with Linux. Bringing a tool into play would be beneficial. GNU Stow and Ansible are the popular choices, with Stow being more frequently recommended. 

## Roadmap

- 📝 Dotfiles: Stow and git (make Linux-safe for sharing).
- 📝 App prefs: iCloud (native support by app, or `ln` / Stow from iCloud to Library).
