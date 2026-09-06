@echo off
REM Kubernetes Deployment Setup Script for Windows
REM This script sets up and deploys the application to Minikube

setlocal enabledelayedexpansion

set NAMESPACE=registration-app
set REGISTRY=localhost:5000

echo ==========================================
echo Kubernetes Deployment Setup
echo ==========================================
echo.

echo [1/7] Checking prerequisites...
where kubectl >nul 2>nul
if errorlevel 1 (
    echo Error: kubectl is not installed
    exit /b 1
)
where minikube >nul 2>nul
if errorlevel 1 (
    echo Error: minikube is not installed
    exit /b 1
)
where docker >nul 2>nul
if errorlevel 1 (
    echo Error: docker is not installed
    exit /b 1
)
echo ✓ All prerequisites found
echo.

echo [2/7] Starting Minikube...
minikube status >nul 2>nul
if errorlevel 1 (
    minikube start --driver=docker --cpus=4 --memory=4096
) else (
    echo ✓ Minikube already running
)
echo.

echo [3/7] Enabling Minikube addons...
minikube addons enable ingress
echo ✓ Ingress addon enabled
echo.

echo [4/7] Setting up Docker registry...
for /f "tokens=*" %%i in ('minikube docker-env --shell cmd') do %%i
echo ✓ Docker environment configured
echo.

echo [5/7] Building Docker images...
echo Building backend image...
docker build -t registration-backend:latest .\backend

echo Building frontend-blue image...
docker build -t registration-frontend-blue:latest .\frontend-blue

echo Building frontend-green image...
docker build -t registration-frontend-green:latest .\frontend-green
echo ✓ All images built successfully
echo.

echo [6/7] Deploying to Kubernetes...
echo Creating namespace...
kubectl create namespace %NAMESPACE% --dry-run=client -o yaml ^| kubectl apply -f -

echo Applying ConfigMaps...
kubectl apply -f k8s\backend-configmap.yaml
kubectl apply -f k8s\frontend-configmap.yaml

echo Deploying MongoDB...
kubectl apply -f k8s\mongo-deployment.yaml

echo Waiting for MongoDB to be ready...
kubectl wait --for=condition=ready pod -l app=mongo -n %NAMESPACE% --timeout=300s

echo Deploying backend...
kubectl apply -f k8s\backend-deployment.yaml

echo Waiting for backend to be ready...
kubectl wait --for=condition=ready pod -l app=backend -n %NAMESPACE% --timeout=300s

echo Deploying frontends...
kubectl apply -f k8s\frontend-blue-deployment.yaml
kubectl apply -f k8s\frontend-green-deployment.yaml

echo Applying ingress configuration...
kubectl apply -f k8s\ingress.yaml
echo ✓ All deployments completed
echo.

echo [7/7] Getting service information...
echo.
echo ==========================================
echo Deployment Summary
echo ==========================================
echo.
echo Namespace: %NAMESPACE%
echo.
echo Services:
kubectl get services -n %NAMESPACE%
echo.
echo Deployments:
kubectl get deployments -n %NAMESPACE%
echo.
echo Pods:
kubectl get pods -n %NAMESPACE%
echo.

for /f "tokens=*" %%i in ('minikube ip') do set MINIKUBE_IP=%%i
echo Minikube IP: %MINIKUBE_IP%
echo.
echo Add these entries to your hosts file (C:\Windows\System32\drivers\etc\hosts):
echo %MINIKUBE_IP% registration.local
echo %MINIKUBE_IP% frontend-blue.local
echo %MINIKUBE_IP% frontend-green.local
echo.

echo Access the application at:
echo   - Main (Blue): http://registration.local
echo   - Direct Blue: http://frontend-blue.local
echo   - Direct Green: http://frontend-green.local
echo   - API: http://registration.local/api
echo.

echo To switch between blue and green deployments, use:
echo   blue-green-switch.bat blue
echo   blue-green-switch.bat green
echo   blue-green-switch.bat status
echo.
