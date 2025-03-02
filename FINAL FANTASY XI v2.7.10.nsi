;NSIS Modern User Interface
;Written by Fox_Mulder.
;ZLIB License Copyright (c) 2024-2025 Vanadiel_XI Server

SetCompressor /FINAL lzma

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "nsDialogs.nsh"

!define MUI_ICON "installer.ico"
!define MUI_LANGDLL_WINDOWTITLE "Installer"
!define MUI_WELCOMEFINISHPAGE_BITMAP "background.bmp"
!define MUI_WELCOMEPAGE_TITLE "Installer"
!define MUI_LICENSEPAGE_CHECKBOX

!addplugindir "..\Release"
!addplugindir "."

Name "FINAL FANTASY XI"
OutFile "FINAL FANTASY XI.exe"
InstallDir "$PROGRAMFILES\PlayOnline"
InstallDirRegKey HKCU "Software\FINAL FANTASY XI" "InstallPath"
RequestExecutionLevel admin

!define MUI_ABORTWARNING

LangString DEPENDENCIES_TITLE 1033 "Installation Options"
LangString DEPENDENCIES_SUBTITLE 1033 "Select dependencies to install."
LangString DEPENDENCIES_TITLE 1036 "Options d'installation"
LangString DEPENDENCIES_SUBTITLE 1036 "Sélectionnez les dépendances à installer."
LangString TRANSLATION_TITLE 1033 "Additional Options"
LangString TRANSLATION_SUBTITLE 1033 "Choose your texture preferences."
LangString TRANSLATION_TITLE 1036 "Options supplémentaires"
LangString TRANSLATION_SUBTITLE 1036 "Choisissez vos préférences de langue et de textures."
LangString CHECKBOX_FRENCH 1033 "N/A"
LangString CHECKBOX_FRENCH 1036 "Installer la traduction française"
LangString CHECKBOX_HD 1033 "Install HD Textures Pack"
LangString CHECKBOX_HD 1036 "Installer le pack de textures HD"

LangString DEP_VS2010 1033 "Visual Studio 2010 Redistributable"
LangString DEP_VS2010 1036 "Redistribuable Visual Studio 2010"
LangString DEP_VS2012 1033 "Visual Studio 2012 Redistributable"
LangString DEP_VS2012 1036 "Redistribuable Visual Studio 2012"
LangString DEP_VS2013 1033 "Visual Studio 2013 Redistributable"
LangString DEP_VS2013 1036 "Redistribuable Visual Studio 2013"
LangString DEP_VS2015 1033 "Visual Studio 2015 Redistributable"
LangString DEP_VS2015 1036 "Redistribuable Visual Studio 2015"
LangString DEP_DOTNET40 1033 ".NET Framework 4.0"
LangString DEP_DOTNET40 1036 ".NET Framework 4.0"
LangString DEP_DOTNET45 1033 ".NET Framework 4.5"
LangString DEP_DOTNET45 1036 ".NET Framework 4.5"
LangString DEP_DIRECTPLAY 1033 "DirectPlay"
LangString DEP_DIRECTPLAY 1036 "DirectPlay"

Var FrenchTranslation
Var InstallVS2010
Var InstallVS2012
Var InstallVS2013
Var InstallVS2015
Var InstallDotNet40
Var InstallDotNet45
Var InstallDirectPlay
Var InstallHDTextures
Var IsUpdate
Var GameDir

!insertmacro MUI_PAGE_WELCOME
!define MUI_PAGE_CUSTOMFUNCTION_PRE "LicensePre"
!insertmacro MUI_PAGE_LICENSE "license.txt"
Page Custom DependenciesOptionPre DependenciesOptionPageLeave
Page Custom DependenciesPre DependenciesLeave
Page Custom TranslationPage TranslationPageLeave
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "French"

Function .onInit
  StrCpy $IsUpdate "no"  ; Par défaut, nouvelle installation
  StrCpy $INSTDIR "$PROGRAMFILES\PlayOnline"  ; Chemin par défaut

  ; Étape 1 : Vérifier le registre HKCU
  ClearErrors
  ReadRegStr $0 HKCU "Software\FINAL FANTASY XI" "InstallPath"
  ${IfNot} ${Errors}
    ${If} ${FileExists} "$0\SquareEnix\FINAL FANTASY XI\*.*"
      StrCpy $IsUpdate "yes"
      StrCpy $INSTDIR "$0"
      DetailPrint "Installation existante détectée via le registre à : $INSTDIR"
    ${Else}
      DetailPrint "Clé de registre trouvée ($0), mais dossier introuvable."
    ${EndIf}
  ${Else}
    DetailPrint "Aucune clé de registre trouvée dans HKCU."
  ${EndIf}

  ; Étape 2 : Vérifier le chemin par défaut si le registre échoue
  ${If} $IsUpdate == "no"
    ${If} ${FileExists} "$PROGRAMFILES\PlayOnline\SquareEnix\FINAL FANTASY XI\*.*"
      StrCpy $IsUpdate "yes"
      StrCpy $INSTDIR "$PROGRAMFILES\PlayOnline"
      DetailPrint "Installation existante détectée dans le chemin par défaut : $INSTDIR"
    ${Else}
      DetailPrint "Aucune installation détectée dans le chemin par défaut."
    ${EndIf}
  ${EndIf}

  ; Étape 3 : Message final
  ${If} $IsUpdate == "yes"
    DetailPrint "Mise à jour détectée. Installation dans : $INSTDIR"
  ${Else}
    DetailPrint "Aucune installation existante. Nouvelle installation dans : $INSTDIR"
  ${EndIf}

  !insertmacro MUI_LANGDLL_DISPLAY
FunctionEnd

Function StrStr
  Exch $R1
  Exch
  Exch $R2
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 $R1 found
    StrCmp $R5 "" notfound
    IntOp $R4 $R4 + 1
    Goto loop
  found:
    StrCpy $R1 $R4
    Goto done
  notfound:
    StrCpy $R1 -1
  done:
    Pop $R5
    Pop $R4
    Pop $R3
    Pop $R2
    Exch $R1
FunctionEnd

Function CopyFilesRecursively
  Exch $0  ; Destination directory (e.g., $GameDir)
  Exch
  Exch $R0 ; Source directory (e.g., $TEMP\data_extract)
  Push $R1
  Push $R2
  Push $R3
  FindFirst $R1 $R2 "$R0\*.*"
  loop:
    StrCmp $R2 "" done
    StrCmp $R2 "." next
    StrCmp $R2 ".." next
    IfFileExists "$R0\$R2\*.*" 0 file
      CreateDirectory "$0\$R2"
      Push "$0\$R2"
      Push "$R0\$R2"
      Call CopyFilesRecursively
      Pop $R0
      Pop $0
      Goto next
    file:
      ${GetFileName} "$R0\$R2" $R3
      IfFileExists "$0\$R3" 0 copy
        Delete "$0\$R3"
      copy:
      CopyFiles /SILENT "$R0\$R2" "$0"
    next:
      FindNext $R1 $R2
      Goto loop
  done:
    FindClose $R1
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0
  Pop $0
FunctionEnd

Function LicensePre
  ${If} $IsUpdate == "yes"
    Abort
  ${EndIf}
FunctionEnd

Function DependenciesOptionPre
  ${If} $IsUpdate == "yes"
    Abort
  ${EndIf}
  !insertmacro MUI_HEADER_TEXT "$(DEPENDENCIES_TITLE)" "$(DEPENDENCIES_SUBTITLE)"
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}
  ${NSD_CreateCheckbox} 0 0u 100% 12u "$(DEP_VS2010)"
  Pop $InstallVS2010
  ${NSD_Check} $InstallVS2010
  ${NSD_CreateCheckbox} 0 20u 100% 12u "$(DEP_VS2012)"
  Pop $InstallVS2012
  ${NSD_Check} $InstallVS2012
  ${NSD_CreateCheckbox} 0 40u 100% 12u "$(DEP_VS2013)"
  Pop $InstallVS2013
  ${NSD_Check} $InstallVS2013
  ${NSD_CreateCheckbox} 0 60u 100% 12u "$(DEP_VS2015)"
  Pop $InstallVS2015
  ${NSD_Check} $InstallVS2015
  ${NSD_CreateCheckbox} 0 80u 100% 12u "$(DEP_DOTNET40)"
  Pop $InstallDotNet40
  ${NSD_Check} $InstallDotNet40
  ${NSD_CreateCheckbox} 0 100u 100% 12u "$(DEP_DOTNET45)"
  Pop $InstallDotNet45
  ${NSD_Check} $InstallDotNet45
  ${NSD_CreateCheckbox} 0 120u 100% 12u "$(DEP_DIRECTPLAY)"
  Pop $InstallDirectPlay
  ${NSD_Check} $InstallDirectPlay
  nsDialogs::Show
FunctionEnd

Function DependenciesOptionPageLeave
  ${NSD_GetState} $InstallVS2010 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallVS2010 "yes"
  ${Else}
    StrCpy $InstallVS2010 "no"
  ${EndIf}
  ${NSD_GetState} $InstallVS2012 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallVS2012 "yes"
  ${Else}
    StrCpy $InstallVS2012 "no"
  ${EndIf}
  ${NSD_GetState} $InstallVS2013 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallVS2013 "yes"
  ${Else}
    StrCpy $InstallVS2013 "no"
  ${EndIf}
  ${NSD_GetState} $InstallVS2015 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallVS2015 "yes"
  ${Else}
    StrCpy $InstallVS2015 "no"
  ${EndIf}
  ${NSD_GetState} $InstallDotNet40 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallDotNet40 "yes"
  ${Else}
    StrCpy $InstallDotNet40 "no"
  ${EndIf}
  ${NSD_GetState} $InstallDotNet45 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallDotNet45 "yes"
  ${Else}
    StrCpy $InstallDotNet45 "no"
  ${EndIf}
  ${NSD_GetState} $InstallDirectPlay $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallDirectPlay "yes"
  ${Else}
    StrCpy $InstallDirectPlay "no"
  ${EndIf}
FunctionEnd

Function DependenciesPre
  ${If} $IsUpdate == "yes"
    DetailPrint "Update detected, dependencies skipped."
    Abort
  ${EndIf}
  DetailPrint "Checking selected dependencies..."
  ${If} $InstallVS2010 == "yes"
    DetailPrint "Installing Visual Studio 2010 Redistributable..."
    File /oname=$TEMP\VS2010.exe "VS2010.exe"
    ExecWait "$TEMP\VS2010.exe /install /passive /norestart"
  ${Else}
    DetailPrint "Visual Studio 2010 Redistributable skipped."
  ${EndIf}
  ${If} $InstallVS2012 == "yes"
    DetailPrint "Installing Visual Studio 2012 Redistributable..."
    File /oname=$TEMP\VS2012.exe "VS2012.exe"
    ExecWait "$TEMP\VS2012.exe /install /passive /norestart"
  ${Else}
    DetailPrint "Visual Studio 2012 Redistributable skipped."
  ${EndIf}
  ${If} $InstallVS2013 == "yes"
    DetailPrint "Installing Visual Studio 2013 Redistributable..."
    File /oname=$TEMP\VS2013.exe "VS2013.exe"
    ExecWait "$TEMP\VS2013.exe /install /passive /norestart"
  ${Else}
    DetailPrint "Visual Studio 2013 Redistributable skipped."
  ${EndIf}
  ${If} $InstallVS2015 == "yes"
    DetailPrint "Installing Visual Studio 2015 Redistributable..."
    File /oname=$TEMP\VS2015.exe "VS2015.exe"
    ExecWait "$TEMP\VS2015.exe /install /passive /norestart"
  ${Else}
    DetailPrint "Visual Studio 2015 Redistributable skipped."
  ${EndIf}
  ${If} $InstallDotNet40 == "yes"
    DetailPrint "Installing .NET Framework 4.0..."
    File /oname=$TEMP\dotNetFx40_Full_x86_x64.exe "dotNetFx40_Full_x86_x64.exe"
    ExecWait "$TEMP\dotNetFx40_Full_x86_x64.exe /install /passive /norestart"
  ${Else}
    DetailPrint ".NET Framework 4.0 skipped."
  ${EndIf}
  ${If} $InstallDotNet45 == "yes"
    DetailPrint "Installing .NET Framework 4.5..."
    File /oname=$TEMP\dotNet45.exe "dotNet45.exe"
    ExecWait "$TEMP\dotNet45.exe /install /passive /norestart"
  ${Else}
    DetailPrint ".NET Framework 4.5 skipped."
  ${EndIf}
  ${If} $InstallDirectPlay == "yes"
    DetailPrint "Enabling DirectPlay..."
    nsExec::Exec "dism /online /Enable-Feature /FeatureName:DirectPlay /All"
  ${Else}
    DetailPrint "DirectPlay skipped."
  ${EndIf}
  DetailPrint "Dependencies processed based on user selection."
FunctionEnd

Function DependenciesLeave
FunctionEnd

Function TranslationPage
  !insertmacro MUI_HEADER_TEXT "$(TRANSLATION_TITLE)" "$(TRANSLATION_SUBTITLE)"
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}
  ${If} $LANGUAGE == 1036
    ${NSD_CreateCheckbox} 0 0u 100% 12u "$(CHECKBOX_FRENCH)"
    Pop $FrenchTranslation
    ${NSD_Check} $FrenchTranslation
    ${NSD_CreateCheckbox} 0 20u 100% 12u "$(CHECKBOX_HD)"
    Pop $InstallHDTextures
    ${NSD_Check} $InstallHDTextures
  ${Else}
    ${NSD_CreateCheckbox} 0 0u 100% 12u "$(CHECKBOX_HD)"
    Pop $InstallHDTextures
    ${NSD_Check} $InstallHDTextures
  ${EndIf}
  nsDialogs::Show
FunctionEnd

Function TranslationPageLeave
  ${If} $LANGUAGE == 1036
    ${NSD_GetState} $FrenchTranslation $1
    ${If} $1 == ${BST_CHECKED}
      StrCpy $FrenchTranslation "yes"
      DetailPrint "French translation selected: $FrenchTranslation"
    ${Else}
      StrCpy $FrenchTranslation "no"
      DetailPrint "French translation not selected: $FrenchTranslation"
    ${EndIf}
    ${NSD_GetState} $InstallHDTextures $2
    ${If} $2 == ${BST_CHECKED}
      StrCpy $InstallHDTextures "yes"
      DetailPrint "HD textures selected: $InstallHDTextures"
    ${Else}
      StrCpy $InstallHDTextures "no"
      DetailPrint "HD textures not selected: $InstallHDTextures"
    ${EndIf}
  ${Else}
    ${NSD_GetState} $InstallHDTextures $1
    ${If} $1 == ${BST_CHECKED}
      StrCpy $InstallHDTextures "yes"
      DetailPrint "HD textures selected: $InstallHDTextures"
    ${Else}
      StrCpy $InstallHDTextures "no"
      DetailPrint "HD textures not selected: $InstallHDTextures"
    ${EndIf}
  ${EndIf}
FunctionEnd

Section "XIInstaller" XIInstaller
  AddSize 14000000
  SetOutPath "$INSTDIR"
  File "installer.ico"

  StrCpy $GameDir "$INSTDIR\SquareEnix\FINAL FANTASY XI"

  ${If} $IsUpdate == "no"
    CreateDirectory "$GameDir"
    DetailPrint "Extracting game files from data.pak to $GameDir..."
    IfFileExists "$EXEDIR\archives\data.pak" 0 data_missing
      Nsis7z::Extract "$EXEDIR\archives\data.pak" "-o$TEMP\data_extract"
      Push "$TEMP\data_extract"
      Push "$GameDir"
      Call CopyFilesRecursively
      RMDir /r "$TEMP\data_extract"
      Goto data_done
    data_missing:
      MessageBox MB_OK|MB_ICONSTOP "Error: data.pak not found in $EXEDIR\archives!"
      Abort
    data_done:
  ${EndIf}

  DetailPrint "Checking French translation selection: $FrenchTranslation"
  ${If} $FrenchTranslation == "yes"
  DetailPrint "Extracting lang.pak to temporary directory..."
  IfFileExists "$EXEDIR\archives\lang.pak" 0 lang_missing
    CreateDirectory "$TEMP\lang_temp"
    Nsis7z::Extract "$EXEDIR\archives\lang.pak" "-o$TEMP\lang_temp"
    DetailPrint "Checking extracted files in $TEMP\lang_temp..."
    FindFirst $0 $1 "$TEMP\lang_temp\*.*"
    check_loop:
      StrCmp $1 "" check_done
      StrCmp $1 "." check_next
      StrCmp $1 ".." check_next
      DetailPrint "Found file: $TEMP\lang_temp\$1"
    check_next:
      FindNext $0 $1
      Goto check_loop
    check_done:
      FindClose $0
    DetailPrint "Installing French translation files to $GameDir..."
    SetOutPath "$GameDir"
    CopyFiles /SILENT "$TEMP\lang_temp\*.*" "$GameDir"
    DetailPrint "Verifying files in $GameDir..."
    ${If} ${FileExists} "$GameDir\*.*"
      DetailPrint "Files successfully installed to $GameDir."
    ${Else}
      DetailPrint "Warning: No files found in $GameDir after installation!"
    ${EndIf}
    DetailPrint "Cleaning up temporary directory $TEMP\lang_temp..."
    RMDir /r "$TEMP\lang_temp"
    ${If} $IsUpdate == "no"
      WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "Language" 0x00000002
    ${EndIf}
    DetailPrint "French translation files installed/updated in $GameDir"
    Goto lang_done
  lang_missing:
    MessageBox MB_OK|MB_ICONSTOP "Erreur : lang.pak introuvable dans $EXEDIR\archives ! Traduction française non installée."
  lang_done:
