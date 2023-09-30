<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1567091669/tomhendra-logo/tomhendra-logo-round-1024.png" width="100" />
<h1>tomdot</h1>
</div>

**TL;DR:** For web dev things on a clean macOS install: `curl -ssL https://git.io/tomdot | sh`

**Disclaimer:** Dotfiles are personal things, and as such I advise against rolling these ones unmodified — they are specific to my setup and will need to be tweaked for yours. 

## What is tomdot?

I am Tom and these are my dotfiles so tomdot is how they shall be known!

On a fresh macOS system, running the script will do the following:

1. Generate SSH auth keys for GitHub.
2. Download repos from GitHub to your local machine.
3. Install NVM.
4. Install Node.js.
5. Install global npm packages.
6. Activate Yarn via corepack.
7. Activate pnpm via corepack.
8. Install Bun.
9. Install Homebrew & packages.
10. Install Mac App Store purchases.
11. Change the Bat colour theme.
12. Symlink config files from `~/.dotfiles` to system.

## Preparation

There is some preparation to be done before performing a clean install of macOS to ensure smooth sailing.

- Backup fonts to iCloud: `mv ~/Library/Fonts ~/Library/Mobile\ Documents/com~apple~CloudDocs/Fonts`.
- Backup any desired app preference files to iCloud.
- Ensure all repos that you want to be cloned from GitHub are included in the `repos_array` of `~/.dotfiles/git/get_repos.sh`.
- Ensure local `~/.dotfiles` and project repos are up-to-date & pushed to GitHub.
- Ensure VS Code settings sync is turned on.
- Ensure browsers are signed into and are synced.
- Ensure Bitwarden or equivalent password manager is synced.
- Login to icloud with a browser and ensure all backed-up fonts and preferences have actually been uploaded.
- Update the NVM install script in install.sh (line 42) to latest version. 
- Upgrade MacOS to latest version. 

## Installation

1. Perform a clean install of macOS. See Apple Support articles [here](https://support.apple.com/en-gb/guide/mac-help/mh27903/mac) and [here](https://support.apple.com/en-us/HT204904) for instructions.
2. Ensure you are logged into the App Store (`mas signin` has been [broken for years](https://github.com/mas-cli/mas/issues/164)).
3. Install Bitwarden manually, enable the extension in Safari and login to GitHub.
4. Install Xcode CLT [manually](https://developer.apple.com/download/all/), since `xcode-select --install` doesn't work on M2 + fresh install of Sonama, for me at least.
5. Run `curl -ssL https://git.io/tomdot | sh` in the terminal and buckle up!

## Post-Installation

- Install fonts backed-up to iCloud.
- Run `fig` in Kitty.
- Launch Raycast.
- Install any apps not purchased from App Store or unavailable via Homebrew (IdeaShare).
- Login to Chrome to sync extensions etc.
- Add SSH public key to Azure DevOps
- Install Xcode Simulator.
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

## Notes
Fig is used for zsh plugin management. For manual control [Antidote](https://getantidote.github.io) has you covered. 

At the time of writing (25/10/22) Fig's Dotfile feature is lacking – aliases added to Fig do not appear in Fig's autocomplete.

## TODO

Consider GNU Stow or Ansible over manually symlinking for Linux compatibility.
