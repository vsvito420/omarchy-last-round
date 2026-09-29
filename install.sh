#!/bin/bash
# Install Last Round (dark, dusk, overcast, daylight) into ~/.config/omarchy/themes.
# Copied (not cloned) so Omarchy treats it as a user theme and keeps
# hyprland.lua. Also builds the crosshair cursor and installs the hook that
# switches it on and off with the theme.
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.config/omarchy/themes"

if [[ $1 == --remove ]]; then
  rm -rf "$DEST"/last-round "$DEST"/last-round-* "$HOME/.local/share/icons/LastRound-Crosshair"
  rm -f "$HOME/.config/omarchy/hooks/theme-set.d/last-round-cursor" \
        "$HOME/.config/omarchy/hooks/post-boot.d/last-round-cursor"
  hyprctl setcursor default "${XCURSOR_SIZE:-24}" >/dev/null 2>&1 || true
  gsettings set org.gnome.desktop.interface cursor-theme default 2>/dev/null || true
  echo "Removed Last Round. Pick another theme with: omarchy theme set <name>"
  exit 0
fi

mkdir -p "$DEST"
for t in "$ROOT"/themes/last-round*; do
  name=$(basename "$t")
  rm -rf "${DEST:?}/$name"
  cp -r "$t" "$DEST/$name"
  echo "Installed theme $name"
done

"$ROOT/cursor/build.py" "$HOME/.local/share/icons/LastRound-Crosshair"

omarchy hook install theme-set "$ROOT/hooks/last-round-cursor"
omarchy hook install post-boot "$ROOT/hooks/last-round-cursor"
echo "Installed crosshair cursor hook"

echo
echo "Apply with:"
echo "  omarchy theme set \"Last Round\"            # darkest"
echo "  omarchy theme set \"Last Round Dusk\""
echo "  omarchy theme set \"Last Round Overcast\""
echo "  omarchy theme set \"Last Round Daylight\"   # brightest"
