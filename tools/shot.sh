#!/usr/bin/env bash
# Кадр доски в браузере без экрана (нужен chromium и Python с Pillow).
#   tools/shot.sh <выход.png> <ширина> <высота> '<строка запроса>' [доска.html]
# Пример: tools/shot.sh /tmp/a.png 950 450 'solo=pearl&variant=dark&gx=0.5&gy=0&lt=0.1&bg=000000'
# Параметры режима solo: gx gy (взгляд, от -1 до 1), px py (запаздывающий взгляд), lt lb (веки, 0..1),
# pupil, wake, pulse, pdx pdy, dim, energy, time, variant (dark|light), bg (цвет фона без #).
set -uo pipefail
here=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
out="$1"; w="$2"; h="$3"; qs="$4"; board="${5:-$here/design/board/index.html}"
url="file://$(python3 -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))' "$board")?$qs"
log="${out%.png}.log"
# Браузер отнимает от окна 87 px под рамку и растягивает снимок обратно: берём окно выше и сжимаем снимок.
timeout 90 chromium --headless=new --no-sandbox --hide-scrollbars --window-size="$w,$((h + 87))" \
  --use-angle=swiftshader --enable-unsafe-swiftshader --enable-logging=stderr --v=0 \
  --screenshot="$out" --virtual-time-budget=2500 "$url" >/dev/null 2>"$log"
grep -E 'SHADER-ERROR|Uncaught' "$log" | cut -c1-400 | head -12
python3 - "$out" "$w" "$h" <<'PY'
import sys
from PIL import Image
p, w, h = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
im = Image.open(p)
if im.size != (w, h):
    im.resize((w, h), Image.LANCZOS).save(p)
PY
rm -f "$log"
