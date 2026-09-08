#!/usr/bin/env bash
# Exercise wallpaper writes without contacting the compositor or changing HOME.
set -euo pipefail

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export HOME="$scratch/home"
mkdir -p "$HOME/.config/rofi" "$scratch/bin"
ln -s "$repo/backgrounds/.config/backgrounds" "$HOME/.config/backgrounds"
ln -s "$repo/config/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"
ln -s "$repo/config/rofi/colors.rasi" "$HOME/.config/rofi/colors.rasi"
install -m 644 "$repo/config/rofi/background.rasi" "$HOME/.config/rofi/background.rasi"

printf '#!/usr/bin/env bash\n[[ "$1" == hyprpaper && "$2" == wallpaper && "$3" == *,*cover ]]\n' > "$scratch/bin/hyprctl"
chmod +x "$scratch/bin/hyprctl"
export PATH="$scratch/bin:$PATH"

before=$(sha256sum "$repo/config/rofi/"*.rasi)
bash "$repo/scripts/change-wallpaper.sh"
test "$(< "$HOME/.cache/wallpaper-index")" = 1
first=$(< "$HOME/.config/rofi/background.rasi")
bash "$repo/scripts/change-wallpaper.sh"
test "$(< "$HOME/.cache/wallpaper-index")" = 2
test "$first" != "$(< "$HOME/.config/rofi/background.rasi")"
test ! -L "$HOME/.config/rofi/background.rasi"
test -w "$HOME/.config/rofi/background.rasi"
test -L "$HOME/.config/rofi/config.rasi"
test "$before" = "$(sha256sum "$repo/config/rofi/"*.rasi)"
test -f "$HOME/.config/backgrounds/griffith.jpg"

# The Lua compositor requires dispatcher expressions, not Hyprlang commands.
! grep -Eq "hyprctl dispatch (workspace|dpms|exit)([^A-Za-z]|$)" \
  "$repo/config/waybar/config.jsonc" "$repo/config/hypr/hypridle.conf" \
  "$repo/config/wlogout/layout"

bash -n "$repo/scripts/change-wallpaper.sh"
bash -n "$repo/config/waybar/scripts/weather.sh"
if command -v luac >/dev/null; then
  for file in "$repo/config/hypr/"*.lua "$repo/config/hypr/conf/"*.lua; do
    luac -p "$file"
  done
fi
printf 'Linux desktop smoke checks passed (no activation or live IPC).\n'
