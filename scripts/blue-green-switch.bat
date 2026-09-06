@echo off
REM Blue-Green Deployment Switch Script for Windows
REM This script switches traffic between blue (basic UI) and green (enhanced UI) deployments

setlocal enabledelayedexpansion

set NAMESPACE=registration-app
set FRONTEND_LB=frontend-lb

:main
if "%1"=="" (
    call :show_help
    exit /b 1
)

if /i "%1"=="blue" (
    call :switch_to_blue
) else if /i "%1"=="green" (
    call :switch_to_green
) else if /i "%1"=="status" (
    call :print_status
) else if /i "%1"=="help" (
    call :show_help
) else if /i "%1"=="-h" (
    call :show_help
) else if /i "%1"=="--help" (
    call :show_help
) else (
    echo Unknown command: %1
    call :show_help
    exit /b 1
)

exit /b 0

:switch_to_blue
echo Switching traffic to BLUE deployment (Basic UI)...
kubectl patch service %FRONTEND_LB% -n %NAMESPACE% -p "{"spec":{"selector":{"deployment":"blue"}}}"
echo ✓ Traffic switched to BLUE deployment
call :print_status
exit /b 0

:switch_to_green
echo Switching traffic to GREEN deployment (Enhanced UI)...
kubectl patch service %FRONTEND_LB% -n %NAMESPACE% -p "{"spec":{"selector":{"deployment":"green"}}}"
echo ✓ Traffic switched to GREEN deployment
call :print_status
exit /b 0

:print_status
echo ===================================================
echo Current Frontend Service Configuration:
echo ===================================================
kubectl get service %FRONTEND_LB% -n %NAMESPACE% -o jsonpath="{.spec.selector}" | find /v ""
echo.
exit /b 0

:show_help
echo Blue-Green Deployment Switch Script
echo Usage: %0% [command]
echo.
echo Commands:
echo   blue     - Switch traffic to blue deployment (basic UI)
echo   green    - Switch traffic to green deployment (enhanced UI)
echo   status   - Show current deployment status
echo   help     - Show this help message
echo.
exit /b 0
