#!/usr/bin/env python3
"""Convert life-area constellation shapes (our points+edges JSON) into a
canvas file loadable in Astralarium (https://tarenethil.github.io/astralarium/,
https://github.com/TarEnethil/astralarium).

Input shape: a JSON list of areas, each `{"key", "label", "shapes": [...]}`,
each shape `{"name", "v", "points": [[x,y], ...], "edges": [[a,b], ...]}`
with x/y in a 0..100 local box — the same structure produced by our
constellation-shape generator script and consumed by the Catalogo
Costellazioni review artifact.

Output: an Astralarium canvas JSON — Fabric.js's own `canvas.toJSON()`
format. Every point becomes a `circle` (a star); every edge becomes a
`line` referencing its two stars' uuids via the custom `from`/`to` fields
Astralarium adds on top of Fabric's serialization. A star's `name` is set
to "<shape name> · <point index>" so from_astralarium.py can regroup
points back into shapes after you've moved them around in the editor,
and so the name is meaningful if you look at it in Astralarium's own UI.

Usage:
    python to_astralarium.py --shapes shapes.json --area physical --out physical.astralarium.json
    python to_astralarium.py --shapes shapes.json --all --out-dir ./out
"""
import argparse
import json
import uuid
from pathlib import Path

FABRIC_VERSION = "4.6.0"  # matches the fabric.min.js Astralarium bundles

COLS = 5
CELL_W = 260
CELL_H = 220
CELL_PADDING = 40
STAR_RADIUS = 5
STAR_FILL = "#ffffff"
STAR_STROKE = "#cccccc"
LINE_STROKE = "#88aadd"
LINE_WIDTH = 2


def layout_cells(count):
    """Top-left (x, y) origin for each shape's grid cell, in canvas px."""
    cells = []
    for i in range(count):
        col = i % COLS
        row = i // COLS
        cells.append((col * CELL_W, row * CELL_H))
    return cells


def build_objects(shapes):
    objects = []
    cell_inner = min(CELL_W, CELL_H) - 2 * CELL_PADDING
    scale = cell_inner / 100.0

    for shape, (ox, oy) in zip(shapes, layout_cells(len(shapes))):
        ox += CELL_PADDING
        oy += CELL_PADDING
        star_uuids = []
        star_by_uuid = {}

        for pi, (x, y) in enumerate(shape["points"]):
            cx = ox + x * scale
            cy = oy + y * scale
            u = str(uuid.uuid4())
            star = {
                "type": "circle",
                "left": round(cx - STAR_RADIUS, 2),
                "top": round(cy - STAR_RADIUS, 2),
                "radius": STAR_RADIUS,
                "fill": STAR_FILL,
                "stroke": STAR_STROKE,
                "strokeWidth": 2,
                "padding": 5,
                "name": f"{shape['name']} · {pi}",
                "uuid": u,
                "lines_from": [],
                "lines_to": [],
            }
            star_uuids.append(u)
            star_by_uuid[u] = star
            objects.append(star)

        for a, b in shape["edges"]:
            ua, ub = star_uuids[a], star_uuids[b]
            sa, sb = star_by_uuid[ua], star_by_uuid[ub]
            lu = str(uuid.uuid4())
            line = {
                "type": "line",
                "x1": sa["left"] + STAR_RADIUS,
                "y1": sa["top"] + STAR_RADIUS,
                "x2": sb["left"] + STAR_RADIUS,
                "y2": sb["top"] + STAR_RADIUS,
                "stroke": LINE_STROKE,
                "strokeWidth": LINE_WIDTH,
                "uuid": lu,
                "from": ua,
                "to": ub,
            }
            objects.append(line)
            sa["lines_from"].append(lu)
            sb["lines_to"].append(lu)

    return objects


def build_canvas(shapes):
    n_cols = min(COLS, len(shapes)) or 1
    n_rows = (len(shapes) + COLS - 1) // COLS
    return {
        "version": FABRIC_VERSION,
        "objects": build_objects(shapes),
        "background": "#0d1220",
        # informational only, Astralarium's own "new canvas" resizes the
        # live canvas to the browser window regardless of these values
        "width": n_cols * CELL_W,
        "height": n_rows * CELL_H,
    }


def load_areas(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def find_area(areas, key):
    for a in areas:
        if a["key"] == key:
            return a
    raise SystemExit(f"no area with key {key!r} — available: {[a['key'] for a in areas]}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--shapes", required=True, help="path to the points+edges shapes JSON (list of areas)")
    group = ap.add_mutually_exclusive_group(required=True)
    group.add_argument("--area", help="life-area key to export (e.g. physical)")
    group.add_argument("--all", action="store_true", help="export every area")
    ap.add_argument("--out", help="output path (single --area only)")
    ap.add_argument("--out-dir", help="output directory (--all only, one file per area)")
    args = ap.parse_args()

    areas = load_areas(args.shapes)

    if args.area:
        area = find_area(areas, args.area)
        out_path = Path(args.out) if args.out else Path(f"{args.area}.astralarium.json")
        canvas = build_canvas(area["shapes"])
        out_path.write_text(json.dumps(canvas), encoding="utf-8")
        print(f"wrote {out_path} ({len(area['shapes'])} shapes, {len(canvas['objects'])} objects)")
    else:
        out_dir = Path(args.out_dir) if args.out_dir else Path(".")
        out_dir.mkdir(parents=True, exist_ok=True)
        for area in areas:
            canvas = build_canvas(area["shapes"])
            out_path = out_dir / f"{area['key']}.astralarium.json"
            out_path.write_text(json.dumps(canvas), encoding="utf-8")
            print(f"wrote {out_path} ({len(area['shapes'])} shapes, {len(canvas['objects'])} objects)")


if __name__ == "__main__":
    main()
