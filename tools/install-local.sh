#!/usr/bin/env bash
# Поставить текущее состояние репозитория как плагин оболочки и перезапустить её.
#   tools/install-local.sh            собрать каталог версии, переключить ссылку, перезапустить оболочку
#   tools/install-local.sh --no-restart
# Прежние версии остаются рядом: откат — вернуть ссылку ~/.config/dms/plugins/vesperEye.
set -euo pipefail
here=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
ver=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "$here/plugin.json")
dest="$HOME/.local/share/vesper-desktop/releases/vesper-eye-$ver"
mkdir -p "$dest/shaders"
cp -a "$here/plugin.json" "$here/VesperEye.qml" "$here/Settings.qml" "$here/Pult.qml" "$here/LICENSE" "$dest/"
rm -rf "${dest:?}/core" "${dest:?}/skins"; cp -a "$here/core" "$here/skins" "$dest/"
rm -f "$dest"/shaders/*.qsb; cp -a "$here"/shaders/*.frag.qsb "$dest/shaders/"
ln -sfn "$dest" "$HOME/.config/dms/plugins/vesperEye"
echo "установлено: $dest"
[ "${1:-}" = "--no-restart" ] && exit 0
pkill -x dms || true; sleep 1.5; pkill -x qs 2>/dev/null || true; sleep 1
hyprctl dispatch 'hl.dsp.exec_cmd("/usr/bin/dms run -d")' >/dev/null
for _ in $(seq 1 20); do pgrep -x qs >/dev/null && break; sleep 1; done
sleep 6
log=$(ls -t /run/user/"$(id -u)"/quickshell/by-id/*/log.qslog 2>/dev/null | head -1)
timeout 8 qs log "$log" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -iE 'VesperEye|vesperEye|Pult|TypeError|ReferenceError|is not a type|Cannot assign|Unable to assign|failed to load| ERROR ' | grep -v 'portal' | cut -c1-220 | tail -12