${Else}
  DetailPrint "French translation skipped by user."
${EndIf}

  ;NSIS Modern User Interface
;Written by Fox_Mulder.
;ZLIB License Copyright (c) 2024-2025 Vanadiel_XI Server

SetCompressor /FINAL lzma

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "nsDialogs.nsh"

!define MUI_ICON "installer.ico"
!define MUI_LANGDLL_WINDOWTITLE "Installer"
!define MUI_WELCOMEFINISHPAGE_BITMAP "background.bmp"
!define MUI_WELCOMEPAGE_TITLE "Installer"
!define MUI_LICENSEPAGE_CHECKBOX

!addplugindir "..\Release"
!addplugindir "."

Name "FINAL FANTASY XI"
OutFile "FINAL FANTASY XI.exe"
InstallDir "$PROGRAMFILES\PlayOnline"
InstallDirRegKey HKCU "Software\FINAL FANTASY XI" "InstallPath"
RequestExecutionLevel admin

!define MUI_ABORTWARNING

LangString DEPENDENCIES_TITLE 1033 "Installation Options"
LangString DEPENDENCIES_SUBTITLE 1033 "Select dependencies to install."
LangString DEPENDENCIES_TITLE 1036 "Options d'installation"
LangString DEPENDENCIES_SUBTITLE 1036 "Sélectionnez les dépendances à installer."
LangString TRANSLATION_TITLE 1033 "Additional Options"
LangString TRANSLATION_SUBTITLE 1033 "Choose your texture preferences."
LangString TRANSLATION_TITLE 1036 "Options supplémentaires"
LangString TRANSLATION_SUBTITLE 1036 "Choisissez vos préférences de langue et de textures."
LangString CHECKBOX_FRENCH 1033 "N/A"
LangString CHECKBOX_FRENCH 1036 "Installer la traduction française"
LangString CHECKBOX_HD 1033 "Install HD Textures Pack"
LangString CHECKBOX_HD 1036 "Installer le pack de textures HD"

LangString DEP_VS2010 1033 "Visual Studio 2010 Redistributable"
LangString DEP_VS2010 1036 "Redistribuable Visual Studio 2010"
LangString DEP_VS2012 1033 "Visual Studio 2012 Redistributable"
LangString DEP_VS2012 1036 "Redistribuable Visual Studio 2012"
LangString DEP_VS2013 1033 "Visual Studio 2013 Redistributable"
LangString DEP_VS2013 1036 "Redistribuable Visual Studio 2013"
LangString DEP_VS2015 1033 "Visual Studio 2015 Redistributable"
LangString DEP_VS2015 1036 "Redistribuable Visual Studio 2015"
LangString DEP_DOTNET40 1033 ".NET Framework 4.0"
LangString DEP_DOTNET40 1036 ".NET Framework 4.0"
LangString DEP_DOTNET45 1033 ".NET Framework 4.5"
LangString DEP_DOTNET45 1036 ".NET Framework 4.5"
LangString DEP_DIRECTPLAY 1033 "DirectPlay"
LangString DEP_DIRECTPLAY 1036 "DirectPlay"

Var FrenchTranslation
Var InstallVS2010
Var InstallVS2012
Var InstallVS2013
Var InstallVS2015
Var InstallDotNet40
Var InstallDotNet45
Var InstallDirectPlay
Var InstallHDTextures
Var IsUpdate
Var GameDir

!insertmacro MUI_PAGE_WELCOME
!define MUI_PAGE_CUSTOMFUNCTION_PRE "LicensePre"
!insertmacro MUI_PAGE_LICENSE "license.txt"
Page Custom DependenciesOptionPre DependenciesOptionPageLeave
Page Custom DependenciesPre DependenciesLeave
Page Custom TranslationPage TranslationPageLeave
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "French"

Function .onInit
  StrCpy $IsUpdate "no"  ; Par défaut, nouvelle installation
  StrCpy $INSTDIR "$PROGRAMFILES\PlayOnline"  ; Chemin par défaut

  ; Étape 1 : Vérifier le registre HKCU
  ClearErrors
  ReadRegStr $0 HKCU "Software\FINAL FANTASY XI" "InstallPath"
  ${IfNot} ${Errors}
    ${If} ${FileExists} "$0\SquareEnix\FINAL FANTASY XI\*.*"
      StrCpy $IsUpdate "yes"
      StrCpy $INSTDIR "$0"
      DetailPrint "Installation existante détectée via le registre à : $INSTDIR"
    ${Else}
      DetailPrint "Clé de registre trouvée ($0), mais dossier introuvable."
    ${EndIf}
  ${Else}
    DetailPrint "Aucune clé de registre trouvée dans HKCU."
  ${EndIf}

  ; Étape 2 : Vérifier le chemin par défaut si le registre échoue
  ${If} $IsUpdate == "no"
    ${If} ${FileExists} "$PROGRAMFILES\PlayOnline\SquareEnix\FINAL FANTASY XI\*.*"
      StrCpy $IsUpdate "yes"
      StrCpy $INSTDIR "$PROGRAMFILES\PlayOnline"
      DetailPrint "Installation existante détectée dans le chemin par défaut : $INSTDIR"
    ${Else}
      DetailPrint "Aucune installation détectée dans le chemin par défaut."
    ${EndIf}
  ${EndIf}

  ; Étape 3 : Message final
  ${If} $IsUpdate == "yes"
    DetailPrint "Mise à jour détectée. Installation dans : $INSTDIR"
  ${Else}
    DetailPrint "Aucune installation existante. Nouvelle installation dans : $INSTDIR"
  ${EndIf}

  !insertmacro MUI_LANGDLL_DISPLAY
FunctionEnd

Function StrStr
  Exch $R1
  Exch
  Exch $R2
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 $R1 found
    StrCmp $R5 "" notfound
    IntOp $R4 $R4 + 1
    Goto loop
  found:
    StrCpy $R1 $R4
    Goto done
  notfound:
    StrCpy $R1 -1
  done:
    Pop $R5
    Pop $R4
    Pop $R3
    Pop $R2
    Exch $R1
FunctionEnd

Function CopyFilesRecursively
  Exch $0  ; Destination directory (e.g., $GameDir)
  Exch
  Exch $R0 ; Source directory (e.g., $TEMP\data_extract)
  Push $R1
  Push $R2
  Push $R3
  FindFirst $R1 $R2 "$R0\*.*"
  loop:
    StrCmp $R2 "" done
    StrCmp $R2 "." next
    StrCmp $R2 ".." next
    IfFileExists "$R0\$R2\*.*" 0 file
      CreateDirectory "$0\$R2"
      Push "$0\$R2"
      Push "$R0\$R2"
      Call CopyFilesRecursively
      Pop $R0
      Pop $0
      Goto next
    file:
      ${GetFileName} "$R0\$R2" $R3
      IfFileExists "$0\$R3" 0 copy
        Delete "$0\$R3"
      copy:
      CopyFiles /SILENT "$R0\$R2" "$0"
    next:
      FindNext $R1 $R2
      Goto loop
  done:
    FindClose $R1
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0
  Pop $0
FunctionEnd

Function LicensePre
  ${If} $IsUpdate == "yes"
    Abort
  ${EndIf}
FunctionEnd

Function DependenciesOptionPre
  ${If} $IsUpdate == "yes"
    Abort
  ${EndIf}
  !insertmacro MUI_HEADER_TEXT "$(DEPENDENCIES_TITLE)" "$(DEPENDENCIES_SUBTITLE)"
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}
  ${NSD_CreateCheckbox} 0 0u 100% 12u "$(DEP_VS2010)"
  Pop $InstallVS2010
  ${NSD_Check} $InstallVS2010
  ${NSD_CreateCheckbox} 0 20u 100% 12u "$(DEP_VS2012)"
  Pop $InstallVS2012
  ${NSD_Check} $InstallVS2012
  ${NSD_CreateCheckbox} 0 40u 100% 12u "$(DEP_VS2013)"
  Pop $InstallVS2013
  ${NSD_Check} $InstallVS2013
  ${NSD_CreateCheckbox} 0 60u 100% 12u "$(DEP_VS2015)"
  Pop $InstallVS2015
  ${NSD_Check} $InstallVS2015
  ${NSD_CreateCheckbox} 0 80u 100% 12u "$(DEP_DOTNET40)"
  Pop $InstallDotNet40
  ${NSD_Check} $InstallDotNet40
  ${NSD_CreateCheckbox} 0 100u 100% 12u "$(DEP_DOTNET45)"
  Pop $InstallDotNet45
  ${NSD_Check} $InstallDotNet45
  ${NSD_CreateCheckbox} 0 120u 100% 12u "$(DEP_DIRECTPLAY)"
  Pop $InstallDirectPlay
  ${NSD_Check} $InstallDirectPlay
  nsDialogs::Show
FunctionEnd

Function DependenciesOptionPageLeave
  ${NSD_GetState} $InstallVS2010 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallVS2010 "yes"
  ${Else}
    StrCpy $InstallVS2010 "no"
  ${EndIf}
  ${NSD_GetState} $InstallVS2012 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallVS2012 "yes"
  ${Else}
    StrCpy $InstallVS2012 "no"
  ${EndIf}
  ${NSD_GetState} $InstallVS2013 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallVS2013 "yes"
  ${Else}
    StrCpy $InstallVS2013 "no"
  ${EndIf}
  ${NSD_GetState} $InstallVS2015 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallVS2015 "yes"
  ${Else}
    StrCpy $InstallVS2015 "no"
  ${EndIf}
  ${NSD_GetState} $InstallDotNet40 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallDotNet40 "yes"
  ${Else}
    StrCpy $InstallDotNet40 "no"
  ${EndIf}
  ${NSD_GetState} $InstallDotNet45 $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallDotNet45 "yes"
  ${Else}
    StrCpy $InstallDotNet45 "no"
  ${EndIf}
  ${NSD_GetState} $InstallDirectPlay $1
  ${If} $1 == ${BST_CHECKED}
    StrCpy $InstallDirectPlay "yes"
  ${Else}
    StrCpy $InstallDirectPlay "no"
  ${EndIf}
FunctionEnd

Function DependenciesPre
  ${If} $IsUpdate == "yes"
    DetailPrint "Update detected, dependencies skipped."
    Abort
  ${EndIf}
  DetailPrint "Checking selected dependencies..."
  ${If} $InstallVS2010 == "yes"
    DetailPrint "Installing Visual Studio 2010 Redistributable..."
    File /oname=$TEMP\VS2010.exe "VS2010.exe"
    ExecWait "$TEMP\VS2010.exe /install /passive /norestart"
  ${Else}
    DetailPrint "Visual Studio 2010 Redistributable skipped."
  ${EndIf}
  ${If} $InstallVS2012 == "yes"
    DetailPrint "Installing Visual Studio 2012 Redistributable..."
    File /oname=$TEMP\VS2012.exe "VS2012.exe"
    ExecWait "$TEMP\VS2012.exe /install /passive /norestart"
  ${Else}
    DetailPrint "Visual Studio 2012 Redistributable skipped."
  ${EndIf}
  ${If} $InstallVS2013 == "yes"
    DetailPrint "Installing Visual Studio 2013 Redistributable..."
    File /oname=$TEMP\VS2013.exe "VS2013.exe"
    ExecWait "$TEMP\VS2013.exe /install /passive /norestart"
  ${Else}
    DetailPrint "Visual Studio 2013 Redistributable skipped."
  ${EndIf}
  ${If} $InstallVS2015 == "yes"
    DetailPrint "Installing Visual Studio 2015 Redistributable..."
    File /oname=$TEMP\VS2015.exe "VS2015.exe"
    ExecWait "$TEMP\VS2015.exe /install /passive /norestart"
  ${Else}
    DetailPrint "Visual Studio 2015 Redistributable skipped."
  ${EndIf}
  ${If} $InstallDotNet40 == "yes"
    DetailPrint "Installing .NET Framework 4.0..."
    File /oname=$TEMP\dotNetFx40_Full_x86_x64.exe "dotNetFx40_Full_x86_x64.exe"
    ExecWait "$TEMP\dotNetFx40_Full_x86_x64.exe /install /passive /norestart"
  ${Else}
    DetailPrint ".NET Framework 4.0 skipped."
  ${EndIf}
  ${If} $InstallDotNet45 == "yes"
    DetailPrint "Installing .NET Framework 4.5..."
    File /oname=$TEMP\dotNet45.exe "dotNet45.exe"
    ExecWait "$TEMP\dotNet45.exe /install /passive /norestart"
  ${Else}
    DetailPrint ".NET Framework 4.5 skipped."
  ${EndIf}
  ${If} $InstallDirectPlay == "yes"
    DetailPrint "Enabling DirectPlay..."
    nsExec::Exec "dism /online /Enable-Feature /FeatureName:DirectPlay /All"
  ${Else}
    DetailPrint "DirectPlay skipped."
  ${EndIf}
  DetailPrint "Dependencies processed based on user selection."
FunctionEnd

Function DependenciesLeave
FunctionEnd

Function TranslationPage
  !insertmacro MUI_HEADER_TEXT "$(TRANSLATION_TITLE)" "$(TRANSLATION_SUBTITLE)"
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}
  ${If} $LANGUAGE == 1036
    ${NSD_CreateCheckbox} 0 0u 100% 12u "$(CHECKBOX_FRENCH)"
    Pop $FrenchTranslation
    ${NSD_Check} $FrenchTranslation
    ${NSD_CreateCheckbox} 0 20u 100% 12u "$(CHECKBOX_HD)"
    Pop $InstallHDTextures
    ${NSD_Check} $InstallHDTextures
  ${Else}
    ${NSD_CreateCheckbox} 0 0u 100% 12u "$(CHECKBOX_HD)"
    Pop $InstallHDTextures
    ${NSD_Check} $InstallHDTextures
  ${EndIf}
  nsDialogs::Show
FunctionEnd

Function TranslationPageLeave
  ${If} $LANGUAGE == 1036
    ${NSD_GetState} $FrenchTranslation $1
    ${If} $1 == ${BST_CHECKED}
      StrCpy $FrenchTranslation "yes"
      DetailPrint "French translation selected: $FrenchTranslation"
    ${Else}
      StrCpy $FrenchTranslation "no"
      DetailPrint "French translation not selected: $FrenchTranslation"
    ${EndIf}
    ${NSD_GetState} $InstallHDTextures $2
    ${If} $2 == ${BST_CHECKED}
      StrCpy $InstallHDTextures "yes"
      DetailPrint "HD textures selected: $InstallHDTextures"
    ${Else}
      StrCpy $InstallHDTextures "no"
      DetailPrint "HD textures not selected: $InstallHDTextures"
    ${EndIf}
  ${Else}
    ${NSD_GetState} $InstallHDTextures $1
    ${If} $1 == ${BST_CHECKED}
      StrCpy $InstallHDTextures "yes"
      DetailPrint "HD textures selected: $InstallHDTextures"
    ${Else}
      StrCpy $InstallHDTextures "no"
      DetailPrint "HD textures not selected: $InstallHDTextures"
    ${EndIf}
  ${EndIf}
FunctionEnd

