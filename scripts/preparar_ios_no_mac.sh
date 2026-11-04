#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo 'ERRO: A compilação para iOS exige macOS + Xcode. Rode no Mac ou em um serviço macOS.'
  exit 1
fi
command -v flutter >/dev/null || { echo 'Instale o Flutter SDK no Mac.'; exit 1; }
command -v xcodebuild >/dev/null || { echo 'Instale o Xcode pela App Store.'; exit 1; }

cd "$(dirname "$0")/.."
echo 'Criando o projeto nativo iOS a partir das fontes Flutter...'
flutter create --platforms=ios --org br.juanrochaboxe --project-name juan_rocha_boxe .
flutter pub get
flutter pub run flutter_launcher_icons

echo ''
echo 'Validação estática:'
flutter analyze

echo ''
echo 'Testes Dart:'
flutter test

echo ''
echo 'Pronto para abrir o projeto em ios/Runner.xcworkspace no Xcode.'
echo 'Configure o Signing & Capabilities com a equipe Apple do proprietário.'
echo 'Depois execute flutter build ipa --release, para uma distribuição assinada.'
