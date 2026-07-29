#!/usr/bin/env python3
"""Upgrade Xcode imagesets to iPad-friendly 360/720/1024 from images/*-1024.png masters.

Existing phone-era sets typically ship 80/160/240 (or 240/320 / single 340).
Catalog body art already uses 360/720/1024 — this script brings other games in line.

Usage:
  ./scripts/upgrade-imagesets-ipad.py --phase dino
  ./scripts/upgrade-imagesets-ipad.py --phase marine
  ./scripts/upgrade-imagesets-ipad.py --phase ptero
  ./scripts/upgrade-imagesets-ipad.py --folders Dinosaur-Eggs Dinosaur-Smile
  ./scripts/upgrade-imagesets-ipad.py --phase dino --dry-run
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "DinoGames" / "DinoGames" / "Assets.xcassets"
IMAGES = ROOT / "DinoGames" / "images"

SIZES = (360, 720, 1024)
SIZE_RE = re.compile(r"-(80|160|240|320|340|360|720|1024)(?: \d+)?\.png$", re.I)

PHASE_FOLDERS = {
    "dino": [
        "Dinosaur-Ages",
        "Dinosaur-Bones",
        "Dinosaur-Characteristics",
        "Dinosaur-Diets",
        "Dinosaur-Eggs",
        "Dinosaur-Fauna",
        "Dinosaur-Flora",
        "Dinosaur-Footprints",
        "Dinosaur-Game-Icons",
        "Dinosaur-Gameplay-Levels",
        "Dinosaur-Height",
        "Dinosaur-Matrix",
        "Dinosaur-Silhouettes",
        "Dinosaur-Smile",
        "Dinosaur-Sources",
        "Dinosaur-Weight",
        "Gameplay-Levels",
        # Already 360/720/1024 — included so --force can refresh if needed
        "Dinosaurs",
        "Dinosaur-Racing",
        "Game-Category",
    ],
    "marine": [
        "Marine-Ages",
        "Marine-Diets",
        "Marine-Eggs",
        "Marine-Flora",
        "Marine-Footprints",
        "Marine-Gameplay-Levels",
        "Marine-Length",
        "Marine-Matrix",
        "Marine-Racing",
        "Marine-Reptile-Weight",
        "Marine-Reptiles",
        "Marine-Reptiles-Game-Icons",
        "Marine-Reptiles-Silhouettes",
        "Marine-Smile",
        "Marine-Sources",
    ],
    "ptero": [
        "Pterosaur-Ages",
        "Pterosaur-Characteristics",
        "Pterosaur-Diets",
        "Pterosaur-Eggs",
        "Pterosaur-Flora",
        "Pterosaur-Footprints",
        "Pterosaur-Game-Icons",
        "Pterosaur-Gameplay-Levels",
        "Pterosaur-Height",
        "Pterosaur-Matrix",
        "Pterosaur-Racing",
        "Pterosaur-Silhouettes",
        "Pterosaur-Smile",
        "Pterosaur-Sources",
        "Pterosaurs",
    ],
}


def index_masters(images_root: Path) -> dict[str, Path]:
    idx: dict[str, Path] = {}
    for path in images_root.rglob("*-1024.png"):
        stem = path.name[: -len("-1024.png")]
        # Prefer first hit; later duplicates are ignored
        idx.setdefault(stem, path)
    return idx


def png_stems(imageset: Path) -> list[str]:
    stems: list[str] = []
    seen: set[str] = set()
    for png in sorted(imageset.glob("*.png")):
        m = SIZE_RE.search(png.name)
        stem = SIZE_RE.sub("", png.name) if m else png.stem
        if stem not in seen:
            seen.add(stem)
            stems.append(stem)
    return stems


def candidate_stems(imageset: Path) -> list[str]:
    names = [imageset.name.replace(".imageset", "")] + png_stems(imageset)
    seen: set[str] = set()
    out: list[str] = []
    for name in names:
        if name not in seen:
            seen.add(name)
            out.append(name)
    return out


def current_sizes(imageset: Path) -> set[str]:
    sizes: set[str] = set()
    for png in imageset.glob("*.png"):
        m = SIZE_RE.search(png.name)
        if m:
            sizes.add(m.group(1))
    return sizes


def is_already_hires(imageset: Path) -> bool:
    return {"360", "720", "1024"}.issubset(current_sizes(imageset))


def find_master(imageset: Path, masters: dict[str, Path]) -> tuple[str, Path] | None:
    for stem in candidate_stems(imageset):
        if stem in masters:
            return stem, masters[stem]
    return None


def write_contents(imageset: Path, asset_stem: str) -> None:
    contents = {
        "images": [
            {"filename": f"{asset_stem}-360.png", "idiom": "universal", "scale": "1x"},
            {"filename": f"{asset_stem}-720.png", "idiom": "universal", "scale": "2x"},
            {"filename": f"{asset_stem}-1024.png", "idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def resize_with_magick(src: Path, dest: Path, size: int) -> None:
    subprocess.run(
        [
            "magick",
            str(src),
            "-resize",
            f"{size}x{size}",
            f"PNG32:{dest}",
        ],
        check=True,
        capture_output=True,
    )


def upgrade_imageset(
    imageset: Path,
    masters: dict[str, Path],
    *,
    dry_run: bool,
    force: bool,
) -> str:
    """Return status: upgraded|skipped_hires|missing|error."""
    if not force and is_already_hires(imageset):
        return "skipped_hires"

    found = find_master(imageset, masters)
    if not found:
        return "missing"

    master_stem, master = found
    asset_stem = imageset.name.replace(".imageset", "")

    if dry_run:
        return "upgraded"

    # Generate into a temp-ish naming then replace old PNGs
    new_files: dict[int, Path] = {}
    try:
        for size in (360, 720):
            out = imageset / f"{asset_stem}-{size}.png"
            resize_with_magick(master, out, size)
            new_files[size] = out
        dest_1024 = imageset / f"{asset_stem}-1024.png"
        if master.resolve() != dest_1024.resolve():
            shutil.copy2(master, dest_1024)
        new_files[1024] = dest_1024
        write_contents(imageset, asset_stem)

        keep = {p.resolve() for p in new_files.values()}
        for png in list(imageset.glob("*.png")):
            if png.resolve() not in keep:
                png.unlink()
    except subprocess.CalledProcessError as exc:
        print(f"ERROR magick failed for {imageset}: {exc.stderr.decode()}", file=sys.stderr)
        return "error"
    except OSError as exc:
        print(f"ERROR {imageset}: {exc}", file=sys.stderr)
        return "error"

    # Touch master_stem in status line for debugging mismatches
    if master_stem != asset_stem:
        return f"upgraded({master_stem})"
    return "upgraded"


def iter_imagesets(folders: list[str]) -> list[Path]:
    out: list[Path] = []
    for folder in folders:
        root = ASSETS / folder
        if not root.is_dir():
            print(f"WARN missing asset folder: {folder}", file=sys.stderr)
            continue
        out.extend(sorted(root.rglob("*.imageset")))
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", choices=sorted(PHASE_FOLDERS), help="Preset folder group")
    parser.add_argument("--folders", nargs="+", help="Explicit Assets.xcassets folder names")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true", help="Rebuild even if already 360/720/1024")
    parser.add_argument("--limit", type=int, default=0, help="Process at most N imagesets")
    args = parser.parse_args()

    folders: list[str] = []
    if args.phase:
        folders.extend(PHASE_FOLDERS[args.phase])
    if args.folders:
        folders.extend(args.folders)
    if not folders:
        parser.error("Provide --phase and/or --folders")

    if not shutil.which("magick"):
        print("ImageMagick `magick` not found on PATH", file=sys.stderr)
        return 1

    masters = index_masters(IMAGES)
    print(f"Indexed {len(masters)} master *-1024.png files under {IMAGES}")

    imagesets = iter_imagesets(folders)
    if args.limit:
        imagesets = imagesets[: args.limit]

    counts = {"upgraded": 0, "skipped_hires": 0, "missing": 0, "error": 0}
    missing: list[str] = []
    aliased = 0

    for imageset in imagesets:
        status = upgrade_imageset(imageset, masters, dry_run=args.dry_run, force=args.force)
        if status.startswith("upgraded"):
            counts["upgraded"] += 1
            if status != "upgraded":
                aliased += 1
                rel = imageset.relative_to(ASSETS)
                print(f"  alias {rel} ← {status[len('upgraded('):-1]}")
        else:
            counts[status] = counts.get(status, 0) + 1
            if status == "missing":
                missing.append(str(imageset.relative_to(ASSETS)))

    mode = "DRY-RUN " if args.dry_run else ""
    print(
        f"{mode}Done: upgraded={counts['upgraded']} "
        f"(aliased_master={aliased}) skipped_hires={counts['skipped_hires']} "
        f"missing={counts['missing']} error={counts['error']} "
        f"total={len(imagesets)}"
    )
    if missing:
        print("Missing masters:")
        for path in missing:
            print(f"  {path}")
    return 1 if counts["error"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
