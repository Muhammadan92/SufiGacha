#!/usr/bin/env python3
"""Background removal for chibi battlers: flood-fill from the image edges
across near-uniform background color, leaving the character on transparent.
Deterministic, offline, free. Works on the solid-background images the
rig-friendly chibi prompt requests.

    python3 tools/art_review/cutout.py <in.png> <out.png>
"""
import sys
from collections import deque

from PIL import Image


def cutout(src_path: str, dst_path: str, tolerance: int = 28) -> float:
    img = Image.open(src_path).convert("RGBA")
    w, h = img.size
    px = img.load()

    # background reference = average of the four corners
    corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    bg = tuple(sum(c[i] for c in corners) // 4 for i in range(3))

    def is_bg(p):
        return abs(p[0] - bg[0]) + abs(p[1] - bg[1]) + abs(p[2] - bg[2]) <= tolerance * 3

    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            q.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            q.append((x, y))
    cleared = 0
    while q:
        x, y = q.popleft()
        idx = y * w + x
        if seen[idx]:
            continue
        seen[idx] = 1
        p = px[x, y]
        if not is_bg(p):
            continue
        px[x, y] = (p[0], p[1], p[2], 0)
        cleared += 1
        if x > 0: q.append((x - 1, y))
        if x < w - 1: q.append((x + 1, y))
        if y > 0: q.append((x, y - 1))
        if y < h - 1: q.append((x, y + 1))

    img.save(dst_path)
    return cleared / float(w * h)


if __name__ == "__main__":
    frac = cutout(sys.argv[1], sys.argv[2])
    print("cleared %.0f%% of pixels as background" % (frac * 100))
    if frac < 0.15:
        print("WARNING: little background removed — image may not have a solid bg")
