@echo off
REM Script to generate code coverage report locally (Windows)

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."

cd /d "%PROJECT_DIR%"

echo 📊 ErmesDart Code Coverage Generator
echo.

REM Generate coverage
echo 🧪 Running tests with coverage instrumentation...
dart test packages/ermes_test/test/ --coverage=coverage

if %ERRORLEVEL% equ 0 (
    echo.
    echo 📝 Converting to LCOV format...
    dart pub global activate coverage
    dart pub global run coverage:format_coverage --in=coverage --out=coverage/lcov.info --lcov --report-on=packages/ermes_core/lib,packages/ermes_signaling/lib,packages/ermes_cipher/lib

    echo ✅ Coverage report generated at coverage/lcov.info
    echo.

    REM Check if genhtml is available
    where genhtml >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        echo 📈 Generating HTML report...
        genhtml coverage/lcov.info -o coverage_html
        echo ✅ HTML report generated in coverage_html/
        echo.
        echo 🔗 View report:
        echo    start coverage_html\index.html
    ) else (
        echo 📝 To view as HTML, install genhtml:
        echo    dart pub global activate coverage
        echo    genhtml coverage/lcov.info -o coverage_html
    )
) else (
    echo.
    echo ❌ Coverage generation failed
    exit /b 1
)

endlocal
