# Mac Setup Checklist

## Pre-Wipe Backup

- [ ] Backup fonts: `cp -r ~/Library/Fonts ~/Library/Mobile\ Documents/com~apple~CloudDocs/Fonts`
- [ ] VS Code Settings Sync enabled and verified
- [ ] Chrome/Firefox signed in and synced
- [ ] All local repos committed and pushed to GitHub
- [ ] iCloud files fully synced
- [ ] Update repos list in `~/.dotfiles/git/get_repos.sh` if needed
- [ ] Push dotfiles: `cd ~/.dotfiles && git add -A && git commit -m "Pre-M5 update" && git push`

---

## Fresh macOS Install

- [ ] Clean install macOS Sequoia (or latest)
- [ ] Complete initial macOS setup (user account, region, etc.)
- [ ] Login to App Store (GUI only, `mas signin` is broken)
- [ ] Install Xcode from App Store
- [ ] Install Xcode Command Line Tools: `xcode-select --install`
- [ ] Run Software Update to ensure CLT is latest version

---

## Run Install Script

- [ ] Open Terminal
- [ ] Run: `curl -ssL https://git.io/tomdot | sh`
- [ ] Follow prompts (GitHub SSH key, dialogs, etc.)
- [ ] Wait for completion (~15-30 minutes depending on connection)

---

## Optional: Apply macOS Settings

- [ ] Run: `cd ~/.dotfiles && ./.macos`
- [ ] Restart Mac

---

## Post-Install Verification

- [ ] Verify Node.js: `node -v` (should be v22.20.0)
- [ ] Verify npm: `npm -v` (should be 10.9.3)
- [ ] Verify pnpm: `pnpm -v` (via Corepack)
- [ ] Verify fnm: `fnm list` (should show v22.20.0 default)
- [ ] Verify only one Node: `which -a node` (should show fnm path only)
- [ ] Verify Rust: `rustc --version`
- [ ] Verify Solana: `solana --version`
- [ ] Verify global packages: `npm list -g --depth=0`

---

## Manual Settings (Cannot be scripted)

- [ ] System Settings → Desktop & Documents Folders → Enable iCloud Drive
- [ ] System Settings → Trackpad → Configure gestures
- [ ] System Settings → Keyboard → Keyboard Shortcuts → Configure as needed
- [ ] Restore fonts from iCloud to `~/Library/Fonts`
- [ ] Raycast → Import snippets/workflows
- [ ] VS Code → Sign in to sync extensions
- [ ] Ghostty → Verify Tokyo Night theme loaded
- [ ] Configure any app-specific preferences

---

## Troubleshooting

### If fnm not found:

```bash
source ~/.zshrc
```

### If pnpm not working:

```bash
corepack enable
```

### If SSH key issues:

```bash
ssh-add ~/.ssh/id_rsa
ssh -T git@github.com
```

### If Homebrew not in PATH:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```
