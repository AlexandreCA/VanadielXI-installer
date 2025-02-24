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
  ClearErrors
  ReadRegStr $0 HKCU "Software\FINAL FANTASY XI" "InstallPath"
  ${If} ${Errors}
  ${OrIfNot} ${FileExists} "$PROGRAMFILES\PlayOnline\SquareEnix\FINAL FANTASY XI"
    StrCpy $IsUpdate "no"
    DetailPrint "No existing installation detected. Proceeding with new install."
  ${Else}
    StrCpy $IsUpdate "yes"
    StrCpy $INSTDIR "$PROGRAMFILES\PlayOnline\SquareEnix\FINAL FANTASY XI"
    DetailPrint "Existing installation detected at $INSTDIR. Proceeding with update."
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
    DetailPrint "Extracting lang.pak to $GameDir..."
    IfFileExists "$EXEDIR\archives\lang.pak" 0 lang_missing
      CreateDirectory "$TEMP\lang_temp"
      Nsis7z::Extract "$EXEDIR\archives\lang.pak" "-o$TEMP\lang_temp"
      DetailPrint "Copying French translation ROM files to $GameDir..."
      CopyFiles "$TEMP\lang_temp\*.*" "$GameDir"
      DetailPrint "Cleaning up temporary directory $TEMP\lang_temp..."
      RMDir /r "$TEMP\lang_temp"
      ${If} $IsUpdate == "no"
        WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "Language" 0x00000002
      ${EndIf}
      DetailPrint "French translation ROM files installed/updated in $GameDir"
      Goto lang_done
    lang_missing:
      MessageBox MB_OK|MB_ICONSTOP "Error: lang.pak not found in $EXEDIR\archives! French translation not installed."
    lang_done:
  ${Else}
    DetailPrint "French translation skipped by user."
  ${EndIf}

  ${If} $InstallHDTextures == "yes"
    DetailPrint "Extracting hd_textures.pak to $GameDir..."
    IfFileExists "$EXEDIR\archives\hd_textures.pak" 0 hd_missing
      CreateDirectory "$TEMP\hd_textures_temp"
      Nsis7z::Extract "$EXEDIR\archives\hd_textures.pak" "-o$TEMP\hd_textures_temp"
      DetailPrint "Copying HD texture ROM files to $GameDir..."
      CopyFiles "$TEMP\hd_textures_temp\*.*" "$GameDir"
      DetailPrint "Cleaning up temporary directory $TEMP\hd_textures_temp..."
      RMDir /r "$TEMP\hd_textures_temp"
      DetailPrint "HD texture ROM files installed/updated in $GameDir"
      Goto hd_done
    hd_missing:
      MessageBox MB_OK|MB_ICONSTOP "Error: hd_textures.pak not found in $EXEDIR\archives! HD textures not installed."
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