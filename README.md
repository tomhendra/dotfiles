<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1567091669/tomhendra-logo/tomhendra-logo-round-1024.png" width="100" />
<h1>Tom's MacOS dotfiles</h1>
</div>

# Hola 👋

Running `install.sh` installs the following: 

1. Xcode Command Line Tools.
2. SSH key for authentication.
3. Node & NPM global packages.
4. Applications and fonts via Homebrew / App Store.
5. Oh-My-Zsh & Powerlevel10K theme. 
6. Symlinks from repo dotfiles to system.
7. MacOS system preferences.

Application preferences are handled by Mackup, excluding those manually symlinked by the dotfiles. 

Mackup [uses symlinks](https://github.com/lra/mackup#bullsht-what-does-it-really-do-to-my-files) under the hood in the same manner that this repo does, but using iCloud as a backup source rather than GitHub.

# Installation

Run `install.sh` directly by typing `curl -ssL https://git.io/tomdot | sh` in the terminal.

# Post-Installation

- Install premium fonts manually (Operator Mono / Dank Mono).
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
