; Installer de mise à jour indépendant pour FINAL FANTASY XI

;--------------------------------
;Include Modern UI
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"

;--------------------------------
;General
Name "FINAL FANTASY XI Updater"
OutFile "FFXI_Updater.exe"
RequestExecutionLevel admin

;--------------------------------
;Interface Settings
!define MUI_ABORTWARNING

;--------------------------------
;Pages
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

;--------------------------------
;Languages
!insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections
Section "Update" Update
  ; URL du fichier zip de mise à jour sur GitHub
  StrCpy $0 "https://github.com/AlexandreCA/Traduction-francaise-du-client-FFXI/releases/download/latest/update.zip"

  ; Fichier temporaire pour stocker le fichier zip téléchargé
  StrCpy $1 "$TEMP\update.zip"

  ; Téléchargez le fichier zip
  nsExec::ExecToLog "powershell -Command (New-Object System.Net.WebClient).DownloadFile('$0', '$1')"

  ; Décompressez le fichier zip
  nsExec::ExecToLog 'powershell -Command "Expand-Archive -Path $1 -DestinationPath $INSTDIR -Force"'

  ; Message de confirmation
  MessageBox MB_OK "Mise à jour terminée."
SectionEnd