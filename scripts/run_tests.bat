@echo off
REM Script to run tests

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."

cd /d "%PROJECT_DIR%"
dart test packages/ermes_test/test/

endlocal
