# dotfiles

Repo containing my dotfiles for hyprland.

It is reccomended to install a nerd font for icon support.

For example install MartianMono Nerd Font, extract it to your font directory (/usr/share/fonts) and then upadte the cache ```fc-cache -fv```

First install all the packages:

```zsh
pacman -S stow blueman hypridle hyprlock hyprpaper hyprland hyprshot ghostty nautilus firefox rofi-wayland waybar fastfetch brightnessctl
```

use stow to create symlinks!

```zsh
cd dotfiles
stow hypridle hyprlock hyprpaper hyprland
```
