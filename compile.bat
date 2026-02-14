@echo off
echo ========================================
echo VanadielXI Auto-Updater - Compilation
echo ========================================
echo.

REM Vérifier que .NET SDK est installé
dotnet --version >nul 2>&1
if errorlevel 1 (
    echo ERREUR: .NET SDK n'est pas installé !
    echo Téléchargez-le depuis : https://dotnet.microsoft.com/download
    pause
    exit /b 1
)

echo [1/3] Compilation de VanadielXI_Updater.exe...
dotnet publish VanadielXI_Updater.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true

if errorlevel 1 (
    echo ERREUR lors de la compilation !
    pause
    exit /b 1
)

echo.
echo [2/3] Copie de l'exécutable...
copy /Y "bin\Release\net6.0-windows\win-x64\publish\VanadielXI_Updater.exe" "VanadielXI_Updater.exe"

if errorlevel 1 (
    echo ERREUR lors de la copie !
    pause
    exit /b 1
)

echo.
echo [3/3] Vérification de NSIS...
if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
    echo NSIS trouvé ! Compilation de l'installeur...
    "C:\Program Files (x86)\NSIS\makensis.exe" FINAL_FANTASY_XI_v2_1_with_updater.nsi
    
    if errorlevel 1 (
        echo ERREUR lors de la compilation NSIS !
        echo Vérifiez que tous les fichiers nécessaires sont présents.
        pause
        exit /b 1
    )
    
    echo.
    echo ========================================
    echo COMPILATION TERMINÉE AVEC SUCCÈS !
    echo ========================================
    echo.
    echo Fichiers créés :
    echo - VanadielXI_Updater.exe (Auto-updater)
    echo - FINAL FANTASY XI.exe (Installeur complet)
    echo.
) else (
    echo.
    echo ========================================
    echo UPDATER COMPILÉ AVEC SUCCÈS !
    echo ========================================
    echo.
    echo Fichier créé : VanadielXI_Updater.exe
    echo.
    echo ATTENTION : NSIS n'est pas installé.
    echo Pour compiler l'installeur complet :
    echo 1. Installez NSIS depuis https://nsis.sourceforge.io/Download
    echo 2. Relancez ce script
    echo.
)

pause
