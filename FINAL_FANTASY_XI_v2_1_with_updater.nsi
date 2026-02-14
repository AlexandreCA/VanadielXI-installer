;NSIS Modern User Interface
;Written by Fox_Mulder
;ZLIB License Copyright (c) 2023-2026 Vanadiel_XI Server
;Modified to include VanadielXI Auto-Updater

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
  !include "LogicLib.nsh"
  !include "FileFunc.nsh"
  !include "StrContains.nsh"
  !include "nsDialogs.nsh"

  !define MUI_ICON "installer.ico"
  !define MUI_LANGDLL_WINDOWTITLE "Installer"
  !define MUI_WELCOMEFINISHPAGE_BITMAP "background.bmp"
  !define MUI_WELCOMEPAGE_TITLE "Installer"

  !define MUI_LICENSEPAGE_CHECKBOX

  !addplugindir "..\Release"
  !addplugindir "."

;--------------------------------
;General

  ;Name and file
  Name "FINAL FANTASY XI "
  OutFile "FINAL FANTASY XI.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\PlayOnline"

  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\FINAL FANTASY XI" "InstallPath"

  ;Request application privileges for Windows Vista
  RequestExecutionLevel admin

;--------------------------------
;Installer Initialization

Function .onInit
  ; Vérifier si une installation existe déjà et utiliser son chemin
  ReadRegStr $0 HKCU "Software\FINAL FANTASY XI" "InstallPath"
  
  ; Si trouvé dans le registre, vérifier que le jeu existe vraiment
  ${If} $0 != ""
    IfFileExists "$0\Windower4\windower.exe" 0 check_default
      StrCpy $INSTDIR $0
      Goto init_done
  ${EndIf}
  
  check_default:
  ; Vérifier le chemin par défaut
  IfFileExists "$PROGRAMFILES\PlayOnline\Windower4\windower.exe" 0 init_done
    StrCpy $INSTDIR "$PROGRAMFILES\PlayOnline"
  
  init_done:
FunctionEnd

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Variables globales
Var /GLOBAL InstallType
Var /GLOBAL ExistingInstallDetected
Var /GLOBAL InstallHDPack

;--------------------------------
;Pages Functions

Function CheckExistingInstall
  ; Vérifier si une installation existe déjà
  StrCpy $ExistingInstallDetected "no"
  
  ; Vérifier si Windower4 existe
  IfFileExists "$INSTDIR\Windower4\windower.exe" existing_found no_existing_install
  
  existing_found:
    StrCpy $ExistingInstallDetected "yes"
    
    MessageBox MB_YESNO|MB_ICONEXCLAMATION \
      "═══════════════════════════════════════$\n\
      INSTALLATION EXISTANTE DÉTECTÉE$\n\
      ═══════════════════════════════════════$\n$\n\
      Emplacement : $INSTDIR$\n$\n\
      ► MISE À JOUR (OUI) - Recommandé$\n\
      • Conserve tous vos fichiers du jeu$\n\
      • Met à jour uniquement l'Auto-Updater$\n\
      • Installation rapide (quelques secondes)$\n$\n\
      ► RÉINSTALLATION (NON)$\n\
      • Réinstalle TOUT le jeu$\n\
      • Écrase tous les fichiers existants$\n\
      • Installation longue (plusieurs minutes)$\n$\n\
      Voulez-vous faire une MISE À JOUR uniquement ?" \
      IDYES update_only
    
    ; Réinstallation complète
    StrCpy $InstallType "full"
    Goto check_done
    
  update_only:
    StrCpy $InstallType "update"
    Goto check_done
    
  no_existing_install:
    StrCpy $InstallType "full"
    
  check_done:
FunctionEnd

Function HDPackPage
  ; Créer une page personnalisée pour demander si on installe le pack HD
  
  nsDialogs::Create 1018
  Pop $0
  
  ${If} $0 == error
    Abort
  ${EndIf}
  
  ; Titre
  ${NSD_CreateLabel} 0 0 100% 20u "Installation du Pack HD (Optionnel)"
  Pop $0
  
  ; Description
  ${NSD_CreateLabel} 0 25u 100% 40u "Le Pack HD améliore considérablement la qualité graphique du jeu avec des textures haute résolution.$\n$\nTaille : environ 2-3 GB supplémentaires.$\n$\nVoulez-vous installer le Pack HD ?"
  Pop $0
  
  ; Case à cocher
  ${NSD_CreateCheckbox} 10u 70u 100% 12u "Installer le Pack HD (recommandé)"
  Pop $InstallHDPack
  
  ; Cocher par défaut
  ${NSD_Check} $InstallHDPack
  
  ; Note en bas
  ${NSD_CreateLabel} 10u 90u 100% 20u "Note : Vous pouvez toujours installer le Pack HD plus tard en relançant l'installateur."
  Pop $0
  
  nsDialogs::Show
