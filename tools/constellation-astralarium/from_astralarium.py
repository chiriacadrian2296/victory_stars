#!/usr/bin/env python3
"""Convert an Astralarium canvas JSON (after you've edited it in the
browser at https://tarenethil.github.io/astralarium/) back into our
points+edges shape format — the reverse of to_astralarium.py.

Stars (circles) are grouped back into shapes by the text before the last
" · " in their `name` field (the point index after it is used to order
points when present, so a shape's point 0/1/2/... stays predictable even
if you reordered objects; stars you renamed or added without that suffix
just fall back to encounter order). Edges come from each line's `from`/
`to` uuids, resolved to the point index of the star they point to. A
shape's points are re-normalized to fit a 0..100 box (padding 10), the
same convention the rest of the pipeline uses.

Usage:
    python from_astralarium.py --in physical.edited.json --area physical --label Fisica --out physical.shapes.json
    python from_astralarium.py --in physical.edited.json --area physical --label Fisica --merge-into shapes.json
"""
import argparse
import json
import re
from pathlib import Path

NAME_RE = re.compile(r"^(.*) · (\d+)$")


def normalize(points, pad=10):
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    minx, maxx = min(xs), max(xs)
    miny, maxy = min(ys), max(ys)
    w = maxx - minx or 1
    h = maxy - miny or 1
    scale = (100 - 2 * pad) / max(w, h)
    cx = (minx + maxx) / 2
    cy = (miny + maxy) / 2
    return [(50 + (x - cx) * scale, 50 + (y - cy) * scale) for x, y in points]


def group_stars(objects):
    """-> { shape_name: [ (order_key, uuid, x, y), ... ] } in encounter order."""
    groups = {}
    for i, obj in enumerate(objects):
        if obj.get("type") != "circle":
            continue
        name = obj.get("name") or "Senza nome"
        m = NAME_RE.match(name)
        shape_name = m.group(1) if m else name
        order_key = int(m.group(2)) if m else i
        radius = obj.get("radius", 0)
        cx = obj["left"] + radius
        cy = obj["top"] + radius
        groups.setdefault(shape_name, []).append((order_key, obj["uuid"], cx, cy))
    for name in groups:
        groups[name].sort(key=lambda t: t[0])
    return groups


def build_shapes(canvas):
    objects = canvas["objects"]
    groups = group_stars(objects)

    # uuid -> (shape_name, point_index)
    uuid_index = {}
    for shape_name, stars in groups.items():
        for idx, (_, u, _, _) in enumerate(stars):
            uuid_index[u] = (shape_name, idx)

    edges_by_shape = {name: [] for name in groups}
    skipped = 0
    for obj in objects:
        if obj.get("type") != "line":
            continue
        frm, to = obj.get("from"), obj.get("to")
        if frm not in uuid_index or to not in uuid_index:
            skipped += 1
            continue
        shape_a, ia = uuid_index[frm]
        shape_b, ib = uuid_index[to]
        if shape_a != shape_b:
            skipped += 1
            continue
        edges_by_shape[shape_a].append((ia, ib))

    if skipped:
        print(f"warning: skipped {skipped} line(s) with a missing endpoint or crossing shapes")

    shapes = []
    for shape_name, stars in groups.items():
        raw_points = [(x, y) for (_, _, x, y) in stars]
        points = normalize(raw_points)
        shapes.append({
            "name": shape_name,
            "points": [[round(x, 2), round(y, 2)] for x, y in points],
            "edges": [list(e) for e in edges_by_shape[shape_name]],
        })
    return shapes


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--in", dest="infile", required=True, help="edited Astralarium canvas JSON")
    ap.add_argument("--area", required=True, help="life-area key (e.g. physical)")
    ap.add_argument("--label", required=True, help="life-area display label (e.g. Fisica)")
    ap.add_argument("--out", help="write the area object to this path")
    ap.add_argument("--merge-into", help="patch this area into an existing shapes.json (list of areas) and rewrite it in place")
    args = ap.parse_args()

    with open(args.infile, encoding="utf-8") as f:
        canvas = json.load(f)

    shapes = build_shapes(canvas)
    area = {"key": args.area, "label": args.label, "shapes": shapes}

    if args.merge_into:
        path = Path(args.merge_into)
        areas = json.loads(path.read_text(encoding="utf-8")) if path.exists() else []
        areas = [a for a in areas if a["key"] != args.area] + [area]
        path.write_text(json.dumps(areas, ensure_ascii=False), encoding="utf-8")
        print(f"merged {len(shapes)} shapes into {path} (area {args.area!r})")

    out_path = Path(args.out) if args.out else Path(f"{args.area}.shapes.json")
    if not args.merge_into or args.out:
        out_path.write_text(json.dumps(area, ensure_ascii=False), encoding="utf-8")
        print(f"wrote {out_path} ({len(shapes)} shapes)")


if __name__ == "__main__":
    main()
