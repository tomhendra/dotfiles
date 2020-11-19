<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1567091669/tomhendra-logo/tomhendra-logo-round-1024.png" width="100" />
<h1>Hola 👋</h1>
</div>

**TLDR:** For all the things on squeaky clean macOS: `curl -ssL https://git.io/tomdot | sh`

**Disclaimer:** Dotfiles are personal things, and as such I would advise against rolling these ones unmodified. By all means, fill your boots, but I am no shellscript expert so there ~~may well~~ most likely will be misfires. 

## What is Installed

On a fresh macOS system the `install.sh` script will install...

1. Xcode CLT & Homebrew.
2. SSH keys & repos from GitHub.
3. Packages, apps & fonts.
4. Node.js configured for n.
5. NPM global packages.
6. Symlinks from `~/.dotfiles`.
7. Theme for bat & delta.
8. macOS system preferences.

## Pre-Installation

- Backup premium fonts to iCloud.
- Backup any desired app preferences to Dropbox.
- Ensure `~/.dotfiles` & `~/Dev` repos are up-to-date & pushed to GitHub.

## Do Installation

- Enter Internet Recovery Mode by holding <kbd>⌘</kbd> + <kbd>⌥</kbd> + <kbd>R</kbd> on startup.
- Use Disk Utility to delete 'Macintosh - Data volume' and erase 'Macintosh HD' as APFS (for SSD).
- Install fresh copy of macOS.
- Login to App Store manually (`mas signin` is [broken](https://github.com/mas-cli/mas#-sign-in) 🤕)
- Run dotfiles installation script in terminal: `curl -ssL https://git.io/tomdot | sh`

## Post-Installation

- Install premium fonts from iCloud backup.
- Set iTerm2 to load preferences from Dropbox (temporarily disable 'save changes to folder when iterm2 quits' to avoid overwrite).
- Install apps not purchased from App Store.
- Restart computer.

## Credit

I've used snippets and found inspiration from dotfiles I have discovered, with many thanks to these very smart people:

- [Dries Vints](https://github.com/driesvints/dotfiles)
- [Kent C Dodds](https://github.com/kentcdodds/dotfiles)
- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Paul Irish](https://github.com/paulirish/dotfiles)
- [Paul Miller](https://github.com/paulmillr/dotfiles)
- [Zach Holman](https://github.com/holman/dotfiles)

## Next Steps: Add Tooling 

Mackup was removed from the workflow due to the following considerations. 

The only supported apps that I use which Mackup could prove useful for are: 

- Bat
- Git
- Docker
- NPM
- ripgrep
- Starship
- Vim
- Yarn
- Zsh

The other supported apps that I use would not benefit from Mackup's features due to the reasons stated:

- Homebrew (not much to configure!)
- IINA (a media player)
- Messages (iCloud)
- Apple Music (iCloud for library)
- WhatsApp Web (synced to iPhone)

Benefits of Mackup:

- No need to pull changes from GitHub dotfiles repo to apply changes - "set and forget".
- Make a change to dotfile > run `mackup backup` > done. 
- New apps installed just need a mackup.cfg entry if supported (specifying which apps to handle). 

Drawbacks of Mackup: 

- Less control (although specifying which apps to handle in .cfg is better than the reverse).
- Zsh / Vim errors (reported) - Common pattern seems to be excluding zsh in Mackup.cfg! 
- Moving things away from Mackup due to errors disorganizes maintenance by using multiple backup methods.
- iTerm2 overwrites Mackup-created symlinks (verified).
- Mackup dev team's support list contains apps without official vendor support. 
- Negative comments from vendors requesting removal from Mackup's support list!
- Dropbox file duplicate errors due to devices syncing concurrently (error handling concerns).

All things considered, Mackup's negatives outweigh its positives. 

The current setup of git and symlinks works, but could scale messily and isn't Linux-compatible. Bringing a tool into play would be beneficial. GNU Stow and Ansible are the popular choices, with Stow being more frequently recommended. 

Dropbox is being used for iTerm2 prefs, and Alfred (if adopted after trailing Spotlight improvements) prefers it for sync. This with choosing Stow sets the course of action when time allows: 

- **TODO:** Dotfiles: Stow and git (make Linux-safe for future proofing).
- **TODO:** App prefs: Dropbox (supported by app, or `ln` / Stow from Dropbox to Library).
