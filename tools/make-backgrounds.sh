#!/bin/bash
# Generate the Last Round wallpapers with ImageMagick. Deterministic (fixed seeds).
set -e
OUT="$(cd "$(dirname "$0")/.." && pwd)/themes/last-round/backgrounds"
W=3840 H=2160
mkdir -p "$OUT"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT

# Shared layers: fog (blurred fractal noise), film grain, vignette, grid.
magick -size ${W}x${H} -seed 3 xc:gray50 +noise Gaussian -colorspace gray -attenuate 0.4 "$T/grain.png"
magick -size ${W}x${H} xc:black -fill white -draw "ellipse $((W/2)),$((H/2)) $((W*62/100)),$((H*70/100)) 0,360" -blur 0x400 -level 0%,100%,0.8 "$T/vig.png"
magick -size ${W}x${H} xc:none -stroke "rgba(160,175,195,0.022)" -strokewidth 1 \
  -draw "$(for x in $(seq 0 120 $W); do echo "line $x,0 $x,$H "; done)" \
  -draw "$(for y in $(seq 0 120 $H); do echo "line 0,$y $W,$y "; done)" "$T/grid.png"

finish() { # $1 base, $2 out, $3 fog seed
  magick -size ${W}x${H} -seed "$3" plasma:grey50-grey0 -colorspace gray -blur 0x90 \
    -level 25%,100% -evaluate multiply 0.22 +level-colors black,"#8a9aae" "$T/fog.png"
  magick "$1" \
    "$T/fog.png" -compose screen -composite \
    "$T/grid.png" -compose over -composite \
    "$T/vig.png" -compose multiply -composite \
    "$T/grain.png" -compose soft-light -composite \
    -quality 92 "$2"
}

# 1. Smoke — cold fog over a tactical grid, one gold bearing marker.
magick -size ${W}x${H} gradient:"#161b22"-"#07080a" \
  -fill none -stroke "rgba(222,155,53,0.55)" -strokewidth 3 \
  -draw "line 2560,1080 2640,1080" -draw "line 2700,1080 2780,1080" \
  -draw "line 2670,990 2670,1050" -draw "line 2670,1110 2670,1170" \
  -stroke none -fill "rgba(222,155,53,0.5)" -font "$(fc-match -f %{file} monospace)" -pointsize 26 \
  -draw "text 2710,1040 'BRG 084  /  RNG 0412'" \
  -fill "rgba(197,201,207,0.18)" -draw "text 180,1980 'ROUND 30 / 30'" \
  "$T/1.png"
finish "$T/1.png" "$OUT/1-smoke.jpg" 7

# 2. Radar — dim sweep rings, CT-blue and T-gold contacts.
rings=""; for r in 180 360 540 720 900; do rings+="circle 2600,1080 $((2600+r)),1080 "; done
ticks=""; for a in $(seq 0 10 350); do
  x1=$(awk -v a=$a 'BEGIN{printf "%d",2600+930*cos(a*3.14159/180)}'); y1=$(awk -v a=$a 'BEGIN{printf "%d",1080+930*sin(a*3.14159/180)}')
  x2=$(awk -v a=$a 'BEGIN{printf "%d",2600+960*cos(a*3.14159/180)}'); y2=$(awk -v a=$a 'BEGIN{printf "%d",1080+960*sin(a*3.14159/180)}')
  ticks+="line $x1,$y1 $x2,$y2 "; done
magick -size ${W}x${H} gradient:"#12161c"-"#08090b" \
  -fill none -stroke "rgba(134,196,228,0.10)" -strokewidth 2 -draw "$rings" \
  -stroke "rgba(134,196,228,0.18)" -draw "$ticks" \
  -stroke "rgba(134,196,228,0.08)" -draw "line 1640,1080 3560,1080" -draw "line 2600,120 2600,2040" \
  \( -size ${W}x${H} xc:none -fill "rgba(134,196,228,0.10)" -stroke none \
     -draw "path 'M 2600,1080 L 3500,780 A 950,950 0 0,1 3530,1000 Z'" -blur 0x18 \) -compose screen -composite \
  -compose over -stroke none -fill "rgba(111,143,208,0.9)" -draw "circle 2980,760 2988,760" -draw "circle 3100,880 3108,880" \
  -fill "rgba(222,155,53,0.95)" -draw "rectangle 2240,1380 2254,1394" -draw "rectangle 2150,1300 2164,1314" \
  "$T/2.png"
finish "$T/2.png" "$OUT/2-radar.jpg" 11

# 3. Dusk — dust-orange horizon under a cold steel sky, ridge silhouette.
ridge="path 'M 0,$H L 0,1560"; x=0; y=1560; RANDOM=42
while (( x < W )); do x=$((x + 60 + RANDOM % 120)); y=$((1480 + RANDOM % 170)); ridge+=" L $x,$y"; done
ridge+=" L $W,$H Z'"
magick -size ${W}x${H} gradient:"#0d1117"-"#2a2620" \
  \( -size ${W}x${H} xc:black -fill "#5a3d18" -draw "ellipse $((W/2)),1560 $((W*55/100)),260 0,360" -blur 0x220 \) -compose screen -composite \
  -compose over -fill "#07080a" -stroke none -draw "$ridge" \
  -fill "rgba(242,212,92,0.8)" -draw "rectangle 2860,1452 2864,1500" \
  "$T/3.png"
finish "$T/3.png" "$OUT/3-dusk.jpg" 23

ls -la "$OUT"
