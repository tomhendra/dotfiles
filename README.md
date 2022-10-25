<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1567091669/tomhendra-logo/tomhendra-logo-round-1024.png" width="100" />
<h1>Hola 👋</h1>
</div>

**TL;DR:** For web dev things on macOS: `curl -ssL https://git.io/tomdot | sh`

**Disclaimer:** Dotfiles are personal things, and as such I would advise against rolling these ones unmodified. 
By all means, fill your boots, but I am no shellscript expert so there probably will be misfires. 

## What is Installed

On a fresh macOS system, running `install.sh` script will handle the following:

1. SSH auth for GitHub.
2. Projects from GitHub to local ~/Developer directory.
3. pnpm.
4. Node.js using pnpm the version manager.
5. Global npm packages.
6. Rust.
7. Homebrew & packages.
8. App Store purchases.
9. Bat colour theme.
10. Symlinks from `~/.dotfiles`.
11. macOS system preferences.

## Pre-Installation

- Access iCloud in terminal: `cd ~/Library/Mobile\ Documents/com~apple~CloudDocs/`
- Backup premium fonts from `~/Library/Fonts` to `iCloud/Fonts` (Operator Mono & Operator Mono Nerd Font).
- Backup any desired app preferences to `iCloud/Preferences`.
- Ensure all active projects are included in `~/.dotfiles/git/get_repos.sh` to be cloned from GitHub.
- Ensure local `~/.dotfiles` & repos in `~/Developer` are up-to-date & pushed to GitHub.
- Ensure `~/dotfiles/browser_exts.txt` is up-to-date.
- Ensure VS Code settings sync is on.
- Login to icloud.com with a browser and ensure fonts and preferences have been uploaded before proceeding.

## Installation

- Perform a clean install of macOS. See Apple Support [here](https://support.apple.com/en-gb/guide/mac-help/mh27903/mac) and [here](https://support.apple.com/en-us/HT204904) for instructions.
- Ensure you are logged into the App Store (`mas signin` has been [broken](https://github.com/mas-cli/mas/issues/164) for years).
- Install password manager and login to GitHub via a browser.
- Run `curl -ssL https://git.io/tomdot | sh` in the terminal and buckle up.

## Post-Installation

- Install premium fonts from iCloud backup.
- Launch fig.app with `fig` in console & go through setup.
- Fig integration with Kitty is experimental. Follow instructions [here](https://github.com/withfig/fig/issues/26#issuecomment-1022537900) and [here](https://github.com/withfig/fig/issues/26#issuecomment-1107334176).
- Install any apps not purchased from App Store or available via Homebrew.
- Install web browser extensions from `browser_exts.txt` (Chrome will do this via sync)
- Generate SSH keys for pseudonym & get repos from GitHub.
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

At the time of writing (25/10/22) Fig's Dotfiles feature is lacking – aliases added to Fig do not appear in Fig's autocomplete!

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

Conclusion -- Mackup's drawbacks outweigh its benefits. 

## TODO

The current setup of git and symlinks works, but could scale messily and isn't compatible with Linux. 
Bringing a tool into play would be beneficial. 
GNU Stow and Ansible are the popular choices, with Stow being more frequently recommended. 