FunctionEnd

Function DependenciesPage
  ; Vérification des dépendances avant installation

  Var /GLOBAL VC2010Installed
  Var /GLOBAL VC2012Installed
  Var /GLOBAL VC2013Installed
  Var /GLOBAL VC2015Installed
  Var /GLOBAL DotNet40Installed
  Var /GLOBAL DotNet45Installed
  Var /GLOBAL DirectPlayInstalled

  ; --- Vérification des Visual C++ Redistributables ---
  ReadRegDWORD $VC2010Installed HKLM "SOFTWARE\Microsoft\VisualStudio\10.0\VC\VCRedist\x86" "Installed"
  ${If} $VC2010Installed != 1
    DetailPrint "Visual C++ 2010 Redistributable not found, installing..."
    File /oname=$TEMP\VS2010.exe VS2010.exe
    ExecWait "$TEMP\VS2010.exe /install /passive /norestart"
    Delete "$TEMP\VS2010.exe"
  ${Else}
    DetailPrint "Visual C++ 2010 Redistributable already installed."
  ${EndIf}

  ReadRegDWORD $VC2012Installed HKLM "SOFTWARE\Microsoft\VisualStudio\11.0\VC\Runtimes\x86" "Installed"
  ${If} $VC2012Installed != 1
    DetailPrint "Visual C++ 2012 Redistributable not found, installing..."
    File /oname=$TEMP\VS2012.exe VS2012.exe
    ExecWait "$TEMP\VS2012.exe /install /passive /norestart"
    Delete "$TEMP\VS2012.exe"
  ${Else}
    DetailPrint "Visual C++ 2012 Redistributable already installed."
  ${EndIf}

  ReadRegDWORD $VC2013Installed HKLM "SOFTWARE\Microsoft\VisualStudio\12.0\VC\Runtimes\x86" "Installed"
  ${If} $VC2013Installed != 1
    DetailPrint "Visual C++ 2013 Redistributable not found, installing..."
    File /oname=$TEMP\VS2013.exe VS2013.exe
    ExecWait "$TEMP\VS2013.exe /install /passive /norestart"
    Delete "$TEMP\VS2013.exe"
  ${Else}
    DetailPrint "Visual C++ 2013 Redistributable already installed."
  ${EndIf}

  ReadRegDWORD $VC2015Installed HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" "Installed"
  ${If} $VC2015Installed != 1
    DetailPrint "Visual C++ 2015-2017 Redistributable not found, installing..."
    File /oname=$TEMP\VS2015.exe VS2015.exe
    ExecWait "$TEMP\VS2015.exe /install /passive /norestart"
    Delete "$TEMP\VS2015.exe"
  ${Else}
    DetailPrint "Visual C++ 2015-2017 Redistributable already installed."
  ${EndIf}

  ; --- Vérification de .NET Framework ---
  ReadRegDWORD $DotNet40Installed HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Install"
  ${If} $DotNet40Installed != 1
    DetailPrint ".NET Framework 4.0 not found, installing..."
    File /oname=$TEMP\dotNetFx40_Full_x86_x64.exe dotNetFx40_Full_x86_x64.exe
    ExecWait "$TEMP\dotNetFx40_Full_x86_x64.exe /install /passive /norestart"
    Delete "$TEMP\dotNetFx40_Full_x86_x64.exe"
  ${Else}
    DetailPrint ".NET Framework 4.0 already installed."
  ${EndIf}

  ReadRegDWORD $DotNet45Installed HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Release"
  ${If} $DotNet45Installed < 378389
    DetailPrint ".NET Framework 4.5 or higher not found, installing..."
    File /oname=$TEMP\dotNet45.exe dotNet45.exe
    ExecWait "$TEMP\dotNet45.exe /install /passive /norestart"
    Delete "$TEMP\dotNet45.exe"
  ${Else}
    DetailPrint ".NET Framework 4.5 or higher already installed."
  ${EndIf}

  ; --- Vérification de DirectPlay ---
  ReadRegDWORD $DirectPlayInstalled HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackageIndex" "Microsoft-Windows-DirectPlay-Package~31bf3856ad364e35~x86~~10.0.0.0"
  ${If} $DirectPlayInstalled != 1
    DetailPrint "DirectPlay not found, enabling..."
    nsExec::Exec "dism /online /Enable-Feature /FeatureName:DirectPlay /All /Quiet /NoRestart"
  ${Else}
    DetailPrint "DirectPlay already enabled."
  ${EndIf}

