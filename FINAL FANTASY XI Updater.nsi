; Installer de mise à jour indépendant pour FINAL FANTASY XI

; Include Modern UI
!include "MUI2.nsh"

Name "FINAL FANTASY XI Updater"
OutFile "FFXI_Updater.exe"
!define MUI_ABORTWARNING

; Set default installation directory
InstallDirRegKey HKCU "Software\FINAL FANTASY XI" "InstallPath"
InstallDir "$PROGRAMFILES\PlayOnline\SquareEnix\FINAL FANTASY XI"

; Pages
!insertmacro MUI_PAGE_DIRECTORY  
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Languages
!insertmacro MUI_LANGUAGE "French"

; Installer Sections
Section "Update" Update
  ; URL du fichier zip de mise à jour sur GitHub (pour un repo privé, vous devez utiliser l'API)
  StrCpy $0 "https://api.github.com/repos/AlexandreCA/Traduction-francaise-du-client-FFXI/releases/assets/ID_DE_L'ASSET"

  ; Fichier temporaire pour stocker le fichier zip téléchargé
  StrCpy $1 "$TEMP\generated_dats.zip"

  ; Token d'accès personnel pour GitHub
  StrCpy $2 "votre_token_personnel_ici" ; Remplacez par votre token d'accès personnel

  ; Téléchargez le fichier zip avec curl (assurez-vous que curl est installé)
  nsExec::ExecToLog 'curl -u ":$2" -L -o "$1" "$0"'
  Pop $R0 ;Get the return value
  StrCmp $R0 "0" downloadSucceeded 0
    MessageBox MB_OK "Échec du téléchargement du fichier. Code de retour : $R0"
    Goto end
  downloadSucceeded:
    MessageBox MB_OK "Téléchargement réussi."
    
    ; Vérifiez la taille du fichier téléchargé
    FileOpen $R1 "$1" r
    FileSeek $R1 0 END $R2
    FileClose $R1
    StrCmp $R2 "0" fileEmpty +1
      MessageBox MB_OK "Taille du fichier téléchargé : $R2 bytes."
      Goto unzip
    fileEmpty:
      MessageBox MB_OK "Le fichier téléchargé semble être vide."
      Goto end

  unzip:
    ; Décompressez le fichier zip avec 7z
    ExecWait '"7z.exe" x "$1" -o"$INSTDIR" -y' $R0
    StrCmp $R0 "0" unzipSucceeded 0
      MessageBox MB_OK "Échec de la décompression du fichier. Code de retour : $R0"
      Goto end
  unzipSucceeded:
    MessageBox MB_OK "Mise à jour terminée. Fichier décompressé dans $INSTDIR."

  end:
SectionEnd