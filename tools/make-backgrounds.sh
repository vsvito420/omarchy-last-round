#!/bin/bash
# Generate the Last Round wallpapers with ImageMagick. Deterministic (fixed seeds).
#   tools/make-backgrounds.sh            # all variants
#   tools/make-backgrounds.sh dusk       # one variant: dark | dusk | overcast | daylight
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FONT="$(fc-match -f %{file} monospace)"
W=3840 H=2160

variant() {
  local v=$1
  # Per-variant palette. Light variants darken (multiply) instead of lighten.
  case $v in
    dark)     top="#161b22" bot="#07080a" fog="#8a9aae" fogmode=screen grid="rgba(160,175,195,0.022)"
              ink="#07080a" gold="rgba(222,155,53,0.55)" goldtext="rgba(222,155,53,0.5)" quiet="rgba(197,201,207,0.18)"
              ring="rgba(134,196,228,0.10)" tick="rgba(134,196,228,0.18)" sweep="rgba(134,196,228,0.10)"
              ct="rgba(111,143,208,0.9)" t="rgba(222,155,53,0.95)" skybot="#2a2620" glow="#5a3d18" vig=multiply dir=last-round ;;
    dusk)     top="#262c35" bot="#111418" fog="#9aa8ba" fogmode=screen grid="rgba(170,185,205,0.03)"
              ink="#111418" gold="rgba(222,155,53,0.6)" goldtext="rgba(222,155,53,0.55)" quiet="rgba(207,211,216,0.2)"
              ring="rgba(134,196,228,0.13)" tick="rgba(134,196,228,0.22)" sweep="rgba(134,196,228,0.12)"
              ct="rgba(123,154,222,0.9)" t="rgba(222,155,53,0.95)" skybot="#3a342b" glow="#6a4a20" vig=multiply dir=last-round-dusk ;;
    overcast) top="#d3d7dc" bot="#b9bfc7" fog="#6b7480" fogmode=multiply grid="rgba(30,34,40,0.025)"
              ink="#8d96a2" gold="rgba(184,72,14,0.55)" goldtext="rgba(184,72,14,0.6)" quiet="rgba(30,34,40,0.25)"
              ring="rgba(36,88,184,0.14)" tick="rgba(36,88,184,0.22)" sweep="rgba(36,88,184,0.10)"
              ct="rgba(36,88,184,0.85)" t="rgba(184,72,14,0.9)" skybot="#d8c9b4" glow="#e8b27a" vig=soft dir=last-round-overcast ;;
    daylight) top="#f4f5f7" bot="#dfe3e8" fog="#8a939e" fogmode=multiply grid="rgba(30,34,40,0.02)"
              ink="#aab2bd" gold="rgba(184,72,14,0.5)" goldtext="rgba(184,72,14,0.55)" quiet="rgba(30,34,40,0.22)"
              ring="rgba(36,88,184,0.12)" tick="rgba(36,88,184,0.2)" sweep="rgba(36,88,184,0.08)"
              ct="rgba(36,88,184,0.8)" t="rgba(184,72,14,0.85)" skybot="#efe2cf" glow="#f2c48f" vig=soft dir=last-round-daylight ;;
    *) echo "unknown variant: $v" >&2; exit 1 ;;
  esac

  local OUT="$ROOT/themes/$dir/backgrounds" T; T=$(mktemp -d)
  mkdir -p "$OUT"

  # Shared layers: film grain, vignette, grid.
  magick -size ${W}x${H} -seed 3 xc:gray50 -attenuate 0.25 +noise Gaussian -colorspace gray "$T/grain.png"
  # Drawn and blurred at 1/8 size, then scaled up: same soft falloff, seconds instead of minutes.
  magick -size $((W/8))x$((H/8)) xc:black -fill white \
    -draw "ellipse $((W/16)),$((H/16)) $((W*62/800)),$((H*70/800)) 0,360" \
    -blur 0x50 -resize ${W}x${H}! -level 0%,100%,0.8 "$T/vig.png"
  [[ $vig == soft ]] && magick "$T/vig.png" +level 82%,100% "$T/vig.png"
  magick -size ${W}x${H} xc:none -stroke "$grid" -strokewidth 1 \
    -draw "$(for x in $(seq 0 120 $W); do echo "line $x,0 $x,$H "; done)" \
    -draw "$(for y in $(seq 0 120 $H); do echo "line 0,$y $W,$y "; done)" "$T/grid.png"

  finish() { # $1 base, $2 out, $3 fog seed
    if [[ $fogmode == screen ]]; then
      magick -size ${W}x${H} -seed "$3" plasma:grey50-grey0 -colorspace gray -blur 0x90 \
        -level 25%,100% -evaluate multiply 0.22 +level-colors black,"$fog" "$T/fog.png"
    else # light: soft grey fog banks that darken
      magick -size ${W}x${H} -seed "$3" plasma:grey50-grey0 -colorspace gray -blur 0x90 \
        -level 25%,100% -evaluate multiply 0.3 -negate +level-colors "$fog",white "$T/fog.png"
    fi
    magick "$1" \
      "$T/fog.png" -compose "$fogmode" -composite \
      "$T/grid.png" -compose over -composite \
      "$T/vig.png" -compose multiply -composite \
      "$T/grain.png" -compose overlay -composite \
      -quality 92 "$2"
  }

  # 1. Smoke — fog over a tactical grid, one bearing marker.
  magick -size ${W}x${H} gradient:"$top"-"$bot" \
    -fill none -stroke "$gold" -strokewidth 3 \
    -draw "line 2560,1080 2640,1080" -draw "line 2700,1080 2780,1080" \
    -draw "line 2670,990 2670,1050" -draw "line 2670,1110 2670,1170" \
    -stroke none -fill "$goldtext" -font "$FONT" -pointsize 26 \
    -draw "text 2710,1040 'BRG 084  /  RNG 0412'" \
    -fill "$quiet" -draw "text 180,1980 'ROUND 30 / 30'" \
    "$T/1.png"
  finish "$T/1.png" "$OUT/1-smoke.jpg" 7

  # 2. Radar — sweep rings, CT-blue and T-gold contacts.
  local rings="" ticks="" a x1 y1 x2 y2 r
  for r in 180 360 540 720 900; do rings+="circle 2600,1080 $((2600+r)),1080 "; done
  for a in $(seq 0 10 350); do
    read -r x1 y1 x2 y2 < <(awk -v a=$a 'BEGIN{c=cos(a*3.14159/180); s=sin(a*3.14159/180);
      printf "%d %d %d %d\n", 2600+930*c, 1080+930*s, 2600+960*c, 1080+960*s}')
    ticks+="line $x1,$y1 $x2,$y2 "
  done
  magick -size ${W}x${H} gradient:"$top"-"$bot" \
    -fill none -stroke "$ring" -strokewidth 2 -draw "$rings" \
    -stroke "$tick" -draw "$ticks" \
    -stroke "$ring" -draw "line 1640,1080 3560,1080" -draw "line 2600,120 2600,2040" \
    \( -size ${W}x${H} xc:none -fill "$sweep" -stroke none \
       -draw "path 'M 2600,1080 L 3500,780 A 950,950 0 0,1 3530,1000 Z'" -blur 0x18 \) -compose over -composite \
    -stroke none -fill "$ct" -draw "circle 2980,760 2988,760" -draw "circle 3100,880 3108,880" \
    -fill "$t" -draw "rectangle 2240,1380 2254,1394" -draw "rectangle 2150,1300 2164,1314" \
    "$T/2.png"
  finish "$T/2.png" "$OUT/2-radar.jpg" 11

  # 3. Dusk — warm horizon under a cold sky, ridge silhouette.
  local ridge px=0 py; RANDOM=42
  ridge="path 'M 0,$H L 0,1560"
  while (( px < W )); do px=$((px + 60 + RANDOM % 120)); py=$((1480 + RANDOM % 170)); ridge+=" L $px,$py"; done
  ridge+=" L $W,$H Z'"
  local glowmode=screen; [[ $fogmode == multiply ]] && glowmode=multiply
  magick -size ${W}x${H} gradient:"$top"-"$skybot" \
    \( -size ${W}x${H} xc:"$([[ $glowmode == screen ]] && echo black || echo white)" -fill "$glow" \
       -draw "ellipse $((W/2)),1560 $((W*55/100)),260 0,360" -blur 0x220 \) -compose $glowmode -composite \
    -compose over -fill "$ink" -stroke none -draw "$ridge" \
    -fill "$t" -draw "rectangle 2860,1452 2864,1500" \
    "$T/3.png"
  finish "$T/3.png" "$OUT/3-dusk.jpg" 23

  rm -rf "$T"
  echo "Wrote $OUT"
}

if (( $# )); then variant "$1"; else for v in dark dusk overcast daylight; do variant $v; done; fi
