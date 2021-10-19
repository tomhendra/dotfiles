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
- Ensure local `~/.dotfiles` & repos in `~/Dev` are up-to-date & pushed to GitHub.

## Installation

- Enter Internet Recovery Mode by holding <kbd>⌘</kbd> + <kbd>⌥</kbd> + <kbd>R</kbd> on startup.
- Use Disk Utility to delete 'Macintosh - Data volume' and erase 'Macintosh HD' as APFS (for SSD).
- Install fresh copy of macOS using on-screen prompts.
- Login to App Store manually (`mas signin` is [broken](https://github.com/mas-cli/mas/issues/164) 🤕).
- Run this command in terminal: `curl -ssL https://git.io/tomdot | sh`.

## Post-Installation

- Install premium fonts from iCloud backup.
- Set iTerm2 to load preferences from iCloud/Preferences directory.
  (Temporarily disable 'save changes to folder when iterm2 quits' to avoid overwrite).
- Launch fig.app & go through setup.
- Install apps not purchased from App Store (Affinity Photo/Designer).
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

Supported apps that I use for which Mackup could be useful are few:

- Bat
- Git
- Docker
- NPM
- ripgrep
- Starship
- Vim
- Yarn
- Zsh

Other supported apps that I use would not benefit from Mackup because:

- Homebrew: Not much to configure
- IINA: A media player
- Messages: iCloud
- Apple Music: iCloud for library
- WhatsApp Web: Synced to iPhone

**Benefits of Mackup**

- No need to pull changes from GitHub dotfiles repo to apply changes - "set and forget".
- Making changes to dotfiles is more work than running `mackup backup`. 
- Newly installed apps supported by Mackup just need a `mackup.cfg` entry. 

**Drawbacks of Mackup**

- Less control (although specifying which apps to handle in `.cfg` is better than the reverse).
- Zsh / Vim errors (reported) - Common pattern seems to be excluding zsh in `Mackup.cfg`! 
- iTerm2 overwrites Mackup-created symlinks (verified).
- Moving things away from Mackup due to errors complicates maintenance by requiring additional backup methods.
- Mackup dev team's support list contains apps without official vendor support. 
- Negative comments from vendors requesting removal from Mackup's support list!
- Dropbox file duplicate errors due to devices syncing concurrently (error handling concerns).

All things considered, Mackup's negatives outweigh its positives. 

The current setup of git and symlinks works, but could scale messily and isn't compatible with Linux. Bringing a tool into play would be beneficial. GNU Stow and Ansible are the popular choices, with Stow being more frequently recommended. 

iCloud is being used for iTerm2 prefs. This with choosing Stow sets the next course of action when time allows: 

- 📝 Dotfiles: Stow and git (make Linux-safe for future proofing).
- 📝 App prefs: iCloud (native support by app, or `ln` / Stow from iCloud to Library).
