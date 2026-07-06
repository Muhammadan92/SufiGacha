#!/usr/bin/env python3
"""Seven Springs Art Review — local site for the Midjourney workflow.

    python3 tools/art_review/serve.py        ->  http://localhost:8787

Workflow (no Midjourney API exists — this optimizes the legitimate path):
  1. QUEUE tab: every needed asset with a ready-to-paste prompt (Copy).
  2. Generate in Midjourney (web/Discord), download keepers into
     art_workbench/inbox/  (set it as your browser download folder, or drag).
  3. REVIEW tab: approve -> auto-imports at correct size via import_art.sh
     and records real art; reject -> moves aside. Then click "Godot reimport".
Everything is file-based; no accounts, no external calls.
"""
import json
import pathlib
import re
import shutil
import subprocess
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
WB = ROOT / "art_workbench"
INBOX = WB / "inbox"
IMPORTED = WB / "imported"
REJECTED = WB / "rejected"
STYLE_PATH = WB / "style.json"
MANIFEST = WB / "real_art.json"
CREFS_PATH = WB / "crefs.json"  # unit_id -> approved anchor's MJ image URL

## Reference-pack poses: everything varies EXCEPT the character (--cref).
REF_POSES = [
    "standing full body, front view, arms relaxed",
    "full body, side profile view",
    "full body, three-quarter back view, looking over shoulder",
    "seated in quiet contemplation",
    "mid-stride, walking forward, low camera angle",
    "casting their power, dramatic action pose",
    "close-up face, serene expression",
    "close-up face, determined expression",
    "character turnaround reference sheet, front side and back views, same outfit",
]
PORT = 8787

DEFAULT_STYLE = {
    "base": "2D anime video game splash art, cel shaded, clean bold lineart, flat vivid colors, stylized illustration, official game art",
    "character_extra": "single character, three-quarter view, centered, dignified traditional Sufi dress, dark cavern background lit by soft mystical light, hand-drawn game character design, not photorealistic",
    "chibi_extra": "chibi proportions, full body, simple standing pose, clean silhouette, plain neutral background, game sprite sheet style",
    "icon_extra": "portrait emblem, head and shoulders close-up, centered, simple dark background, game avatar icon",
    "bg_extra": "wide establishing environment, atmospheric depth, no characters, painted game background art, stylized not photoreal",
    "flags": "--niji 6 --s 180 --no photo, photorealism, realistic skin texture"
}
AR = {"portrait": "2:3", "chibi": "1:1", "icon": "1:1", "background": "16:9"}

VALLEYS = {
    1: "the Valley of the Quest: a dim cavern road beside an underground spring, first light of hope, emerald moss and silver water",
    2: "the Valley of Love: a murmuring orchard underground, petals drifting in dark air, warm rose light against deep shadow",
    3: "the Valley of Knowledge: a vast library of smoke and echoes, mirrored surfaces, cold turquoise light",
    4: "the Valley of Detachment: a heavy stone gate half-buried in hoarded treasures turned to dust, amber gloom",
    5: "the Valley of Unity: a single still road over dark water, one thread of light, profound calm",
    6: "the Valley of Wonder: a gilded bazaar of illusions, golden ornament dripping from black stone, dazzling false stars",
    7: "the Valley of the Passing-Away: a thinning road into luminous white emptiness, the last veil, quiet and vast",
}


def load_json(path, default):
    try:
        return json.loads(path.read_text())
    except Exception:
        return default


def parse_units():
    units = []
    for f in sorted((ROOT / "data" / "units").glob("*.tres")):
        text = f.read_text()

        def field(name, default=""):
            # LAST match: the unit's own properties live in [resource], which
            # comes AFTER skill sub-resources (whose display_name would
            # otherwise shadow the unit's — the "Grace Note bug").
            matches = re.findall(r'^%s = "(.*)"$' % name, text, re.M)
            return matches[-1] if matches else default

        m_rar = re.search(r"^rarity = (\d+)", text, re.M)
        units.append({
            "id": f.stem,
            "name": field("display_name", f.stem),
            "epithet": field("epithet"),
            "order": field("order_name"),
            "notes": field("art_notes"),
            "rarity": int(m_rar.group(1)) if m_rar else 3,
            "enemy": "is_enemy = true" in text,
            "gender": "f" if "woman" in field("art_notes").lower() else
                ("m" if re.search(r"\bman\b|\bsailor\b", field("art_notes").lower()) else "n"),
        })
    return units


