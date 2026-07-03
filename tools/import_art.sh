#!/bin/bash
# Import a finished art file into the game at the correct size and location,
# and record it as REAL art (vs. placeholder) for tools/audit_assets.gd.
# Uses macOS `sips` (built in) — no dependencies.
#
#   ./tools/import_art.sh unit <unit_id> <portrait|chibi|icon> <source-image>
#   ./tools/import_art.sh valley <valley_number> <source-image>
#
# After importing, re-import resources so Godot picks them up:
#   godot --headless --path . --import
set -euo pipefail
cd "$(dirname "$0")/.."

MANIFEST="art_workbench/real_art.json"
mkdir -p art_workbench

record() { # key
  python3 - "$1" <<'EOF'
import json, sys, os
path = "art_workbench/real_art.json"
data = {}
if os.path.exists(path):
    data = json.load(open(path))
data[sys.argv[1]] = True
json.dump(data, open(path, "w"), indent=1, sort_keys=True)
EOF
}

case "${1:-}" in
  unit)
    ID="$2"; KIND="$3"; SRC="$4"
    [ -f "data/units/$ID.tres" ] || { echo "ERROR: unknown unit id '$ID' (no data/units/$ID.tres)"; exit 1; }
    case "$KIND" in
      portrait) SIZE=1024 ;;
      chibi)    SIZE=512 ;;
      icon)     SIZE=256 ;;
      *) echo "ERROR: kind must be portrait|chibi|icon"; exit 1 ;;
    esac
    DEST="assets/art/units/$ID/$KIND.png"
    mkdir -p "assets/art/units/$ID"
    sips -Z "$SIZE" -s format png "$SRC" --out "$DEST" >/dev/null
    record "$ID/$KIND"
    echo "imported: $DEST (max ${SIZE}px)"
    ;;
  valley)
    V="$2"; SRC="$3"
    DEST="assets/art/stages/valley_$V/background.png"
    mkdir -p "assets/art/stages/valley_$V"
    sips -Z 1920 -s format png "$SRC" --out "$DEST" >/dev/null
    record "valley_$V/background"
    echo "imported: $DEST"
    ;;
  *)
    grep '^#' "$0" | head -12
    exit 1
    ;;
esac

echo "now run:  godot --headless --path . --import"
