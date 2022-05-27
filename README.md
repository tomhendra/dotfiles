<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1567091669/tomhendra-logo/tomhendra-logo-round-1024.png" width="100" />
<h1>Hola 👋</h1>
</div>

**TLDR:** For all the web dev things on macOS: `curl -ssL https://git.io/tomdot | sh`

**Disclaimer:** Dotfiles are personal things, and as such I would advise against rolling these ones unmodified. By all means, fill your boots, but I am no shellscript expert so there most likely will be misfires. 

## What is Installed

On a fresh macOS system, running `install.sh` script will handle the following:

1. Xcode CLT & Homebrew.
2. SSH keys & repos from GitHub.
3. Homebrew packages.
4. App Store purchases.
5. Node.js configured via n.
6. npm global packages.
7. Symlinks from `~/.dotfiles`.
8. macOS system preferences.

## Pre-Installation

- Access iCloud in terminal: `cd ~/Library/Mobile\ Documents/com~apple~CloudDocs/`
- Backup premium fonts to `iCloud/Fonts` (Operator Mono & Operator Mono Nerd Font).
- Backup any desired app preferences to `iCloud/Preferences`.
- Ensure all desired GitHub repos are included in `~/.dotfiles/git/clone-projects.sh` to be cloned to local.
- Ensure local `~/.dotfiles` & repos in `~/Dev` are up-to-date & pushed to GitHub.

## Installation

- To perform a clean install on macOS Monterey: 
  - Launch System Preferences & select Erase All Content and Settings.
- To perform a clean install on macOS Big Sur or earlier: 
  - Enter Internet Recovery Mode by holding <kbd>⌘</kbd> + <kbd>⌥</kbd> + <kbd>R</kbd> on startup.
  - Use Disk Utility to delete 'Macintosh - Data volume' and erase 'Macintosh HD' as APFS (for SSD).
- Install fresh copy of macOS using on-screen prompts.
- Login to App Store manually (`mas signin` is [broken](https://github.com/mas-cli/mas/issues/164) 🤕).
- Run this command in terminal: `curl -ssL https://git.io/tomdot | sh`.

## Post-Installation

- Install premium fonts from iCloud backup.
- Launch fig.app & go through setup.
- Install apps not purchased from App Store (Affinity Photo/Designer/Sketch).
- Install web browser extensions.
- Restart computer.

## Credit

Inspiration comes from these very smart people with many thanks:

- [Dries Vints](https://github.com/driesvints/dotfiles)
- [Kent C Dodds](https://github.com/kentcdodds/dotfiles)
- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Paul Irish](https://github.com/paulirish/dotfiles)
- [Paul Miller](https://github.com/paulmillr/dotfiles)
- [Zach Holman](https://github.com/holman/dotfiles)

## Next Steps: Add Tooling 

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

All things considered, Mackup's negatives outweigh its positives. 

The current setup of git and symlinks works, but could scale messily and isn't compatible with Linux. Bringing a tool into play would be beneficial. GNU Stow and Ansible are the popular choices, with Stow being more frequently recommended. 

Next course of action when time allows: 

- 📝 Dotfiles: Stow and git (make Linux-safe for sharing).
- 📝 App prefs: iCloud (native support by app, or `ln` / Stow from iCloud to Library).
