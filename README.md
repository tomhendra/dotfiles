<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1567091669/tomhendra-logo/tomhendra-logo-round-1024.png" width="100" />
<h1>Hola 👋</h1>
</div>

**Disclaimer:** Dotfiles are personal and as such I advise against using these ones unchanged. By all means, fill your boots, but I am very much the  scripting amateur, so please don't *bash* me if your Mac grumbles.

On a fresh macOS system, the `install.sh` script will install...

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
- Backup any required app preferences to `~/Dropbox/Preferences`.
- Ensure `~/.dotfiles` & `~/Dev` repos are up-to-date & pushed to GitHub.

## Installation

- Enter Internet Recovery Mode by holding <kbd>⌘</kbd> + <kbd>⌥</kbd> + <kbd>R</kbd> on startup.
- Use Disk Utility to delete 'Macintosh - Data volume' and erase 'Macintosh HD' as APFS (for SSD).
- Install squeaky clean macOS.
- Login to App Store manually (`mas signin` is [broken](https://github.com/mas-cli/mas#-sign-in)) :(
- Run dotfiles installation script in terminal: `curl -ssL https://git.io/tomdot | sh`

## Post-Installation

- Install premium fonts that were backed up to iCloud.
- Set iTerm2 preferences to load from `~/Dropbox/Preferences` (temporarily disable 'save changes to folder when iterm2 quits' to avoid overwrite).
- Install apps purchased outside of App Store.
- Restart computer to finalize the process.

## Credit

My dotfiles have been created using snippets and inspiration from others I have discovered, with thanks to these very smart people:

- [Kent C Dodds](https://github.com/kentcdodds/dotfiles)
- [Dries Vints](https://github.com/driesvints/dotfiles)
- [Mathias Bynens](https://github.com/mathiasbynens/dotfiles)
- [Paul Irish](https://github.com/paulirish/dotfiles)
- [Paul Miller](https://github.com/paulmillr/dotfiles)
- [Zach Holman](https://github.com/holman/dotfiles)

## Next Steps: Tool Consideration 

Mackup was removed from the workflow, because the only useful support (not already handled) is easily configured with a dotfile and symlinked:

- Docker
- npm
- ripgrep
- Vim
- yarn

And everything else I use which is supported by Mackup would be of little use due to the reasons in brackets:

- Homebrew (not much to configure!)
- IINA (a media player)
- Messages (iCloud)
- Apple Music (iCloud)
- WhatsApp Web (synced to iPhone)

Benefits of Mackup:

- No need to pull changes from GitHub dotfiles repo on other machine.
- Make a change to dotfile > run `mackup backup` > done. 
- New apps installed just need a mackup.cfg entry if supported. 

Drawbacks of Mackup: 

- Lack of control (although we can specify which apps to handle, which is better than the reverse).
- Need to remember where dotfiles are located for editing.
- `mackup backup` command symlinks everything not just what has changed (?).
- zsh / vim issues (reported) - Common pattern seems to be excluding zsh in Mackup.cfg! 
- If zsh / vim need to be handled outside Mackup anyway, I'd prefer dotfile management to be unified. 
- iTerm2 overwrites Mackup set symlinks (verified).
- Mackup dev team lists apps as supported without having official vendor support. 
- Negative comments from vendors requesting removal from Mackup's support list!
- Reports of file duplicates by Dropbox due to devices syncing concurrently.

All things considered, Mackup's negatives far outweigh the positives. 

The current setup with git and symlinks works, but could could scale poorly, and isn't Linux-compatible. Bringing a tool into play seems like a good idea. GNU Stow and Ansible are the popular choices, with Stow being more frequently recommended. 

Dropbox is now used for iTerm2 prefs and Alfred (if adopted) prefers sync via Dropbox. 

This sets a course for a future workflow: 

- Dotfiles: Stow and git (make Linux-safe for future proofing).
- App prefs: Dropbox (supported by app, manually dumped or scripted).
