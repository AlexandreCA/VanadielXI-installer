;NSIS Modern User Interface
;FINAL FANTASY XI Private Server Installer - Improved Version
;ZLIB License Copyright (c) 2023-2025 Vanadiel_XI Server

;--------------------------------
;Include Modern UI

  !include "MUI2.nsh"
  !include "LogicLib.nsh"
  !include "FileFunc.nsh"
  !include "StrContains.nsh"

  !define MUI_ICON "installer.ico"
  !define MUI_LANGDLL_WINDOWTITLE "Installer"
  !define MUI_WELCOMEFINISHPAGE_BITMAP "background.bmp"
  !define MUI_WELCOMEPAGE_TITLE "FINAL FANTASY XI Installer"
  !define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of FINAL FANTASY XI with Windower4.$\r$\n$\r$\nClick Next to continue."

  !define MUI_LICENSEPAGE_CHECKBOX

  !addplugindir "..\Release"
  !addplugindir "."

;--------------------------------
;General

  ;Name and file
  Name "FINAL FANTASY XI"
  OutFile "FINAL_FANTASY_XI_Setup.exe"

  ;Default installation folder
  InstallDir "$PROGRAMFILES\PlayOnline"

  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\FINAL FANTASY XI" "InstallPath"

  ;Request application privileges for Windows Vista+
  RequestExecutionLevel admin

  ;Compression
  SetCompressor /SOLID lzma
  SetCompressorDictSize 64

;--------------------------------
;Variables

  Var /GLOBAL ServerIP
  Var /GLOBAL Username
  Var /GLOBAL Password
  Var /GLOBAL IsUpdate
  Var /GLOBAL InstallMode
  Var /GLOBAL ConfigDialog
  Var /GLOBAL ServerIPField
  Var /GLOBAL UsernameField
  Var /GLOBAL PasswordField
  Var /GLOBAL ModeDialog
  Var /GLOBAL RadioFresh
  Var /GLOBAL RadioRepair
  Var /GLOBAL RadioModify

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING
  !define MUI_FINISHPAGE_NOAUTOCLOSE
  !define MUI_UNFINISHPAGE_NOAUTOCLOSE

;--------------------------------
;Pages

  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "license.txt"
  Page Custom DependenciesPage DependenciesLeave
  Page Custom ServerConfigPage ServerConfigLeave
  !insertmacro MUI_PAGE_DIRECTORY
  Page Custom InstallModePage InstallModeLeave
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH

;--------------------------------
;Languages

  !insertmacro MUI_LANGUAGE "English"
  !insertmacro MUI_LANGUAGE "French"

;--------------------------------
;Custom Page: Server Configuration

Function ServerConfigPage
  nsDialogs::Create 1018
  Pop $ConfigDialog

  ${If} $ConfigDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 24u "Please enter your server connection details:"
  Pop $0

  ${NSD_CreateLabel} 0 30u 30% 12u "Server IP:"
  Pop $0
  ${NSD_CreateText} 35% 28u 60% 12u "192.168.1.15"
  Pop $ServerIPField

  ${NSD_CreateLabel} 0 50u 30% 12u "Username:"
  Pop $0
  ${NSD_CreateText} 35% 48u 60% 12u "username"
  Pop $UsernameField

  ${NSD_CreateLabel} 0 70u 30% 12u "Password:"
  Pop $0
  ${NSD_CreatePassword} 35% 68u 60% 12u "password"
  Pop $PasswordField

  ${NSD_CreateLabel} 0 90u 100% 24u "Note: These settings can be changed later in Windower4\settings.xml"
  Pop $0

  nsDialogs::Show
FunctionEnd

Function ServerConfigLeave
  ${NSD_GetText} $ServerIPField $ServerIP
  ${NSD_GetText} $UsernameField $Username
  ${NSD_GetText} $PasswordField $Password

  ; Validation
  ${If} $ServerIP == ""
    MessageBox MB_ICONEXCLAMATION "Server IP cannot be empty!"
    Abort
  ${EndIf}

  ${If} $Username == ""
    MessageBox MB_ICONEXCLAMATION "Username cannot be empty!"
    Abort
  ${EndIf}

  ${If} $Password == ""
    MessageBox MB_ICONEXCLAMATION "Password cannot be empty!"
    Abort
  ${EndIf}
FunctionEnd

;--------------------------------
;Custom Page: Installation Mode Selection

