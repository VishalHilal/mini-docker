@echo off
REM Mini-Docker Helper Script for Windows

setlocal enabledelayedexpansion

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running. Please start Docker first.
    exit /b 1
)

REM Main script logic
if "%1"=="start" (
    echo [INFO] Starting mini-docker services with profile: %~2
    if "%~2"=="testing" (
        docker-compose --profile testing up -d
    ) else if "%~2"=="dev" (
        docker-compose --profile dev up -d
    ) else (
        docker-compose up -d engine
    )
    echo [INFO] Services started successfully!
) else if "%1"=="stop" (
    echo [INFO] Stopping mini-docker services...
    docker-compose down
    echo [INFO] Services stopped successfully!
) else if "%1"=="restart" (
    echo [INFO] Restarting mini-docker services...
    docker-compose down
    timeout /t 2 /nobreak >nul
    if "%~2"=="testing" (
        docker-compose --profile testing up -d
    ) else if "%~2"=="dev" (
        docker-compose --profile dev up -d
    ) else (
        docker-compose up -d engine
    )
    echo [INFO] Services restarted successfully!
) else if "%1"=="logs" (
    echo [INFO] Showing logs for service: %~2
    if "%~2"=="" (
        docker-compose logs -f engine
    ) else (
        docker-compose logs -f %~2
    )
) else if "%1"=="test" (
    echo [INFO] Testing CLI commands...
    echo [INFO] Waiting for engine to be healthy...
    docker-compose exec cli go run ./cmd/docker/main.go images
    docker-compose exec cli go run ./cmd/docker/main.go ps
    echo [INFO] CLI test completed!
) else if "%1"=="status" (
    echo [INFO] Mini-Docker Service Status:
    docker-compose ps
) else if "%1"=="cleanup" (
    echo [WARN] Cleaning up mini-docker resources...
    docker-compose down -v --remove-orphans
    docker system prune -f
    echo [INFO] Cleanup completed!
) else if "%1"=="help" goto :help
else if "%1"=="-h" goto :help
else if "%1"=="--help" goto :help
else (
    echo [ERROR] Unknown command: %1
    echo Use '%0 help' for usage information.
    exit /b 1
)

goto :eof

:help
echo Mini-Docker Helper Script
echo.
echo Usage: %0 [COMMAND] [OPTIONS]
echo.
echo Commands:
echo   start [profile]    Start services (profiles: basic, testing, dev)
echo   stop               Stop all services
echo   restart [profile]  Restart services
echo   logs [service]     Show logs for service (default: engine)
echo   test               Test CLI commands
echo   status             Show service status
echo   cleanup            Clean up all resources
echo   help               Show this help message
echo.
echo Examples:
echo   %0 start           # Start engine only
echo   %0 start testing   # Start engine and CLI
echo   %0 start dev       # Start development environment
echo   %0 logs engine     # Show engine logs
echo   %0 test            # Test CLI functionality
goto :eof
