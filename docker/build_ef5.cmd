@echo off
REM ============================================================================
REM build_ef5.cmd : Windows CMD pur (sans PowerShell)
REM ============================================================================
REM Evite completement les blocages lies a la strategie d'execution PowerShell
REM et aux strategies de groupe.
REM
REM Utilisation (depuis la racine du dossier ou depuis docker\) :
REM   docker\build_ef5.cmd
REM   docker\build_ef5.cmd -Status
REM   docker\build_ef5.cmd -Load
REM   docker\build_ef5.cmd -Rebuild
REM   docker\build_ef5.cmd -Rebuild -NoCache
REM   docker\build_ef5.cmd -Save
REM ============================================================================
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"
set "SCRIPT_DIR=%CD%"
if defined EF5_IMAGE (
  set "IMAGE=%EF5_IMAGE%"
) else (
  set "IMAGE=ef5-container:latest"
)
set "ARCHIVE=%SCRIPT_DIR%\ef5-container.tar"

set "DO_REBUILD=0"
set "DO_LOAD=0"
set "DO_SAVE=0"
set "DO_STATUS=0"
set "NO_CACHE="

:parse
if "%~1"=="" goto parsed
if /I "%~1"=="-Status"  set "DO_STATUS=1" & shift & goto parse
if /I "%~1"=="--status" set "DO_STATUS=1" & shift & goto parse
if /I "%~1"=="-Load"    set "DO_LOAD=1" & shift & goto parse
if /I "%~1"=="--load"   set "DO_LOAD=1" & shift & goto parse
if /I "%~1"=="-Rebuild" set "DO_REBUILD=1" & shift & goto parse
if /I "%~1"=="--rebuild" set "DO_REBUILD=1" & shift & goto parse
if /I "%~1"=="-NoCache" set "NO_CACHE=--no-cache" & shift & goto parse
if /I "%~1"=="--no-cache" set "NO_CACHE=--no-cache" & shift & goto parse
if /I "%~1"=="-Save"    set "DO_SAVE=1" & shift & goto parse
if /I "%~1"=="--save"   set "DO_SAVE=1" & shift & goto parse
if /I "%~1"=="-h" goto usage
if /I "%~1"=="--help" goto usage
if /I "%~1"=="/?" goto usage
echo Option inconnue : %~1
goto usage

:parsed
where docker >nul 2>&1
if errorlevel 1 (
  echo ERREUR : docker est introuvable dans le PATH. Installez d'abord Docker Desktop.
  exit /b 1
)
docker info >nul 2>&1
if errorlevel 1 (
  echo ERREUR : impossible de joindre le demon Docker. Docker Desktop est-il demarre ?
  exit /b 1
)

echo ==============================================
echo   Image Docker EF5, construction ou reutilisation (Windows CMD)
echo ==============================================
echo   Image   : %IMAGE%
echo   Archive : %ARCHIVE%
echo ==============================================

if "%DO_STATUS%"=="1" goto status
if "%DO_LOAD%"=="1" goto load
if "%DO_REBUILD%"=="1" goto rebuild

REM par defaut : reutiliser / charger / construire
docker image inspect "%IMAGE%" >nul 2>&1
if not errorlevel 1 (
  echo ^>^>^> Reutilisation de l'image %IMAGE%
  echo     Pour une construction neuve : docker\build_ef5.cmd -Rebuild
  goto maybe_save
)
if exist "%ARCHIVE%" (
  echo ^>^>^> Image absente de la machine. Chargement de l'archive.
  goto do_load
)
echo ^>^>^> Ni image ni archive. Construction depuis le Dockerfile.
goto do_build

:status
docker image inspect "%IMAGE%" >nul 2>&1
if not errorlevel 1 (
  echo   Image ef5-container : PRESENTE sur la machine ^(%IMAGE%^)
  exit /b 0
)
if exist "%ARCHIVE%" (
  echo   Image ef5-container : NON chargee. Archive presente.
  echo   Chargez-la avec : docker\build_ef5.cmd -Load
  exit /b 0
)
echo   Image ef5-container : absente, et aucune archive. Construisez avec -Rebuild.
exit /b 0

:load
if not exist "%ARCHIVE%" (
  echo ERREUR : archive introuvable : %ARCHIVE%
  echo   Construisez d'abord : docker\build_ef5.cmd -Rebuild -Save
  exit /b 1
)
goto do_load

:do_load
echo ^>^>^> Chargement de l'image depuis %ARCHIVE%
docker load -i "%ARCHIVE%"
if errorlevel 1 exit /b 1
echo ^>^>^> Image chargee.
exit /b 0

:rebuild
echo ^>^>^> Construction de %IMAGE% depuis le Dockerfile (compilation d'EF5^)...
echo     Internet requis (clone AHWALab/EF5^). Compter quelques minutes.
goto do_build

:do_build
docker build %NO_CACHE% -t "%IMAGE%" "%SCRIPT_DIR%"
if errorlevel 1 exit /b 1
echo ^>^>^> Construction terminee.
goto maybe_save

:maybe_save
if not "%DO_SAVE%"=="1" goto done
echo ^>^>^> Enregistrement de %IMAGE% -^> %ARCHIVE%
docker save "%IMAGE%" -o "%ARCHIVE%"
if errorlevel 1 exit /b 1
for %%A in ("%ARCHIVE%") do echo     %%~fA  %%~zA octets
goto done

:done
echo.
echo   Termine. Image : %IMAGE%
echo   Executer EF5 :    run_ef5.cmd -Control control_30m.txt
echo   Verifier l'etat : docker\build_ef5.cmd -Status
exit /b 0

:usage
echo Utilisation : build_ef5.cmd [-Status^|-Load^|-Rebuild^|-NoCache^|-Save]
exit /b 1