FunctionEnd

SetCompress off

Function DependenciesLeave
FunctionEnd

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "license.txt"
  Page Custom DependenciesPage DependenciesLeave
  !insertmacro MUI_PAGE_DIRECTORY
  Page Custom CheckExistingInstall
  Page Custom HDPackPage
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages

  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
;Installer Sections

Section "XIInstaller" XIInstaller
  AddSize 14000000
  SetOutPath "$INSTDIR"

  Var /GLOBAL IsUpdate
  IfFileExists "$INSTDIR\Windower4\windower.exe" 0 not_update
    StrCpy $IsUpdate "yes"
    Goto update_check_done
  not_update:
    StrCpy $IsUpdate "no"
  update_check_done:

  File installer.ico

  ; Si c'est une mise à jour uniquement, sauter l'extraction
  ${If} $InstallType == "update"
    DetailPrint "Mode mise à jour: conservation des fichiers existants..."
    ; Définir quand même $R0 pour le HD Pack
    ${GetExePath} $R0
    Goto skip_extraction
  ${EndIf}

  DetailPrint "Extracting game files, please wait..."
  ${GetExePath} $R0
  Nsis7z::ExtractWithDetails "$R0\data.pak" "Installing game files %s..."

  skip_extraction:

  ; Installation automatique du HD Pack si disponible
  DetailPrint "Checking for HD Pack..."
  ${GetExePath} $R0
  DetailPrint "DEBUG: Exe path = $R0"
  
  ; Toujours essayer d'installer le HD Pack s'il est embarqué
  DetailPrint "Attempting to install HD Pack..."
  Nsis7z::ExtractWithDetails "$R0\hd_pack.pak" "Installing HD textures %s..."
  Pop $1
  DetailPrint "Nsis7z returned: [$1]"
  
  ${If} $1 == "success"
    DetailPrint "✓ HD Pack installed successfully!"
  ${ElseIf} $1 == "0"
    DetailPrint "✓ HD Pack installed successfully! (code 0)"
  ${Else}
    DetailPrint "HD Pack not available or extraction failed (code: $1)"
  ${EndIf}

  DetailPrint "Updating registry settings..."
  
  SetRegView 64

  WriteRegStr HKCU "Software\FINAL FANTASY XI" "InstallPath" "$INSTDIR"

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "DisplayName" "Uninstall FINAL FANTASY XI"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "InstallLocation" "$\"$INSTDIR$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "DisplayIcon" "$\"$INSTDIR\installer.ico$\""

  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS" "CommonFilesFolder" "$PROGRAMFILES\Common Files\"
  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder" "0001" "$INSTDIR\SquareEnix\FINAL FANTASY XI\"
  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder" "1000" "$INSTDIR\SquareEnix\PlayOnlineViewer"

  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Interface" "0001" "130b5023"
  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Interface" "1000" "1304d1e8"

  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Setting" "0001" "$INSTDIR\SquareEnix\FINAL FANTASY XI\User\"
  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Setting" "1000" "$INSTDIR\SquareEnix\PlayOnlineViewer\"

  ${If} $IsUpdate == "yes"
    DetailPrint "Existing Windower4 installation found, updating configuration..."
    IfFileExists "$INSTDIR\Windower4\settings.xml" 0 config_missing
      FileOpen $0 "$INSTDIR\Windower4\settings.xml" r
      StrCpy $1 ""
      StrCpy $2 ""
read_loop:
      FileRead $0 $2
      ${If} ${Errors}
        Goto read_done
      ${EndIf}
      Push "$2"
      Push "<executable>"
      Call StrContains
      Pop $3
      ${If} $3 != ""
        StrLen $4 "<executable>"
        StrCpy $1 $2 "" $4
        Push "$1"
        Push "</executable>"
        Call StrContains
        Pop $5
        ${If} $5 != ""
          StrCpy $1 $5
        ${EndIf}
        Goto read_done
      ${EndIf}
      Goto read_loop
read_done:
      FileClose $0
      StrCpy $3 "$INSTDIR\..\Windower4\xiloader.exe"
      ${If} $1 != $3
        DetailPrint "Windower4 configuration incorrect, updating..."
        Goto write_config
      ${Else}
        DetailPrint "Windower4 configuration is correct."
        Goto config_done
      ${EndIf}
    config_missing:
      DetailPrint "Windower4 configuration file missing, creating it..."
      Goto write_config
  ${Else}
    DetailPrint "New installation, creating Windower4 configuration..."
    Goto write_config
  ${EndIf}

