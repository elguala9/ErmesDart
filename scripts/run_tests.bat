@echo off
REM Script to run tests with automatic Docker Compose setup for Ganache (Windows)

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_DIR=%SCRIPT_DIR%.."
set "DOCKER_COMPOSE_FILE=%PROJECT_DIR%\docker-compose-evm.yml"

echo.
echo 🧪 Testing ErmesDart with optional Ganache support...
echo.

REM Check if Docker is available
where docker >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ Docker is available

    REM Check if docker daemon is running
    docker ps >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo ✅ Docker daemon is running

        REM Try to start Ganache
        if exist "%DOCKER_COMPOSE_FILE%" (
            echo 🚀 Starting Ganache from docker-compose...
            docker-compose -f "%DOCKER_COMPOSE_FILE%" up -d

            REM Wait for Ganache to be ready
            echo ⏳ Waiting for Ganache to be ready...
            setlocal enabledelayedexpansion
            for /l %%i in (1,1,30) do (
                curl -s -X POST http://localhost:9545 -H "Content-Type: application/json" -d "{\"jsonrpc\":\"2.0\",\"method\":\"web3_clientVersion\",\"id\":1}" >nul 2>&1
                if !ERRORLEVEL! EQU 0 (
                    echo ✅ Ganache is ready!
                    goto ganache_ready
                )
                if %%i EQU 30 (
                    echo ⚠️  Ganache not responding, continuing with skipped tests...
                    goto ganache_ready
                )
                timeout /t 1 /nobreak >nul
            )
            :ganache_ready
        )
    ) else (
        echo ⚠️  Docker daemon is not running, continuing with skipped Ganache tests...
    )
) else (
    echo ⚠️  Docker not available, ErmesSignalingServer tests will be skipped
)

echo.
echo Running tests...
cd /d "%PROJECT_DIR%"
call dart test packages/ermes_test/test/

REM Optional: Stop Ganache after tests
if exist "%DOCKER_COMPOSE_FILE%" (
    echo.
    echo 🛑 Stopping Ganache...
    docker-compose -f "%DOCKER_COMPOSE_FILE%" down
)

endlocal