Section "XIInstaller" XIInstaller
  AddSize 14000000
  SetOutPath "$INSTDIR"
  File "installer.ico"

  StrCpy $GameDir "$INSTDIR\SquareEnix\FINAL FANTASY XI"

  ${If} $IsUpdate == "no"
    CreateDirectory "$GameDir"
    DetailPrint "Extracting game files from data.pak to $GameDir..."
    IfFileExists "$EXEDIR\archives\data.pak" 0 data_missing
      Nsis7z::Extract "$EXEDIR\archives\data.pak" "-o$TEMP\data_extract"
      Push "$TEMP\data_extract"
      Push "$GameDir"
      Call CopyFilesRecursively
      RMDir /r "$TEMP\data_extract"
      Goto data_done
    data_missing:
      MessageBox MB_OK|MB_ICONSTOP "Error: data.pak not found in $EXEDIR\archives!"
      Abort
    data_done:
  ${EndIf}

  DetailPrint "Checking French translation selection: $FrenchTranslation"
  ${If} $FrenchTranslation == "yes"
    DetailPrint "Extracting lang.pak to temporary directory..."
    IfFileExists "$EXEDIR\archives\lang.pak" 0 lang_missing
      CreateDirectory "$TEMP\lang_temp"
      Nsis7z::Extract "$EXEDIR\archives\lang.pak" "-o$TEMP\lang_temp"
      DetailPrint "Checking extracted files in $TEMP\lang_temp..."
      FindFirst $0 $1 "$TEMP\lang_temp\*.*"
      check_loop:
        StrCmp $1 "" check_done
        StrCmp $1 "." check_next
        StrCmp $1 ".." check_next
        DetailPrint "Found file: $TEMP\lang_temp\$1"
      check_next:
        FindNext $0 $1
        Goto check_loop
      check_done:
        FindClose $0
      DetailPrint "Installing French translation files to $GameDir..."
      SetOutPath "$GameDir"
      File /r "$TEMP\lang_temp\*.*"
      DetailPrint "Verifying files in $GameDir..."
      ${If} ${FileExists} "$GameDir\*.*"
        DetailPrint "Files successfully installed to $GameDir."
      ${Else}
        DetailPrint "Warning: No files found in $GameDir after installation!"
      ${EndIf}
      DetailPrint "Cleaning up temporary directory $TEMP\lang_temp..."
      RMDir /r "$TEMP\lang_temp"
      ${If} $IsUpdate == "no"
        WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "Language" 0x00000002
      ${EndIf}
      DetailPrint "French translation files installed/updated in $GameDir"
      Goto lang_done
    lang_missing:
      MessageBox MB_OK|MB_ICONSTOP "Erreur : lang.pak introuvable dans $EXEDIR\archives ! Traduction française non installée."
    lang_done:
  ${Else}
    DetailPrint "French translation skipped by user."
  ${EndIf}

  ${If} $InstallHDTextures == "yes"
    DetailPrint "Extracting hd_textures.pak to temporary directory..."
    IfFileExists "$EXEDIR\archives\hd_textures.pak" 0 hd_missing
      CreateDirectory "$TEMP\hd_textures_temp"
      Nsis7z::Extract "$EXEDIR\archives\hd_textures.pak" "-o$TEMP\hd_textures_temp"
      DetailPrint "Checking extracted files in $TEMP\hd_textures_temp..."
      FindFirst $0 $1 "$TEMP\hd_textures_temp\*.*"
      hd_check_loop:
        StrCmp $1 "" hd_check_done
        StrCmp $1 "." hd_check_next
        StrCmp $1 ".." hd_check_next
        DetailPrint "Found file: $TEMP\hd_textures_temp\$1"
      hd_check_next:
        FindNext $0 $1
        Goto hd_check_loop
      hd_check_done:
        FindClose $0
      DetailPrint "Installing HD texture files to $GameDir..."
      SetOutPath "$GameDir"
      File /r "$TEMP\hd_textures_temp\*.*"
      DetailPrint "Verifying files in $GameDir..."
      ${If} ${FileExists} "$GameDir\*.*"
        DetailPrint "Files successfully installed to $GameDir."
      ${Else}
        DetailPrint "Warning: No files found in $GameDir after installation!"
      ${EndIf}
      DetailPrint "Cleaning up temporary directory $TEMP\hd_textures_temp..."
      RMDir /r "$TEMP\hd_textures_temp"
      DetailPrint "HD texture files installed/updated in $GameDir"
      Goto hd_done
    hd_missing:
      MessageBox MB_OK|MB_ICONSTOP "Erreur : hd_textures.pak introuvable dans $EXEDIR\archives ! Textures HD non installées."
    hd_done:
  ${Else}
    DetailPrint "HD textures pack skipped by user."
  ${EndIf}

  ${If} $IsUpdate == "yes"
    CreateDirectory "$INSTDIR\..\Ashita\config\boot"
  ${Else}
    CreateDirectory "$INSTDIR\Ashita\config\boot"
  ${EndIf}

  ${If} $IsUpdate == "yes"
    DetailPrint "Existing installation detected, checking Ashita configuration..."
    IfFileExists "$INSTDIR\..\Ashita\config\boot\Private Server.xml" 0 config_missing
      ClearErrors
      FileOpen $0 "$INSTDIR\..\Ashita\config\boot\Private Server.xml" r
      StrCpy $1 ""
read_loop:
      FileRead $0 $2
      ${If} ${Errors}
        Goto read_done
      ${EndIf}
      Push $2
      Push '<setting name="boot_file">'
      Call StrStr
      Pop $3
      ${If} $3 != -1
        StrLen $4 '<setting name="boot_file">'
        StrCpy $1 $2 "" $4
        Push $1
        Push "</setting>"
        Call StrStr
        Pop $5
        StrCpy $1 $1 $5
        Goto read_done
      ${EndIf}
      Goto read_loop
read_done:
      FileClose $0
      StrCpy $3 "$INSTDIR\..\Ashita\ffxi-bootmod\xiloader.exe"
      ${If} $1 != $3
        DetailPrint "Ashita configuration incorrect (boot_file: $1), updating to $3..."
        Goto write_config
      ${Else}
        DetailPrint "Ashita configuration is correct (boot_file: $1)."
        Goto config_done
      ${EndIf}
    config_missing:
      DetailPrint "Ashita configuration file missing, creating it..."
      Goto write_config
  ${Else}
    DetailPrint "New installation, creating Ashita configuration..."
    Goto write_config
  ${EndIf}

write_config:
  ${If} $IsUpdate == "yes"
    FileOpen $0 "$INSTDIR\..\Ashita\config\boot\Private Server.xml" w
  ${Else}
    FileOpen $0 "$INSTDIR\Ashita\config\boot\Private Server.xml" w
  ${EndIf}
  FileWrite $0 '<?xml version="1.0" encoding="utf-8" standalone="yes"?>$\r$\n'
  FileWrite $0 "<settings>$\r$\n"
  FileWrite $0 '  <setting name="config_name">VanadielXI (Private Server)</setting>$\r$\n'
  FileWrite $0 '  <setting name="auto_close">True</setting>$\r$\n'
  FileWrite $0 '  <setting name="language">2</setting>$\r$\n'
  FileWrite $0 '  <setting name="pol_version">2</setting>$\r$\n'
  FileWrite $0 '  <setting name="test_server">False</setting>$\r$\n'
  FileWrite $0 '  <setting name="log_level">4</setting>$\r$\n'
  FileWrite $0 '  <setting name="windowed">True</setting>$\r$\n'
  FileWrite $0 '  <setting name="show_border">False</setting>$\r$\n'
  FileWrite $0 '  <setting name="unhook_mouse">False</setting>$\r$\n'
  FileWrite $0 '  <setting name="window_x">1920</setting>$\r$\n'
  FileWrite $0 '  <setting name="window_y">1080</setting>$\r$\n'
  FileWrite $0 '  <setting name="startpos_x">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="startpos_y">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="background_x">1920</setting>$\r$\n'
  FileWrite $0 '  <setting name="background_y">1080</setting>$\r$\n'
  FileWrite $0 '  <setting name="menu_x">1920</setting>$\r$\n'
  FileWrite $0 '  <setting name="menu_y">1080</setting>$\r$\n'
  ${If} $IsUpdate == "yes"
    FileWrite $0 '  <setting name="boot_file">$INSTDIR\..\Ashita\ffxi-bootmod\xiloader.exe</setting>$\r$\n'
  ${Else}
    FileWrite $0 '  <setting name="boot_file">$INSTDIR\Ashita\ffxi-bootmod\xiloader.exe</setting>$\r$\n'
  ${EndIf}
  FileWrite $0 '  <setting name="boot_command">--user XX --pass XX --hairpin</setting>$\r$\n'
  FileWrite $0 '  <setting name="startup_script">Default.txt</setting>$\r$\n'
  FileWrite $0 '  <setting name="d3d_presentparams_buffercount">1</setting>$\r$\n'
  FileWrite $0 '  <setting name="d3d_presentparams_swapeffect">1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_mipmapping">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_bumpmapping">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_gammabase">0</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_envanimation">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_texturecompression">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_mapcompression">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_fontcompression">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_soundenabled">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_soundalwayson">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_showopeningmovie">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_simplecharcreation">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_stablegraphics">-1</setting>$\r$\n'
  FileWrite $0 "</settings>$\r$\n"
  FileClose $0
  ${If} $IsUpdate == "yes"
    DetailPrint "Private Server.xml created/updated in $INSTDIR\..\Ashita\config\boot with dynamic path."
  ${Else}
    DetailPrint "Private Server.xml created/updated in $INSTDIR\Ashita\config\boot with dynamic path."
  ${EndIf}
config_done:

  ${If} $IsUpdate == "no"
    DetailPrint "Updating registry settings..."
    SetRegView 64
    WriteRegStr HKCU "Software\FINAL FANTASY XI" "InstallPath" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "DisplayName" "Uninstall FINAL FANTASY XI"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "UninstallString" "$GameDir\Uninstall FINAL FANTASY XI.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "QuietUninstallString" "$GameDir\Uninstall FINAL FANTASY XI.exe /S"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "DisplayIcon" "$GameDir\installer.ico"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS" "CommonFilesFolder" "$PROGRAMFILES\Common Files\"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder" "0001" "$GameDir\"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder" "1000" "$INSTDIR\SquareEnix\PlayOnlineViewer"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Interface" "0001" "130b5023"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Interface" "1000" "1304d1e8"
    WriteRegBin HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Product" "0001" 9741e0849e6dc5ec1220cd8c1ecd9649be988450ab9a402c58fbfb50fecae9f3bad2df087753f81d1f33e92a8e4a2faa04dff98ee20508a30fb501134eda95f3f029a5795fa83626a451c3008c52772a1ff31c0c7311d737b1f2f53375887d091a55611511ec3561d55f3a2f252171c73d2eeb09041b801bf03e3cf029869d844d0870d6453da92ee5e03acea1c93a8996abe96dddc6149b648ad02e37ab8767c61d252140618ffa22ac270845ff4419f57670816dd860827536055e29b11463260f64617e7b3c5df923688c664d38c15cfd5b967097cc2022a0135fba2df6589d4fe22e4db2e596903eb45c8a8f30780b29b30ec5e0295da24c6e9168a0590ab762f78359aa022b321feedf8d5e05da9eb59d59625389e5a8c63ba02623705b
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0000" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0001" 0x00000640
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0002" 0x00000384
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0003" 0x00000640
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0004" 0x00000384
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0007" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0011" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0017" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0018" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0019" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0020" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0021" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0022" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0023" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0024" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0028" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0029" 0x0000000c
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0030" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0031" 0x3bc49ba6
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0032" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0033" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0034" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0035" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0036" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0037" 0x00000640
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0038" 0x00000384
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0039" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0040" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0041" 0x00000000
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0042" "$GameDir"
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0043" 0x00000000
    WriteRegBin HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "bFirst" 00
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "padsin000" "8,9,13,12,10,0,1,3,2,15,-1,-1,14,-33,-33,32,32,-36,-36,35,35,6,7,5,4,11,-1"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "padmode000" "1,0,1,0,1,1"
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer" "FirstBootPlayMovie" 0x00000000
    WriteRegBin HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer" "SPS000" 66c84962897d8dce4d64151db09a4ca4267c07c18b8df49c8f31a4b35a72f34cda1df301ee999021d69a2a941e91797e9b4d6d5db04a362a03ac41cdf89c6e50ed98531f457b017faa35eb0cd4cb0fea6d3852bfed8fa10351e83d64074178269644b322c6e21ef57a32b167199da82164facc60f1623623b8f8a3f3881a6d26bbd15e4dcf04012c1a91a50f2b942fa344644dac419e9aadb22489b813110830cf7a8b305ba06b8bdb8131bf2ab1f29e392f6bf43e47714d39fd00ed10369c647251aa6bc05fcf3c0210e71178ff0fe3df2548963e927f38c3bd205bed21ac6ed12fea4576c534b4bf3128c1d5fc4315f3580d03b21df18c30b11cf125f9132f980f9e7b1d8579f77a8eaf6d6426fc67e50d265f0e13a8bad5bad1bead511761c43e93b67e6428379c7a0c7ba2084db1458af16efa76a77f037484ba7e540e3e07b4f9f34df3d5b6b273174fa2f87ff2527472824fedd498385e3f48374ba7a317964db33826bd56bb5edf4acb3666d83b1accfdde4d0cb1b6a46733fca102d2d246a209d506d7c6869eeafe2dc9ed6ac9e9d64bf84d4f881db3e7425a061de002ab6043b448e9a2078c32517c6a1c9cefc8974f0d21fbcd3b80e08e0a85e915a6889912828a01cc41a8c0046fb033532b6f158ac05e45e33efdf3437643505a1839a303d7838f244f6a82e218947826d508c513a84e06906bd9677cc9226d19a350bef70802d40c7dccbbfe30f93482839f62f5b96a7ea3672e342e81598180f18c388e5615935ee097d0c880a635ab2068e093d6dfc420f49718d86b297dde1a224044311adbba93224182ef211becca81bdcfec40f80fd1a0fdef79ad744ee5329883af56497f8e6f7ed43d842573582afa93cf16cff1ca1d889a72dcdfae4f9a9956d2dfe1c7aabf514180f4f376fbb9d767da165028788aeceecfc775f440e78b3546c4fc162367c3b1ab027a25af51f97d7d11b71ac0988f712477c492775742b41069823320b3723855e5ce3d5c2dc7ae7fb409f5458c40bebe41eb23c39d99a7a09f037b06d881b1a8b4efdf2adfb96b8b9d4dcc51e3f2519a8244fbc5190ec701f73c85b9bab3e1a60d01bb0dd990f875a378aa375e302c1747f5fa99e36613740c76443af4a5d1956521830d82872d43124471af8e8b41984174404066c0cc62b1df99d6296b01496adc5a90e7241dab32ebc640dd19ff15bfd36675f45cfac7e1f0fae90f5664c5c3b4bcca4f730d24f68736e84bd7c50150571613bce014b29beb8282586931a8ceb76d7b5e2b3c3a965f35f84939162bf414cf053188bc7ae02b4a024b69c5bd3a3fa3d561a29498331841c5314a3466b194625a3f5d67e67265898c51fb6a2e62a87866364be2c3cec1389a528301e97e4ab05be3f55fc7498e559593eefff3785b4dc48217e2d1734e0d490ec0bae10b0212758567e64200e7e2b3c39ef302e666b2f4801546a3636805c9533e114b6a323d56133c88a369bda4ab8c203aff022063c816d94b504c2a393e719547a2488c5a16634abe247d292147eb4e794c6a2ce7f2478cedeb3618ce531be72abd9f63173e15cf65c7d21f44e4880b32ac2a9fb16c9378058a51e36c8bba70fdcfcb3e6b6d852f478b92a1c152a9caba215ecdc247008583e6018f3b5c61c1b10de9fe53fd68078ff2c91a57d795114a0863a81e81d5e2c024c30f99be4ec4b923776c5cbd7bd9ccde38f56b6c0180b0c9be4c1bc2307e612702e576b7990bd35fcc8251fa14e86348b8714a6ca8f1c50ae07337143c52120fd420a66a6f88cadd02e49dea36c716b3f845dc4d3fbd8db3baf966cdf68cc7875c3f881d09222cd8a9c099a91b0cf6274dc9d6d679f484d9a9597c106d172c663ce96ad8ba8efb697f6ff1ed074110869dae9159ec4d5a6f4570944db1c4baf0edb35b4e02ac1c4a81cc76d17dc69931120561550f9947b714a6a372e6daf434c08d5b2db1b2433edda30469585f12fc869c266f0cf30cc9f03bba79c9c5de6a99038158118ca4bfa029e6ee6de7d01058095175adb149fb6b520c9b1502d6bd1a220456d7536bce0cae334ce4afcd698c2dcf7c6c016cf7acf516c8193e1a0a0d75ce1f501ca53c40af5d8f5a9316739a8b577ffa2838fb83d9ac01870ec55d0f929f4adff94239a39645d931ac3733356f80f2a5fae14ff057fbaefaebf4ef1288c9e2d287fbb93c57599bb88490bd335911dd2c19ba4588fc1b4f30abdbf1bcb0305afa9670d8e198e0339a52989d3f6b25e44351754b92f66c379a93a84a85a07245d002764886c7e9f6c0249e2b3b00a4652dfb8d3b7972b6de7c1300fb8d01099d1b4bacf9cb59ddce92222f286a86c02425cb736e03c4aa0e032072853648bb2ad4e528db1be1818c5779cd8971a342f92a5c4bb933fed5635ff61589433932ea36ab61ac8720b9b2ae94f3655412d36386dd13bf55f6f49f057ace71f46de4f0a509bf7969569429134e8d9f6b42ed7bd861ba6d8ccad9f6e7bf8f8a22563edc23a448ab1ddb62338cf878a230c72aa6eb4f625cb40edc644739ebaef343c7b9473e3f1389280fc8122f5ba745d824bab71ea3eda0aaeb5224cfb27b89faa6a806e9159fc7e1f215ed5043

    DetailPrint "Registering libraries..."
    RegDLL "$GameDir\FFXi.dll"
    RegDLL "$GameDir\FFXiMain.dll"
    RegDLL "$GameDir\FFXiResource.dll"
    RegDLL "$GameDir\FFXiVersions.dll"
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

    DetailPrint "Creating uninstaller..."
    WriteUninstaller "$GameDir\Uninstall FINAL FANTASY XI.exe"

    DetailPrint "Creating shortcuts..."
    ${If} $IsUpdate == "yes"
      SetOutPath "$INSTDIR\..\Ashita"
      CreateShortcut "$DESKTOP\Play FINAL FANTASY XI.lnk" "$INSTDIR\..\Ashita\Ashita.exe" "" "$INSTDIR\installer.ico"
      CreateDirectory "$SMPROGRAMS\FINAL FANTASY XI"
      CreateShortcut "$SMPROGRAMS\FINAL FANTASY XI\Play FINAL FANTASY XI.lnk" "$INSTDIR\..\Ashita\Ashita.exe" "" "$INSTDIR\installer.ico"
      CreateShortcut "$SMPROGRAMS\FINAL FANTASY XI\Uninstall FINAL FANTASY XI.lnk" "$GameDir\Uninstall FINAL FANTASY XI.exe"
    ${Else}
      SetOutPath "$INSTDIR\Ashita"
      CreateShortcut "$DESKTOP\Play FINAL FANTASY XI.lnk" "$INSTDIR\Ashita\Ashita.exe" "" "$INSTDIR\installer.ico"
      CreateDirectory "$SMPROGRAMS\FINAL FANTASY XI"
      CreateShortcut "$SMPROGRAMS\FINAL FANTASY XI\Play FINAL FANTASY XI.lnk" "$INSTDIR\Ashita\Ashita.exe" "" "$INSTDIR\installer.ico"
      CreateShortcut "$SMPROGRAMS\FINAL FANTASY XI\Uninstall FINAL FANTASY XI.lnk" "$GameDir\Uninstall FINAL FANTASY XI.exe"
    ${EndIf}
  ${EndIf}
