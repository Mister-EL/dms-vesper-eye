#!/usr/bin/env python3
"""Собирает живой набросок образа «Смотритель»: рабочий стол в браузере с настоящим шейдером глаза.

    python3 design/keeper/build.py [выход.html ...]

Без аргументов пишет design/keeper/index.html. Страница самодостаточна: шейдер и цвета вшиты в неё.
"""
import json
import sys
from pathlib import Path

here = Path(__file__).resolve().parent
repo = here.parents[1]
skin = json.loads((repo / "skins" / "keeper.json").read_text(encoding="utf-8"))
parts = [repo / "shaders" / "web" / "header.glsl", repo / "shaders" / "src" / "common.glsl",
         repo / "shaders" / "src" / f"{skin['shader']}.glsl", repo / "shaders" / "web" / "footer.glsl"]
shader = "\n".join(p.read_text(encoding="utf-8") for p in parts)
page = (here / "template.html").read_text(encoding="utf-8")
for marker, value in (("/*__SKIN__*/null", skin), ("/*__SHADER__*/null", shader)):
    assert page.count(marker) == 1, marker
    page = page.replace(marker, json.dumps(value, ensure_ascii=False).replace("</", "<\\/"))
for out in sys.argv[1:] or [str(here / "index.html")]:
    Path(out).write_text(page, encoding="utf-8")
    print("записано:", out)