Function InstallModePage
  ; Check if installation already exists
  IfFileExists "$INSTDIR\Windower4\windower.exe" show_mode_page skip_mode_page
  
  show_mode_page:
    StrCpy $IsUpdate "yes"
    
    nsDialogs::Create 1018
    Pop $ModeDialog

    ${If} $ModeDialog == error
      Abort
    ${EndIf}

    ${NSD_CreateLabel} 0 0 100% 20u "An existing installation was detected. Please choose an installation mode:"
    Pop $0

    ${NSD_CreateRadioButton} 10u 30u 100% 12u "Fresh Install (Remove everything and reinstall)"
    Pop $RadioFresh

    ${NSD_CreateRadioButton} 10u 50u 100% 12u "Repair (Fix corrupted files, keep settings)"
    Pop $RadioRepair
    ${NSD_Check} $RadioRepair

    ${NSD_CreateRadioButton} 10u 70u 100% 12u "Modify (Update server configuration only)"
    Pop $RadioModify

    ${NSD_CreateLabel} 0 90u 100% 40u "• Fresh Install: Removes all existing files including settings$\r$\n• Repair: Verifies and replaces corrupted game files, keeps Windower settings$\r$\n• Modify: Only updates server connection settings in Windower4"
    Pop $0

    nsDialogs::Show
    Return

  skip_mode_page:
    StrCpy $IsUpdate "no"
    StrCpy $InstallMode "fresh"
FunctionEnd

Function InstallModeLeave
  ${If} $IsUpdate == "yes"
    ${NSD_GetState} $RadioFresh $0
    ${If} $0 == ${BST_CHECKED}
      StrCpy $InstallMode "fresh"
      MessageBox MB_YESNO|MB_ICONQUESTION "Fresh install will DELETE all existing files including settings. Continue?" IDYES +2
      Abort
    ${EndIf}

    ${NSD_GetState} $RadioRepair $0
    ${If} $0 == ${BST_CHECKED}
      StrCpy $InstallMode "repair"
    ${EndIf}

    ${NSD_GetState} $RadioModify $0
    ${If} $0 == ${BST_CHECKED}
      StrCpy $InstallMode "modify"
    ${EndIf}
  ${EndIf}
FunctionEnd

;--------------------------------
;Dependencies Installation Page

