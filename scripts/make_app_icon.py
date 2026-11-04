#!/usr/bin/env python3
"""Draw a 1024x1024 opaque RGB app icon and write a PNG."""

import struct
import zlib
from pathlib import Path


def chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def rounded_rect(x: int, y: int, left: int, top: int, right: int, bottom: int, radius: int) -> bool:
    if x < left or x >= right or y < top or y >= bottom:
        return False
    if x < left + radius and y < top + radius:
        dx = x - (left + radius)
        dy = y - (top + radius)
        return dx * dx + dy * dy <= radius * radius
    if x >= right - radius and y < top + radius:
        dx = x - (right - radius - 1)
        dy = y - (top + radius)
        return dx * dx + dy * dy <= radius * radius
    if x < left + radius and y >= bottom - radius:
        dx = x - (left + radius)
        dy = y - (bottom - radius - 1)
        return dx * dx + dy * dy <= radius * radius
    if x >= right - radius and y >= bottom - radius:
        dx = x - (right - radius - 1)
        dy = y - (bottom - radius - 1)
        return dx * dx + dy * dy <= radius * radius
    return True


def blend(a, b, t: float):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def main() -> None:
    size = 1024
    bg = (31, 30, 28)
    paper = (244, 239, 230)
    tiles = [
        (94, 143, 168),
        (196, 122, 106),
        (125, 150, 112),
        (212, 168, 96),
        (142, 112, 145),
        (90, 148, 140),
        (86, 104, 128),
        (176, 122, 98),
    ]
    raw = bytearray()
    for y in range(size):
        raw.append(0)
        for x in range(size):
            if rounded_rect(x, y, 96, 96, 928, 928, 180):
                color = paper
                # Widget bar.
                if rounded_rect(x, y, 168, 188, 856, 430, 48):
                    color = blend((232, 220, 206), (176, 196, 204), (x - 168) / 688)
                # Icon tiles, 4 columns x 2 rows.
                col = (x - 168) // 176
                row = (y - 480) // 176
                if 0 <= col < 4 and 0 <= row < 2:
                    cell_x = 168 + col * 176
                    cell_y = 480 + row * 176
                    if rounded_rect(x, y, cell_x, cell_y, cell_x + 148, cell_y + 148, 36):
                        color = tiles[row * 4 + col]
                raw.extend(color)
            else:
                raw.extend(bg)
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    out = Path(__file__).resolve().parents[1] / "DeskStyle" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"
    out.write_bytes(png)
    print(f"wrote {out} ({len(png)} bytes)")


if __name__ == "__main__":
    main()