write_config:
  IfFileExists "$INSTDIR\Windower4\xiloader.exe" 0 no_xiloader
    DetailPrint "Creating settings.xml in $INSTDIR\Windower4"
    FileOpen $0 "$INSTDIR\Windower4\settings.xml" w
    ${If} ${Errors}
      DetailPrint "Error: Failed to open settings.xml for writing."
      Goto no_xiloader
    ${EndIf}
    FileWriteByte $0 0xEF
    FileWriteByte $0 0xBB
    FileWriteByte $0 0xBF
    FileWrite $0 `<?xml version="1.0" encoding="utf-8"?>$\r$\n`
    FileWrite $0 `<settings>$\r$\n`
    FileWrite $0 `  <launcher>$\r$\n`
    FileWrite $0 `    <branch>stable</branch>$\r$\n`
    FileWrite $0 `  </launcher>$\r$\n`
    FileWrite $0 `  <autoload>$\r$\n`
    FileWrite $0 `    <addon>ChatLink</addon>$\r$\n`
    FileWrite $0 `    <addon>chatPorter</addon>$\r$\n`
    FileWrite $0 `    <addon>xivbar</addon>$\r$\n`
    FileWrite $0 `    <addon>Trusts</addon>$\r$\n`
    FileWrite $0 `    <addon>lottery</addon>$\r$\n`
    FileWrite $0 `    <addon>itemizer</addon>$\r$\n`
    FileWrite $0 `    <addon>invtracker</addon>$\r$\n`
    FileWrite $0 `    <addon>giltracker</addon>$\r$\n`
    FileWrite $0 `    <addon>EasyNuke</addon>$\r$\n`
    FileWrite $0 `    <addon>Debuffed</addon>$\r$\n`
    FileWrite $0 `    <addon>AutoRA</addon>$\r$\n`
    FileWrite $0 `    <addon>barfiller</addon>$\r$\n`
    FileWrite $0 `    <plugin>FFXIDB</plugin>$\r$\n`
    FileWrite $0 `    <plugin>MipmapFix</plugin>$\r$\n`
    FileWrite $0 `    <plugin>Timers</plugin>$\r$\n`
    FileWrite $0 `    <plugin>Binder</plugin>$\r$\n`
    FileWrite $0 `  </autoload>$\r$\n`
    FileWrite $0 `  <profile name="VanadielXI">$\r$\n`
    FileWrite $0 `    <consolekey>Insert</consolekey>$\r$\n`
    FileWrite $0 `    <mipmaplevel>6</mipmaplevel>$\r$\n`
    FileWrite $0 `    <uiscale>1</uiscale>$\r$\n`
    FileWrite $0 `    <alwaysenablegamepad>false</alwaysenablegamepad>$\r$\n`
    FileWrite $0 `    <args>--server 192.168.1.15 --user alexandre --pass alexandre --hairpin</args>$\r$\n`
    FileWrite $0 `    <executable>xiloader.exe</executable>$\r$\n`
    FileWrite $0 `  </profile>$\r$\n`
    FileWrite $0 `</settings>$\r$\n`
    FileClose $0
    ${If} ${Errors}
      DetailPrint "Error: Failed to write settings.xml."
    ${Else}
      DetailPrint "Successfully created settings.xml."
      ExecWait 'icacls "$INSTDIR\Windower4\settings.xml" /grant Users:F'
      DetailPrint "Set permissions on settings.xml."
    ${EndIf}
    Goto config_done
  no_xiloader:
    DetailPrint "Error: xiloader.exe not found. Skipping settings.xml creation."
  config_done:
  
  ; Si c'est une mise à jour uniquement, sauter l'enregistrement des DLLs
  ${If} $InstallType == "update"
    DetailPrint "Mode mise à jour: DLLs déjà enregistrées, skip..."
    Goto skip_dll_registration
  ${EndIf}
  
  DetailPrint "Registering libraries..."
  RegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXi.dll"
  RegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiMain.dll"
  RegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiResource.dll"
  RegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiVersions.dll"

  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\polhook.dll"
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\unicows.dll"
  
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\patchfiles\PlayOnlineViewer\viewer\com\app.dll"
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\patchfiles\PlayOnlineViewer\viewer\com\polcore.dll"
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\polcfg\sysinfo.dll"
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\util\unicows.dll"

  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\MSVCR71.dll"
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\polmvf.dll"
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\polmvfINT.dll"

  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\com\app.dll"
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\com\polcore.dll"
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\contents\PolContents.dll"
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\contents\polcontentsINT.dll"

  skip_dll_registration:

  DetailPrint "Creating Uninstaller..."
  WriteUninstaller "$INSTDIR\Uninstall FINAL FANTASY XI.exe"

  DetailPrint "Building Shortcuts..."
  SetOutPath "$INSTDIR\Windower4\"
  CreateShortCut "$DESKTOP\Play FINAL FANTASY XI.lnk" "$INSTDIR\Windower4\windower.exe" "" "$INSTDIR\installer.ico"

  createDirectory "$SMPROGRAMS\FINAL FANTASY XI"
  createShortCut "$SMPROGRAMS\FINAL FANTASY XI\Play FINAL FANTASY XI.lnk" "$INSTDIR\Windower4\windower.exe" "" "$INSTDIR\installer.ico"
  createShortCut "$SMPROGRAMS\FINAL FANTASY XI\VanadielXI Auto-Updater.lnk" "$INSTDIR\VanadielXI_Updater.exe" "" "$INSTDIR\installer.ico"
  createShortCut "$SMPROGRAMS\FINAL FANTASY XI\Uninstall FINAL FANTASY XI.lnk" "$INSTDIR\Uninstall FINAL FANTASY XI.exe"

  DetailPrint "Installing VanadielXI Auto-Updater..."
  SetOutPath "$INSTDIR"
  File "VanadielXI_Updater.exe"
  
  ; Configurer l'updater pour toujours s'exécuter en administrateur
  WriteRegStr HKLM "Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" "$INSTDIR\VanadielXI_Updater.exe" "RUNASADMIN"
  
  ; Créer le fichier de version initial
  FileOpen $0 "$INSTDIR\version.txt" w
  FileWrite $0 "1.0.0"
  FileClose $0
  
  ; Ajouter au démarrage automatique
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "VanadielXI_Updater" "$\"$INSTDIR\VanadielXI_Updater.exe$\""
  
  ; Démarrer l'updater en tant qu'administrateur
  ExecShell "" "$INSTDIR\VanadielXI_Updater.exe" "" SW_SHOWNORMAL
  
  DetailPrint "Auto-Updater installed and started"

SectionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"
  SetOutPath "$INSTDIR"

  ; Arrêter et supprimer l'auto-updater
  DetailPrint "Stopping VanadielXI Auto-Updater..."
  nsExec::Exec 'taskkill /F /IM VanadielXI_Updater.exe'
  Sleep 1000
  Delete "$INSTDIR\VanadielXI_Updater.exe"
  Delete "$INSTDIR\version.txt"
  Delete "$INSTDIR\installer.ico"
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "VanadielXI_Updater"
  DeleteRegValue HKLM "Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" "$INSTDIR\VanadielXI_Updater.exe"

  ; Supprimer les raccourcis
  DetailPrint "Removing shortcuts..."
  Delete "$DESKTOP\Play FINAL FANTASY XI.lnk"
  Delete "$SMPROGRAMS\FINAL FANTASY XI\Play FINAL FANTASY XI.lnk"
  Delete "$SMPROGRAMS\FINAL FANTASY XI\VanadielXI Auto-Updater.lnk"
  Delete "$SMPROGRAMS\FINAL FANTASY XI\Uninstall FINAL FANTASY XI.lnk"
  RMDir "$SMPROGRAMS\FINAL FANTASY XI"

  ; Désenregistrer les DLLs
  DetailPrint "Unregistering DLLs..."
  UnRegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXi.dll"
  UnRegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiMain.dll"
  UnRegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiResource.dll"
  UnRegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiVersions.dll"

  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\polhook.dll"
  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\unicows.dll"
  
  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\patchfiles\PlayOnlineViewer\viewer\com\app.dll"
  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\patchfiles\PlayOnlineViewer\viewer\com\polcore.dll"
  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\polcfg\sysinfo.dll"
  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\util\unicows.dll"

  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\MSVCR71.dll"
  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\polmvf.dll"
  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\polmvfINT.dll"

  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\com\app.dll"
  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\com\polcore.dll"
  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\contents\PolContents.dll"
  UnRegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\contents\polcontentsINT.dll"

  ; Supprimer les fichiers et dossiers
  DetailPrint "Removing game files..."
  Delete "$INSTDIR\Windower4\settings.xml"
  RMDir /r "$INSTDIR\Windower4"
  RMDir /r "$INSTDIR\SquareEnix"
  RMDir /r "$INSTDIR"

  ; Nettoyer le registre
  DetailPrint "Cleaning registry..."
  DeleteRegKey /ifempty HKCU "Software\FINAL FANTASY XI"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI"
  DeleteRegKey HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS"

  DetailPrint "Uninstallation complete!"

SectionEnd
