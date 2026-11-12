; Instalador de ATUALIZACAO Juan Rocha Boxe v1.1.
; Executar apenas no computador Windows do usuario que ja possui o app.
; O backup do banco e da versao anterior e obrigatorio antes de alterar arquivos.
#define AppName "Juan Rocha Boxe"
#define AppVersion "1.1.0"
#define AppExe "juan_rocha_boxe.exe"

[Setup]
; NAO ALTERAR: mesmo AppId usado no instalador original v1.0.
AppId={{B9D28B17-C603-40AF-87E6-C5F4065B53B6}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Juan Rocha Boxe
DefaultDirName={localappdata}\Programs\Juan Rocha Boxe
DefaultGroupName=Juan Rocha Boxe
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=Juan_Rocha_Boxe_Setup
SetupIconFile=..\assets\brand\app_icon_windows.ico
UninstallDisplayIcon={app}\{#AppExe}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes
RestartApplications=no
UsePreviousAppDir=yes
Uninstallable=yes

[Files]
; IMPORTANTE: o pacote de distribuicao NAO inclui arquivos *.sqlite ou *.db.
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Arquivo embutido dentro do Setup.exe e executado antes da substituicao.
Source: "..\scripts\backup_windows_preinstall.ps1"; Flags: dontcopy

[Icons]
Name: "{autoprograms}\Juan Rocha Boxe"; Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"
Name: "{autodesktop}\Juan Rocha Boxe"; Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"

[Run]
Filename: "{app}\{#AppExe}"; Description: "Abrir Juan Rocha Boxe"; Flags: nowait postinstall skipifsilent

[Code]
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ExitCode: Integer;
  CommandLine: String;
  PowerShellPath: String;
begin
  Result := '';
  ExtractTemporaryFile('backup_windows_preinstall.ps1');
  PowerShellPath := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
  CommandLine := '-NoProfile -NonInteractive -ExecutionPolicy RemoteSigned -File "' +
    ExpandConstant('{tmp}\backup_windows_preinstall.ps1') +
    '" -InstallDir "' + WizardDirValue + '"';

  if not Exec(PowerShellPath, CommandLine, '', SW_HIDE,
      ewWaitUntilTerminated, ExitCode) then
  begin
    Result := 'Nao foi possivel executar a verificacao de seguranca. ' +
      'Nenhum arquivo do programa foi atualizado.';
    Exit;
  end;

  case ExitCode of
    0:
      Log('Backup verificado. A atualizacao pode prosseguir.');
    20:
      Result := 'O Juan Rocha Boxe ainda esta aberto. Feche o aplicativo ' +
        'normalmente e tente novamente. Nenhum arquivo foi atualizado.';
    21:
      Result := 'A versao anterior do programa nao foi encontrada na pasta ' +
        'selecionada. Para proteger os dados, a atualizacao foi cancelada.';
    22:
      Result := 'Nao foi possivel identificar com seguranca um unico banco ' +
        'de dados existente. A atualizacao foi cancelada para preservar ' +
        'os alunos. Procure o suporte.';
    23:
      Result := 'A pasta Documentos nao esta acessivel para salvar o ' +
        'backup. Nenhum arquivo foi atualizado.';
    else
      Result := 'Falha ao verificar ou copiar os dados. A atualizacao ' +
        'foi cancelada. Consulte o registro JuanRochaBoxe_Atualizacao.log ' +
        'na pasta temporaria do Windows.';
  end;
end;
