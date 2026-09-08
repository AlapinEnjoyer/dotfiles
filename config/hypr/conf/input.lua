hl.config({
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        follow_mouse = 1,
        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.config({
    cursor = {
        -- Use the system XCursor theme instead of Hyprland's embedded
        -- hyprcursor theme: the installed Adwaita ships no hyprcursor data,
        -- so the embedded Hyprland theme would win otherwise.
        enable_hyprcursor = false,
    },
})
