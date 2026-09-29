-- Last Round Daylight: the tactical look on a light background. Tight gaps, near-square corners,
-- a thin burnt-gold edge on the focused window, fast motion with no bounce.

local active_border_color = { colors = { "rgba(b8480eee)", "rgba(7a543388)" }, angle = 90 }
local inactive_border_color = "rgba(9aa3b0aa)"

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
    dim_strength = 0.06,

    shadow = {
      enabled = true,
      range = 14,
      render_power = 4,
      color = "rgba(1e222855)",
      color_inactive = "rgba(1e222822)",
    },

    blur = {
      enabled = true,
      size = 6,
      passes = 2,
      noise = 0.03,
      contrast = 1.1,
      brightness = 1.0,
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
