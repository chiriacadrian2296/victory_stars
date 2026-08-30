# constellation-astralarium

Scripts to round-trip constellation shapes through [Astralarium](https://tarenethil.github.io/astralarium/) ([source](https://github.com/TarEnethil/astralarium)), a small browser-based editor for custom point-and-line diagrams — useful when a shape needs an actual hands-on edit (drag a star, add/remove a line) instead of a described-in-words change.

These are one-off data-conversion helpers for the constellation design workflow, not part of the shipped app.

## Format

Our shapes are plain JSON: a list of areas, each `{"key", "label", "shapes": [...]}`, each shape `{"name", "points": [[x,y], ...], "edges": [[a,b], ...]}` with x/y in a 0..100 box.

Astralarium's own save/load format is just Fabric.js's canvas JSON — stars are `circle` objects, lines are `line` objects referencing two stars' uuids via `from`/`to`.

## Usage

```
# our shapes -> an Astralarium canvas, one area at a time or all at once
python to_astralarium.py --shapes shapes.json --area physical --out physical.astralarium.json
python to_astralarium.py --shapes shapes.json --all --out-dir ./out

# open physical.astralarium.json in Astralarium ("Load canvas" -> JSON file),
# edit freely, then "Export as JSON"

# the edited Astralarium canvas -> our shapes format
python from_astralarium.py --in physical.edited.json --area physical --label Fisica --out physical.shapes.json
# or merge straight back into the full shapes file:
python from_astralarium.py --in physical.edited.json --area physical --label Fisica --merge-into shapes.json
```

Each star's `name` is set to `"<shape name> · <point index>"` on export — that's how `from_astralarium.py` regroups stars back into shapes and keeps point order stable even after you've dragged things around. Renaming a star just moves it into a differently-named shape group (or starts a brand new one) — that's a feature, not a bug, if you want to hand-draw an entirely new shape on the same canvas.

Verified round-trip: generating a canvas and immediately reading it back (no edits) reproduces the original points/edges exactly.
