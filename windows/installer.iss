; Inno Setup script for the CAD Cleaner Windows release.
; Packs the whole Flutter bundle into a single downloadable CadService-Setup.exe.
; Version is injected by CI: ISCC.exe /DAppVersion=1.2.3 windows\installer.iss

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{8F2B6C41-3D7E-4A19-9B54-1E0C7A5D2F63}
AppName=CAD Cleaner
AppVersion={#AppVersion}
AppPublisher=markfili
DefaultDirName={autopf}\CAD Cleaner
DefaultGroupName=CAD Cleaner
DisableProgramGroupPage=yes
OutputDir=..\dist
OutputBaseFilename=CadService-Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; The wizard removes program files and registry keys, so it needs elevation.
PrivilegesRequired=admin
UninstallDisplayName=CAD Cleaner

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\CAD Cleaner"; Filename: "{app}\CadService.exe"
Name: "{commondesktop}\CAD Cleaner"; Filename: "{app}\CadService.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"

[Run]
Filename: "{app}\CadService.exe"; Description: "Launch CAD Cleaner"; Flags: nowait postinstall skipifsilent