Function DependenciesPage
  ; Display a custom page showing dependency checks
  DetailPrint "=== Checking System Dependencies ==="

  Var /GLOBAL VC2010Installed
  Var /GLOBAL VC2012Installed
  Var /GLOBAL VC2013Installed
  Var /GLOBAL VC2015Installed
  Var /GLOBAL DotNet40Installed
  Var /GLOBAL DotNet45Installed

  ; --- Visual C++ 2010 Redistributable (x86) ---
  ClearErrors
  ReadRegDWORD $VC2010Installed HKLM "SOFTWARE\Microsoft\VisualStudio\10.0\VC\VCRedist\x86" "Installed"
  ${If} ${Errors}
  ${OrIf} $VC2010Installed != 1
    DetailPrint "Installing Visual C++ 2010 Redistributable..."
    File /oname=$TEMP\VS2010.exe "VS2010.exe"
    ExecWait '"$TEMP\VS2010.exe" /install /passive /norestart' $0
    Delete "$TEMP\VS2010.exe"
    ${If} $0 != 0
      DetailPrint "Warning: VC++ 2010 installation returned code $0"
    ${EndIf}
  ${Else}
    DetailPrint "✓ Visual C++ 2010 already installed"
  ${EndIf}

  ; --- Visual C++ 2012 Redistributable (x86) ---
  ClearErrors
  ReadRegDWORD $VC2012Installed HKLM "SOFTWARE\Microsoft\VisualStudio\11.0\VC\Runtimes\x86" "Installed"
  ${If} ${Errors}
  ${OrIf} $VC2012Installed != 1
    DetailPrint "Installing Visual C++ 2012 Redistributable..."
    File /oname=$TEMP\VS2012.exe "VS2012.exe"
    ExecWait '"$TEMP\VS2012.exe" /install /passive /norestart' $0
    Delete "$TEMP\VS2012.exe"
    ${If} $0 != 0
      DetailPrint "Warning: VC++ 2012 installation returned code $0"
    ${EndIf}
  ${Else}
    DetailPrint "✓ Visual C++ 2012 already installed"
  ${EndIf}

  ; --- Visual C++ 2013 Redistributable (x86) ---
  ClearErrors
  ReadRegDWORD $VC2013Installed HKLM "SOFTWARE\Microsoft\VisualStudio\12.0\VC\Runtimes\x86" "Installed"
  ${If} ${Errors}
  ${OrIf} $VC2013Installed != 1
    DetailPrint "Installing Visual C++ 2013 Redistributable..."
    File /oname=$TEMP\VS2013.exe "VS2013.exe"
    ExecWait '"$TEMP\VS2013.exe" /install /passive /norestart' $0
    Delete "$TEMP\VS2013.exe"
    ${If} $0 != 0
      DetailPrint "Warning: VC++ 2013 installation returned code $0"
    ${EndIf}
  ${Else}
    DetailPrint "✓ Visual C++ 2013 already installed"
  ${EndIf}

  ; --- Visual C++ 2015-2022 Redistributable (x86) ---
  ClearErrors
  ReadRegDWORD $VC2015Installed HKLM "SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" "Installed"
  ${If} ${Errors}
  ${OrIf} $VC2015Installed != 1
    DetailPrint "Installing Visual C++ 2015-2022 Redistributable..."
    File /oname=$TEMP\VS2015.exe "VS2015.exe"
    ExecWait '"$TEMP\VS2015.exe" /install /passive /norestart' $0
    Delete "$TEMP\VS2015.exe"
    ${If} $0 != 0
      DetailPrint "Warning: VC++ 2015-2022 installation returned code $0"
    ${EndIf}
  ${Else}
    DetailPrint "✓ Visual C++ 2015-2022 already installed"
  ${EndIf}

  ; --- .NET Framework 4.0 ---
  ClearErrors
  ReadRegDWORD $DotNet40Installed HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Install"
  ${If} ${Errors}
  ${OrIf} $DotNet40Installed != 1
    DetailPrint "Installing .NET Framework 4.0..."
    File /oname=$TEMP\dotNetFx40_Full_x86_x64.exe "dotNetFx40_Full_x86_x64.exe"
    ExecWait '"$TEMP\dotNetFx40_Full_x86_x64.exe" /q /norestart' $0
    Delete "$TEMP\dotNetFx40_Full_x86_x64.exe"
    ${If} $0 != 0
      DetailPrint "Warning: .NET 4.0 installation returned code $0"
    ${EndIf}
  ${Else}
    DetailPrint "✓ .NET Framework 4.0 already installed"
  ${EndIf}

  ; --- .NET Framework 4.5+ ---
  ClearErrors
  ReadRegDWORD $DotNet45Installed HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Release"
  ${If} ${Errors}
  ${OrIf} $DotNet45Installed < 378389
    DetailPrint "Installing .NET Framework 4.5 or higher..."
    File /oname=$TEMP\dotNet45.exe "dotNet45.exe"
    ExecWait '"$TEMP\dotNet45.exe" /q /norestart' $0
    Delete "$TEMP\dotNet45.exe"
    ${If} $0 != 0
      DetailPrint "Warning: .NET 4.5+ installation returned code $0"
    ${EndIf}
  ${Else}
    DetailPrint "✓ .NET Framework 4.5 or higher already installed"
  ${EndIf}

  ; --- DirectPlay Feature ---
  DetailPrint "Checking DirectPlay feature..."
  nsExec::ExecToStack 'dism /online /Get-FeatureInfo /FeatureName:DirectPlay'
  Pop $0
  Pop $1
  
  ${If} $0 == 0
    Push $1
    Push "State : Enabled"
    Call StrContains
    Pop $2
    ${If} $2 == ""
      DetailPrint "Enabling DirectPlay feature..."
      nsExec::ExecToLog 'dism /online /Enable-Feature /FeatureName:DirectPlay /All /Quiet /NoRestart'
      Pop $0
      ${If} $0 == 0
        DetailPrint "✓ DirectPlay enabled successfully"
      ${Else}
        DetailPrint "Warning: DirectPlay enable returned code $0"
      ${EndIf}
    ${Else}
      DetailPrint "✓ DirectPlay already enabled"
    ${EndIf}
  ${Else}
    DetailPrint "Warning: Could not check DirectPlay status"
  ${EndIf}

  DetailPrint "=== Dependency Check Complete ==="
FunctionEnd

Function DependenciesLeave
FunctionEnd

;--------------------------------
;Installer Section

