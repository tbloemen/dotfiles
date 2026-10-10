#!/usr/bin/env python3
"""Turn a macOS dynamic wallpaper (.heic) into a directory Services/Wallpaper.qml
can play: the frames as PNGs plus a wallpaper.json that places each frame by
the sun's elevation.

    wallpaper-import.py "Tokyo Street.heic" ~/wallpapers/tokyo-street

Apple stores the timing as a base64 binary plist in the XMP:
  apple_desktop:solar  -- per frame: altitude `a`, azimuth `z` (used as is)
  apple_desktop:h24    -- per frame: time of day `t` (0..1); converted to the
                          elevation the sun has at that solar time on an
                          equinox at darkman's latitude, so a "18:00" frame
                          lands on sunset all year instead of at 18:00
  apple_desktop:apr    -- only a light and a dark frame, no timing
Frames are matched to the images in item order. Identical images are written
once. Needs heif-convert (libheif).
"""

import base64
import hashlib
import json
import math
import os
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile

# Where darkman flips, and where a frame counts as a light one: the sun's
# centre at -0.833 deg is sunrise/sunset once refraction is accounted for.
HORIZON = -0.833


def darkman_lat() -> float:
    path = os.path.expanduser("~/.config/darkman/config.yaml")
    try:
        with open(path) as f:
            m = re.search(r"^lat:\s*(-?[\d.]+)", f.read(), re.M)
            if m:
                return float(m.group(1))
    except OSError:
        pass
    return 52.0


def read_meta(data: bytes) -> tuple[str, dict]:
    xmp = re.search(rb"<x:xmpmeta.*?</x:xmpmeta>", data, re.S)
    if not xmp:
        sys.exit("no XMP metadata: not a dynamic wallpaper")
    text = xmp.group(0).decode("utf-8", "replace")
    for kind in ("solar", "h24", "apr"):
        m = re.search(rf'apple_desktop:{kind}="([^"]+)"', text) or re.search(
            rf"<apple_desktop:{kind}>([^<]+)<", text
        )
        if m:
            return kind, plistlib.loads(base64.b64decode(m.group(1)))
    sys.exit("XMP has no apple_desktop solar/h24/apr data")


def frame(i: int, elevation: float | None, rising: bool | None) -> dict:
    f: dict = {"image": i}
    if elevation is not None:
        f["elevation"] = round(elevation, 2)
        f["rising"] = rising
        f["mode"] = "light" if elevation > HORIZON else "dark"
    return f


def frames_from(kind: str, meta: dict, lat: float) -> list[dict]:
    if kind == "solar":
        return [frame(s["i"], s["a"], s["z"] < 180) for s in meta["si"]]
    if kind == "h24":
        out = []
        for t in meta["ti"]:
            hour_angle = (t["t"] * 24 - 12) * 15
            el = math.degrees(
                math.asin(math.cos(math.radians(lat)) * math.cos(math.radians(hour_angle)))
            )
            out.append(frame(t["i"], el, hour_angle < 0))
        return out
    # apr: no timing, just which frame is the light and which the dark one.
    ap = meta.get("ap", meta)
    return [{"image": ap["l"], "mode": "light"}, {"image": ap["d"], "mode": "dark"}]


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, out_dir = sys.argv[1], os.path.expanduser(sys.argv[2])
    with open(src, "rb") as f:
        kind, meta = read_meta(f.read())
    frames = frames_from(kind, meta, darkman_lat())

    os.makedirs(out_dir, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(
            ["heif-convert", "--quiet", src, os.path.join(tmp, "f.png")], check=True
        )
        # heif-convert writes f-1.png, f-2.png, ... (or just f.png for one).
        pngs = sorted(
            (p for p in os.listdir(tmp) if p.endswith(".png")),
            key=lambda p: int(p.removesuffix(".png").rpartition("-")[2] or 0)
            if "-" in p
            else 0,
        )
        files, seen = [], {}
        for p in pngs:
            path = os.path.join(tmp, p)
            with open(path, "rb") as f:
                digest = hashlib.sha256(f.read()).hexdigest()
            if digest not in seen:
                seen[digest] = f"frame-{len(seen)}.png"
                shutil.copyfile(path, os.path.join(out_dir, seen[digest]))
            files.append(seen[digest])

    for f in frames:
        f["file"] = files[f.pop("image")]
    with open(os.path.join(out_dir, "wallpaper.json"), "w") as f:
        json.dump({"source": os.path.basename(src), "kind": kind, "frames": frames}, f, indent=2)
        f.write("\n")
    print(f"{len(frames)} frames ({len(seen)} distinct images) -> {out_dir}")


if __name__ == "__main__":
    main()
