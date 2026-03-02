@echo off
REM Script to run tests with automatic Docker Compose setup for Ganache (Windows)

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."

cd /d "%PROJECT_DIR%"
dart run tool/test_runner.dart %*

endlocal