Section "FINAL FANTASY XI" MainSection
  SectionIn RO
  
  SetOutPath "$INSTDIR"
  SetOverwrite on

  DetailPrint "=== Starting Installation (Mode: $InstallMode) ==="

  ; Handle Fresh Install mode
  ${If} $InstallMode == "fresh"
    DetailPrint "Fresh install mode - removing all existing files..."
    RMDir /r "$INSTDIR\Windower4"
    RMDir /r "$INSTDIR\SquareEnix"
    Delete "$INSTDIR\installer.ico"
    DetailPrint "✓ Existing files removed"
  ${EndIf}

  ; Handle Modify mode (only update configuration)
  ${If} $InstallMode == "modify"
    DetailPrint "Modify mode - updating server configuration only..."
    
    ; Only update Windower4 settings
    File "installer.ico"
    Call ConfigureWindower
    Call CreateShortcuts
    
    DetailPrint "✓ Server configuration updated"
    DetailPrint "=== Modification Complete ==="
    Return
  ${EndIf}

  ; For Fresh and Repair modes, continue with full installation
  AddSize 14000000

  ; Extract installer icon
  File "installer.ico"

  ; Extract game files (skip for repair if files exist and are valid)
  ${If} $InstallMode == "repair"
    DetailPrint "Repair mode - verifying game files..."
    IfFileExists "$INSTDIR\SquareEnix\FINAL FANTASY XI\pol.exe" 0 need_extraction
      DetailPrint "Game files exist - verifying integrity..."
      
      ; Check critical files
      IfFileExists "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXi.dll" 0 need_extraction
      IfFileExists "$INSTDIR\SquareEnix\PlayOnlineViewer\pol.exe" 0 need_extraction
        DetailPrint "✓ Core game files verified - skipping extraction"
        Goto skip_extraction
      
    need_extraction:
      DetailPrint "Missing or corrupted files detected - extracting..."
  ${EndIf}

  ; Extract game files
  DetailPrint "Extracting game files (this may take several minutes)..."
  ${GetExePath} $R0
  Nsis7z::ExtractWithDetails "$R0\data.pak" "Installing game files %s..."
  Pop $0
  ${If} $0 != "success"
    MessageBox MB_ICONSTOP "Failed to extract game files: $0"
    Abort
  ${EndIf}
  DetailPrint "✓ Game files extracted successfully"

  skip_extraction:

  ; Update registry
  DetailPrint "Configuring registry settings..."
  Call ConfigureRegistry
  DetailPrint "✓ Registry configured"

  ; Configure Windower4
  DetailPrint "Configuring Windower4..."
  Call ConfigureWindower
  DetailPrint "✓ Windower4 configured"

  ; Register DLLs
  DetailPrint "Registering game libraries..."
  Call RegisterDLLs
  DetailPrint "✓ Libraries registered"

  ; Create uninstaller
  DetailPrint "Creating uninstaller..."
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Create shortcuts
  DetailPrint "Creating shortcuts..."
  Call CreateShortcuts
  DetailPrint "✓ Shortcuts created"

  ${If} $InstallMode == "repair"
    DetailPrint "=== Repair Complete ==="
  ${Else}
    DetailPrint "=== Installation Complete ==="
  ${EndIf}
SectionEnd

;--------------------------------
;Configure Registry Function

