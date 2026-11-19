#!/usr/bin/env python3
"""Собирает шейдеры образов для Qt (qsb) и для браузерной доски из одних исходников.

    python3 tools/build.py                     всё: .frag, .qsb, skins/SkinData.js, design/board/index.html
    python3 tools/build.py --no-qsb            без вызова qsb (только доска и данные)
    python3 tools/build.py --only pearl,signal только перечисленные образы
    python3 tools/build.py --board-out FILE    доску записать в FILE (для проб, не трогая общую)

Образ — это пара файлов: skins/<id>.json и shaders/src/<id>.glsl. Порядок задаёт skins/order.json;
образы, у которых ещё нет обоих файлов, пропускаются.
"""
import json
import os
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
src = root / "shaders" / "src"
args = sys.argv[1:]


def opt(name):
    return args[args.index(name) + 1] if name in args else None


only = set(opt("--only").split(",")) if opt("--only") else None
order = json.loads((root / "skins" / "order.json").read_text(encoding="utf-8"))
skins = {}
for sid in order:
    meta, body = root / "skins" / f"{sid}.json", None
    if only and sid not in only:
        continue
    if not meta.exists():
        continue
    info = json.loads(meta.read_text(encoding="utf-8"))
    body = src / f"{info['shader']}.glsl"
    if not body.exists():
        print(f"пропуск {sid}: нет {body.name}")
        continue
    skins[sid] = info
ids = [s for s in order if s in skins]
common = (src / "common.glsl").read_text(encoding="utf-8")


def assemble(flavor: str, shader: str) -> str:
    head = (root / "shaders" / flavor / "header.glsl").read_text(encoding="utf-8")
    foot = (root / "shaders" / flavor / "footer.glsl").read_text(encoding="utf-8")
    return head + "\n" + common + "\n" + (src / f"{shader}.glsl").read_text(encoding="utf-8") + foot


shaders = sorted({skins[s]["shader"] for s in ids})
qsb = os.environ.get("QSB", "/usr/lib/qt6/bin/qsb")
use_qsb = "--no-qsb" not in args and os.access(qsb, os.X_OK)
if use_qsb:
    build = root / "shaders" / "build"
    build.mkdir(exist_ok=True)
    for name in shaders:
        frag = build / f"{name}.frag"
        frag.write_text(assemble("qt", name), encoding="utf-8")
        # Одного SPIR-V мало: оболочка по умолчанию рисует через OpenGL, в том числе старых версий.
        subprocess.run([qsb, "--glsl", "100 es,120,150,300 es,330", "--hlsl", "50", "--msl", "12",
                        "-o", str(root / "shaders" / f"{name}.frag.qsb"), str(frag)], check=True)

data = {"order": ids, "skins": skins}
if not only and not opt("--board-out"):
    (root / "skins" / "SkinData.js").write_text(
        ".pragma library\n// Создано tools/build.py из skins/*.json. Руками не править.\nvar data = "
        + json.dumps(data, ensure_ascii=False, indent=1) + ";\n", encoding="utf-8")

template = (root / "design" / "board" / "template.html").read_text(encoding="utf-8")
marker = "/*__DATA__*/null"
assert template.count(marker) == 1
payload = json.dumps({**data, "shaders": {n: assemble("web", n) for n in shaders}}, ensure_ascii=False).replace("</", "<\\/")
out = Path(opt("--board-out")) if opt("--board-out") else root / "design" / "board" / "index.html"
out.write_text(template.replace(marker, payload), encoding="utf-8")
print(f"образы: {', '.join(ids) or 'нет'}; qsb: {'да' if use_qsb else 'нет'}; доска: {out}")
