#!/usr/bin/env python3
"""Rename Ptero Flora imagesets and source files to ptero-flora-{formation}-{taxon} pattern."""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
DINO_GAMES = REPO_ROOT / "apps/dino-games/DinoGames"
XC_ROOT = DINO_GAMES / "DinoGames/Assets.xcassets/Pterosaur-Flora"
IMG_ROOT = DINO_GAMES / "images/ptero-flora"
JSON_ROOT = DINO_GAMES / "json/ptero-flora"

FORMATION_XC = {
    "Densus_Ciula_Formation": "densus-ciula",
    "Dinosaur_Park_Formation": "dinosaur-park",
    "Javelina_Formation": "javelina",
    "Karabastau_Formation": "karabastau",
    "Lagarcito_Formation": "lagarcito",
    "Muwaqqar_Chalk_Formation": "muwaqqar-chalk",
    "Plottier_Formation": "plottier",
    "Santana_Romualdo_Formation": "santana-romualdo",
    "Tangshang_Formation": "tangshang",
    "Tiaojishan_Formation": "tiaojishan",
}

SOURCE_FOLDER = {
    "densus-ciula": "ptero_densus_ciula_formation",
    "dinosaur-park": "ptero_dinosaur_park_formation",
    "javelina": "ptero_javelina_formation",
    "karabastau": "ptero_karabastau_formation",
    "lagarcito": "ptero_lagarcito_formation",
    "muwaqqar-chalk": "ptero_muwaqqar_chalk_formation",
    "plottier": "ptero_plottier_formation",
    "santana-romualdo": "ptero_santana_romualdo_formation",
    "tangshang": "ptero_tangshang_formation",
    "tiaojishan": "ptero_tiaojishan_formation",
}

# Old JSON/image slug aliases -> canonical taxon slug (within formation folder)
TAXON_ALIASES: dict[str, str] = {
    "coccoliths-bloom": "coccolith-bloom",
    "hardy-ferns": "hardy-fern",
    "karabastau-araucariaceae": "araucariacea",
    "karabastau-conifer": "conifer",
    "karabastau-equisetites": "equisetites",
    "javelina-conifer": "conifer",
    "javelina-early-angiosperm": "early-angiosperm",
    "plottier-equisetites": "equisetites",
    "santana-romualdo-araucariaceae": "araucariaceae",
    "tangshang-conifer": "conifer",
    "tangshang-ginkgo": "ginkgo",
}


def target_stem(formation: str, current_stem: str) -> str:
    rest = current_stem.removeprefix("ptero-flora-")
    if rest.startswith(formation + "-"):
        return current_stem
    return f"ptero-flora-{formation}-{rest}"


def safe_mv(src: Path, dst: Path, dry_run: bool) -> None:
    if src == dst or not src.exists():
        return
    if dst.exists():
        print(f"SKIP (exists): {dst.name}", file=sys.stderr)
        return
    rel_src = src.relative_to(REPO_ROOT)
    rel_dst = dst.relative_to(REPO_ROOT)
    print(f"{'DRY' if dry_run else 'MV'}: {rel_src} -> {rel_dst}")
    if dry_run:
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        ["git", "mv", str(rel_src), str(rel_dst)],
        cwd=REPO_ROOT,
        capture_output=True,
    )
    if result.returncode != 0:
        src.rename(dst)


def git_mv(src: Path, dst: Path, dry_run: bool) -> None:
    safe_mv(src, dst, dry_run)


def plain_mv(src: Path, dst: Path, dry_run: bool) -> None:
    if src == dst or not src.exists():
        return
    if dst.exists():
        print(f"SKIP (exists): {dst.name}", file=sys.stderr)
        return
    print(f"{'DRY' if dry_run else 'MV'}: {src} -> {dst}")
    if not dry_run:
        dst.parent.mkdir(parents=True, exist_ok=True)
        src.rename(dst)