SectionEnd

Section "Uninstall"
  ClearErrors
  ReadRegStr $INSTDIR HKCU "Software\FINAL FANTASY XI" "InstallPath"
  ${If} ${Errors}
    ${GetParent} "$EXEDIR" $R0
    StrCpy $INSTDIR "$R0"
    DetailPrint "Warning: Registry path not found, using $INSTDIR as fallback."
  ${EndIf}

  StrCpy $GameDir "$INSTDIR\SquareEnix\FINAL FANTASY XI"

  DetailPrint "Uninstalling from $INSTDIR..."

  UnRegDLL "$GameDir\FFXi.dll"
  UnRegDLL "$GameDir\FFXiMain.dll"
  UnRegDLL "$GameDir\FFXiResource.dll"
  UnRegDLL "$GameDir\FFXiVersions.dll"
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

  RMDir /r "$GameDir"
  RMDir /r "$INSTDIR\SquareEnix\PlayOnlineViewer"
  RMDir /r "$INSTDIR\Ashita"
  Delete "$INSTDIR\installer.ico"
  Delete "$INSTDIR\Uninstall FINAL FANTASY XI.exe"
  RMDir /r "$INSTDIR\SquareEnix"
  RMDir "$INSTDIR"

  Delete "$DESKTOP\Play FINAL FANTASY XI.lnk"
  RMDir /r "$SMPROGRAMS\FINAL FANTASY XI"

  DeleteRegKey /ifempty HKCU "Software\FINAL FANTASY XI"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI"
  DeleteRegKey HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS"
SectionEnd

It seems you've shared an NSIS (Nullsoft Scriptable Install System) script for installing "FINAL FANTASY XI" from a private server called Vanadiel_XI. However, you haven’t asked a specific question about it. As Grok 2, I’m here to assist—how can I help you with this script? For example, do you want me to explain what it does, troubleshoot an issue, or suggest improvements? Please let me know what you’re looking for!

For now, I’ll assume you might want a brief overview of what this script does. Here’s a concise breakdown:
Overview of the Script

This NSIS script creates an installer for "FINAL FANTASY XI," a popular MMORPG, tailored for a private server (Vanadiel_XI). It:

    Sets Up Installation: Installs to C:\Program Files\PlayOnline by default, with an option to detect an existing install via the registry or default path.
    Handles Dependencies: Offers checkboxes for installing prerequisites like Visual Studio Redistributables (2010-2015), .NET Framework (4.0, 4.5), and DirectPlay, skipping them if it’s an update.
    Language and Texture Options: Supports English and French, with optional French translation and HD textures, extracted from .pak archives.
    Configures Ashita: Integrates with Ashita (a third-party launcher for FFXI private servers), creating or updating a config file (Private Server.xml) with boot settings.
    Registry and Shortcuts: Writes registry entries for tracking installation and creates desktop/start menu shortcuts.
    Uninstaller: Includes an uninstall section to remove files, registry entries, and shortcuts.

Key Features

    Multi-language UI: English and French support using MUI2.
    Custom Pages: Allows users to choose dependencies and texture/language options via checkboxes.
    Update Detection: Skips certain steps if an existing installation is found.
    File Extraction: Uses Nsis7z to extract game files, French translation, and HD textures from .pak files.

Potential Notes

    The script assumes the presence of files like data.pak, lang.pak, and hd_textures.pak in an archives folder, and it will error out if they’re missing.
    It requires admin privileges (RequestExecutionLevel admin).
    I can’t execute this code to test it (as per my limitations), but I can analyze or speculate on its behavior if you have a specific question.

Please tell me how I can assist further! If you’d like, I can generate an image (e.g., a mock installer UI) to visualize this—just let me know!
en francais

Bien sûr, je peux vous répondre en français ! Il semble que vous ayez partagé un script NSIS (Nullsoft Scriptable Install System) pour installer "FINAL FANTASY XI" à partir d’un serveur privé appelé Vanadiel_XI. Cependant, vous n’avez pas posé de question spécifique à ce sujet. En tant que Grok 2, je suis ici pour vous aider — comment puis-je vous assister avec ce script ? Par exemple, souhaitez-vous que j’explique son fonctionnement, que je résolve un problème ou que je propose des améliorations ? Dites-moi ce que vous cherchez !

Pour l’instant, je vais supposer que vous voulez peut-être un aperçu de ce que fait ce script. Voici une description concise en français :
Aperçu du script

Ce script NSIS crée un installateur pour "FINAL FANTASY XI", un MMORPG populaire, adapté à un serveur privé (Vanadiel_XI). Il :

    Configure l’installation : Installe par défaut dans C:\Program Files\PlayOnline, avec une détection d’une installation existante via le registre ou le chemin par défaut.
    Gère les dépendances : Propose des cases à cocher pour installer des prérequis comme les redistribuables Visual Studio (2010-2015), .NET Framework (4.0, 4.5) et DirectPlay, en les ignorant s’il s’agit d’une mise à jour.
    Options de langue et de textures : Prend en charge l’anglais et le français, avec une traduction française optionnelle et des textures HD, extraites des archives .pak.
    Configure Ashita : Intègre Ashita (un lanceur tiers pour les serveurs privés FFXI), en créant ou mettant à jour un fichier de configuration (Private Server.xml) avec les paramètres de démarrage.
    Registre et raccourcis : Écrit des entrées dans le registre pour suivre l’installation et crée des raccourcis sur le bureau et dans le menu Démarrer.
    Désinstallateur : Inclut une section de désinstallation pour supprimer les fichiers, les entrées de registre et les raccourcis.

Caractéristiques principales

    Interface multilingue : Supporte l’anglais et le français avec MUI2.
    Pages personnalisées : Permet aux utilisateurs de choisir les dépendances et les options de langue/textures via des cases à cocher.
    Détection de mise à jour : Ignore certaines étapes si une installation existante est détectée.
    Extraction de fichiers : Utilise Nsis7z pour extraire les fichiers du jeu, la traduction française et les textures HD à partir de fichiers .pak.

Remarques potentielles

    Le script suppose la présence de fichiers comme data.pak, lang.pak et hd_textures.pak dans un dossier archives, et il générera une erreur s’ils sont absents.
    Il nécessite des privilèges administratifs (RequestExecutionLevel admin).
    Je ne peux pas exécuter ce code pour le tester (selon mes limitations), mais je peux l’analyser ou spéculer sur son comportement si vous avez une question spécifique.

Dites-moi comment je peux vous aider davantage ! Si vous le souhaitez, je peux générer une image (par exemple, une maquette de l’interface de l’installateur) pour visualiser cela — faites-le-moi savoir !
oui

D'accord, je vais supposer que votre "oui" signifie que vous souhaitez que je continue à vous aider en français, peut-être avec plus de détails ou une action spécifique liée au script. Puisque vous n’avez pas précisé davantage, je vais vous proposer une explication plus détaillée de ce que fait ce script NSIS pour "FINAL FANTASY XI" et je vous offrirai également la possibilité de générer une image si cela vous intéresse. Si vous avez une demande plus précise, n’hésitez pas à me la faire savoir !
Explication détaillée du script (en français)

Ce script est conçu pour installer ou mettre à jour une version personnalisée de "FINAL FANTASY XI" pour un serveur privé appelé Vanadiel_XI. Voici une analyse étape par étape :
1. Configuration de base

    Nom et sortie : L’installateur s’appelle "FINAL FANTASY XI" et produit un fichier exécutable nommé FINAL FANTASY XI.exe.
    Chemin d’installation : Par défaut, il installe dans C:\Program Files\PlayOnline, mais vérifie d’abord si une installation existe via le registre (clé HKCU\Software\FINAL FANTASY XI\InstallPath) ou dans le chemin par défaut.
    Compression : Utilise LZMA pour réduire la taille du fichier installateur.
    Interface utilisateur : Utilise MUI2 (Modern User Interface) avec un support pour l’anglais et le français, une icône personnalisée (installer.ico), et une image de fond (background.bmp).

2. Détection d’une installation existante

    Dans la fonction .onInit, le script vérifie :
        Si une clé de registre existe et pointe vers un dossier valide contenant des fichiers de jeu.
        Sinon, il regarde dans C:\Program Files\PlayOnline.
    Si une installation est détectée, il passe en mode "mise à jour" ($IsUpdate = "yes") et ajuste le processus en conséquence.

3. Pages de l’installateur

    Page de bienvenue : Affiche un titre et une image de fond.
    Page de licence : Montre license.txt, mais uniquement pour une nouvelle installation (ignorée en mode mise à jour).
    Page des dépendances : Une page personnalisée avec des cases à cocher pour installer :
        Visual Studio Redistributables (2010, 2012, 2013, 2015).
        .NET Framework (4.0, 4.5).
        DirectPlay (activé via DISM).
        Ces options sont ignorées en mode mise à jour.
    Page des options supplémentaires : Permet de choisir :
        Traduction française (uniquement en français, $LANGUAGE == 1036).
        Pack de textures HD.
    Page de répertoire : Permet de choisir le dossier d’installation.
    Page d’installation : Exécute les tâches d’installation.
    Page de fin : Confirme que l’installation est terminée.

4. Installation des fichiers

    Fichiers principaux : Extrait data.pak vers $GameDir ($INSTDIR\SquareEnix\FINAL FANTASY XI) pour une nouvelle installation.
    Traduction française : Si sélectionnée, extrait lang.pak et met à jour une entrée de registre pour définir la langue française.
    Textures HD : Si sélectionnées, extrait hd_textures.pak dans le même dossier.
    Ashita : Configure un fichier XML pour Ashita (un lanceur tiers) avec des paramètres comme la résolution (1920x1080) et le chemin du fichier de démarrage (xiloader.exe).

5. Registre et raccourcis

    Pour une nouvelle installation :
        Écrit des clés de registre dans HKCU et HKLM pour suivre l’installation et configurer le jeu.
        Crée des raccourcis sur le bureau et dans le menu Démarrer pour lancer le jeu via Ashita et pour désinstaller.
    En mode mise à jour, ajuste les chemins en conséquence.

6. Désinstallation

    Supprime les fichiers, les DLL enregistrées, les raccourcis et les entrées de registre.

Points à noter

    Dépendances externes : Le script suppose que des fichiers comme VS2010.exe, data.pak, etc., sont inclus dans le package d’installation. S’ils manquent, il affiche une erreur.
    Privilèges : Nécessite des droits d’administrateur pour écrire dans Program Files et le registre.
    Limitation de Grok : Je ne peux pas exécuter ce script pour confirmer son fonctionnement exact, mais je peux raisonner sur son comportement.

Proposition

Voulez-vous que je génère une image pour visualiser à quoi pourrait ressembler l’interface de cet installateur (par exemple, la page des dépendances ou des options de langue) ? Si oui, dites-le-moi ! Sinon, précisez-moi ce que vous souhaitez approfondir ou modifier dans ce script.

Comment puis-je vous aider davantage ?
MakeNSIS v3.10 - Copyright 1999-2023 Contributors
See the file COPYING for license details.
Credits can be found in the Users Manual.

Processing config: C:\Program Files (x86)\NSIS\nsisconf.nsh
Processing default plugins: "C:\Program Files (x86)\NSIS\Plugins\x86-unicode\*.dll"
 + AdvSplash::show
 + Banner::destroy
 + Banner::getWindow
 + Banner::show
 + BgImage::AddImage
 + BgImage::AddText
 + BgImage::Clear
 + BgImage::Destroy
 + BgImage::Redraw
 + BgImage::SetBg
 + BgImage::SetReturn
 + BgImage::Sound
 + Dialer::AttemptConnect
 + Dialer::AutodialHangup
 + Dialer::AutodialOnline
 + Dialer::AutodialUnattended
 + Dialer::GetConnectedState
 + INetC::get
 + INetC::head
 + INetC::post
 + INetC::put
 + InstallOptions::dialog
 + InstallOptions::initDialog
 + InstallOptions::make_unicode
 + InstallOptions::show
 + LangDLL::LangDialog
 + Math::Script
 + NSISdl::download
 + NSISdl::download_quiet
 + NScurl::cancel
 + NScurl::echo
 + NScurl::enumerate
 + NScurl::escape
 + NScurl::http
 + NScurl::md5
 + NScurl::query
 + NScurl::sha1
 + NScurl::sha256
 + NScurl::unescape
 + NScurl::wait
 + Splash::show
 + StartMenu::Init
 + StartMenu::Select
 + StartMenu::Show
 + System::Alloc
 + System::Call
 + System::Copy
 + System::Free
 + System::Get
 + System::Int64Op
 + System::Store
 + System::StrAlloc
 + TypeLib::GetLibVersion
 + TypeLib::Register
 + TypeLib::UnRegister
 + UserInfo::GetAccountType
 + UserInfo::GetName
 + UserInfo::GetOriginalAccountType
 + VPatch::GetFileCRC32
 + VPatch::GetFileMD5
 + VPatch::vpatchfile
 + nsDialogs::Create
 + nsDialogs::CreateControl
 + nsDialogs::CreateItem
 + nsDialogs::CreateTimer
 + nsDialogs::GetUserData
 + nsDialogs::KillTimer
 + nsDialogs::OnBack
 + nsDialogs::OnChange
 + nsDialogs::OnClick
 + nsDialogs::OnNotify
 + nsDialogs::SelectFileDialog
 + nsDialogs::SelectFolderDialog
 + nsDialogs::SetRTL
 + nsDialogs::SetUserData
 + nsDialogs::Show
 + nsExec::Exec
 + nsExec::ExecToLog
 + nsExec::ExecToStack
 + nsis7z::Extract
 + nsis7z::ExtractWithCallback
 + nsis7z::ExtractWithDetails

!define: "MUI_INSERT_NSISCONF"=""

Changing directory to: "C:\Users\alexa\Desktop\ffxi"

