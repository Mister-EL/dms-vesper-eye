#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
qsb_bin=${QSB:-/usr/lib/qt6/bin/qsb}
[[ -x $qsb_bin ]] || { echo 'Set QSB to the Qt 6 qsb executable.' >&2; exit 1; }
# SPIR-V alone is not enough for the default OpenGL Quickshell renderer.
"$qsb_bin" --glsl '100 es,300 es,150,330' --hlsl 50 --msl 12 -o "$repo_dir/shaders/eye.frag.qsb" "$repo_dir/shaders/eye.frag"