def rename_imageset(imageset: Path, new_stem: str, dry_run: bool) -> None:
    old_stem = imageset.name.replace(".imageset", "")
    if old_stem.endswith("-habitat"):
        old_stem = old_stem[: -len("-habitat")]
    elif old_stem.endswith("-seeds"):
        old_stem = old_stem[: -len("-seeds")]
    suffix = "-habitat" if (imageset.name.replace(".imageset", "").endswith("-habitat")) else "-seeds"
    if old_stem == new_stem:
        return

    contents_path = imageset / "Contents.json"
    if contents_path.exists():
        data = json.loads(contents_path.read_text())
        for entry in data.get("images", []):
            filename = entry.get("filename")
            if not filename:
                continue
            new_filename = filename.replace(old_stem, new_stem, 1)
            if new_filename != filename:
                old_png = imageset / filename
                new_png = imageset / new_filename
                git_mv(old_png, new_png, dry_run)
                entry["filename"] = new_filename
        if not dry_run:
            contents_path.write_text(json.dumps(data, indent=2) + "\n")
        else:
            print(f"  would update {contents_path.name}: {old_stem} -> {new_stem}")

    new_name = f"{new_stem}{suffix}.imageset"
    git_mv(imageset, imageset.parent / new_name, dry_run)


def rename_xcassets(dry_run: bool) -> int:
    count = 0
    for folder_name, formation in FORMATION_XC.items():
        folder = XC_ROOT / folder_name
        if not folder.is_dir():
            continue
        stems: set[str] = set()
        for imageset in folder.glob("*.imageset"):
            name = imageset.name.replace(".imageset", "")
            if name.endswith("-habitat"):
                stems.add(name[: -len("-habitat")])
        for old_stem in sorted(stems):
            new_stem = target_stem(formation, old_stem)
            for suffix in ("-habitat", "-seeds"):
                imageset = folder / f"{old_stem}{suffix}.imageset"
                if imageset.is_dir():
                    rename_imageset(imageset, new_stem, dry_run)
                    count += 1
    return count


IMAGE_RE = re.compile(
    r"^(?P<stem>ptero-flora-.+?)-(?P<variant>habitat|seeds)-(?P<size>\d+)\.png$"
)
JSON_RE = re.compile(
    r"^(?P<stem>ptero-flora-.+?)-(?P<variant>habitat|seeds)\.json$"
)


def parse_source_stem(raw: str, formation: str) -> tuple[str, str]:
    """Return (current_stem_without_variant, canonical target stem)."""
    stem = raw
    if stem.startswith("ptero-flora-"):
        rest = stem.removeprefix("ptero-flora-")
        if rest.startswith(formation + "-"):
            taxon_part = rest[len(formation) + 1 :]
        else:
            taxon_part = TAXON_ALIASES.get(rest, rest)
        canonical_taxon = TAXON_ALIASES.get(taxon_part, taxon_part)
        if not rest.startswith(formation + "-"):
            current_stem = f"ptero-flora-{rest}"
        else:
            current_stem = stem
        target = f"ptero-flora-{formation}-{canonical_taxon}"
        return current_stem, target
    return stem, stem


def rename_source_images(dry_run: bool) -> int:
    count = 0
    for formation, src_folder in SOURCE_FOLDER.items():
        dir_path = IMG_ROOT / src_folder
        if not dir_path.is_dir():
            continue
        for src in sorted(dir_path.glob("*.png")):
            match = IMAGE_RE.match(src.name)
            if not match:
                print(f"UNMATCHED image: {src}", file=sys.stderr)
                continue
            _, target = parse_source_stem(match.group("stem"), formation)
            variant = match.group("variant")
            size = match.group("size")
            dst_name = f"{target}-{variant}-{size}.png"
            dst = dir_path / dst_name
            git_mv(src, dst, dry_run)
            count += 1
    return count


def rename_source_json(dry_run: bool) -> int:
    count = 0
    for formation, src_folder in SOURCE_FOLDER.items():
        dir_path = JSON_ROOT / src_folder
        if not dir_path.is_dir():
            continue
        for src in sorted(dir_path.rglob("*.json")):
            match = JSON_RE.match(src.name)
            if not match:
                continue
            _, target = parse_source_stem(match.group("stem"), formation)
            variant = match.group("variant")
            dst_name = f"{target}-{variant}.json"
            dst = src.parent / dst_name
            git_mv(src, dst, dry_run)
            count += 1
    return count


def main() -> None:
    dry_run = "--dry-run" in sys.argv
    xc = rename_xcassets(dry_run)
    imgs = rename_source_images(dry_run)
    js = rename_source_json(dry_run)
    print(f"Processed {xc} imagesets, {imgs} source PNGs, {js} JSON files")


if __name__ == "__main__":
    main()
