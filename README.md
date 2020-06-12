<div align=center>
<img alt="Tom Hendra logo" src="https://res.cloudinary.com/tomhendra/image/upload/v1567091669/tomhendra-logo/tomhendra-logo-round-1024.png" width="100" />
<h1>Shell Config for Hyper</h1>
<p>A minimalist style setup with Nord theme.</p>
<video autoplay>
<source src="https://res.cloudinary.com/tomhendra/video/upload/v1591954592/github-readmes/hyper-shell-setup.mp4" type="video/mov">
</video>
</div>

## 1. Install Hyper

Download & install [Hyper](https://hyper.is).

## 2. Configure Hyper

Download & install [FuraCode Nerd Font](https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/FiraCode.zip).

**Note**: To open files in VS Code from the terminal in macOS, you first need to install the code command in the PATH,
otherwise you may receive this error message: `zsh: command not found: code`.

To correct this, open the Command Palette via (F1 or ⇧⌘P) in VS Code and type `shell command` and select the Shell Command: Install 'code' command in PATH

Open the Hyper config file in VS Code.

```sh
code ~/.hyper.js
```

Make the following changes.

```js
fontFamily: 'FuraCode Nerd Font',
lineHeight: 1.2,
fontSize: 13,
webGLRenderer: false, // to allow correct rendering of ligatures.
cursorColor: '#B48EAD',
selectionColor: 'rgba(136,192,208,0.4)',
```

Add plugins:

```js
  plugins: [
    'hyper-nord', // color theme
    'hyper-font-ligatures', // correctly render ligatures
    'hypercwd', // open new tab in current working directory
    'hyper-search', // search functionality
    'hyperlinks', // make links in Hyper clickable
    'hyperterm-summon' // hotkey to show / hide terminal
  ],
```

Add settings to config for `hyperterm-summon`.

```js
module.exports = {
  config: {
    // ...rest of config
    summon: {
      hotkey: 'Cmd+;',
    },
  },
};
```

Quit and relaunch Hyper.

## 3. Install Oh My Zsh

Download Oh My Zsh with curl:

```sh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Clone extensions & theme repos from GitHub and add to Oh My Zsh.

```sh
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
```

## 4. Configure Oh My Zsh

Open Oh My Zsh config file in VS Code.

```sh
code ~/.zshrc
```

Make the following changes.

```sh
plugins=(git vscode zsh-autosuggestions zsh-syntax-highlighting)
ZSH_THEME="powerlevel10k/powerlevel10k"
```

Quit and relaunch Hyper.

## 5. Configure Powerlevel10K theme

The Powerlevel10K config wizard should have started automatically on Hyper relaunch.
To run the config wizard manually at any time run `p10k configure` from Hyper.

Choose the following options:

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

Quit Hyper and relaunch, and you are done! 🚀

Press ⌘; to show and hide the window.

## 6. Bonus: Maintenance

Hyper supports Automatic Updates so you should see a notification when there is an update available.

Oh My Zsh also notifies when updates are available. To update manually at any time run `upgrade_oh_my_zsh` in Hyper.

Oh My Zsh upgrades are handled by the upgrade.sh script.
To update any custom plugins (assuming those are Git clones), you can add a few lines lines to the end of the script:

```sh
code ~/.oh-my-zsh/tools/upgrade.sh
```

```sh
printf "\n${BLUE}%s${RESET}\n" "Updating custom plugins"
cd custom/plugins

for plugin in */; do
  if [ -d "$plugin/.git" ]; then
     printf "${YELLOW}%s${RESET}\n" "${plugin%/}"
     git -C "$plugin" pull
  fi
done
```

Now, whenever Oh My Zsh is updated, your custom plugins will be updated too.
Credit to [Eugene Yarmash](https://unix.stackexchange.com/questions/477258/how-to-auto-update-custom-plugins-in-oh-my-zsh).
