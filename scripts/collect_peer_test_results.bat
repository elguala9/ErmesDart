@echo off
REM Collect Docker peer test results and create summary report (Windows)

setlocal enabledelayedexpansion

set RESULTS_DIR=test_results
set SUMMARY_FILE=test_results_summary.json

echo 📊 Collecting peer test results...

if not exist "%RESULTS_DIR%" (
    echo ❌ No test results directory found at %RESULTS_DIR%
    exit /b 1
)

REM Count JSON files
for /f %%A in ('dir /b "%RESULTS_DIR%\*_result.json" 2^>nul ^| find /c /v ""') do set RESULT_COUNT=%%A

if "%RESULT_COUNT%"=="0" (
    echo ❌ No peer test results found in %RESULTS_DIR%
    exit /b 1
)

echo ✅ Found %RESULT_COUNT% peer results

REM Create summary (simplified for Windows batch)
(
    echo.{
    echo.  "timestamp": "%date% %time%",
    echo.  "total_peers": %RESULT_COUNT%,
    echo.  "results": [
) > "%SUMMARY_FILE%"

setlocal enabledelayedexpansion
set first=1
for /f "tokens=*" %%F in ('dir /b "%RESULTS_DIR%\*_result.json"') do (
    if !first! equ 0 (
        echo. , >> "%SUMMARY_FILE%"
    )
    type "%RESULTS_DIR%\%%F" >> "%SUMMARY_FILE%"
    set first=0
)

(
    echo.  ]
    echo.}
) >> "%SUMMARY_FILE%"

echo.
echo ✅ Test summary saved to: %SUMMARY_FILE%
echo.
echo 📄 Summary:
type "%SUMMARY_FILE%"

REM Count passed
set /a total_success=0
for /f "tokens=*" %%F in ('dir /b "%RESULTS_DIR%\*_result.json"') do (
    REM Note: Simple check - in production use PowerShell or jq
    findstr /M "\"success\": true" "%RESULTS_DIR%\%%F" >nul && set /a total_success+=1
)

echo.
if "%total_success%"=="%RESULT_COUNT%" (
    echo 🎉 ALL PEER TESTS PASSED!
    exit /b 0
) else (
    echo ❌ SOME PEER TESTS FAILED (%total_success%/%RESULT_COUNT%)
    exit /b 1
)
