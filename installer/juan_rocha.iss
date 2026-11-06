; Instalador de Juan Rocha Boxe - compilado a partir do Flutter Windows Release.
; O GitHub Actions cria o Windows Release e executa o Inno Setup.
#define AppName "Juan Rocha Boxe"
#define AppVersion "1.0.0"
#define AppExe "juan_rocha_boxe.exe"

[Setup]
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

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Juan Rocha Boxe"; Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"
Name: "{autodesktop}\Juan Rocha Boxe"; Filename: "{app}\{#AppExe}"; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"

[Run]
Filename: "{app}\{#AppExe}"; Description: "Abrir Juan Rocha Boxe"; Flags: nowait postinstall skipifsilent
