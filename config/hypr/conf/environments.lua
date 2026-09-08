hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")
-- The Nix libXcursor only searches ~/.local/share/icons, ~/.icons and its
-- own store paths, so without this it never sees Arch's /usr/share/icons
-- and Hyprland falls back to its embedded droplet cursor.
hl.env("XCURSOR_PATH", "~/.local/share/icons:~/.icons:~/.nix-profile/share/icons:/usr/share/icons:/usr/share/pixmaps")
hl.env("OZONE_PLATFORM", "wayland")
