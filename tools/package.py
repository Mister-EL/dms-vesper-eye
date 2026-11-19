#!/usr/bin/env python3
"""Архив для установки: только то, что нужно плагину в работе, с контрольными суммами."""
import gzip
import hashlib
import io
import json
import tarfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
version = json.loads((root / "plugin.json").read_text())["version"]
files = ["plugin.json", "VesperEye.qml", "Settings.qml", "README.md", "LICENSE", "CHANGELOG.md", "skins/SkinData.js"]
files += [str(p.relative_to(root)) for p in sorted((root / "core").iterdir()) if p.suffix in (".qml", ".js")]
files += [str(p.relative_to(root)) for p in sorted((root / "shaders").glob("*.frag.qsb"))]
files = sorted(set(files))
checks = {name: hashlib.sha256((root / name).read_bytes()).hexdigest() for name in files}
dist = root / ".dist"
dist.mkdir(exist_ok=True)
out = dist / f"vesper-eye-{version}.tar.gz"
buffer = io.BytesIO()
with tarfile.open(fileobj=buffer, mode="w") as archive:
    def add(name, data):
        info = tarfile.TarInfo("vesperEye/" + name)
        info.size, info.mode, info.mtime = len(data), 0o644, 0
        archive.addfile(info, io.BytesIO(data))
    for name in files:
        add(name, (root / name).read_bytes())
    add("SHA256SUMS.json", (json.dumps(checks, indent=2) + "\n").encode())
out.write_bytes(gzip.compress(buffer.getvalue(), mtime=0))
(dist / (out.name + ".sha256")).write_text(hashlib.sha256(out.read_bytes()).hexdigest() + "  " + out.name + "\n")
with tarfile.open(out) as archive:
    for name, digest in checks.items():
        assert hashlib.sha256(archive.extractfile("vesperEye/" + name).read()).hexdigest() == digest
print(f"{out.name}: {len(files)} файлов, {out.stat().st_size} байт; контрольные суммы сверены")
