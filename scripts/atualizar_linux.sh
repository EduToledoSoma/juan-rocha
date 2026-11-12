#!/usr/bin/env bash
# Atualizacao local sem excluir o banco SQLite do usuario.
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
if command -v pgrep >/dev/null 2>&1 && pgrep -f '[j]uan_rocha_boxe$' >/dev/null 2>&1; then
  echo 'Feche o Juan Rocha Boxe antes de atualizar.' >&2
  exit 1
fi
command -v flutter >/dev/null || { echo 'Flutter nao localizado no PATH.' >&2; exit 1; }
flutter config --enable-linux-desktop
flutter pub get
flutter build linux --release
bash scripts/instalar_no_menu_linux.sh "$ROOT"
echo 'Atualizacao concluida. Seus registros continuam na pasta de dados do usuario.'