Processing script file: "C:\Users\alexa\Desktop\ffxi\FINAL FANTASY XI v2.7.10.nsi" (UTF8)
SetCompressor: /FINAL lzma
!include: "C:\Program Files (x86)\NSIS\Include\MUI2.nsh" (UTF8)
!include: "C:\Program Files (x86)\NSIS\Contrib\Modern UI 2\MUI2.nsh" (UTF8)
NSIS Modern User Interface version 2.1 - Copyright 2002-2023 Joost Verburg (C:\Program Files (x86)\NSIS\Contrib\Modern UI 2\MUI2.nsh:14)
!include: closed: "C:\Program Files (x86)\NSIS\Contrib\Modern UI 2\MUI2.nsh"
!include: closed: "C:\Program Files (x86)\NSIS\Include\MUI2.nsh"
!include: "C:\Program Files (x86)\NSIS\Include\LogicLib.nsh" (UTF8)
!include: closed: "C:\Program Files (x86)\NSIS\Include\LogicLib.nsh"
!include: "C:\Program Files (x86)\NSIS\Include\FileFunc.nsh" (UTF8)
!include: closed: "C:\Program Files (x86)\NSIS\Include\FileFunc.nsh"
!include: "C:\Program Files (x86)\NSIS\Include\nsDialogs.nsh" (UTF8)
!include: closed: "C:\Program Files (x86)\NSIS\Include\nsDialogs.nsh"
!define: "MUI_ICON"="installer.ico"
!define: "MUI_LANGDLL_WINDOWTITLE"="Installer"
!define: "MUI_WELCOMEFINISHPAGE_BITMAP"="background.bmp"
!define: "MUI_WELCOMEPAGE_TITLE"="Installer"
!define: "MUI_LICENSEPAGE_CHECKBOX"=""
!addplugindir: "..\Release"
!addplugindir: "."
Name: "FINAL FANTASY XI"
OutFile: "FINAL FANTASY XI.exe"
InstallDir: "$PROGRAMFILES\PlayOnline"
InstallRegKey: "HKCU\Software\FINAL FANTASY XI\InstallPath"
!define: "MUI_ABORTWARNING"=""
LangString: "DEPENDENCIES_TITLE" 1033 "Installation Options"
LangString: "DEPENDENCIES_SUBTITLE" 1033 "Select dependencies to install."
LangString: "DEPENDENCIES_TITLE" 1036 "Options d'installation"
LangString: "DEPENDENCIES_SUBTITLE" 1036 "Sélectionnez les dépendances à installer."
LangString: "TRANSLATION_TITLE" 1033 "Additional Options"
LangString: "TRANSLATION_SUBTITLE" 1033 "Choose your texture preferences."
LangString: "TRANSLATION_TITLE" 1036 "Options supplémentaires"
LangString: "TRANSLATION_SUBTITLE" 1036 "Choisissez vos préférences de langue et de textures."
LangString: "CHECKBOX_FRENCH" 1033 "N/A"
LangString: "CHECKBOX_FRENCH" 1036 "Installer la traduction française"
LangString: "CHECKBOX_HD" 1033 "Install HD Textures Pack"
LangString: "CHECKBOX_HD" 1036 "Installer le pack de textures HD"
LangString: "DEP_VS2010" 1033 "Visual Studio 2010 Redistributable"
LangString: "DEP_VS2010" 1036 "Redistribuable Visual Studio 2010"
LangString: "DEP_VS2012" 1033 "Visual Studio 2012 Redistributable"
LangString: "DEP_VS2012" 1036 "Redistribuable Visual Studio 2012"
LangString: "DEP_VS2013" 1033 "Visual Studio 2013 Redistributable"
LangString: "DEP_VS2013" 1036 "Redistribuable Visual Studio 2013"
LangString: "DEP_VS2015" 1033 "Visual Studio 2015 Redistributable"
LangString: "DEP_VS2015" 1036 "Redistribuable Visual Studio 2015"
LangString: "DEP_DOTNET40" 1033 ".NET Framework 4.0"
LangString: "DEP_DOTNET40" 1036 ".NET Framework 4.0"
LangString: "DEP_DOTNET45" 1033 ".NET Framework 4.5"
LangString: "DEP_DOTNET45" 1036 ".NET Framework 4.5"

LangString: "DEP_DIRECTPLAY" 1033 "DirectPlay"
LangString: "DEP_DIRECTPLAY" 1036 "DirectPlay"
Var: "FrenchTranslation"
Var: "InstallVS2010"
Var: "InstallVS2012"
Var: "InstallVS2013"
Var: "InstallVS2015"
Var: "InstallDotNet40"
Var: "InstallDotNet45"
Var: "InstallDirectPlay"
Var: "InstallHDTextures"
Var: "IsUpdate"
Var: "GameDir"
!insertmacro: MUI_PAGE_WELCOME
!insertmacro: end of MUI_PAGE_WELCOME
!define: "MUI_PAGE_CUSTOMFUNCTION_PRE"="LicensePre"
!insertmacro: MUI_PAGE_LICENSE
!insertmacro: end of MUI_PAGE_LICENSE
Page: Custom (creator:DependenciesOptionPre) (leave:DependenciesOptionPageLeave)
Page: Custom (creator:DependenciesPre) (leave:DependenciesLeave)
Page: Custom (creator:TranslationPage) (leave:TranslationPageLeave)
!insertmacro: MUI_PAGE_DIRECTORY
!insertmacro: end of MUI_PAGE_DIRECTORY
!insertmacro: MUI_PAGE_INSTFILES
!insertmacro: end of MUI_PAGE_INSTFILES
!insertmacro: MUI_PAGE_FINISH
!insertmacro: end of MUI_PAGE_FINISH
!insertmacro: MUI_LANGUAGE
!insertmacro: end of MUI_LANGUAGE
!insertmacro: MUI_LANGUAGE
!insertmacro: end of MUI_LANGUAGE
Function: ".onInit"
StrCpy $IsUpdate "no" () ()
StrCpy $INSTDIR "$PROGRAMFILES\PlayOnline" () ()
ClearErrors: 
ReadRegStr $0 HKCU\Software\FINAL FANTASY XI\InstallPath
!insertmacro: _If
!insertmacro: end of _If
!insertmacro: _If
!insertmacro: end of _If
StrCpy $IsUpdate "yes" () ()
StrCpy $INSTDIR "$0" () ()
DetailPrint: "Installation existante détectée via le registre à : $INSTDIR"
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Clé de registre trouvée ($0), mais dossier introuvable."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Aucune clé de registre trouvée dans HKCU."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
!insertmacro: _If
!insertmacro: end of _If
StrCpy $IsUpdate "yes" () ()
StrCpy $INSTDIR "$PROGRAMFILES\PlayOnline" () ()
DetailPrint: "Installation existante détectée dans le chemin par défaut : $INSTDIR"
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Aucune installation détectée dans le chemin par défaut."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Mise à jour détectée. Installation dans : $INSTDIR"
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Aucune installation existante. Nouvelle installation dans : $INSTDIR"
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: MUI_LANGDLL_DISPLAY
!insertmacro: end of MUI_LANGDLL_DISPLAY
FunctionEnd
Function: "StrStr"
Exch($R1,0)
Exch(st(1),0)
Exch($R2,0)
Push: $R3
Push: $R4
Push: $R5
StrLen $R3 "$R1"
StrCpy $R4 "0" () ()
StrCpy $R5 "$R2" ($R3) ($R4)
StrCmp "$R5" "$R1" equal=found, nonequal=
StrCmp "$R5" "" equal=notfound, nonequal=
IntOp: $R4=$R4+1
Goto: loop
StrCpy $R1 "$R4" () ()
Goto: done
StrCpy $R1 "-1" () ()
Pop: $R5
Pop: $R4
Pop: $R3
Pop: $R2
Exch($R1,0)
FunctionEnd
Function: "CopyFilesRecursively"
Exch($0,0)
Exch(st(1),0)
Exch($R0,0)
Push: $R1
Push: $R2
Push: $R3
FindFirst: spec="$R0\*.*" handle=$R1 output=$R2
StrCmp "$R2" "" equal=done, nonequal=
StrCmp "$R2" "." equal=next, nonequal=
StrCmp "$R2" ".." equal=next, nonequal=
IfFileExists: "$R0\$R2\*.*" ? 0 : file
CreateDirectory: "$0\$R2"
Push: $0\$R2
Push: $R0\$R2
Call "CopyFilesRecursively"
Pop: $R0
Pop: $0
Goto: next
!insertmacro: GetFileNameCall
!insertmacro: end of GetFileNameCall
IfFileExists: "$0\$R3" ? 0 : copy
Delete: "$0\$R3"
CopyFiles: (silent) "$R0\$R2" -> "$0", size=0KB
FindNext: handle=$R1 output=$R2
Goto: loop
FindClose: $R1
Pop: $R3
Pop: $R2
Pop: $R1
Pop: $R0
Pop: $0
FunctionEnd
Function: "LicensePre"
!insertmacro: _If
!insertmacro: end of _If
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
FunctionEnd
Function: "DependenciesOptionPre"
!insertmacro: _If
!insertmacro: end of _If
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: MUI_HEADER_TEXT
!insertmacro: end of MUI_HEADER_TEXT
Plugin command: Create 1018
Pop: $0