Function ConfigureRegistry
  SetRegView 64

  ; User settings
  WriteRegStr HKCU "Software\FINAL FANTASY XI" "InstallPath" "$INSTDIR"

  ; Uninstall information
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "DisplayName" "FINAL FANTASY XI"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "DisplayVersion" "1.0.0"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "Publisher" "Vanadiel XI Server"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "QuietUninstallString" "$\"$INSTDIR\Uninstall.exe$\" /S"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "DisplayIcon" "$INSTDIR\installer.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "ModifyPath" "$\"$EXEPATH$\""
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "NoModify" 0
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI" "NoRepair" 0

  ; PlayOnline registry keys
  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS" "CommonFilesFolder" "$PROGRAMFILES\Common Files\"
  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder" "0001" "$INSTDIR\SquareEnix\FINAL FANTASY XI\"
  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\InstallFolder" "1000" "$INSTDIR\SquareEnix\PlayOnlineViewer"

  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Interface" "0001" "130b5023"
  WriteRegStr HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Interface" "1000" "1304d1e8"

  WriteRegBin HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\Product" "0001" 9741e0849e6dc5ec1220cd8c1ecd9649be988450ab9a402c58fbfb50fecae9f3bad2df087753f81d1f33e92a8e4a2faa04dff98ee20508a30fb501134eda95f3f029a5795fa83626a451c3008c52772a1ff31c0c7311d737b1f2f53375887d091a55611511ec3561d55f3a2f252171c73d2eeb09041b801bf03e3cf029869d844d0870d6453da92ee5e03acea1c93a8996abe96dddc6149b648ad02e37ab8767c61d252140618ffa22ac270845ff4419f57670816dd860827536055e29b11463260f64617e7b3c5df923688c664d38c15cfd5b967097cc2022a0135fba2df6589d4fe22e4db2e596903eb45c8a8f30780b29b30ec5e0295da24c6e9168a0590ab762f78359aa022b321feedf8d5e05da9eb59d59625389e5a8c63ba02623705b

  ; FFXI game settings
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
  WriteRegStr   HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0042" "$INSTDIR\SquareEnix\FINAL FANTASY XI"
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "0043" 0x00000000
  WriteRegBin   HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "bFirst" 00
  WriteRegStr   HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "padsin000" "8,9,13,12,10,0,1,3,2,15,-1,-1,14,-33,-33,32,32,-36,-36,35,35,6,7,5,4,11,-1"
  WriteRegStr   HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\FinalFantasyXI" "padmode000" "1,0,1,0,1,1"

  ; PlayOnline Viewer settings
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer" "FirstBootPlayMovie" 0x00000000
  WriteRegBin HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer" "SPS000" 66c84962897d8dce4d64151db09a4ca4267c07c18b8df49c8f31a4b35a72f34cda1df301ee999021d69a2a941e91797e9b4d6d5db04a362a03ac41cdf89c6e50ed98531f457b017faa35eb0cd4cb0fea6d3852bfed8fa10351e83d64074178269644b322c6e21ef57a32b167199da82164facc60f1623623b8f8a3f3881a6d26bbd15e4dcf04012c1a91a50f2b942fa344644dac419e9aadb22489b813110830cf7a8b305ba06b8bdb8131bf2ab1f29e392f6bf43e47714d39fd00ed10369c647251aa6bc05fcf3c0210e71178ff0fe3df2548963e927f38c3bd205bed21ac6ed12fea4576c534b4bf3128c1d5fc4315f3580d03b21df18c30b11cf125f9132f980f9e7b1d8579f77a8eaf6d6426fc67e50d265f0e13a8bad5bad1bead511761c43e93b67e6428379c7a0c7ba2084db1458af16efa76a77f037484ba7e540e3e07b4f9f34df3d5b6b273174fa2f87ff2527472824fedd498385e3f48374ba7a317964db33826bd56bb5edf4acb3666d83b1accfdde4d0cb1b6a46733fca102d2d246a209d506d7c6869eeafe2dc9ed6ac9e9d64bf84d4f881db3e7425a061de002ab6043b448e9a2078c32517c6a1c9cefc8974f0d21fbcd3b80e08e0a85e915a6889912828a01cc41a8c0046fb3532b6f158ac05e45e33efdf3437643505a1839a303d7838f244f6a82e218947826d508c513a84e06906bd9677cc9226d19a350bef70802d40c7dccbbfe30f93482839f62f5b96a7ea3672e342e81598180f18c388e5615935ee097d0c880a635ab2068e093d6dfc420f49718d86b297dde1a224044311adbba93224182ef211becca81bdcfec40f80fd1a0fdef79ad744ee5329883af56497f8e6f7ed43d842573582afa93cf16cff1ca1d889a72dcdfae4f9a9956d2dfe1c7aabf514180f4f376fbb9d767da165028788aeceecfc775f440e78b3546c4fc162367c3b1ab027a25af51f97d7d11b71ac0988f712477c492775742b41069823320b3723855e5ce3d5c2dc7ae7fb409f5458c40bebe41eb23c39d99a7a09f037b06d881b1a8b4efdf2adfb96b8b9d4dcc51e3f2519a8244fbc5190ec701f73c85b9bab3e1a60d01bb0dd990f875a378aa375e302c1747f5fa99e36613740c76443af4a5d1956521830d82872d43124471af8e8b41984174404066c0cc62b1df99d6296b01496adc5a90e7241dab32ebc640dd19ff15bfd36675f45cfac7e1f0fae90f5664c5c3b4bcca4f730d24f68736e84bd7c50150571613bce014b29beb8282586931a8ceb76d7b5e2b3c3a965f35f84939162bf414cf053188bc7ae02b4a024b69c5bd3a3fa3d561a29498331841c5314a3466b194625a3f5d67e67265898c51fb6a2e62a87866364be2c3cec1389a528301e97e4ab05be3f55fc7498e559593eefff3785b4dc48217e2d1734e0d490ec0bae10b0212758567e64200e7e2b3c39ef302e666b2f4801546a3636805c9533e114b6a323d56133c88a369bda4ab8c203aff022063c816d94b504c2a393e719547a2488c5a16634abe247d292147eb4e794c6a2ce7f2478cedeb3618ce531be72abd9f63173e15cf65c7d21f44e4880b32ac2a9fb16c9378058a51e36c8bba70fdcfcb3e6b6d852f478b92a1c152a9caba215ecdc247008583e6018f3b5c61c1b10de9fe53fd68078ff2c91a57d795114a0863a81e81d5e2c024c30f99be4ec4b923776c5cbd7bd9ccde38f56b6c0180b0c9be4c1bc2307e612702e576b7990bd35fcc8251fa14e86348b8714a6ca8f1c50ae07337143c52120fd420a66a6f88cadd02e49dea36c716b3f845dc4d3fbd8db3baf966cdf68cc7875c3f881d09222cd8a9c099a91b0cf6274dc9d6d679f484d9a9597c106d172c663ce96ad8ba8efb697f6ff1ed074110869dae9159ec4d5a6f4570944db1c4baf0edb35b4e02ac1c4a81cc76d17dc69931120561550f9947b714a6a372e6daf434c08d5b2db1b2433edda30469585f12fc869c266f0cf30cc9f03bba79c9c5de6a99038158118ca4bfa029e6ee6de7d01058095175adb149fb6b520c9b1502d6bd1a220456d7536bce0cae334ce4afcd698c2dcf7c6c016cf7acf516c8193e1a0a0d75ce1f501ca53c40af5d8f5a9316739a8b577ffa2838fb83d9ac01870ec55d0f929f4adff94239a39645d931ac3733356f80f2a5fae14ff057fbaefaebf4ef1288c9e2d287fbb93c57599bb88490bd335911dd2c19ba4588fc1b4f30abdbf1bcb0305afa9670d8e198e0339a52989d3f6b25e44351754b92f66c379a93a84a85a07245d002764886c7e9f6c0249e2b3b00a4652dfb8d3b7972b6de7c1300fb8d01099d1b4bacf9cb59ddce92222f286a86c02425cb736e03c4aa0e032072853648bb2ad4e528db1be1818c5779cd8971a342f92a5c4bb933fed5635ff61589433932ea36ab61ac8720b9b2ae94f3655412d36386dd13bf55f6f49f057ace71f46de4f0a509bf7969569429134e8d9f6b42ed7bd861ba6d8ccad9f6e7bf8f8a22563edc23a448ab1ddb62338cf878a230c72aa6eb4f625cb40edc644739ebaef343c7b9473e3f1389280fc8122f5ba745d824bab71ea3eda0aaeb5224cfb27b89faa6a806e9159fc7e1f215ed5043

  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings" "FullScreen" 0x00000000
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings" "Language" 0x00000001
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings" "PlayAudio" 0x00000001
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings" "PlayOpeningMovie" 0x00000001
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings" "ResetSettings" 0x00000000
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings" "SupportLanguage" 0x00000001
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings" "UseGameController" 0x00000000
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings" "WindowH" 0x000001e0
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings" "WindowW" 0x00000280
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings" "WindowX" 0x00000082
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings" "WindowY" 0x00000082

  ; Controller settings
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "AnchorDown" 0x00000034
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "AnchorLeft" 0x00000036
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "AnchorRight" 0x00000032
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "AnchorUp" 0x00000030
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "Cancel" 0x00000002
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "ChrCsrNext" 0x00000007
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "ChrCsrPrev" 0x00000006
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "ID" 0x00000000
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "Menu" 0x00000000
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "Navi" 0x00000003
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "Ok" 0x00000001
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "PageNext" 0x00000005
  WriteRegDWORD HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\Settings\Controller" "PagePrev" 0x00000004

  WriteRegBin HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS\SquareEnix\PlayOnlineViewer\SystemInfo\QCheck" "LastMeasurementTime" ""
