$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter não está no PATH. Instale Flutter e Visual Studio com Desktop development with C++."
}
flutter config --enable-windows-desktop
if ($LASTEXITCODE -ne 0) { throw "Falha ao habilitar Windows desktop" }
flutter create --platforms=windows,linux --project-name juan_rocha_boxe .
if ($LASTEXITCODE -ne 0) { throw "Falha ao gerar projeto Windows" }
if (Test-Path "assets/brand/app_icon_windows.ico") {
    Copy-Item "assets/brand/app_icon_windows.ico" "windows/runner/resources/app_icon.ico" -Force
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "Falha ao baixar dependências" }
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw "Falha no build Windows" }
Write-Host "Versão Windows em: $((Get-Location).Path)\build\windows\x64\runner\Release"
Write-Host "Copie a pasta Release inteira; não apenas o executável."
