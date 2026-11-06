#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v flutter >/dev/null 2>&1; then
  echo 'ERRO: Flutter não instalado ou ausente no PATH.' >&2
  exit 1
fi
flutter config --enable-linux-desktop
flutter create --platforms=linux,windows --project-name juan_rocha_boxe .
flutter pub get
flutter build linux --release
printf '\nAplicativo Linux criado em: %s\n' "$(pwd)/build/linux/x64/release/bundle"
echo 'Execute: ./build/linux/x64/release/bundle/juan_rocha_boxe'