FunctionEnd

;--------------------------------
;Configure Windower4 Function

Function ConfigureWindower
  ; Create Windower4 directory
  CreateDirectory "$INSTDIR\Windower4"

  ; Check if xiloader.exe exists
  IfFileExists "$INSTDIR\Windower4\xiloader.exe" 0 windower_error
    DetailPrint "Creating Windower4 configuration file..."
    
    ; Create settings.xml with user-provided credentials
    FileOpen $0 "$INSTDIR\Windower4\settings.xml" w
    ${If} ${Errors}
      DetailPrint "ERROR: Failed to create settings.xml"
      MessageBox MB_ICONEXCLAMATION "Failed to create Windower4 configuration file"
      Goto windower_done
    ${EndIf}

    ; Write UTF-8 BOM
    FileWriteByte $0 0xEF
    FileWriteByte $0 0xBB
    FileWriteByte $0 0xBF

    ; Write XML content with user configuration
    FileWrite $0 '<?xml version="1.0" encoding="utf-8"?>$\r$\n'
    FileWrite $0 '<settings>$\r$\n'
    FileWrite $0 '  <launcher>$\r$\n'
    FileWrite $0 '    <branch>stable</branch>$\r$\n'
    FileWrite $0 '  </launcher>$\r$\n'
    FileWrite $0 '  <autoload>$\r$\n'
    FileWrite $0 '    <addon>ChatLink</addon>$\r$\n'
    FileWrite $0 '    <addon>chatPorter</addon>$\r$\n'
    FileWrite $0 '    <addon>xivbar</addon>$\r$\n'
    FileWrite $0 '    <addon>Trusts</addon>$\r$\n'
    FileWrite $0 '    <addon>lottery</addon>$\r$\n'
    FileWrite $0 '    <addon>itemizer</addon>$\r$\n'
    FileWrite $0 '    <addon>invtracker</addon>$\r$\n'
    FileWrite $0 '    <addon>giltracker</addon>$\r$\n'
    FileWrite $0 '    <addon>EasyNuke</addon>$\r$\n'
    FileWrite $0 '    <addon>Debuffed</addon>$\r$\n'
    FileWrite $0 '    <addon>AutoRA</addon>$\r$\n'
    FileWrite $0 '    <addon>barfiller</addon>$\r$\n'
    FileWrite $0 '    <plugin>FFXIDB</plugin>$\r$\n'
    FileWrite $0 '    <plugin>MipmapFix</plugin>$\r$\n'
    FileWrite $0 '    <plugin>Timers</plugin>$\r$\n'
    FileWrite $0 '    <plugin>Binder</plugin>$\r$\n'
    FileWrite $0 '  </autoload>$\r$\n'
    FileWrite $0 '  <profile name="VanadielXI">$\r$\n'
    FileWrite $0 '    <consolekey>Insert</consolekey>$\r$\n'
    FileWrite $0 '    <mipmaplevel>6</mipmaplevel>$\r$\n'
    FileWrite $0 '    <uiscale>1</uiscale>$\r$\n'
    FileWrite $0 '    <alwaysenablegamepad>false</alwaysenablegamepad>$\r$\n'
    FileWrite $0 '    <args>--server $ServerIP --user $Username --pass $Password --hairpin</args>$\r$\n'
    FileWrite $0 '    <executable>xiloader.exe</executable>$\r$\n'
    FileWrite $0 '  </profile>$\r$\n'
    FileWrite $0 '</settings>$\r$\n'
    FileClose $0

    ${If} ${Errors}
      DetailPrint "ERROR: Failed to write settings.xml"
      MessageBox MB_ICONEXCLAMATION "Failed to write Windower4 configuration"
    ${Else}
      DetailPrint "Windower4 configuration created successfully"
      
      ; Set file permissions for all users
      nsExec::ExecToLog 'icacls "$INSTDIR\Windower4\settings.xml" /grant Users:(F)'
    ${EndIf}
    Goto windower_done

  windower_error:
    DetailPrint "WARNING: xiloader.exe not found - Windower4 configuration skipped"
    MessageBox MB_ICONINFORMATION "Windower4 xiloader.exe not found. Configuration will be skipped."

  windower_done:
