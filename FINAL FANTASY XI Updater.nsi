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

;;--------------------------------
;Set default installation directory
; Vérifie si le répertoire d'installation est dans le registre
InstallDirRegKey HKCU "Software\FINAL FANTASY XI" "InstallPath"

; Si l'entrée de registre n'existe pas, on définit un répertoire par défaut
; Le répertoire par défaut est PlayOnline/SquareEnix/FINAL FANTASY XI
InstallDir "$PROGRAMFILES\PlayOnline\SquareEnix\FINAL FANTASY XI"

;--------------------------------
;Pages
!insertmacro MUI_PAGE_DIRECTORY  
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

;--------------------------------
;Languages
!insertmacro MUI_LANGUAGE "French"

;--------------------------------
;Installer Sections
Section "Update" Update
  ; URL du fichier zip de mise à jour sur GitHub
  StrCpy $0 "https://github.com/AlexandreCA/Traduction-francaise-du-client-FFXI/releases/download/update/generated_dats.zip"

  ; Fichier temporaire pour stocker le fichier zip téléchargé
  StrCpy $1 "$TEMP\generated_dats.zip"

  ; Téléchargez le fichier zip
  nsExec::ExecToLog "powershell -Command (New-Object System.Net.WebClient).DownloadFile('$0', '$1')"

  ; Décompressez le fichier zip
  nsExec::ExecToLog 'powershell -Command "Expand-Archive -Path $1 -DestinationPath $INSTDIR -Force"'

  ; Message de confirmation
  MessageBox MB_OK "Mise à jour terminée."
SectionEnd