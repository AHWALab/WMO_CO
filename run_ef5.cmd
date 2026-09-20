@echo off
REM ============================================================================
REM run_ef5.cmd : Windows CMD pur (sans PowerShell)
REM ============================================================================
REM Evite completement les blocages lies a la strategie d'execution PowerShell
REM et aux strategies de groupe.
REM
REM Utilisation (depuis la racine du dossier) :
REM   run_ef5.cmd
REM   run_ef5.cmd -Control control_30m.txt
REM   run_ef5.cmd -Bash
REM ============================================================================
setlocal EnableExtensions EnableDelayedExpansion

cd /d "%~dp0"
set "ROOT=%CD%"
if defined EF5_IMAGE (
  set "IMAGE=%EF5_IMAGE%"
) else (
  set "IMAGE=ef5-container:latest"
)
set "CONTROL=control_30m.txt"
set "DO_BASH=0"

:parse
if "%~1"=="" goto parsed
if /I "%~1"=="-Control" (
  if "%~2"=="" (
    echo ERREUR : -Control demande un nom de fichier
    exit /b 1
  )
  set "CONTROL=%~2"
  shift & shift & goto parse
)
if /I "%~1"=="--control" (
  if "%~2"=="" (
    echo ERREUR : --control demande un nom de fichier
    exit /b 1
  )
  set "CONTROL=%~2"
  shift & shift & goto parse
)
if /I "%~1"=="-Bash" set "DO_BASH=1" & shift & goto parse
if /I "%~1"=="--bash" set "DO_BASH=1" & shift & goto parse
if /I "%~1"=="-b" set "DO_BASH=1" & shift & goto parse
if /I "%~1"=="-h" goto usage
if /I "%~1"=="--help" goto usage
if /I "%~1"=="/?" goto usage
REM accepte un nom de fichier de controle en premier argument :
REM   run_ef5.cmd control_30m.txt
if not "%~1"=="" if "%CONTROL%"=="control_30m.txt" if "%DO_BASH%"=="0" (
  set "CONTROL=%~1"
  shift & goto parse
)
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

REM S'assurer que l'image existe (reutiliser / charger / construire, en CMD pur)
docker image inspect "%IMAGE%" >nul 2>&1
if errorlevel 1 (
  echo Image %IMAGE% introuvable. Preparation en cours...
  call "%ROOT%\docker\build_ef5.cmd"
  if errorlevel 1 exit /b 1
)

if not defined OMP_NUM_THREADS (
  set "OMP_NUM_THREADS=%NUMBER_OF_PROCESSORS%"
)

if "%DO_BASH%"=="1" (
  echo Ouverture d'un terminal interactif dans le conteneur EF5...
  echo   /data   -^> %ROOT%\data
  echo   /output -^> %ROOT%\output
  echo   /conf   -^> %ROOT%\conf
  docker compose run --rm ef5 /bin/sh
  exit /b %ERRORLEVEL%
)

REM Retire le prefixe conf\ ou conf/ s'il est present
set "CTRL=%CONTROL%"
if /I "%CTRL:~0,5%"=="conf\" set "CTRL=%CTRL:~5%"
if /I "%CTRL:~0,5%"=="conf/" set "CTRL=%CTRL:~5%"

if not exist "%ROOT%\conf\%CTRL%" (
  echo ERREUR : fichier de controle introuvable : %ROOT%\conf\%CTRL%
  echo   Il doit se trouver dans conf\
  exit /b 1
)

echo ==============================================
echo   EF5 Docker, execution (Windows CMD)
echo ==============================================
echo   Image    : %IMAGE%
echo   Controle : %ROOT%\conf\%CTRL%
echo   Donnees  : %ROOT%\data    -^> /data
echo   Sorties  : %ROOT%\output  -^> /output
echo   Conf     : %ROOT%\conf    -^> /conf
echo   OMP      : %OMP_NUM_THREADS% fils d'execution
echo ==============================================

docker compose run --rm -e "OMP_NUM_THREADS=%OMP_NUM_THREADS%" ef5 /ef5/bin/ef5 "/conf/%CTRL%"
if errorlevel 1 exit /b 1

echo.
echo Execution d'EF5 terminee. Les resultats sont dans %ROOT%\output\
exit /b 0

:usage
echo Utilisation :
echo   run_ef5.cmd
echo   run_ef5.cmd -Control control_30m.txt
echo   run_ef5.cmd -Bash
exit /b 1
