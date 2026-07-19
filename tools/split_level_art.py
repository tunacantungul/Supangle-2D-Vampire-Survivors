#!/usr/bin/env python3
"""Elle çizilmiş tek parça bölüm görselini oyuna hazır karelere böler.

Procreate'ten çıkan 14400x9000'lik tuval tek doku olarak oyuna konamıyor
(GPU'ların doku sınırı genelde 16384 ve sıkıştırmasız ~520 MB VRAM eder),
bu yüzden ızgaraya bölünüp yan yana Sprite2D olarak diziliyor.

Kullanım:
    python3 tools/split_level_art.py "Bolum 1.png" level_1
    python3 tools/split_level_art.py "Bolum 1.png" level_1 --cols 4 --rows 4

Çıktı:
    supangle/assets/levels/<ad>/tile_<satir>_<sutun>.png
    supangle/scenes/levels/<ad>_art.tscn   (karelerin dizildiği hazır sahne)
"""

import argparse
import sys
from pathlib import Path

from PIL import Image

# 129,6 MP'lik tuval Pillow'un "decompression bomb" eşiğini aşıyor; kaynak
# kendi çizimimiz olduğu için sınırı kaldırıyoruz.
Image.MAX_IMAGE_PIXELS = None

REPO = Path(__file__).resolve().parent.parent
ASSETS = REPO / "supangle" / "assets" / "levels"
SCENES = REPO / "supangle" / "scenes" / "levels"

# Oyun dünyasının oynanabilir alanı: duvarlar x=+-7290, y=+-4590'da ve 180
# birim kalınlığında (bkz. scenes/levels/level_1.tscn).
WORLD_W = 14400
WORLD_H = 9000


def slice_image(src: Path, name: str, cols: int, rows: int) -> tuple[int, int]:
    img = Image.open(src)
    if img.mode != "RGBA":
        img = img.convert("RGBA")

    if img.size != (WORLD_W, WORLD_H):
        print(
            f"uyari: gorsel {img.width}x{img.height}, dunya {WORLD_W}x{WORLD_H}. "
            "Kareler yine de gorselin kendi olcusune gore bolunuyor; sahnede "
            "olcekleme gerekebilir."
        )

    tile_w = img.width // cols
    tile_h = img.height // rows
    if tile_w * cols != img.width or tile_h * rows != img.height:
        sys.exit(
            f"hata: {img.width}x{img.height} gorsel {cols}x{rows} izgaraya tam "
            "bolunmuyor. Bolen bir sayi sec."
        )

    out_dir = ASSETS / name
    out_dir.mkdir(parents=True, exist_ok=True)
    for row in range(rows):
        for col in range(cols):
            box = (col * tile_w, row * tile_h, (col + 1) * tile_w, (row + 1) * tile_h)
            tile = img.crop(box)
            tile.save(out_dir / f"tile_{row}_{col}.png")
            print(f"  tile_{row}_{col}.png  {tile_w}x{tile_h}")
    return tile_w, tile_h


def write_scene(
    name: str, cols: int, rows: int, tile_w: int, tile_h: int, mirror: bool = False
) -> Path:
    """Kareleri dunya merkezine gore dizen bir sahne yazar.

    Sprite2D varsayilan olarak merkezden konumlanir, bu yuzden her karenin
    konumu kendi merkezidir; ilk karenin sol ust kosesi dunyanin sol ust
    kosesine denk gelsin diye yarim kare kaydiriliyor.
    """
    left = -(cols * tile_w) / 2
    top = -(rows * tile_h) / 2

    lines = ["[gd_scene format=3]", ""]
    for row in range(rows):
        for col in range(cols):
            rid = row * cols + col + 1
            path = f"res://assets/levels/{name}/tile_{row}_{col}.png"
            lines.append(f'[ext_resource type="Texture2D" path="{path}" id="{rid}"]')
    lines += ["", '[node name="LevelArt" type="Node2D"]', ""]
    for row in range(rows):
        for col in range(cols):
            rid = row * cols + col + 1
            x = left + col * tile_w + tile_w / 2
            y = top + row * tile_h + tile_h / 2
            node = [
                f'[node name="Tile{row}_{col}" type="Sprite2D" parent="."]',
            ]
            if mirror:
                # Aynalama yeni gorsel gerektirmiyor: ayni kareler x ekseninde
                # ters konuma tasinip kendi icinde de cevriliyor. Sonuc, haritanin
                # tam ayna goruntusu; depoya tek byte eklenmiyor.
                node.append(f"position = Vector2({-x:g}, {y:g})")
                node.append("flip_h = true")
            else:
                node.append(f"position = Vector2({x:g}, {y:g})")
            node.append(f'texture = ExtResource("{rid}")')
            node.append("")
            lines += node

    suffix = "_art_flipped" if mirror else "_art"
    scene = SCENES / f"{name}{suffix}.tscn"
    scene.write_text("\n".join(lines))
    return scene


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "source", type=Path, nargs="?", help="tek parca cizim (png/psd/jpg)"
    )
    ap.add_argument("name", help="bolum adi, orn. level_1")
    ap.add_argument("--cols", type=int, default=4)
    ap.add_argument("--rows", type=int, default=4)
    ap.add_argument(
        "--scenes-only",
        action="store_true",
        help="kareleri yeniden kesme, sadece sahneleri uret (kareler zaten varsa)",
    )
    args = ap.parse_args()

    if args.scenes_only:
        tiles = sorted((ASSETS / args.name).glob("tile_*.png"))
        if not tiles:
            sys.exit(f"hata: {ASSETS / args.name} altinda kare yok")
        with Image.open(tiles[0]) as first:
            tile_w, tile_h = first.size
        for mirror in (False, True):
            scene = write_scene(args.name, args.cols, args.rows, tile_w, tile_h, mirror)
            print(f"sahne: {scene.relative_to(REPO)}")
        return

    if not args.source.exists():
        sys.exit(f"hata: {args.source} bulunamadi")

    print(f"{args.source.name} -> {args.cols}x{args.rows} kare")
    tile_w, tile_h = slice_image(args.source, args.name, args.cols, args.rows)
    scene = write_scene(args.name, args.cols, args.rows, tile_w, tile_h)
    print(f"\nsahne: {scene.relative_to(REPO)}")
    print(f"Bolum sahnesinde bu sahneyi z_index'i dusuk bir cocuk olarak ekle.")


if __name__ == "__main__":
    main()
