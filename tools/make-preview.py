#!/usr/bin/env python3
"""Build preview.png (1280x800) for every Last Round variant: wallpaper, a mock
code window and the palette, all read from the variant's colors.toml.
Synthetic on purpose: no real screen contents."""
import glob, os, subprocess, tomllib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = subprocess.run(["fc-match", "-f", "%{file}", "monospace"], capture_output=True, text=True).stdout
PT, ADV = 18, 18 * 0.6  # monospace advance width



def palette(th):
    with open(os.path.join(th, "colors.toml"), "rb") as f:
        t = tomllib.load(f)
    return dict(bg=t["background"], panel=t["lighter_background"], term=t["darker_background"],
                sel=t["selection"], muted=t["muted"], fg=t["foreground"], dim=t["dark_foreground"],
                red=t["red"], green=t["green"], yellow=t["yellow"], gold=t["accent"],
                blue=t["blue"], cyan=t["cyan"], magenta=t["magenta"])


CODE = [
    [("muted", "// last round: nothing left to lose")],
    [("blue", "fn "), ("fg", "defuse("), ("cyan", "kit"), ("fg", ": &Kit) -> "), ("gold", "Result"), ("fg", "<()> {")],
    [("blue", "    let "), ("fg", "time = "), ("yellow", "10.0"), ("fg", ";")],
    [("blue", "    if "), ("fg", "kit.ready() { "), ("green", '"site secured"'), ("fg", " }")],
    [("blue", "    else "), ("fg", "{ "), ("red", 'panic!("no kit")'), ("fg", " }")],
    [("fg", "}")],
]
TERM = [
    [("dim", "$ "), ("fg", "git diff --stat")],
    [("green", "+ 42 additions"), ("dim", "  |  "), ("red", "- 7 deletions")],
    [("yellow", "warning: "), ("fg", "unused smoke grenade")],
    [("cyan", "info: "), ("fg", "CT win  "), ("gold", "T eliminated")],
    [("dim", "$ "), ("gold", "█")],
]


def text(C, lines, y0):
    args = []
    for i, line in enumerate(lines):
        x = 70
        for color, s in line:
            # ImageMagick drops leading spaces, so turn them into an x offset
            lead = len(s) - len(s.lstrip(" "))
            args += ["-fill", C[color], "-annotate", f"+{x + lead * ADV:.0f}+{y0 + i * 30}", s.lstrip(" ")]
            x += len(s) * ADV
    return args


for th in sorted(glob.glob(os.path.join(ROOT, "themes", "last-round*"))):
    C = palette(th)
    TH = th
    args = ["magick", os.path.join(TH, "backgrounds", "2-radar.jpg"),
            "-resize", "1280x800^", "-gravity", "center", "-extent", "1280x800", "-gravity", "northwest",
            "-fill", C["bg"], "-stroke", C["gold"], "-strokewidth", "2", "-draw", "rectangle 40,60 900,560",
            "-stroke", "none", "-fill", C["panel"], "-draw", "rectangle 41,61 899,92",
            "-fill", C["term"], "-draw", "rectangle 41,330 899,559",
            "-font", FONT, "-pointsize", "15",
            "-fill", C["dim"], "-annotate", "+60+82", "~/ops/defuse.rs",
            "-fill", C["gold"], "-annotate", "+800+82", "ROUND 30",
            "-pointsize", str(PT)]
    args += text(C, CODE, 135) + text(C, TERM, 375)
    for i, key in enumerate(["bg", "panel", "sel", "muted", "fg", "red", "green", "yellow", "gold", "blue", "cyan", "magenta"]):
        x, y = 950 + (i % 3) * 95, 110 + (i // 3) * 95
        args += ["-fill", C[key], "-stroke", C["sel"], "-strokewidth", "1", "-draw", f"rectangle {x},{y} {x + 80},{y + 80}"]
    args.append(os.path.join(TH, "preview.png"))
    subprocess.run(args, check=True)
    print("Wrote", os.path.join(TH, "preview.png"))
