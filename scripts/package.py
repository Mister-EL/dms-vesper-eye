#!/usr/bin/env python3
"""Build a runtime archive from an explicit allowlist, excluding personal data and git internals."""
from pathlib import Path
import gzip,hashlib,io,json,tarfile
root=Path(__file__).resolve().parents[1]
version=json.loads((root/'plugin.json').read_text())['version']
files=['plugin.json','VesperEye.qml','Settings.qml','README.md','LICENSE','CHANGELOG.md','legacy/noctalia/LICENSE','design/palette.json','design/style-board.html']
for directory in ['components','helpers','shaders','scripts','docs','legacy/noctalia']:
 files += [str(p.relative_to(root)) for p in (root/directory).rglob('*') if p.is_file() and '__pycache__' not in p.parts and p.suffix not in ['.pyc','.log']]
files=sorted(set(files));checks={name:hashlib.sha256((root/name).read_bytes()).hexdigest() for name in files}
dist=root/'.dist';dist.mkdir(exist_ok=True);out=dist/f'vesper-eye-{version}.tar.gz'
buffer=io.BytesIO()
with tarfile.open(fileobj=buffer,mode='w') as archive:
 for name in files:
  data=(root/name).read_bytes();info=tarfile.TarInfo('vesperEye/'+name);info.size=len(data);info.mode=0o755 if name.startswith('scripts/') else 0o644;info.mtime=0;archive.addfile(info,io.BytesIO(data))
 data=(json.dumps(checks,indent=2)+'\n').encode();info=tarfile.TarInfo('vesperEye/SHA256SUMS.json');info.size=len(data);info.mode=0o644;info.mtime=0;archive.addfile(info,io.BytesIO(data))
out.write_bytes(gzip.compress(buffer.getvalue(),mtime=0))
(dist/(out.name+'.sha256')).write_text(hashlib.sha256(out.read_bytes()).hexdigest()+'  '+out.name+'\n')
with tarfile.open(out) as archive:
 for name,digest in checks.items():assert hashlib.sha256(archive.extractfile('vesperEye/'+name).read()).hexdigest()==digest
print(f'{out.name}: {len(files)} files, {out.stat().st_size} bytes; checksums verified')