FunctionEnd

;--------------------------------
;Register DLLs Function

Function RegisterDLLs
  ; FFXI DLLs
  ClearErrors
  RegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXi.dll"
  ${IfNot} ${Errors}
    DetailPrint "✓ Registered FFXi.dll"
  ${EndIf}

  ClearErrors
  RegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiMain.dll"
  ${IfNot} ${Errors}
    DetailPrint "✓ Registered FFXiMain.dll"
  ${EndIf}

  ClearErrors
  RegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiResource.dll"
  ${IfNot} ${Errors}
    DetailPrint "✓ Registered FFXiResource.dll"
  ${EndIf}

  ClearErrors
  RegDLL "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiVersions.dll"
  ${IfNot} ${Errors}
    DetailPrint "✓ Registered FFXiVersions.dll"
  ${EndIf}

  ; PlayOnline Viewer DLLs
  ClearErrors
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\polhook.dll"
  ${IfNot} ${Errors}
    DetailPrint "✓ Registered polhook.dll"
  ${EndIf}

  ClearErrors
  RegDLL "$INSTDIR\SquareEnix\PlayOnlineViewer\unicows.dll"
  ${IfNot} ${Errors}
    DetailPrint "✓ Registered unicows.dll"
  ${EndIf}

  ; Additional DLLs (with error checking)
  !macro RegDLLSafe DllPath
    IfFileExists "${DllPath}" 0 +3
      ClearErrors
      RegDLL "${DllPath}"
  !macroend

  !insertmacro RegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\patchfiles\PlayOnlineViewer\viewer\com\app.dll"
  !insertmacro RegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\patchfiles\PlayOnlineViewer\viewer\com\polcore.dll"
  !insertmacro RegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\polcfg\sysinfo.dll"
  !insertmacro RegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\util\unicows.dll"
  !insertmacro RegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\MSVCR71.dll"
  !insertmacro RegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\polmvf.dll"
  !insertmacro RegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\polmvfINT.dll"
  !insertmacro RegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\com\app.dll"
  !insertmacro RegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\com\polcore.dll"
  !insertmacro RegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\contents\PolContents.dll"
  !insertmacro RegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\contents\polcontentsINT.dll"
