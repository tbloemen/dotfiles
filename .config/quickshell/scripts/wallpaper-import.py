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
once, as JPEGs scaled down to cover a 4K screen (the sources run up to 6K and
the wallpapers live in git). wallpaper.json also records the sun's range the
elevations were measured against (`dayMin`/`dayMax`), so the shell can stretch
them to each day's range: a frame from an equinox noon then still shows at a
lower winter noon instead of every midday frame piling up at the top.

Some files carry contradicting data -- Apple's `ap` (which frame is the light
and which the dark one) disagreeing with the timings. Then the timings are
wrong (e.g. a night photo placed at noon) and only `ap` is kept.

Needs heif-convert (libheif) and magick (ImageMagick).
"""

import base64
import hashlib
import json
import math
import os
import plistlib
import re
import subprocess
import sys
import tempfile

# Where darkman flips, and where a frame counts as a light one: the sun's
# centre at -0.833 deg is sunrise/sunset once refraction is accounted for.
HORIZON = -0.833

# Big enough to cover a 3840x2160 screen; larger sources are scaled down.
COVER = "3840x2160^>"
QUALITY = "90"


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


def appearance(meta: dict) -> list[dict]:
    ap = meta.get("ap", meta)
    return [{"image": ap["l"], "mode": "light"}, {"image": ap["d"], "mode": "dark"}]


def frames_from(kind: str, meta: dict, lat: float) -> tuple[list[dict], dict]:
    """The frames, plus the elevation range they were placed in."""
    if kind == "solar":
        frames = [frame(s["i"], s["a"], s["z"] < 180) for s in meta["si"]]
        els = [f["elevation"] for f in frames]
        # The day the photos were taken is unknown; the extremes the frames
        # reach are the best guess at its range.
        return frames, {"dayMin": min(min(els), -18), "dayMax": max(max(els), 10)}
    if kind == "h24":
        frames = []
        for t in meta["ti"]:
            hour_angle = (t["t"] * 24 - 12) * 15
            el = math.degrees(
                math.asin(math.cos(math.radians(lat)) * math.cos(math.radians(hour_angle)))
            )
            frames.append(frame(t["i"], el, hour_angle < 0))
        return frames, {"dayMin": -(90 - abs(lat)), "dayMax": 90 - abs(lat)}
    return appearance(meta), {}


def consistent(frames: list[dict], meta: dict) -> bool:
    """False when `ap` calls a frame light that the timing puts at night, or
    the other way round."""
    ap = meta.get("ap")
    if not ap or "l" not in ap or "d" not in ap or ap["l"] == ap["d"]:
        return True
    modes = {f["image"]: f.get("mode") for f in frames}
    return modes.get(ap["l"]) != "dark" and modes.get(ap["d"]) != "light"


def convert(src: str, out: str) -> None:
    cmd = ["heif-convert", "--quiet", src, out]
    r = subprocess.run(cmd, capture_output=True, text=True)
    # Files built from many tiles (one has 1099) trip libheif's guard against
    # malicious input; this is a wallpaper you chose to import.
    if r.returncode != 0 and "Security limit" in r.stderr + r.stdout:
        r = subprocess.run(cmd[:2] + ["--disable-limits"] + cmd[2:], capture_output=True, text=True)
    if r.returncode != 0:
        sys.exit(f"heif-convert failed: {(r.stderr or r.stdout).strip()}")


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, out_dir = sys.argv[1], os.path.expanduser(sys.argv[2])
    with open(src, "rb") as f:
        kind, meta = read_meta(f.read())
    frames, day = frames_from(kind, meta, darkman_lat())
    if not consistent(frames, meta):
        print("timings contradict the light/dark frames; using those only", file=sys.stderr)
        kind, frames, day = "apr", appearance(meta), {}

    os.makedirs(out_dir, exist_ok=True)
    # Frames from an earlier import (names and counts may differ now).
    for old in os.listdir(out_dir):
        if re.fullmatch(r"frame-\d+\.(png|jpg)", old):
            os.remove(os.path.join(out_dir, old))
    with tempfile.TemporaryDirectory() as tmp:
        convert(src, os.path.join(tmp, "f.png"))
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
                seen[digest] = f"frame-{len(seen)}.jpg"
                subprocess.run(
                    ["magick", path, "-resize", COVER, "-quality", QUALITY,
                     os.path.join(out_dir, seen[digest])],
                    check=True,
                )
            files.append(seen[digest])

    for f in frames:
        f["file"] = files[f.pop("image")]
    with open(os.path.join(out_dir, "wallpaper.json"), "w") as f:
        json.dump(
            {"source": os.path.basename(src), "kind": kind, **day, "frames": frames}, f, indent=2
        )
        f.write("\n")
    print(f"{len(frames)} frames ({len(seen)} distinct images) -> {out_dir}")


if __name__ == "__main__":
    main()
