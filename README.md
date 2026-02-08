# dotfiles

Repo containing my dotfiles for hyprland.

## Prerequisites

Install a nerd font for icon support. For example MartianMono Nerd Font:
- Extract to `/usr/share/fonts`
- Update cache: `fc-cache -fv`

### Install yay (if not already installed)

```zsh
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay && makepkg -si && cd .. && rm -rf yay
```

## Installation

Install all packages:

```zsh
yay -S stow blueman hypridle hyprlock hyprpaper hyprland hyprshot ghostty dolphin zen-browser-bin rofi-wayland waybar fastfetch brightnessctl wlogout fzf eza bat fd ripgrep noto-fonts-emoji mise networkmanager network-manager-applet
```

Clone and stow:

```zsh
git clone https://github.com/AlapinEnjoyer/dotfiles.git
cd dotfiles
stow backgrounds conf fontconfig ghostty hypridle hyprland hyprlock hyprpaper waybar rofi scripts wlogout
```
