#!/bin/bash

set -e # Stop if any command fails

DOTFILES_DIR="$(realpath "$(dirname "$0")")"

# Install build essential
sudo apt install build-essential curl

echo "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sudo apt install zsh
  export RUNZSH=no
  export CHSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed."
fi

ln -sf $DOTFILES_DIR/zsh/zshrc ~/.zshrc
ln -sf $DOTFILES_DIR/config/rosrc ~/.rosrc
ln -sf $DOTFILES_DIR/config/aliasrc ~/.aliasrc
# ln -sf $DOTFILES_DIR/config/apikeys ~/.apikeys

# Sync custom plugins (including submodules)
CUSTOM_SRC="$DOTFILES_DIR/zsh/plugins/custom"
CUSTOM_DEST="$HOME/.oh-my-zsh/custom/plugins"

# Ensure git submodules are initialized
echo "Updating submodules..."
git -C "$DOTFILES_DIR" submodule update --init --recursive

echo "Syncing custom plugins..."
mkdir -p "$CUSTOM_DEST"
rsync -a "$CUSTOM_SRC/" "$CUSTOM_DEST/"

########## Neovim + LazyVim ##########
echo "Setting up Neovim + LazyVim..."

# Install Neovim if not found
if ! command -v nvim &>/dev/null; then
  echo "Neovim not found. Installing..."
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install neovim
  else
    wget https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz &&
      tar -zxvf nvim-linux-x86_64.tar.gz && ./nvim-linux-x86_64/bin/nvim &&
      rm -rf nvim-linux-x86_64 nvim-linux-x86_64.tar.gz
  fi
else
  echo "Neovim already installed."
fi

# Setup LazyVim
NVIM_SRC="$DOTFILES_DIR/config/nvim"
NVIM_DEST="$HOME/.config/nvim"

if ! [ -d "$NVIM_SRC" ]; then
  echo "Downloading LazyVim ..."
  git clone https://github.com/LazyVim/starter $NVIM_SRC &&
    rm -rf $NVIM_SRC/.git
  echo "Linking LazyVim config..."
  mkdir -p "$(dirname "$NVIM_DEST")"
  ln -sf "$NVIM_SRC" "$NVIM_DEST"
else
  echo "nvim config already exist."
fi

########## Nerd Font ##########

echo "Checking for Nerd Font..."

if ! fc-list | grep -qi "JetBrainsMono Nerd"; then
  echo "Installing Nerd Font (JetBrainsMono)..."
  mkdir -p ~/.local/share/fonts
  cd ~/.local/share/fonts
  curl -LO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip
  unzip -o JetBrainsMono.zip
  rm JetBrainsMono.zip
  fc-cache -fv

  echo "Nerd Font installed."
else
  echo "Nerd Font already installed."
fi

# Change shell to zsh
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Changing default shell to zsh..."
  chsh -s "$(which zsh)"
fi

########## tmux ##########
echo "Checking for tmux..."
if command -v tmux &>/dev/null; then
  echo "tmux is installed."
else
  echo "tmux is not installed. Installing tmux..."
  mkdir tmp && cd tmp
  git clone https://github.com/tmux/tmux.git
  cd tmux
  sh autogen.sh
  ./configure
  make && sudo make install
  cd ../..
  rm -rf tmp
fi
echo "Linking tmux configuration..."
ln -sf $DOTFILES_DIR/config/tmux/tmux.conf ~/.tmux.conf

########## Done ##########
echo ""
echo "All done! Final checklist:"
echo " - Set your terminal font to 'JetBrainsMono Nerd Font'"
echo " - Launch Neovim with 'nvim'"
echo " - Let LazyVim finish installing plugins on first launch"
