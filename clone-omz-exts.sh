  #!/bin/sh

  plugins="$ZSH_CUSTOM/plugins"
  themes="$ZSH_CUSTOM/themes"
  
  # Exentions
  git clone https://github.com/zsh-users/zsh-autosuggestions.git $plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $plugins/zsh-syntax-highlighting

  # Theme
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $themes/powerlevel10k
