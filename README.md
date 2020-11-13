<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1567091669/tomhendra-logo/tomhendra-logo-round-1024.png" width="100" />
<h1>Tom's dotfiles</h1>
</div>

# Notes

[Sync SSH to iCloud] ?

```
$ touch ~/Dropbox/.ssh-config
$ ln -s ~/Dropbox/.ssh-config ~/.ssh/config
```

# Powerlevel10K config: ~/.p10k.zsh
------------------------------------------------

To run the config wizard manually at any time run `p10k configure`.

```sh
1. (y) Yes
2. (y) Yes
3. (y) Yes
4. (y) Yes
5. (1) Lean
6. (1) Unicode
7. (2) 8 colors
8. (2) 24-hour format
9. (2) Two lines
10. (2) Dotted
11. (1) No frame
12. (4) Blue
13. (2) Sparse
14. (2) Many icons
15. (1) Concise
16. (Y) Transient prompt
17. (3) Verbose
18. (y) Yes Overwrite ~/.p10k.zsh
```

Open Powerlevel10k theme config file in VS Code.

```sh
code ~/.p10k.zsh
```

Change the following from false to enable current working directory to be shown in bold.

```sh
POWERLEVEL9K_DIR_ANCHOR_BOLD=true
```

Change prompt symbols for better visibility, especially when using transient prompt:

```sh
  # Default prompt symbol. ❯
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='▶'
  # Prompt symbol in command vi mode. ❮
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='◀'
  # Prompt symbol in visual vi mode. V
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='▼'
  # Prompt symbol in overwrite vi mode. ▶
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='▶▶'
```

Change Transient prompt default to trim down prompt when accepting a command line unless this is the first command typed after changing current working directory.

```sh
POWERLEVEL9K_TRANSIENT_PROMPT=same-dir
```

# Credit

The following very smart folks are to thank for these dotfiles...

- Kent C Dodds
- Dries Vints
- Mathias Bynens
- Paul Irish
- Paul Miller
- Zach Holman