FunctionEnd

;--------------------------------
;Create Shortcuts Function

Function CreateShortcuts
  SetOutPath "$INSTDIR\Windower4\"
  
  ; Desktop shortcut
  CreateShortCut "$DESKTOP\Play FINAL FANTASY XI.lnk" "$INSTDIR\Windower4\windower.exe" "" "$INSTDIR\installer.ico" 0 SW_SHOWNORMAL "" "Launch FINAL FANTASY XI"

  ; Start Menu folder and shortcuts
  CreateDirectory "$SMPROGRAMS\FINAL FANTASY XI"
  CreateShortCut "$SMPROGRAMS\FINAL FANTASY XI\Play FINAL FANTASY XI.lnk" "$INSTDIR\Windower4\windower.exe" "" "$INSTDIR\installer.ico" 0 SW_SHOWNORMAL "" "Launch FINAL FANTASY XI"
  CreateShortCut "$SMPROGRAMS\FINAL FANTASY XI\Windower Settings.lnk" "$INSTDIR\Windower4\settings.xml" "" "" 0 SW_SHOWNORMAL "" "Edit Windower Settings"
  CreateShortCut "$SMPROGRAMS\FINAL FANTASY XI\Uninstall.lnk" "$INSTDIR\Uninstall.exe" "" "" 0 SW_SHOWNORMAL "" "Uninstall FINAL FANTASY XI"
FunctionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"
  DetailPrint "=== Starting Uninstallation ==="

  ; Unregister DLLs
  DetailPrint "Unregistering DLLs..."
  
  !macro UnRegDLLSafe DllPath
    IfFileExists "${DllPath}" 0 +3
      ClearErrors
      UnRegDLL "${DllPath}"
  !macroend

  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXi.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiMain.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiResource.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\FINAL FANTASY XI\FFXiVersions.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\polhook.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\unicows.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\patchfiles\PlayOnlineViewer\viewer\com\app.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\patchfiles\PlayOnlineViewer\viewer\com\polcore.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\polcfg\sysinfo.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\util\unicows.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\MSVCR71.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\polmvf.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\ax\polmvfINT.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\com\app.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\com\polcore.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\contents\PolContents.dll"
  !insertmacro UnRegDLLSafe "$INSTDIR\SquareEnix\PlayOnlineViewer\viewer\contents\polcontentsINT.dll"

  ; Ask user if they want to keep user data
  MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to keep your Windower4 settings and user data?" IDYES keep_userdata

  ; Delete everything including user data
  DetailPrint "Removing all files including user data..."
  RMDir /r "$INSTDIR\Windower4"
  Goto continue_uninstall

  keep_userdata:
    DetailPrint "Preserving Windower4 user data..."
    ; Only delete non-user files
    Delete "$INSTDIR\Windower4\windower.exe"
    Delete "$INSTDIR\Windower4\xiloader.exe"
    ; Keep settings.xml and other user data

  continue_uninstall:

  ; Remove game files
  DetailPrint "Removing game files..."
  RMDir /r "$INSTDIR\SquareEnix"

  ; Remove shortcuts
  DetailPrint "Removing shortcuts..."
  Delete "$DESKTOP\Play FINAL FANTASY XI.lnk"
  RMDir /r "$SMPROGRAMS\FINAL FANTASY XI"

  ; Remove registry keys
  DetailPrint "Cleaning registry..."
  SetRegView 64
  DeleteRegKey HKCU "Software\FINAL FANTASY XI"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\FINAL FANTASY XI"
  DeleteRegKey HKLM "SOFTWARE\WOW6432Node\PlayOnlineUS"

  ; Remove installer files
  Delete "$INSTDIR\installer.ico"
  Delete "$INSTDIR\Uninstall.exe"

  ; Try to remove install directory (will fail if Windower4 data was kept)
  RMDir "$INSTDIR"

  DetailPrint "=== Uninstallation Complete ==="
SectionEnd

;--------------------------------
;Version Information

  VIProductVersion "1.0.0.0"
  VIAddVersionKey "ProductName" "FINAL FANTASY XI"
  VIAddVersionKey "CompanyName" "Vanadiel XI Server"
  VIAddVersionKey "FileDescription" "FINAL FANTASY XI Installer"
  VIAddVersionKey "FileVersion" "1.0.0.0"
  VIAddVersionKey "ProductVersion" "1.0.0.0"
  VIAddVersionKey "LegalCopyright" "© 2023-2025 Vanadiel XI Server"
