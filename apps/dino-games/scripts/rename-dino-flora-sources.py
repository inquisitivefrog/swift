#!/usr/bin/env python3
"""Rename dino-flora source images and JSON to dino-flora-{formation}-{taxon}-* pattern."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
BASE = REPO_ROOT / "apps/dino-games/DinoGames"

FOLDER_TO_FORMATION = {
    "horseshoe_canyon": "horseshoe-canyon",
    "huincul": "huincul",
    "iren_dabasu": "iren-dabasu",
    "jiufotang": "jiufotang",
    "kem_kem": "kem-kem",
    "la_amarga": "la-amarga",
    "lance_hell_creek": "lance-hell-creek",
    "morrison": "morrison",
    "shaximiao": "shaximiao",
    "solnhofen": "solnhofen",
    "tahora": "tahora",
    "wealden": "wealden",
}

# (formation, canonical taxon, filename slug aliases)
PLANTS: list[tuple[str, str, list[str]]] = [
    ("morrison", "araucaria", ["araucaria"]),
    ("horseshoe-canyon", "azolla", ["azolla"]),
    ("lance-hell-creek", "bennettitales", ["bennettitales"]),
    ("jiufotang", "birch", ["birch"]),
    ("shaximiao", "brachyphyllum", ["brachyphyllum"]),
    ("jiufotang", "charophytes", ["charophytes"]),
    ("la-amarga", "clubmoss", ["clubmoss"]),
    ("morrison", "cycad", ["cycad", "cycads"]),
    ("wealden", "cypress", ["cypress"]),
    ("jiufotang", "equisetites", ["equisetites"]),
    ("morrison", "herbaceous-fern", ["herbaceous-fern", "fern"]),
    ("la-amarga", "fungi", ["fungi"]),
    ("morrison", "ginkgo", ["ginkgo"]),
    ("la-amarga", "ginkgoites", ["ginkgoites"]),
    ("kem-kem", "horsetail", ["horsetail", "horsetails"]),
    ("huincul", "kauri", ["kauri"]),
    ("tahora", "kelp", ["kelp"]),
    ("lance-hell-creek", "laurel", ["laurel"]),
    ("jiufotang", "liverwort", ["liverwort"]),
    ("lance-hell-creek", "magnolia", ["magnolia"]),
    ("tahora", "magnoliid", ["magnoliid"]),
    ("jiufotang", "mamaku", ["mamaku"]),
    ("horseshoe-canyon", "metasequoia", ["metasequoia"]),
    ("morrison", "moss", ["moss"]),
    ("lance-hell-creek", "oak", ["oak"]),
    ("tahora", "paleopus", ["paleopus"]),
    ("solnhofen", "palm", ["palm"]),
    ("la-amarga", "ponga", ["ponga", "pongo"]),
    ("horseshoe-canyon", "redwood", ["redwood"]),
    ("la-amarga", "rimu", ["rimu"]),
    ("kem-kem", "sycamore", ["sycamore"]),
    ("horseshoe-canyon", "taxodium", ["taxodium"]),
    ("la-amarga", "totara", ["totara"]),
    ("morrison", "tree-fern", ["tree-fern"]),
    ("iren-dabasu", "walnut", ["walnut"]),
    ("jiufotang", "water-lilies", ["water-lilies"]),
]

TAXON_LOOKUP: dict[tuple[str, str], str] = {}
for formation, taxon, aliases in PLANTS:
    for alias in aliases:
        TAXON_LOOKUP[(formation, alias)] = taxon

IMAGE_RE = re.compile(
    r"^(?:dino-flora-|flora-)(?P<taxon>.+?)-(?P<variant>habitat|seeds)-(?P<size>\d+)\.png$"
)
JSON_RE = re.compile(
    r"^flora-(?P<taxon>.+?)-(?P<variant>habitat|seeds?)(?:-json)?$"
)


def resolve_taxon(formation: str, raw_taxon: str) -> str:
    if (formation, raw_taxon) in TAXON_LOOKUP:
        return TAXON_LOOKUP[(formation, raw_taxon)]
    raise KeyError(f"No taxon mapping for formation={formation!r} slug={raw_taxon!r}")


def git_mv(src: Path, dst: Path, dry_run: bool) -> None:
    if src == dst:
        return
    if dst.exists():
        print(f"SKIP (target exists): {src.name} -> {dst.name}", file=sys.stderr)
        return
    rel_src = src.relative_to(REPO_ROOT)
    rel_dst = dst.relative_to(REPO_ROOT)
    print(f"{'DRY' if dry_run else 'MV'}: {rel_src} -> {rel_dst}")
    if not dry_run:
        subprocess.run(
            ["git", "mv", str(rel_src), str(rel_dst)],
            cwd=REPO_ROOT,
            check=True,
        )


def rename_images(dry_run: bool) -> int:
    count = 0
    images_root = BASE / "images/dino-flora"
    for folder, formation in sorted(FOLDER_TO_FORMATION.items()):
        dir_path = images_root / folder
        if not dir_path.is_dir():
            continue
        for src in sorted(dir_path.iterdir()):
            if not src.is_file() or src.suffix != ".png":
                continue
            match = IMAGE_RE.match(src.name)
            if not match:
                print(f"UNMATCHED image: {src}", file=sys.stderr)
                continue
            taxon = resolve_taxon(formation, match.group("taxon"))
            variant = match.group("variant")
            size = match.group("size")
            dst_name = f"dino-flora-{formation}-{taxon}-{variant}-{size}.png"
            dst = dir_path / dst_name
            git_mv(src, dst, dry_run)
            count += 1
    return count


def rename_json(dry_run: bool) -> int:
    count = 0
    json_root = BASE / "json/dino-flora"
    for folder, formation in sorted(FOLDER_TO_FORMATION.items()):
        dir_path = json_root / folder
        if not dir_path.is_dir():
            continue
        for src in sorted(dir_path.iterdir()):
            if not src.is_file():
                continue
            stem = src.name[:-5] if src.name.endswith(".json") else src.name
            match = JSON_RE.match(stem)
            if not match:
                print(f"UNMATCHED json: {src}", file=sys.stderr)
                continue
            taxon = resolve_taxon(formation, match.group("taxon"))
            variant = match.group("variant")
            if variant == "seed":
                variant = "seeds"
            dst_name = f"dino-flora-{formation}-{taxon}-{variant}.json"
            dst = dir_path / dst_name
            git_mv(src, dst, dry_run)
            count += 1
    return count


def main() -> None:
    dry_run = "--dry-run" in sys.argv
    image_count = rename_images(dry_run)
    json_count = rename_json(dry_run)
    print(f"Processed {image_count} images, {json_count} json files")


if __name__ == "__main__":
    main()
