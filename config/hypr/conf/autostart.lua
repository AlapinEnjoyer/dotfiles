hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("nm-applet")

    -- Set the initial wallpaper after hyprpaper has started.
    hl.exec_cmd("sleep 1 && ~/.scripts/change-wallpaper.sh")
end)
