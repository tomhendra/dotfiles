<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1567091669/tomhendra-logo/tomhendra-logo-round-1024.png" width="100" />
<h1>Hola 👋</h1>
</div>

On a fresh MacOS system, these dotfiles will install...

1. Xcode Command Line Tools.
2. SSH key for authentication.
3. Node & NPM global packages.
4. Applications & fonts via Homebrew & App Store.
5. Starship prompt & Antibody shell plugin manager for zsh.
6. Symlinks from dotfiles to OS.
7. MacOS system preferences.

Application preferences are backed up by Mackup, excluding some manually symlinked in the dotfiles. Mackup [uses symlinks](https://github.com/lra/mackup#bullsht-what-does-it-really-do-to-my-files) under the hood in the same manner as this repo does, but using iCloud as a backup source rather than GitHub.

# Pre-Installation

- Update mackup & run `mackup backup` to backup system preferences.
- Ensure projects & `~/.dotfiles` repos are committed & pushed to GitHub.

# Installation

- Enter Internet Recovery Mode, by holding CMD + OPT + R on startup.
- Use Disk Utility to delete Macintosh - Data volume, and erase Macintosh HD.
- Fresh install MacOS.
- Install premium fonts not available via Homebrew (Operator Mono / Dank Mono / Fira Code Nerd Font).
- Login to App Store manually (`mas signin` is [broken](https://github.com/mas-cli/mas#-sign-in)).
- Run dotfiles installation script in terminal: `curl -ssL https://git.io/tomdot | sh`

# Post-Installation

- Assuming `mackup backup` was run on the previous system, once Mackup has synced with iCloud on the new system, run `mackup restore`.
- Restart computer to finalize the process.

# Credit

These dotfiles have been created with snippets from others I have discovered. The following very smart folks are to thank:

- Kent C Dodds
- Dries Vints
- Mathias Bynens
- Paul Irish
- Paul Miller
- Zach Holman
