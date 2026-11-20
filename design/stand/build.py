#!/usr/bin/env python3
"""Страница показа тем: живые глаза на своих обоях, одно выражение сразу у всех.

    python3 design/stand/build.py <папка с картинками> <выход.html> [описание страницы.json]

В папке лежат обои wall-<имя>.jpg и образцы ref-<имя>.jpg; что и в каком порядке показывать,
задаёт описание страницы (по умолчанию design/stand/views.json).

Шейдеры и описания образов берутся из тех же исходников, что и у плагина (через tools/build.py).
"""
import base64
import json
import subprocess
import sys
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[2]
walls_dir, out = Path(sys.argv[1]), Path(sys.argv[2])
views = Path(sys.argv[3]) if len(sys.argv) > 3 else Path(__file__).parent / "views.json"
with tempfile.TemporaryDirectory() as tmp:
    board = Path(tmp) / "board.html"
    subprocess.run([sys.executable, str(root / "tools" / "build.py"), "--no-qsb", "--board-out", str(board)], check=True, stdout=subprocess.DEVNULL)
    text = board.read_text(encoding="utf-8")
a = text.index("const DATA = ") + len("const DATA = ")
data = text[a:text.index(";\nconst VS", a)]
walls = {}
for f in sorted(walls_dir.glob("wall-*.jpg")):
    walls[f.stem[5:]] = "data:image/jpeg;base64," + base64.b64encode(f.read_bytes()).decode()
for f in sorted(walls_dir.glob("ref-*.jpg")):
    walls[f.stem] = "data:image/jpeg;base64," + base64.b64encode(f.read_bytes()).decode()
page = (Path(__file__).parent / "template.html").read_text(encoding="utf-8")
assert page.count("/*__DATA__*/null") == 1 and page.count("/*__WALLS__*/null") == 1 and page.count("/*__PAGE__*/null") == 1
out.write_text(page.replace("/*__DATA__*/null", data).replace("/*__WALLS__*/null", json.dumps(walls))
               .replace("/*__PAGE__*/null", json.dumps(json.loads(views.read_text(encoding="utf-8")), ensure_ascii=False).replace("</", "<\\/")), encoding="utf-8")
print(f"показ: {out} ({out.stat().st_size // 1024} КБ), обои: {', '.join(walls)}")
