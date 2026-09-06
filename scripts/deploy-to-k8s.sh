#!/bin/bash

# Kubernetes Deployment Setup Script
# This script sets up and deploys the application to Minikube

set -e

NAMESPACE="registration-app"
REGISTRY="localhost:5000"

echo "=========================================="
echo "Kubernetes Deployment Setup"
echo "=========================================="
echo ""

# Check prerequisites
echo "[1/7] Checking prerequisites..."
check_command() {
  if ! command -v $1 &> /dev/null; then
    echo "Error: $1 is not installed"
    exit 1
  fi
}

check_command kubectl
check_command minikube
check_command docker
echo "✓ All prerequisites found"
echo ""

# Start Minikube
echo "[2/7] Starting Minikube..."
if ! minikube status &> /dev/null; then
  minikube start --driver=docker --cpus=4 --memory=4096
else
  echo "✓ Minikube already running"
fi
echo ""

# Enable ingress addon
echo "[3/7] Enabling Minikube addons..."
minikube addons enable ingress
echo "✓ Ingress addon enabled"
echo ""

# Set up Docker registry
echo "[4/7] Setting up Docker registry..."
eval $(minikube docker-env)
echo "✓ Docker environment configured"
echo ""

# Build images
echo "[5/7] Building Docker images..."
echo "Building backend image..."
docker build -t registration-backend:latest ./backend

echo "Building frontend-blue image..."
docker build -t registration-frontend-blue:latest ./frontend-blue

echo "Building frontend-green image..."
docker build -t registration-frontend-green:latest ./frontend-green
echo "✓ All images built successfully"
echo ""

# Create namespace and deploy
echo "[6/7] Deploying to Kubernetes..."
echo "Creating namespace..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

echo "Applying ConfigMaps..."
kubectl apply -f k8s/backend-configmap.yaml
kubectl apply -f k8s/frontend-configmap.yaml

echo "Deploying MongoDB..."
kubectl apply -f k8s/mongo-deployment.yaml

echo "Waiting for MongoDB to be ready..."
kubectl wait --for=condition=ready pod -l app=mongo -n ${NAMESPACE} --timeout=300s

echo "Deploying backend..."
kubectl apply -f k8s/backend-deployment.yaml

echo "Waiting for backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend -n ${NAMESPACE} --timeout=300s

echo "Deploying frontends..."
kubectl apply -f k8s/frontend-blue-deployment.yaml
kubectl apply -f k8s/frontend-green-deployment.yaml

echo "Applying ingress configuration..."
kubectl apply -f k8s/ingress.yaml
echo "✓ All deployments completed"
echo ""

# Get service information
echo "[7/7] Getting service information..."
echo ""
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
echo ""
echo "Namespace: ${NAMESPACE}"
echo ""
echo "Services:"
kubectl get services -n ${NAMESPACE}
echo ""
echo "Deployments:"
kubectl get deployments -n ${NAMESPACE}
echo ""
echo "Pods:"
kubectl get pods -n ${NAMESPACE}
echo ""

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: ${MINIKUBE_IP}"
echo ""
echo "Add these entries to your /etc/hosts file:"
echo "${MINIKUBE_IP} registration.local"
echo "${MINIKUBE_IP} frontend-blue.local"
echo "${MINIKUBE_IP} frontend-green.local"
echo ""

echo "Access the application at:"
echo "  - Main (Blue): http://registration.local"
echo "  - Direct Blue: http://frontend-blue.local"
echo "  - Direct Green: http://frontend-green.local"
echo "  - API: http://registration.local/api"
echo ""

echo "To switch between blue and green deployments, use:"
echo "  bash scripts/blue-green-switch.sh blue"
echo "  bash scripts/blue-green-switch.sh green"
echo "  bash scripts/blue-green-switch.sh status"
echo ""