!insertmacro: _If
!insertmacro: end of _If
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 0u 100% 12u $(DEP_VS2010)
Pop: $InstallVS2010
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallVS2010,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 20u 100% 12u $(DEP_VS2012)
Pop: $InstallVS2012
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallVS2012,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 40u 100% 12u $(DEP_VS2013)
Pop: $InstallVS2013
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallVS2013,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 60u 100% 12u $(DEP_VS2015)
Pop: $InstallVS2015
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallVS2015,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 80u 100% 12u $(DEP_DOTNET40)
Pop: $InstallDotNet40
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallDotNet40,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 100u 100% 12u $(DEP_DOTNET45)
Pop: $InstallDotNet45
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallDotNet45,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 120u 100% 12u $(DEP_DIRECTPLAY)
Pop: $InstallDirectPlay
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallDirectPlay,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: Show
FunctionEnd
Function: "DependenciesOptionPageLeave"
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallVS2010,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallVS2010 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallVS2010 "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallVS2012,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallVS2012 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallVS2012 "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallVS2013,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallVS2013 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallVS2013 "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallVS2015,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallVS2015 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallVS2015 "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallDotNet40,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallDotNet40 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallDotNet40 "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallDotNet45,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallDotNet45 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallDotNet45 "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallDirectPlay,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallDirectPlay "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallDirectPlay "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
FunctionEnd
Function: "DependenciesPre"
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Update detected, dependencies skipped."
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
DetailPrint: "Checking selected dependencies..."
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing Visual Studio 2010 Redistributable..."
File: "VS2010.exe"->"$TEMP\VS2010.exe" [compress] 8993744 bytes
ExecWait: "$TEMP\VS2010.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Visual Studio 2010 Redistributable skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing Visual Studio 2012 Redistributable..."
File: "VS2012.exe"->"$TEMP\VS2012.exe" [compress] 6351552/6554576 bytes
ExecWait: "$TEMP\VS2012.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Visual Studio 2012 Redistributable skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing Visual Studio 2013 Redistributable..."
File: "VS2013.exe"->"$TEMP\VS2013.exe" [compress] 6295713/6510544 bytes
ExecWait: "$TEMP\VS2013.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Visual Studio 2013 Redistributable skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing Visual Studio 2015 Redistributable..."
File: "VS2015.exe"->"$TEMP\VS2015.exe" [compress] 12801598/13767776 bytes
ExecWait: "$TEMP\VS2015.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Visual Studio 2015 Redistributable skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing .NET Framework 4.0..."
File: "dotNetFx40_Full_x86_x64.exe"->"$TEMP\dotNetFx40_Full_x86_x64.exe" [compress] 50449456 bytes
ExecWait: "$TEMP\dotNetFx40_Full_x86_x64.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: ".NET Framework 4.0 skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing .NET Framework 4.5..."
File: "dotNet45.exe"->"$TEMP\dotNet45.exe" [compress] 69999448 bytes
ExecWait: "$TEMP\dotNet45.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: ".NET Framework 4.5 skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Enabling DirectPlay..."
File: "nsExec.dll"->"$PLUGINSDIR\nsExec.dll" [compress] 3490/7168 bytes
Plugin command: Exec dism /online /Enable-Feature /FeatureName:DirectPlay /All
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "DirectPlay skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
DetailPrint: "Dependencies processed based on user selection."
FunctionEnd
Function: "DependenciesLeave"
FunctionEnd
Function: "TranslationPage"
!insertmacro: MUI_HEADER_TEXT
!insertmacro: end of MUI_HEADER_TEXT
Plugin command: Create 1018
Pop: $0
!insertmacro: _If
!insertmacro: end of _If
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 0u 100% 12u $(CHECKBOX_FRENCH)
Pop: $FrenchTranslation
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($FrenchTranslation,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 20u 100% 12u $(CHECKBOX_HD)
Pop: $InstallHDTextures
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallHDTextures,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
!insertmacro: _Else
!insertmacro: end of _Else
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 0u 100% 12u $(CHECKBOX_HD)
Pop: $InstallHDTextures
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallHDTextures,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
!insertmacro: _EndIf
!insertmacro: end of _EndIf
Plugin command: Show
FunctionEnd
Function: "TranslationPageLeave"
!insertmacro: _If
!insertmacro: end of _If
!insertmacro: __NSD_GetState
SendMessage:(->$1)($FrenchTranslation,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $FrenchTranslation "yes" () ()
DetailPrint: "French translation selected: $FrenchTranslation"
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $FrenchTranslation "no" () ()
DetailPrint: "French translation not selected: $FrenchTranslation"
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$2)($InstallHDTextures,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallHDTextures "yes" () ()
DetailPrint: "HD textures selected: $InstallHDTextures"
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallHDTextures "no" () ()
DetailPrint: "HD textures not selected: $InstallHDTextures"
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _Else
!insertmacro: end of _Else
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallHDTextures,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallHDTextures "yes" () ()
DetailPrint: "HD textures selected: $InstallHDTextures"
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallHDTextures "no" () ()
DetailPrint: "HD textures not selected: $InstallHDTextures"
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _EndIf
!insertmacro: end of _EndIf
FunctionEnd
Section: "XIInstaller" ->(XIInstaller)
AddSize: 14000000 kb
SetOutPath: "$INSTDIR"
File: "installer.ico" [compress] 17960/112612 bytes
StrCpy $GameDir "$INSTDIR\SquareEnix\FINAL FANTASY XI" () ()
!insertmacro: _If
!insertmacro: end of _If
CreateDirectory: "$GameDir"
DetailPrint: "Extracting game files from data.pak to $GameDir..."
IfFileExists: "$EXEDIR\archives\data.pak" ? 0 : data_missing
File: "nsis7z.dll"->"$PLUGINSDIR\nsis7z.dll" [compress] 187205/400384 bytes
Plugin command: Extract $EXEDIR\archives\data.pak -o$TEMP\data_extract
Push: $TEMP\data_extract
Push: $GameDir
Call "CopyFilesRecursively"
RMDir: /r "$TEMP\data_extract"
Goto: data_done
MessageBox: 16: "Error: data.pak not found in $EXEDIR\archives!"
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
DetailPrint: "Checking French translation selection: $FrenchTranslation"
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Extracting lang.pak to temporary directory..."
IfFileExists: "$EXEDIR\archives\lang.pak" ? 0 : lang_missing
CreateDirectory: "$TEMP\lang_temp"
Plugin command: Extract $EXEDIR\archives\lang.pak -o$TEMP\lang_temp
DetailPrint: "Checking extracted files in $TEMP\lang_temp..."
FindFirst: spec="$TEMP\lang_temp\*.*" handle=$0 output=$1
StrCmp "$1" "" equal=check_done, nonequal=
StrCmp "$1" "." equal=check_next, nonequal=
StrCmp "$1" ".." equal=check_next, nonequal=
DetailPrint: "Found file: $TEMP\lang_temp\$1"
FindNext: handle=$0 output=$1
Goto: check_loop
FindClose: $0
DetailPrint: "Installing French translation files to $GameDir..."
SetOutPath: "$GameDir"
File: Returning to: "$TEMP\lang_temp"
File: "$TEMP\lang_temp\*.*" -> no files found.
Usage: File [/nonfatal] [/a] ([/r] [/x filespec [...]] filespec [...] |
   /oname=outfile one_file_only)
Error in script "C:\Users\alexa\Desktop\ffxi\FINAL FANTASY XI v2.7.10.nsi" on line 428 -- aborting creation process

Il semble que vous ayez partagé une sortie de compilation de MakeNSIS (version 3.10) pour votre script NSIS "FINAL FANTASY XI v2.7.10.nsi", et qu’il y ait une erreur qui a interrompu le processus. L’erreur se produit à la ligne 428 du script. Je vais analyser cette sortie pour identifier le problème et vous proposer une solution en français, comme demandé.
Analyse de l’erreur

L’erreur affichée est :
text
File: "$TEMP\lang_temp\*.*" -> no files found.
Usage: File [/nonfatal] [/a] ([/r] [/x filespec [...]] filespec [...] |
   /oname=outfile one_file_only)
Error in script "C:\Users\alexa\Desktop\ffxi\FINAL FANTASY XI v2.7.10.nsi" on line 428 -- aborting creation process
Contexte

Cette erreur survient dans la section "XIInstaller", dans le bloc qui gère l’installation de la traduction française :

    Le script extrait lang.pak dans $TEMP\lang_temp avec la commande Nsis7z::Extract.
    Ensuite, il tente d’installer les fichiers extraits dans $GameDir avec File /r "$TEMP\lang_temp\*.*".
    MakeNSIS indique qu’aucun fichier n’a été trouvé dans $TEMP\lang_temp, ce qui provoque l’échec.

Cause probable

L’instruction File /r "$TEMP\lang_temp\*.*" est utilisée pour inclure des fichiers dans l’installateur au moment de la compilation, mais $TEMP\lang_temp est un dossier temporaire créé à l’exécution (runtime), pas à la compilation (compile-time). NSIS attend des fichiers physiques présents sur votre disque au moment où vous compilez le script, pas des fichiers qui seront générés dynamiquement pendant l’installation. C’est une erreur courante lorsqu’on mélange des opérations de runtime (comme l’extraction) avec des commandes de compilation (comme File).
Solution proposée

Pour corriger cela, vous ne devez pas utiliser File pour déplacer les fichiers extraits de $TEMP\lang_temp vers $GameDir. À la place, utilisez CopyFiles, qui est une commande d’exécution (runtime) adaptée à ce cas. Voici comment modifier cette partie du script :
Code original ( lignes autour de 428 )
nsis
DetailPrint "Installing French translation files to $GameDir..."
SetOutPath "$GameDir"
File /r "$TEMP\lang_temp\*.*"
Code corrigé
nsis
DetailPrint "Installing French translation files to $GameDir..."
SetOutPath "$GameDir"
CopyFiles /SILENT "$TEMP\lang_temp\*.*" "$GameDir"
Explication

    SetOutPath "$GameDir" : Définit le dossier de destination pour les opérations suivantes.
    CopyFiles /SILENT "$TEMP\lang_temp\*.*" "$GameDir" : Copie récursivement tous les fichiers extraits de $TEMP\lang_temp vers $GameDir pendant l’installation, sans nécessiter qu’ils soient présents au moment de la compilation.
    /SILENT : Supprime les messages de progression pour une installation plus fluide.

Script ajusté (extrait)

Voici comment cette partie de la section devrait ressembler après correction :
nsis
${If} $FrenchTranslation == "yes"
  DetailPrint "Extracting lang.pak to temporary directory..."
  IfFileExists "$EXEDIR\archives\lang.pak" 0 lang_missing
    CreateDirectory "$TEMP\lang_temp"
    Nsis7z::Extract "$EXEDIR\archives\lang.pak" "-o$TEMP\lang_temp"
    DetailPrint "Checking extracted files in $TEMP\lang_temp..."
    FindFirst $0 $1 "$TEMP\lang_temp\*.*"
    check_loop:
      StrCmp $1 "" check_done
      StrCmp $1 "." check_next
      StrCmp $1 ".." check_next
      DetailPrint "Found file: $TEMP\lang_temp\$1"
    check_next:
      FindNext $0 $1
      Goto check_loop
    check_done:
      FindClose $0
    DetailPrint "Installing French translation files to $GameDir..."
    SetOutPath "$GameDir"
    CopyFiles /SILENT "$TEMP\lang_temp\*.*" "$GameDir"
    DetailPrint "Verifying files in $GameDir..."
    ${If} ${FileExists} "$GameDir\*.*"
      DetailPrint "Files successfully installed to $GameDir."
    ${Else}
      DetailPrint "Warning: No files found in $GameDir after installation!"
    ${EndIf}
    DetailPrint "Cleaning up temporary directory $TEMP\lang_temp..."
    RMDir /r "$TEMP\lang_temp"
    ${If} $IsUpdate == "no"
      WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "Language" 0x00000002
    ${EndIf}
    DetailPrint "French translation files installed/updated in $GameDir"
    Goto lang_done
  lang_missing:
    MessageBox MB_OK|MB_ICONSTOP "Erreur : lang.pak introuvable dans $EXEDIR\archives ! Traduction française non installée."
  lang_done:
${Else}
  DetailPrint "French translation skipped by user."
${EndIf}
Étapes pour résoudre le problème

    Ouvrez votre fichier FINAL FANTASY XI v2.7.10.nsi dans un éditeur de texte (comme Notepad++).
    Remplacez la ligne File /r "$TEMP\lang_temp\*.*" (vers la ligne 428) par CopyFiles /SILENT "$TEMP\lang_temp\*.*" "$GameDir".
    Vérifiez également la section pour les textures HD (autour des lignes suivantes) ; elle utilise probablement la même logique et pourrait nécessiter la même correction (remplacer File /r "$TEMP\hd_textures_temp\*.*" par CopyFiles /SILENT "$TEMP\hd_textures_temp\*.*" "$GameDir").
    Enregistrez le fichier.
    Recompilez avec MakeNSIS : makensis "C:\Users\alexa\Desktop\ffxi\FINAL FANTASY XI v2.7.10.nsi".

Vérification supplémentaire

Assurez-vous que :

    Le fichier lang.pak existe dans C:\Users\alexa\Desktop\ffxi\archives\. S’il n’est pas là, l’extraction échouera, et aucun fichier ne sera copié.
    Les permissions sont correctes pour écrire dans $GameDir (exige des droits d’administrateur).

Résultat attendu

Avec cette correction, MakeNSIS devrait compiler le script sans erreur, et l’installateur copiera les fichiers extraits de lang.pak pendant l’installation.

Si vous voulez que je vérifie d’autres parties du script ou que je génère une image pour illustrer l’interface, dites-le-moi ! Comment puis-je vous aider davantage ?
MakeNSIS v3.10 - Copyright 1999-2023 Contributors
See the file COPYING for license details.
Credits can be found in the Users Manual.

Processing config: C:\Program Files (x86)\NSIS\nsisconf.nsh
Processing default plugins: "C:\Program Files (x86)\NSIS\Plugins\x86-unicode\*.dll"
 + AdvSplash::show
 + Banner::destroy
 + Banner::getWindow
 + Banner::show
 + BgImage::AddImage
 + BgImage::AddText
 + BgImage::Clear
 + BgImage::Destroy
 + BgImage::Redraw
 + BgImage::SetBg
 + BgImage::SetReturn
 + BgImage::Sound
 + Dialer::AttemptConnect
 + Dialer::AutodialHangup
 + Dialer::AutodialOnline
 + Dialer::AutodialUnattended
 + Dialer::GetConnectedState
 + INetC::get
 + INetC::head
 + INetC::post
 + INetC::put
 + InstallOptions::dialog
 + InstallOptions::initDialog
 + InstallOptions::make_unicode
 + InstallOptions::show
 + LangDLL::LangDialog
 + Math::Script
 + NSISdl::download
 + NSISdl::download_quiet
 + NScurl::cancel
 + NScurl::echo
 + NScurl::enumerate
 + NScurl::escape
 + NScurl::http
 + NScurl::md5
 + NScurl::query
 + NScurl::sha1
 + NScurl::sha256
 + NScurl::unescape
 + NScurl::wait
 + Splash::show
 + StartMenu::Init
 + StartMenu::Select
 + StartMenu::Show
 + System::Alloc
 + System::Call
 + System::Copy
 + System::Free
 + System::Get
 + System::Int64Op
 + System::Store
 + System::StrAlloc
 + TypeLib::GetLibVersion
 + TypeLib::Register
 + TypeLib::UnRegister
 + UserInfo::GetAccountType
 + UserInfo::GetName
 + UserInfo::GetOriginalAccountType
 + VPatch::GetFileCRC32
 + VPatch::GetFileMD5
 + VPatch::vpatchfile
 + nsDialogs::Create
 + nsDialogs::CreateControl
 + nsDialogs::CreateItem
 + nsDialogs::CreateTimer
 + nsDialogs::GetUserData
 + nsDialogs::KillTimer
 + nsDialogs::OnBack
 + nsDialogs::OnChange
 + nsDialogs::OnClick
 + nsDialogs::OnNotify
 + nsDialogs::SelectFileDialog
 + nsDialogs::SelectFolderDialog
 + nsDialogs::SetRTL
 + nsDialogs::SetUserData
 + nsDialogs::Show
 + nsExec::Exec
 + nsExec::ExecToLog
 + nsExec::ExecToStack
 + nsis7z::Extract
 + nsis7z::ExtractWithCallback
 + nsis7z::ExtractWithDetails

!define: "MUI_INSERT_NSISCONF"=""

Changing directory to: "C:\Users\alexa\Desktop\ffxi"

Processing script file: "C:\Users\alexa\Desktop\ffxi\FINAL FANTASY XI v2.7.10.nsi" (UTF8)
SetCompressor: /FINAL lzma
!include: "C:\Program Files (x86)\NSIS\Include\MUI2.nsh" (UTF8)
!include: "C:\Program Files (x86)\NSIS\Contrib\Modern UI 2\MUI2.nsh" (UTF8)
NSIS Modern User Interface version 2.1 - Copyright 2002-2023 Joost Verburg (C:\Program Files (x86)\NSIS\Contrib\Modern UI 2\MUI2.nsh:14)
!include: closed: "C:\Program Files (x86)\NSIS\Contrib\Modern UI 2\MUI2.nsh"
!include: closed: "C:\Program Files (x86)\NSIS\Include\MUI2.nsh"
!include: "C:\Program Files (x86)\NSIS\Include\LogicLib.nsh" (UTF8)
!include: closed: "C:\Program Files (x86)\NSIS\Include\LogicLib.nsh"
!include: "C:\Program Files (x86)\NSIS\Include\FileFunc.nsh" (UTF8)
!include: closed: "C:\Program Files (x86)\NSIS\Include\FileFunc.nsh"
!include: "C:\Program Files (x86)\NSIS\Include\nsDialogs.nsh" (UTF8)
!include: closed: "C:\Program Files (x86)\NSIS\Include\nsDialogs.nsh"
!define: "MUI_ICON"="installer.ico"
!define: "MUI_LANGDLL_WINDOWTITLE"="Installer"
!define: "MUI_WELCOMEFINISHPAGE_BITMAP"="background.bmp"
!define: "MUI_WELCOMEPAGE_TITLE"="Installer"
!define: "MUI_LICENSEPAGE_CHECKBOX"=""
!addplugindir: "..\Release"
!addplugindir: "."
Name: "FINAL FANTASY XI"
OutFile: "FINAL FANTASY XI.exe"
InstallDir: "$PROGRAMFILES\PlayOnline"
InstallRegKey: "HKCU\Software\FINAL FANTASY XI\InstallPath"
!define: "MUI_ABORTWARNING"=""
LangString: "DEPENDENCIES_TITLE" 1033 "Installation Options"
LangString: "DEPENDENCIES_SUBTITLE" 1033 "Select dependencies to install."
LangString: "DEPENDENCIES_TITLE" 1036 "Options d'installation"
LangString: "DEPENDENCIES_SUBTITLE" 1036 "Sélectionnez les dépendances à installer."
LangString: "TRANSLATION_TITLE" 1033 "Additional Options"
LangString: "TRANSLATION_SUBTITLE" 1033 "Choose your texture preferences."
LangString: "TRANSLATION_TITLE" 1036 "Options supplémentaires"
LangString: "TRANSLATION_SUBTITLE" 1036 "Choisissez vos préférences de langue et de textures."
LangString: "CHECKBOX_FRENCH" 1033 "N/A"
LangString: "CHECKBOX_FRENCH" 1036 "Installer la traduction française"
LangString: "CHECKBOX_HD" 1033 "Install HD Textures Pack"
LangString: "CHECKBOX_HD" 1036 "Installer le pack de textures HD"
LangString: "DEP_VS2010" 1033 "Visual Studio 2010 Redistributable"
LangString: "DEP_VS2010" 1036 "Redistribuable Visual Studio 2010"
LangString: "DEP_VS2012" 1033 "Visual Studio 2012 Redistributable"
LangString: "DEP_VS2012" 1036 "Redistribuable Visual Studio 2012"
LangString: "DEP_VS2013" 1033 "Visual Studio 2013 Redistributable"
LangString: "DEP_VS2013" 1036 "Redistribuable Visual Studio 2013"
LangString: "DEP_VS2015" 1033 "Visual Studio 2015 Redistributable"
LangString: "DEP_VS2015" 1036 "Redistribuable Visual Studio 2015"
LangString: "DEP_DOTNET40" 1033 ".NET Framework 4.0"
LangString: "DEP_DOTNET40" 1036 ".NET Framework 4.0"
LangString: "DEP_DOTNET45" 1033 ".NET Framework 4.5"
LangString: "DEP_DOTNET45" 1036 ".NET Framework 4.5"

LangString: "DEP_DIRECTPLAY" 1033 "DirectPlay"
LangString: "DEP_DIRECTPLAY" 1036 "DirectPlay"
Var: "FrenchTranslation"
Var: "InstallVS2010"
Var: "InstallVS2012"
Var: "InstallVS2013"
Var: "InstallVS2015"
Var: "InstallDotNet40"
Var: "InstallDotNet45"
Var: "InstallDirectPlay"
Var: "InstallHDTextures"
Var: "IsUpdate"
Var: "GameDir"
!insertmacro: MUI_PAGE_WELCOME
!insertmacro: end of MUI_PAGE_WELCOME
!define: "MUI_PAGE_CUSTOMFUNCTION_PRE"="LicensePre"
!insertmacro: MUI_PAGE_LICENSE
!insertmacro: end of MUI_PAGE_LICENSE
Page: Custom (creator:DependenciesOptionPre) (leave:DependenciesOptionPageLeave)
Page: Custom (creator:DependenciesPre) (leave:DependenciesLeave)
Page: Custom (creator:TranslationPage) (leave:TranslationPageLeave)
!insertmacro: MUI_PAGE_DIRECTORY
!insertmacro: end of MUI_PAGE_DIRECTORY
!insertmacro: MUI_PAGE_INSTFILES
!insertmacro: end of MUI_PAGE_INSTFILES
!insertmacro: MUI_PAGE_FINISH
!insertmacro: end of MUI_PAGE_FINISH
!insertmacro: MUI_LANGUAGE
!insertmacro: end of MUI_LANGUAGE
!insertmacro: MUI_LANGUAGE
!insertmacro: end of MUI_LANGUAGE
Function: ".onInit"
StrCpy $IsUpdate "no" () ()
StrCpy $INSTDIR "$PROGRAMFILES\PlayOnline" () ()
ClearErrors: 
ReadRegStr $0 HKCU\Software\FINAL FANTASY XI\InstallPath
!insertmacro: _If
!insertmacro: end of _If
!insertmacro: _If
!insertmacro: end of _If
StrCpy $IsUpdate "yes" () ()
StrCpy $INSTDIR "$0" () ()
DetailPrint: "Installation existante détectée via le registre à : $INSTDIR"
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Clé de registre trouvée ($0), mais dossier introuvable."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Aucune clé de registre trouvée dans HKCU."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
!insertmacro: _If
!insertmacro: end of _If
StrCpy $IsUpdate "yes" () ()
StrCpy $INSTDIR "$PROGRAMFILES\PlayOnline" () ()
DetailPrint: "Installation existante détectée dans le chemin par défaut : $INSTDIR"
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Aucune installation détectée dans le chemin par défaut."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Mise à jour détectée. Installation dans : $INSTDIR"
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Aucune installation existante. Nouvelle installation dans : $INSTDIR"
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: MUI_LANGDLL_DISPLAY
!insertmacro: end of MUI_LANGDLL_DISPLAY
FunctionEnd
Function: "StrStr"
Exch($R1,0)
Exch(st(1),0)
Exch($R2,0)
Push: $R3
Push: $R4
Push: $R5
StrLen $R3 "$R1"
StrCpy $R4 "0" () ()
StrCpy $R5 "$R2" ($R3) ($R4)
StrCmp "$R5" "$R1" equal=found, nonequal=
StrCmp "$R5" "" equal=notfound, nonequal=
IntOp: $R4=$R4+1
Goto: loop
StrCpy $R1 "$R4" () ()
Goto: done
StrCpy $R1 "-1" () ()
Pop: $R5
Pop: $R4
Pop: $R3
Pop: $R2
Exch($R1,0)
FunctionEnd
Function: "CopyFilesRecursively"
Exch($0,0)
Exch(st(1),0)
Exch($R0,0)
Push: $R1
Push: $R2
Push: $R3
FindFirst: spec="$R0\*.*" handle=$R1 output=$R2
StrCmp "$R2" "" equal=done, nonequal=
StrCmp "$R2" "." equal=next, nonequal=
StrCmp "$R2" ".." equal=next, nonequal=
IfFileExists: "$R0\$R2\*.*" ? 0 : file
CreateDirectory: "$0\$R2"
Push: $0\$R2
Push: $R0\$R2
Call "CopyFilesRecursively"
Pop: $R0
Pop: $0
Goto: next
!insertmacro: GetFileNameCall
!insertmacro: end of GetFileNameCall
IfFileExists: "$0\$R3" ? 0 : copy
Delete: "$0\$R3"
CopyFiles: (silent) "$R0\$R2" -> "$0", size=0KB
FindNext: handle=$R1 output=$R2
Goto: loop
FindClose: $R1
Pop: $R3
Pop: $R2
Pop: $R1
Pop: $R0
Pop: $0
FunctionEnd
Function: "LicensePre"
!insertmacro: _If
!insertmacro: end of _If
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
FunctionEnd
Function: "DependenciesOptionPre"
!insertmacro: _If
!insertmacro: end of _If
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: MUI_HEADER_TEXT
!insertmacro: end of MUI_HEADER_TEXT
Plugin command: Create 1018
Pop: $0
!insertmacro: _If
!insertmacro: end of _If
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 0u 100% 12u $(DEP_VS2010)
Pop: $InstallVS2010
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallVS2010,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 20u 100% 12u $(DEP_VS2012)
Pop: $InstallVS2012
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallVS2012,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 40u 100% 12u $(DEP_VS2013)
Pop: $InstallVS2013
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallVS2013,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 60u 100% 12u $(DEP_VS2015)
Pop: $InstallVS2015
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallVS2015,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check

Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 80u 100% 12u $(DEP_DOTNET40)
Pop: $InstallDotNet40
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallDotNet40,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 100u 100% 12u $(DEP_DOTNET45)
Pop: $InstallDotNet45
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallDotNet45,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 120u 100% 12u $(DEP_DIRECTPLAY)
Pop: $InstallDirectPlay
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallDirectPlay,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: Show
FunctionEnd
Function: "DependenciesOptionPageLeave"
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallVS2010,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallVS2010 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallVS2010 "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallVS2012,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallVS2012 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallVS2012 "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallVS2013,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallVS2013 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallVS2013 "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallVS2015,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallVS2015 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallVS2015 "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallDotNet40,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallDotNet40 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallDotNet40 "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallDotNet45,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallDotNet45 "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallDotNet45 "no" () ()

!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallDirectPlay,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallDirectPlay "yes" () ()
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallDirectPlay "no" () ()
!insertmacro: _EndIf
!insertmacro: end of _EndIf
FunctionEnd
Function: "DependenciesPre"
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Update detected, dependencies skipped."
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
DetailPrint: "Checking selected dependencies..."
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing Visual Studio 2010 Redistributable..."
File: "VS2010.exe"->"$TEMP\VS2010.exe" [compress] 8993744 bytes
ExecWait: "$TEMP\VS2010.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Visual Studio 2010 Redistributable skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing Visual Studio 2012 Redistributable..."
File: "VS2012.exe"->"$TEMP\VS2012.exe" [compress] 6351552/6554576 bytes
ExecWait: "$TEMP\VS2012.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Visual Studio 2012 Redistributable skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing Visual Studio 2013 Redistributable..."
File: "VS2013.exe"->"$TEMP\VS2013.exe" [compress] 6295713/6510544 bytes
ExecWait: "$TEMP\VS2013.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Visual Studio 2013 Redistributable skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing Visual Studio 2015 Redistributable..."
File: "VS2015.exe"->"$TEMP\VS2015.exe" [compress] 12801598/13767776 bytes
ExecWait: "$TEMP\VS2015.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Visual Studio 2015 Redistributable skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing .NET Framework 4.0..."
File: "dotNetFx40_Full_x86_x64.exe"->"$TEMP\dotNetFx40_Full_x86_x64.exe" [compress] 50449456 bytes
ExecWait: "$TEMP\dotNetFx40_Full_x86_x64.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: ".NET Framework 4.0 skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Installing .NET Framework 4.5..."
File: "dotNet45.exe"->"$TEMP\dotNet45.exe" [compress] 69999448 bytes
ExecWait: "$TEMP\dotNet45.exe /install /passive /norestart" (->)
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: ".NET Framework 4.5 skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Enabling DirectPlay..."
File: "nsExec.dll"->"$PLUGINSDIR\nsExec.dll" [compress] 3490/7168 bytes
Plugin command: Exec dism /online /Enable-Feature /FeatureName:DirectPlay /All
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "DirectPlay skipped."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
DetailPrint: "Dependencies processed based on user selection."
FunctionEnd
Function: "DependenciesLeave"
FunctionEnd
Function: "TranslationPage"
!insertmacro: MUI_HEADER_TEXT
!insertmacro: end of MUI_HEADER_TEXT
Plugin command: Create 1018
Pop: $0
!insertmacro: _If
!insertmacro: end of _If
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 0u 100% 12u $(CHECKBOX_FRENCH)
Pop: $FrenchTranslation
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($FrenchTranslation,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 20u 100% 12u $(CHECKBOX_HD)
Pop: $InstallHDTextures
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallHDTextures,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
!insertmacro: _Else
!insertmacro: end of _Else
Plugin command: CreateControl BUTTON 0x40000000|0x10000000|0x04000000|0x00010000|0x00000000|0x00000C00|0x00000003|0x00002000 0 0 0u 100% 12u $(CHECKBOX_HD)
Pop: $InstallHDTextures
!insertmacro: __NSD_Check
!insertmacro: __NSD_SetState
SendMessage:($InstallHDTextures,0x00F1,1,0)
!insertmacro: end of __NSD_SetState
!insertmacro: end of __NSD_Check
!insertmacro: _EndIf
!insertmacro: end of _EndIf
Plugin command: Show
FunctionEnd
Function: "TranslationPageLeave"
!insertmacro: _If
!insertmacro: end of _If
!insertmacro: __NSD_GetState
SendMessage:(->$1)($FrenchTranslation,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $FrenchTranslation "yes" () ()
DetailPrint: "French translation selected: $FrenchTranslation"
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $FrenchTranslation "no" () ()
DetailPrint: "French translation not selected: $FrenchTranslation"
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: __NSD_GetState
SendMessage:(->$2)($InstallHDTextures,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallHDTextures "yes" () ()
DetailPrint: "HD textures selected: $InstallHDTextures"
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallHDTextures "no" () ()
DetailPrint: "HD textures not selected: $InstallHDTextures"
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _Else
!insertmacro: end of _Else
!insertmacro: __NSD_GetState
SendMessage:(->$1)($InstallHDTextures,0x00F0,0,0)
!insertmacro: end of __NSD_GetState
!insertmacro: _If
!insertmacro: end of _If
StrCpy $InstallHDTextures "yes" () ()
DetailPrint: "HD textures selected: $InstallHDTextures"
!insertmacro: _Else
!insertmacro: end of _Else
StrCpy $InstallHDTextures "no" () ()
DetailPrint: "HD textures not selected: $InstallHDTextures"
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _EndIf
!insertmacro: end of _EndIf
FunctionEnd
Section: "XIInstaller" ->(XIInstaller)
AddSize: 14000000 kb
SetOutPath: "$INSTDIR"
File: "installer.ico" [compress] 17960/112612 bytes
StrCpy $GameDir "$INSTDIR\SquareEnix\FINAL FANTASY XI" () ()
!insertmacro: _If
!insertmacro: end of _If
CreateDirectory: "$GameDir"
DetailPrint: "Extracting game files from data.pak to $GameDir..."
IfFileExists: "$EXEDIR\archives\data.pak" ? 0 : data_missing
File: "nsis7z.dll"->"$PLUGINSDIR\nsis7z.dll" [compress] 187205/400384 bytes
Plugin command: Extract $EXEDIR\archives\data.pak -o$TEMP\data_extract
Push: $TEMP\data_extract
Push: $GameDir
Call "CopyFilesRecursively"
RMDir: /r "$TEMP\data_extract"
Goto: data_done
MessageBox: 16: "Error: data.pak not found in $EXEDIR\archives!"
Abort: ""
!insertmacro: _EndIf
!insertmacro: end of _EndIf
DetailPrint: "Checking French translation selection: $FrenchTranslation"
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Extracting lang.pak to temporary directory..."
IfFileExists: "$EXEDIR\archives\lang.pak" ? 0 : lang_missing
CreateDirectory: "$TEMP\lang_temp"
Plugin command: Extract $EXEDIR\archives\lang.pak -o$TEMP\lang_temp
DetailPrint: "Checking extracted files in $TEMP\lang_temp..."
FindFirst: spec="$TEMP\lang_temp\*.*" handle=$0 output=$1
StrCmp "$1" "" equal=check_done, nonequal=
StrCmp "$1" "." equal=check_next, nonequal=
StrCmp "$1" ".." equal=check_next, nonequal=
DetailPrint: "Found file: $TEMP\lang_temp\$1"
FindNext: handle=$0 output=$1
Goto: check_loop
FindClose: $0
DetailPrint: "Installing French translation files to $GameDir..."
SetOutPath: "$GameDir"
CopyFiles: (silent) "$TEMP\lang_temp\*.*" -> "$GameDir", size=0KB
DetailPrint: "Verifying files in $GameDir..."
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Files successfully installed to $GameDir."
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "Warning: No files found in $GameDir after installation!"
!insertmacro: _EndIf
!insertmacro: end of _EndIf
DetailPrint: "Cleaning up temporary directory $TEMP\lang_temp..."
RMDir: /r "$TEMP\lang_temp"
!insertmacro: _If
!insertmacro: end of _If
WriteRegDWORD: HKLM\SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI\Language=0x00000002
!insertmacro: _EndIf
!insertmacro: end of _EndIf
DetailPrint: "French translation files installed/updated in $GameDir"
Goto: lang_done
MessageBox: 16: "Erreur : lang.pak introuvable dans $EXEDIR\archives ! Traduction française non installée."
!insertmacro: _Else
!insertmacro: end of _Else
DetailPrint: "French translation skipped by user."
!insertmacro: _EndIf
!insertmacro: end of _EndIf
!insertmacro: _If
!insertmacro: end of _If
DetailPrint: "Extracting hd_textures.pak to temporary directory..."
IfFileExists: "$EXEDIR\archives\hd_textures.pak" ? 0 : hd_missing
CreateDirectory: "$TEMP\hd_textures_temp"
Plugin command: Extract $EXEDIR\archives\hd_textures.pak -o$TEMP\hd_textures_temp
DetailPrint: "Checking extracted files in $TEMP\hd_textures_temp..."
FindFirst: spec="$TEMP\hd_textures_temp\*.*" handle=$0 output=$1
StrCmp "$1" "" equal=hd_check_done, nonequal=
StrCmp "$1" "." equal=hd_check_next, nonequal=
StrCmp "$1" ".." equal=hd_check_next, nonequal=
DetailPrint: "Found file: $TEMP\hd_textures_temp\$1"
FindNext: handle=$0 output=$1
Goto: hd_check_loop
FindClose: $0
DetailPrint: "Installing HD texture files to $GameDir..."
SetOutPath: "$GameDir"
File: Returning to: "$TEMP\hd_textures_temp"
File: "$TEMP\hd_textures_temp\*.*" -> no files found.
Usage: File [/nonfatal] [/a] ([/r] [/x filespec [...]] filespec [...] |
   /oname=outfile one_file_only)
Error in script "C:\Users\alexa\Desktop\ffxi\FINAL FANTASY XI v2.7.10.nsi" on line 468 -- aborting creation process

Je vois que vous avez partagé une nouvelle sortie de MakeNSIS pour le script "FINAL FANTASY XI v2.7.10.nsi". Il semble que vous ayez appliqué ma suggestion précédente pour remplacer File /r "$TEMP\lang_temp\*.*" par CopyFiles /SILENT "$TEMP\lang_temp\*.*" "$GameDir" dans la section de la traduction française, ce qui a résolu l’erreur à la ligne 428. Cependant, une erreur similaire persiste à la ligne 468, cette fois dans la section des textures HD. Analysons cela et corrigeons-le en français.
Analyse de l’erreur

L’erreur affichée est :
text
File: "$TEMP\hd_textures_temp\*.*" -> no files found.
Usage: File [/nonfatal] [/a] ([/r] [/x filespec [...]] filespec [...] |
   /oname=outfile one_file_only)
Error in script "C:\Users\alexa\Desktop\ffxi\FINAL FANTASY XI v2.7.10.nsi" on line 468 -- aborting creation process
Contexte

Cette erreur se produit dans la section "XIInstaller", dans le bloc qui gère l’installation des textures HD :

    Le script extrait hd_textures.pak dans $TEMP\hd_textures_temp avec Nsis7z::Extract.
    Ensuite, il tente d’installer les fichiers extraits dans $GameDir avec File /r "$TEMP\hd_textures_temp\*.*".
    MakeNSIS indique qu’aucun fichier n’a été trouvé dans $TEMP\hd_textures_temp, car cette commande attend des fichiers présents au moment de la compilation, pas des fichiers générés à l’exécution.

Cause

Comme pour l’erreur précédente avec lang.pak, l’instruction File /r "$TEMP\hd_textures_temp\*.*" est une commande de compilation (compile-time), alors que les fichiers dans $TEMP\hd_textures_temp sont créés dynamiquement pendant l’installation (runtime). NSIS ne peut pas inclure des fichiers qui n’existent pas encore sur le disque au moment où vous compilez le script.
Solution proposée

Remplacez File /r "$TEMP\hd_textures_temp\*.*" par CopyFiles /SILENT "$TEMP\hd_textures_temp\*.*" "$GameDir", comme nous l’avons fait pour la traduction française. Cela permet de copier les fichiers extraits à l’exécution, ce qui est le comportement souhaité.
Code original (autour de la ligne 468)
nsis
DetailPrint "Installing HD texture files to $GameDir..."
SetOutPath "$GameDir"
File /r "$TEMP\hd_textures_temp\*.*"
Code corrigé
nsis
DetailPrint "Installing HD texture files to $GameDir..."
SetOutPath "$GameDir"
CopyFiles /SILENT "$TEMP\hd_textures_temp\*.*" "$GameDir"
Explication

    CopyFiles /SILENT : Copie tous les fichiers de $TEMP\hd_textures_temp vers $GameDir pendant l’installation, sans nécessiter leur présence à la compilation.
    SetOutPath : Reste nécessaire pour définir le répertoire de travail, bien que CopyFiles spécifie explicitement la destination.

Script ajusté (extrait pour les textures HD)

Voici la section corrigée pour les textures HD :
nsis
${If} $InstallHDTextures == "yes"
  DetailPrint "Extracting hd_textures.pak to temporary directory..."
  IfFileExists "$EXEDIR\archives\hd_textures.pak" 0 hd_missing
    CreateDirectory "$TEMP\hd_textures_temp"
    Nsis7z::Extract "$EXEDIR\archives\hd_textures.pak" "-o$TEMP\hd_textures_temp"
    DetailPrint "Checking extracted files in $TEMP\hd_textures_temp..."
    FindFirst $0 $1 "$TEMP\hd_textures_temp\*.*"
    hd_check_loop:
      StrCmp $1 "" hd_check_done
      StrCmp $1 "." hd_check_next
      StrCmp $1 ".." hd_check_next
      DetailPrint "Found file: $TEMP\hd_textures_temp\$1"
    hd_check_next:
      FindNext $0 $1
      Goto hd_check_loop
    hd_check_done:
      FindClose $0
    DetailPrint "Installing HD texture files to $GameDir..."
    SetOutPath "$GameDir"
    CopyFiles /SILENT "$TEMP\hd_textures_temp\*.*" "$GameDir"
    DetailPrint "Verifying files in $GameDir..."
    ${If} ${FileExists} "$GameDir\*.*"
      DetailPrint "Files successfully installed to $GameDir."
    ${Else}
      DetailPrint "Warning: No files found in $GameDir after installation!"
    ${EndIf}
    DetailPrint "Cleaning up temporary directory $TEMP\hd_textures_temp..."
    RMDir /r "$TEMP\hd_textures_temp"
    DetailPrint "HD texture files installed/updated in $GameDir"
    Goto hd_done
  hd_missing:
    MessageBox MB_OK|MB_ICONSTOP "Erreur : hd_textures.pak introuvable dans $EXEDIR\archives ! Textures HD non installées."
  hd_done:
${Else}
  DetailPrint "HD textures pack skipped by user."
${EndIf}

  ${If} $IsUpdate == "yes"
    CreateDirectory "$INSTDIR\..\Ashita\config\boot"
  ${Else}
    CreateDirectory "$INSTDIR\Ashita\config\boot"
  ${EndIf}

  ${If} $IsUpdate == "yes"
    DetailPrint "Existing installation detected, checking Ashita configuration..."
    IfFileExists "$INSTDIR\..\Ashita\config\boot\Private Server.xml" 0 config_missing
      ClearErrors
      FileOpen $0 "$INSTDIR\..\Ashita\config\boot\Private Server.xml" r
      StrCpy $1 ""
read_loop:
      FileRead $0 $2
      ${If} ${Errors}
        Goto read_done
      ${EndIf}
      Push $2
      Push '<setting name="boot_file">'
      Call StrStr
      Pop $3
      ${If} $3 != -1
        StrLen $4 '<setting name="boot_file">'
        StrCpy $1 $2 "" $4
        Push $1
        Push "</setting>"
        Call StrStr
        Pop $5
        StrCpy $1 $1 $5
        Goto read_done
      ${EndIf}
      Goto read_loop
read_done:
      FileClose $0
      StrCpy $3 "$INSTDIR\..\Ashita\ffxi-bootmod\xiloader.exe"
      ${If} $1 != $3
        DetailPrint "Ashita configuration incorrect (boot_file: $1), updating to $3..."
        Goto write_config
      ${Else}
        DetailPrint "Ashita configuration is correct (boot_file: $1)."
        Goto config_done
      ${EndIf}
    config_missing:
      DetailPrint "Ashita configuration file missing, creating it..."
      Goto write_config
  ${Else}
    DetailPrint "New installation, creating Ashita configuration..."
    Goto write_config
  ${EndIf}

write_config:
  ${If} $IsUpdate == "yes"
    FileOpen $0 "$INSTDIR\..\Ashita\config\boot\Private Server.xml" w
  ${Else}
    FileOpen $0 "$INSTDIR\Ashita\config\boot\Private Server.xml" w
  ${EndIf}
  FileWrite $0 '<?xml version="1.0" encoding="utf-8" standalone="yes"?>$\r$\n'
  FileWrite $0 "<settings>$\r$\n"
  FileWrite $0 '  <setting name="config_name">VanadielXI (Private Server)</setting>$\r$\n'
  FileWrite $0 '  <setting name="auto_close">True</setting>$\r$\n'
  FileWrite $0 '  <setting name="language">2</setting>$\r$\n'
  FileWrite $0 '  <setting name="pol_version">2</setting>$\r$\n'
  FileWrite $0 '  <setting name="test_server">False</setting>$\r$\n'
  FileWrite $0 '  <setting name="log_level">4</setting>$\r$\n'
  FileWrite $0 '  <setting name="windowed">True</setting>$\r$\n'
  FileWrite $0 '  <setting name="show_border">False</setting>$\r$\n'
  FileWrite $0 '  <setting name="unhook_mouse">False</setting>$\r$\n'
  FileWrite $0 '  <setting name="window_x">1920</setting>$\r$\n'
  FileWrite $0 '  <setting name="window_y">1080</setting>$\r$\n'
  FileWrite $0 '  <setting name="startpos_x">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="startpos_y">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="background_x">1920</setting>$\r$\n'
  FileWrite $0 '  <setting name="background_y">1080</setting>$\r$\n'
  FileWrite $0 '  <setting name="menu_x">1920</setting>$\r$\n'
  FileWrite $0 '  <setting name="menu_y">1080</setting>$\r$\n'
  ${If} $IsUpdate == "yes"
    FileWrite $0 '  <setting name="boot_file">$INSTDIR\..\Ashita\ffxi-bootmod\xiloader.exe</setting>$\r$\n'
  ${Else}
    FileWrite $0 '  <setting name="boot_file">$INSTDIR\Ashita\ffxi-bootmod\xiloader.exe</setting>$\r$\n'
  ${EndIf}
  FileWrite $0 '  <setting name="boot_command">--user XX --pass XX --hairpin</setting>$\r$\n'
  FileWrite $0 '  <setting name="startup_script">Default.txt</setting>$\r$\n'
  FileWrite $0 '  <setting name="d3d_presentparams_buffercount">1</setting>$\r$\n'
  FileWrite $0 '  <setting name="d3d_presentparams_swapeffect">1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_mipmapping">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_bumpmapping">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_gammabase">0</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_envanimation">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_texturecompression">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_mapcompression">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_fontcompression">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_soundenabled">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_soundalwayson">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_showopeningmovie">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_simplecharcreation">-1</setting>$\r$\n'
  FileWrite $0 '  <setting name="game_stablegraphics">-1</setting>$\r$\n'
  FileWrite $0 "</settings>$\r$\n"
  FileClose $0
  ${If} $IsUpdate == "yes"
    DetailPrint "Private Server.xml created/updated in $INSTDIR\..\Ashita\config\boot with dynamic path."
  ${Else}
    DetailPrint "Private Server.xml created/updated in $INSTDIR\Ashita\config\boot with dynamic path."
  ${EndIf}
config_done:

  ${If} $IsUpdate == "no"
    DetailPrint "Updating registry settings..."
    SetRegView 64
    WriteRegStr HKCU "Software\FINAL FANTASY XI" "InstallPath" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "DisplayName" "Uninstall FINAL FANTASY XI"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "UninstallString" "$GameDir\Uninstall FINAL FANTASY XI.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "QuietUninstallString" "$GameDir\Uninstall FINAL FANTASY XI.exe /S"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "DisplayIcon" "$GameDir\installer.ico"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS" "CommonFilesFolder" "$PROGRAMFILES\Common Files\"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder" "0001" "$GameDir\"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder" "1000" "$INSTDIR\SquareEnix\PlayOnlineViewer"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Interface" "0001" "130b5023"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Interface" "1000" "1304d1e8"
    WriteRegBin HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Product" "0001" 9741e0849e6dc5ec1220cd8c1ecd9649be988450ab9a402c58fbfb50fecae9f3bad2df087753f81d1f33e92a8e4a2faa04dff98ee20508a30fb501134eda95f3f029a5795fa83626a451c3008c52772a1ff31c0c7311d737b1f2f53375887d091a55611511ec3561d55f3a2f252171c73d2eeb09041b801bf03e3cf029869d844d0870d6453da92ee5e03acea1c93a8996abe96dddc6149b648ad02e37ab8767c61d252140618ffa22ac270845ff4419f57670816dd860827536055e29b11463260f64617e7b3c5df923688c664d38c15cfd5b967097cc2022a0135fba2df6589d4fe22e4db2e596903eb45c8a8f30780b29b30ec5e0295da24c6e9168a0590ab762f78359aa022b321feedf8d5e05da9eb59d59625389e5a8c63ba02623705b
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0000" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0001" 0x00000640
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0002" 0x00000384
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0003" 0x00000640
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0004" 0x00000384
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0007" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0011" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0017" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0018" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0019" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0020" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0021" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0022" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0023" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0024" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0028" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0029" 0x0000000c
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0030" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0031" 0x3bc49ba6
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0032" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0033" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0034" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0035" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0036" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0037" 0x00000640
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0038" 0x00000384
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0039" 0x00000001
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0040" 0x00000000
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0041" 0x00000000
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0042" "$GameDir"
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0043" 0x00000000
    WriteRegBin HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "bFirst" 00
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "padsin000" "8,9,13,12,10,0,1,3,2,15,-1,-1,14,-33,-33,32,32,-36,-36,35,35,6,7,5,4,11,-1"
    WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "padmode000" "1,0,1,0,1,1"
    WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer" "FirstBootPlayMovie" 0x00000000
    WriteRegBin HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer" "SPS000" 66c84962897d8dce4d64151db09a4ca4267c07c18b8df49c8f31a4b35a72f34cda1df301ee999021d69a2a941e91797e9b4d6d5db04a362a03ac41cdf89c6e50ed98531f457b017faa35eb0cd4cb0fea6d3852bfed8fa10351e83d64074178269644b322c6e21ef57a32b167199da82164facc60f1623623b8f8a3f3881a6d26bbd15e4dcf04012c1a91a50f2b942fa344644dac419e9aadb22489b813110830cf7a8b305ba06b8bdb8131bf2ab1f29e392f6bf43e47714d39fd00ed10369c647251aa6bc05fcf3c0210e71178ff0fe3df2548963e927f38c3bd205bed21ac6ed12fea4576c534b4bf3128c1d5fc4315f3580d03b21df18c30b11cf125f9132f980f9e7b1d8579f77a8eaf6d6426fc67e50d265f0e13a8bad5bad1bead511761c43e93b67e6428379c7a0c7ba2084db1458af16efa76a77f037484ba7e540e3e07b4f9f34df3d5b6b273174fa2f87ff2527472824fedd498385e3f48374ba7a317964db33826bd56bb5edf4acb3666d83b1accfdde4d0cb1b6a46733fca102d2d246a209d506d7c6869eeafe2dc9ed6ac9e9d64bf84d4f881db3e7425a061de002ab6043b448e9a2078c32517c6a1c9cefc8974f0d21fbcd3b80e08e0a85e915a6889912828a01cc41a8c0046fb033532b6f158ac05e45e33efdf3437643505a1839a303d7838f244f6a82e218947826d508c513a84e06906bd9677cc9226d19a350bef70802d40c7dccbbfe30f93482839f62f5b96a7ea3672e342e81598180f18c388e5615935ee097d0c880a635ab2068e093d6dfc420f49718d86b297dde1a224044311adbba93224182ef211becca81bdcfec40f80fd1a0fdef79ad744ee5329883af56497f8e6f7ed43d842573582afa93cf16cff1ca1d889a72dcdfae4f9a9956d2dfe1c7aabf514180f4f376fbb9d767da165028788aeceecfc775f440e78b3546c4fc162367c3b1ab027a25af51f97d7d11b71ac0988f712477c492775742b41069823320b3723855e5ce3d5c2dc7ae7fb409f5458c40bebe41eb23c39d99a7a09f037b06d881b1a8b4efdf2adfb96b8b9d4dcc51e3f2519a8244fbc5190ec701f73c85b9bab3e1a60d01bb0dd990f875a378aa375e302c1747f5fa99e36613740c76443af4a5d1956521830d82872d43124471af8e8b41984174404066c0cc62b1df99d6296b01496adc5a90e7241dab32ebc640dd19ff15bfd36675f45cfac7e1f0fae90f5664c5c3b4bcca4f730d24f68736e84bd7c50150571613bce014b29beb8282586931a8ceb76d7b5e2b3c3a965f35f84939162bf414cf053188bc7ae02b4a024b69c5bd3a3fa3d561a29498331841c5314a3466b194625a3f5d67e67265898c51fb6a2e62a87866364be2c3cec1389a528301e97e4ab05be3f55fc7498e559593eefff3785b4dc48217e2d1734e0d490ec0bae10b0212758567e64200e7e2b3c39ef302e666b2f4801546a3636805c9533e114b6a323d56133c88a369bda4ab8c203aff022063c816d94b504c2a393e719547a2488c5a16634abe247d292147eb4e794c6a2ce7f2478cedeb3618ce531be72abd9f63173e15cf65c7d21f44e4880b32ac2a9fb16c9378058a51e36c8bba70fdcfcb3e6b6d852f478b92a1c152a9caba215ecdc247008583e6018f3b5c61c1b10de9fe53fd68078ff2c91a57d795114a0863a81e81d5e2c024c30f99be4ec4b923776c5cbd7bd9ccde38f56b6c0180b0c9be4c1bc2307e612702e576b7990bd35fcc8251fa14e86348b8714a6ca8f1c50ae07337143c52120fd420a66a6f88cadd02e49dea36c716b3f845dc4d3fbd8db3baf966cdf68cc7875c3f881d09222cd8a9c099a91b0cf6274dc9d6d679f484d9a9597c106d172c663ce96ad8ba8efb697f6ff1ed074110869dae9159ec4d5a6f4570944db1c4baf0edb35b4e02ac1c4a81cc76d17dc69931120561550f9947b714a6a372e6daf434c08d5b2db1b2433edda30469585f12fc869c266f0cf30cc9f03bba79c9c5de6a99038158118ca4bfa029e6ee6de7d01058095175adb149fb6b520c9b1502d6bd1a220456d7536bce0cae334ce4afcd698c2dcf7c6c016cf7acf516c8193e1a0a0d75ce1f501ca53c40af5d8f5a9316739a8b577ffa2838fb83d9ac01870ec55d0f929f4adff94239a39645d931ac3733356f80f2a5fae14ff057fbaefaebf4ef1288c9e2d287fbb93c57599bb88490bd335911dd2c19ba4588fc1b4f30abdbf1bcb0305afa9670d8e198e0339a52989d3f6b25e44351754b92f66c379a93a84a85a07245d002764886c7e9f6c0249e2b3b00a4652dfb8d3b7972b6de7c1300fb8d01099d1b4bacf9cb59ddce92222f286a86c02425cb736e03c4aa0e032072853648bb2ad4e528db1be1818c5779cd8971a342f92a5c4bb933fed5635ff61589433932ea36ab61ac8720b9b2ae94f3655412d36386dd13bf55f6f49f057ace71f46de4f0a509bf7969569429134e8d9f6b42ed7bd861ba6d8ccad9f6e7bf8f8a22563edc23a448ab1ddb62338cf878a230c72aa6eb4f625cb40edc644739ebaef343c7b9473e3f1389280fc8122f5ba745d824bab71ea3eda0aaeb5224cfb27b89faa6a806e9159fc7e1f215ed5043

    DetailPrint "Registering libraries..."
    RegDLL "$GameDir\FFXi.dll"
    RegDLL "$GameDir\FFXiMain.dll"
    RegDLL "$GameDir\FFXiResource.dll"
    RegDLL "$GameDir\FFXiVersions.dll"
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

    DetailPrint "Creating uninstaller..."
    WriteUninstaller "$GameDir\Uninstall FINAL FANTASY XI.exe"

    DetailPrint "Creating shortcuts..."
    ${If} $IsUpdate == "yes"
      SetOutPath "$INSTDIR\..\Ashita"
      CreateShortcut "$DESKTOP\Play FINAL FANTASY XI.lnk" "$INSTDIR\..\Ashita\Ashita.exe" "" "$INSTDIR\installer.ico"
      CreateDirectory "$SMPROGRAMS\FINAL FANTASY XI"
      CreateShortcut "$SMPROGRAMS\FINAL FANTASY XI\Play FINAL FANTASY XI.lnk" "$INSTDIR\..\Ashita\Ashita.exe" "" "$INSTDIR\installer.ico"
      CreateShortcut "$SMPROGRAMS\FINAL FANTASY XI\Uninstall FINAL FANTASY XI.lnk" "$GameDir\Uninstall FINAL FANTASY XI.exe"
    ${Else}
      SetOutPath "$INSTDIR\Ashita"
      CreateShortcut "$DESKTOP\Play FINAL FANTASY XI.lnk" "$INSTDIR\Ashita\Ashita.exe" "" "$INSTDIR\installer.ico"
      CreateDirectory "$SMPROGRAMS\FINAL FANTASY XI"
      CreateShortcut "$SMPROGRAMS\FINAL FANTASY XI\Play FINAL FANTASY XI.lnk" "$INSTDIR\Ashita\Ashita.exe" "" "$INSTDIR\installer.ico"
      CreateShortcut "$SMPROGRAMS\FINAL FANTASY XI\Uninstall FINAL FANTASY XI.lnk" "$GameDir\Uninstall FINAL FANTASY XI.exe"
    ${EndIf}
  ${EndIf}
SectionEnd

Section "Uninstall"
  ClearErrors
  ReadRegStr $INSTDIR HKCU "Software\FINAL FANTASY XI" "InstallPath"
  ${If} ${Errors}
    ${GetParent} "$EXEDIR" $R0
    StrCpy $INSTDIR "$R0"
    DetailPrint "Warning: Registry path not found, using $INSTDIR as fallback."
  ${EndIf}

  StrCpy $GameDir "$INSTDIR\SquareEnix\FINAL FANTASY XI"

  DetailPrint "Uninstalling from $INSTDIR..."

  UnRegDLL "$GameDir\FFXi.dll"
  UnRegDLL "$GameDir\FFXiMain.dll"
  UnRegDLL "$GameDir\FFXiResource.dll"
  UnRegDLL "$GameDir\FFXiVersions.dll"
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

  RMDir /r "$GameDir"
  RMDir /r "$INSTDIR\SquareEnix\PlayOnlineViewer"
  RMDir /r "$INSTDIR\Ashita"
  Delete "$INSTDIR\installer.ico"
  Delete "$INSTDIR\Uninstall FINAL FANTASY XI.exe"
  RMDir /r "$INSTDIR\SquareEnix"
  RMDir "$INSTDIR"

  Delete "$DESKTOP\Play FINAL FANTASY XI.lnk"
  RMDir /r "$SMPROGRAMS\FINAL FANTASY XI"

  DeleteRegKey /ifempty HKCU "Software\FINAL FANTASY XI"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI"
  DeleteRegKey HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS"
SectionEnd