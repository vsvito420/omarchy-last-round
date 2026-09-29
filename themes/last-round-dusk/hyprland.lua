-- Last Round Dusk: tactical and quiet. Tight gaps, near-square corners,
-- a thin gold edge on the focused window, fast motion with no bounce.

local active_border_color = { colors = { "rgba(de9b35ee)", "rgba(8a6a4588)" }, angle = 90 }
local inactive_border_color = "rgba(333b4aaa)"

hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 6,
    border_size = 2,
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  decoration = {
    rounding = 3,

    -- Unfocused windows fall back into the fog.
    dim_inactive = true,
    dim_strength = 0.12,

    shadow = {
      enabled = true,
      range = 14,
      render_power = 4,
      color = "rgba(000000aa)",
      color_inactive = "rgba(00000055)",
    },

    blur = {
      enabled = true,
      size = 6,
      passes = 2,
      noise = 0.03,
      contrast = 1.1,
      brightness = 0.8,
      vibrancy = 0.05,
      popups = true,
      new_optimizations = true,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
})

-- Snappy and linear-ish: nothing wobbles while you work.
hl.curve("lrSnap", { type = "bezier", points = { { 0.2, 0.9 }, { 0.1, 1 } } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "lrSnap", style = "popin 96%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "lrSnap", style = "popin 96%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.5, bezier = "lrSnap" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2, bezier = "lrSnap", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, bezier = "lrSnap", style = "slidefade 12%" })

-- Code stays fully opaque: no text bleeding through.
o.window({ tag = "default-opacity" }, { opacity = "1 0.96" })

-- Smoked glass behind the Omarchy shell surfaces only.
hl.layer_rule({
  match = { namespace = "^(omarchy-bar|omarchy-notifications|omarchy-osd|omarchy-menu|omarchy-clipboard|omarchy-emojis|omarchy-polkit|omarchy-reminders|omarchy-keyboard-panel|omarchy-network-qr)$" },
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.3,
})
