#!/usr/bin/env python3
"""Build the Last Round crosshair XCursor theme from the SVGs in this folder.

Needs rsvg-convert and ImageMagick (both ship with Omarchy). Writes an XCursor
theme that inherits everything else (text I-beam, resize arrows, busy) from
Adwaita, so only the pointer turns into a crosshair.

    ./build.py <output-dir>     # e.g. ~/.local/share/icons/LastRound-Crosshair
"""
import os, struct, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SIZES = [24, 32, 48, 64, 96]

# svg -> XCursor names (first is the file, the rest are symlinks)
CURSORS = {
    "crosshair.svg": ["left_ptr", "default", "arrow", "top_left_arrow",
                      "crosshair", "cross", "tcross", "cell", "plus"],
    "crosshair-dot.svg": ["pointer", "hand1", "hand2", "pointing_hand",
                          "e29285e634086352946a0e7090d73106",
                          "9d800788f1b08800ae810202380a0822"],
}


def render(svg, size):
    with tempfile.NamedTemporaryFile(suffix=".png") as png:
        subprocess.run(["rsvg-convert", "-w", str(size), "-h", str(size),
                        "-o", png.name, os.path.join(HERE, svg)], check=True)
        raw = subprocess.run(["magick", png.name, "-depth", "8", "rgba:-"],
                             check=True, capture_output=True).stdout
    pixels = []
    for i in range(0, len(raw), 4):
        r, g, b, a = raw[i:i + 4]
        # XCursor wants premultiplied ARGB
        pixels.append((a << 24) | (r * a // 255 << 16) | (g * a // 255 << 8) | (b * a // 255))
    return pixels


def xcursor(svg):
    images = []
    for size in SIZES:
        hot = size // 2
        header = struct.pack("<9I", 36, 0xFFFD0002, size, 1, size, size, hot, hot, 0)
        images.append((size, header + struct.pack(f"<{size * size}I", *render(svg, size))))
    ntoc = len(images)
    out = struct.pack("<4sIII", b"Xcur", 16, 0x10000, ntoc)
    pos = 16 + ntoc * 12
    toc = b""
    for size, chunk in images:
        toc += struct.pack("<III", 0xFFFD0002, size, pos)
        pos += len(chunk)
    return out + toc + b"".join(chunk for _, chunk in images)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    dest = os.path.expanduser(sys.argv[1])
    cursors = os.path.join(dest, "cursors")
    os.makedirs(cursors, exist_ok=True)
    with open(os.path.join(dest, "index.theme"), "w") as f:
        f.write("[Icon Theme]\nName=LastRound-Crosshair\n"
                "Comment=Last Round crosshair cursor\nInherits=Adwaita\n")
    for svg, names in CURSORS.items():
        main_name, *aliases = names
        with open(os.path.join(cursors, main_name), "wb") as f:
            f.write(xcursor(svg))
        for alias in aliases:
            link = os.path.join(cursors, alias)
            if os.path.lexists(link):
                os.remove(link)
            os.symlink(main_name, link)
    print(f"Built crosshair cursor theme in {dest}")


if __name__ == "__main__":
    main()