def build_prompt(style, notes, kind):
    extra = style.get({"portrait": "character_extra", "chibi": "chibi_extra",
                       "icon": "icon_extra", "background": "bg_extra"}[kind], "")
    parts = [style.get("base", ""), notes, extra]
    prompt = ", ".join(p.strip() for p in parts if p.strip())
    return ("%s --ar %s %s" % (prompt, AR[kind], style.get("flags", ""))).strip()


def state():
    style = load_json(STYLE_PATH, DEFAULT_STYLE)
    real = load_json(MANIFEST, {})
    units = []
    for u in parse_units():
        kinds = {}
        for kind in ["portrait", "chibi", "icon"]:
            kinds[kind] = {
                "real": bool(real.get("%s/%s" % (u["id"], kind))),
                "prompt": build_prompt(style, u["notes"], kind),
            }
        units.append({**u, "kinds": kinds})
    valleys = []
    for v, theme in VALLEYS.items():
        valleys.append({
            "valley": v, "theme": theme,
            "real": bool(real.get("valley_%d/background" % v)),
            "prompt": build_prompt(style, theme, "background"),
        })
    crefs = load_json(CREFS_PATH, {})
    for u in units:
        u["cref"] = crefs.get(u["id"], "")
        if u["cref"]:
            base = build_prompt(style, u["notes"], "portrait")
            u["ref_pack"] = ["%s, %s --cref %s --cw 100" % (base.split(" --ar ")[0], pose, u["cref"])
                + " --ar 2:3 " + style.get("flags", "") for pose in REF_POSES]
    inbox = sorted(p.name for p in INBOX.glob("*")
                   if p.suffix.lower() in [".png", ".jpg", ".jpeg", ".webp"])
    return {"style": style, "units": units, "valleys": valleys, "inbox": inbox}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _json(self, obj, code=200):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urllib.parse.unquote(self.path.split("?")[0])
        if path == "/":
            body = (pathlib.Path(__file__).parent / "index.html").read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif path == "/api/state":
            self._json(state())
        elif path.startswith("/inbox/"):
            f = INBOX / pathlib.Path(path[len("/inbox/"):]).name
            if f.exists():
                body = f.read_bytes()
                self.send_response(200)
                self.send_header("Content-Type", "image/png")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
            else:
                self._json({"error": "not found"}, 404)
        else:
            self._json({"error": "not found"}, 404)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        req = json.loads(self.rfile.read(length) or b"{}")
        path = self.path
        if path == "/api/approve":
            src = INBOX / pathlib.Path(req["file"]).name
            if not src.exists():
                return self._json({"error": "file gone"}, 400)
            if req["target"] == "unit":
                cmd = ["./tools/import_art.sh", "unit", req["id"], req["kind"], str(src)]
            else:
                cmd = ["./tools/import_art.sh", "valley", str(req["id"]), str(src)]
            r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True)
            if r.returncode != 0:
                return self._json({"error": r.stderr or r.stdout}, 400)
            IMPORTED.mkdir(exist_ok=True)
            shutil.move(str(src), IMPORTED / src.name)
            self._json({"ok": True, "detail": r.stdout.strip()})
        elif path == "/api/cref":
            crefs = load_json(CREFS_PATH, {})
            crefs[req["id"]] = req["url"].strip()
            CREFS_PATH.write_text(json.dumps(crefs, indent=1))
            self._json({"ok": True})
        elif path == "/api/reference":
            src_f = INBOX / pathlib.Path(req["file"]).name
            if not src_f.exists():
                return self._json({"error": "file gone"}, 400)
            dest = WB / "refs" / req["id"]
            dest.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src_f), dest / src_f.name)
            n = len(list(dest.glob("*")))
            self._json({"ok": True, "detail": "reference saved (%s now has %d refs; ~15-30 makes a LoRA set)" % (req["id"], n)})
        elif path == "/api/reject":
            src = INBOX / pathlib.Path(req["file"]).name
            if src.exists():
                REJECTED.mkdir(exist_ok=True)
                shutil.move(str(src), REJECTED / src.name)
            self._json({"ok": True})
        elif path == "/api/style":
            STYLE_PATH.write_text(json.dumps(req, indent=1))
            self._json({"ok": True})
        elif path == "/api/reimport":
            subprocess.Popen(["godot", "--headless", "--path", ".", "--import"],
                             cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self._json({"ok": True, "detail": "Godot reimport started (~30s)"})
        else:
            self._json({"error": "not found"}, 404)


def main():
    INBOX.mkdir(parents=True, exist_ok=True)
    if not STYLE_PATH.exists():
        STYLE_PATH.write_text(json.dumps(DEFAULT_STYLE, indent=1))
    print("Seven Springs Art Review  ->  http://localhost:%d" % PORT)
    print("inbox: %s" % INBOX)
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()


if __name__ == "__main__":
    main()
