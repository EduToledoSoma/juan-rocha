# Juan Rocha Boxe - validacao e backup OBRIGATORIOS antes de atualizar.
# Este script e executado automaticamente pelo instalador Inno Setup.
# Nao modifica o banco de dados original e nao encerra o aplicativo a forca.
param(
  [Parameter(Mandatory = $true)]
  [string]$InstallDir
)

$ErrorActionPreference = 'Stop'
$LogPath = Join-Path $env:TEMP 'JuanRochaBoxe_Atualizacao.log'

function Write-Log([string]$Message) {
  $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
  Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

try {
  Write-Log 'Iniciando verificacao anterior a atualizacao.'
  if (Get-Process -Name 'juan_rocha_boxe' -ErrorAction SilentlyContinue) {
    Write-Log 'BLOQUEADO: aplicativo aberto. Feche-o normalmente.'
    exit 20
  }

  $OldExe = Join-Path $InstallDir 'juan_rocha_boxe.exe'
  if (-not (Test-Path -LiteralPath $OldExe -PathType Leaf)) {
    Write-Log "BLOQUEADO: instalacao anterior nao encontrada: $OldExe"
    exit 21
  }

  # O Flutter/path_provider usa AppData Roaming + metadados do executavel
  # + JuanRochaBoxe\databases. Considera possiveis metadados antigos.
  $VersionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($OldExe)
  $Company = [string]$VersionInfo.CompanyName
  $Product = [string]$VersionInfo.ProductName
  $Roots = @($env:APPDATA, $env:LOCALAPPDATA) |
    Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) } |
    Select-Object -Unique

  $SearchBases = New-Object 'System.Collections.Generic.List[string]'
  foreach ($Root in $Roots) {
    if ($Company -and $Product) {
      $SearchBases.Add((Join-Path (Join-Path $Root $Company) $Product))
    }
    if ($Product) { $SearchBases.Add((Join-Path $Root $Product)) }
    $SearchBases.Add((Join-Path $Root 'juan_rocha_boxe'))
    $SearchBases.Add((Join-Path $Root 'JuanRochaBoxe'))
  }

  function Find-ActiveDatabases([string[]]$Directories) {
    $Results = @()
    foreach ($Dir in ($Directories | Select-Object -Unique)) {
      if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { continue }
      $Files = @(Get-ChildItem -LiteralPath $Dir -Filter 'juan_rocha_boxe.sqlite' -File -Recurse -ErrorAction SilentlyContinue)
      foreach ($File in $Files) {
        # Nunca confundir backups antigos com o banco ativo.
        if ($File.DirectoryName -match '[\\/]JuanRochaBoxe[\\/]databases$') {
          $Results += $File.FullName
        }
      }
    }
    return @($Results | Sort-Object -Unique)
  }

  $Databases = @(Find-ActiveDatabases -Directories $SearchBases.ToArray())
  if ($Databases.Count -eq 0) {
    # Fallback: o aplicativo antigo pode ter usado outros metadados.
    $Databases = @(Find-ActiveDatabases -Directories $Roots)
  }

  if ($Databases.Count -ne 1) {
    Write-Log ("BLOQUEADO: quantidade de bancos ativos encontrada = {0}" -f $Databases.Count)
    foreach ($DbFound in $Databases) { Write-Log "Candidato: $DbFound" }
    exit 22
  }

  $DbPath = $Databases[0]
  Write-Log "Banco original identificado: $DbPath"

  # Se outra aplicacao mantiver o SQLite aberto, abortar sem copiar um
  # conjunto WAL/SHM potencialmente inconsistente.
  $Stream = [System.IO.File]::Open($DbPath,
    [System.IO.FileMode]::Open,
    [System.IO.FileAccess]::Read,
    [System.IO.FileShare]::None)
  try {
    if ($Stream.Length -lt 100) { throw 'Banco SQLite com tamanho invalido.' }
    $Header = New-Object byte[] 16
    if ($Stream.Read($Header, 0, 16) -ne 16 -or
        [System.Text.Encoding]::ASCII.GetString($Header, 0, 15) -ne 'SQLite format 3') {
      throw 'Cabecalho SQLite invalido.'
    }
  } finally {
    $Stream.Dispose()
  }

  $Documents = [Environment]::GetFolderPath('MyDocuments')
  if ([string]::IsNullOrWhiteSpace($Documents) -or
      -not (Test-Path -LiteralPath $Documents -PathType Container)) {
    Write-Log 'BLOQUEADO: pasta Documentos indisponivel para o backup.'
    exit 23
  }

  $Timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss-fff'
  $BackupDir = Join-Path $Documents ("Backup Juan Rocha Boxe\Antes da atualizacao $Timestamp")
  $DbBackupDir = Join-Path $BackupDir 'BancoOriginal'
  $ProgramBackupDir = Join-Path $BackupDir 'ProgramaAnterior'
  New-Item -ItemType Directory -Path $DbBackupDir -Force | Out-Null
  New-Item -ItemType Directory -Path $ProgramBackupDir -Force | Out-Null

  # O banco principal e seus arquivos auxiliares, se existirem, sao copiados.
  foreach ($Source in @($DbPath, "${DbPath}-wal", "${DbPath}-shm")) {
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { continue }
    $Target = Join-Path $DbBackupDir (Split-Path $Source -Leaf)
    Copy-Item -LiteralPath $Source -Destination $Target -ErrorAction Stop
    if ((Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash -ne
        (Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash) {
      throw "A copia nao corresponde ao original: $Source"
    }
  }

  # Tambem preserva a versao anterior do programa, para suporte/recuperacao.
  Get-ChildItem -LiteralPath $InstallDir -Force -ErrorAction Stop | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $ProgramBackupDir -Recurse -Force -ErrorAction Stop
  }
  if (-not (Test-Path -LiteralPath (Join-Path $ProgramBackupDir 'juan_rocha_boxe.exe'))) {
    throw 'Nao foi possivel verificar a copia da versao anterior do programa.'
  }

  $Manifest = @(
    'JUAN ROCHA BOXE - BACKUP ANTES DA ATUALIZACAO',
    "Data: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Banco original (NAO SUBSTITUIR): $DbPath",
    "Programa anterior: $InstallDir",
    'Este backup e exclusivo deste usuario do Windows.',
    'Nao copie bancos de dados de outros computadores.',
    'Se os alunos sumirem apos a atualizacao, NAO crie novos registros.',
    'Contate o suporte antes de tentar restaurar.'
  )
  Set-Content -LiteralPath (Join-Path $BackupDir 'LEIA-ME.txt') -Value $Manifest -Encoding UTF8
  Write-Log "Backup confirmado: $BackupDir"
  exit 0
} catch {
  Write-Log ("FALHA: " + $_.Exception.Message)
  exit 30
}
