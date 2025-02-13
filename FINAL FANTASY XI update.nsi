;NSIS Modern User Interface
;Written by Joost Verburg
;ZLIB License Copyright (c) 2018-2020 Eden Server

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
  !include "LogicLib.nsh"
  !include "FileFunc.nsh"
  !include "StrContains.nsh"

  !define MUI_ICON "installer.ico"
  !define MUI_LANGDLL_WINDOWTITLE "Installer"
  !define MUI_WELCOMEFINISHPAGE_BITMAP "background.bmp"
  !define MUI_WELCOMEPAGE_TITLE "Installer"

  !define MUI_LICENSEPAGE_CHECKBOX

  !addplugindir "..\Release"
  !addplugindir "."

;--------------------------------
;General

  ;Default installation folder
  InstallDir "$PROGRAMFILES\PlayOnline\FINAL FANTASY XI"

  ;Request application privileges for Windows Vista
  RequestExecutionLevel admin

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
; No need to compress twice!
SetCompress off

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "license.txt"
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH
  ;!insertmacro MUI_UNPAGE_WELCOME
  ;!insertmacro MUI_UNPAGE_CONFIRM
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

  ;Add files
  File installer.ico

  DetailPrint "Extracting game files, please wait..."
  ${GetExePath} $R0 ;
  Nsis7z::ExtractWithDetails "$R0\data.pak" "Installing game files %s..."
   
SectionEnd

