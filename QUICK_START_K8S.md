# Kubernetes Deployment Quick Start

This guide will deploy the application to Minikube with blue-green capability.

## Prerequisites

- Minikube installed and working
- kubectl installed
- Docker installed
- ~4GB RAM and 4 CPU cores for Minikube
- Bash shell

## Quick Start (5-10 minutes)

### 1. Prepare Minikube

```bash
# Start Minikube with sufficient resources
minikube start --driver=docker --cpus=4 --memory=4096

# Enable ingress (required for routing)
minikube addons enable ingress

# Verify status
minikube status
```

### 2. Configure Docker Environment

```bash
# Point Docker to Minikube's daemon
eval $(minikube docker-env)

# Verify connection (should show Minikube's Docker)
docker ps
```

### 3. Run Automated Deployment

```bash
cd Blue-green-Deployment

# Make script executable (if not already)
chmod +x scripts/deploy-to-k8s.sh

# Run deployment (automated setup)
bash scripts/deploy-to-k8s.sh
```

The script will:
- ✓ Check prerequisites
- ✓ Start Minikube
- ✓ Enable addons
- ✓ Build Docker images
- ✓ Deploy all Kubernetes resources
- ✓ Show access instructions

### 4. Configure Hosts File

After deployment, add to your hosts file (`/etc/hosts` on Linux/Mac, `C:\Windows\System32\drivers\etc\hosts` on Windows):

```
# Get Minikube IP (from script output)
<MINIKUBE_IP> registration.local
<MINIKUBE_IP> frontend-blue.local
<MINIKUBE_IP> frontend-green.local
```

### 5. Access the Application

Open your browser:

| URL | Description |
|-----|-------------|
| http://registration.local | Main app (default: blue) |
| http://frontend-blue.local | Direct access to blue (basic UI) |
| http://frontend-green.local | Direct access to green (enhanced UI) |
| http://registration.local/api | Backend API |

## Blue-Green Deployment

### View Current Status

```bash
bash scripts/blue-green-switch.sh status
```

### Switch to Blue (Basic UI)

```bash
bash scripts/blue-green-switch.sh blue
# Then refresh http://registration.local
```

### Switch to Green (Enhanced UI)

```bash
bash scripts/blue-green-switch.sh green
# Then refresh http://registration.local
```

## Monitoring

### Check Deployment Status

```bash
# Check all resources
kubectl get all -n registration-app

# Check specific deployments
kubectl get deployments -n registration-app

# Check pods (should be Running and Ready)
kubectl get pods -n registration-app

# Check services
kubectl get services -n registration-app
```

### View Logs

```bash
# Backend logs
kubectl logs -n registration-app -l app=backend

# Blue frontend logs
kubectl logs -n registration-app -l deployment=blue

# Green frontend logs
kubectl logs -n registration-app -l deployment=green

# Follow logs in real-time
kubectl logs -f -n registration-app -l app=backend
```

### Describe a Pod

```bash
# Get detailed info about a pod
kubectl describe pod <pod-name> -n registration-app

# Example: describe the first backend pod
kubectl describe pod $(kubectl get pods -n registration-app -l app=backend -o name | head -1)
```

## Common Commands

```bash
# Access cluster info
kubectl cluster-info

# Get context and cluster details
kubectl config current-context
kubectl get nodes

# Check namespace resources
kubectl get all -n registration-app

# Scale a deployment
kubectl scale deployment backend -n registration-app --replicas=5

# Restart a deployment
kubectl rollout restart deployment backend -n registration-app

# Check rollout status
kubectl rollout status deployment backend -n registration-app

# Get ingress details
kubectl describe ingress registration-ingress -n registration-app

# Debug with port-forward
kubectl port-forward -n registration-app svc/backend 5000:5000
```

## Manual Kubernetes Deployment

If the automated script doesn't work, deploy manually:

```bash
# Create namespace and resources in order
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/backend-configmap.yaml
kubectl apply -f k8s/frontend-configmap.yaml
kubectl apply -f k8s/mongo-deployment.yaml

# Wait for MongoDB
kubectl wait --for=condition=ready pod -l app=mongo -n registration-app --timeout=300s

# Deploy backend and frontends
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-blue-deployment.yaml
kubectl apply -f k8s/frontend-green-deployment.yaml

# Apply ingress (last, after services exist)
kubectl apply -f k8s/ingress.yaml

# Verify all pods are running
kubectl get pods -n registration-app
```

## Testing the Deployment

### Test 1: Check Services

```bash
# All services should have endpoints
kubectl get services -n registration-app
```

### Test 2: Test API from Inside Cluster

```bash
# Start a test pod
kubectl run -it --rm debug --image=alpine --restart=Never -n registration-app -- sh

# Inside the pod, test connectivity:
apk add --no-cache curl

# Test backend
curl http://backend:5000/health

# Test blue frontend
curl http://frontend-blue:3100/health

# Test green frontend
curl http://frontend-green:3200/health

# Exit pod
exit
```

### Test 3: Test Blue-Green Switching

```bash
# Show current selector
kubectl get service frontend-lb -n registration-app -o jsonpath='{.spec.selector}' | jq

# Switch to blue
bash scripts/blue-green-switch.sh blue

# Show updated selector
kubectl get service frontend-lb -n registration-app -o jsonpath='{.spec.selector}' | jq

# Should now show: {"app":"frontend","deployment":"blue"}

# Switch to green
bash scripts/blue-green-switch.sh green

# Should now show: {"app":"frontend","deployment":"green"}
```

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n registration-app

# Describe a pod to see events
kubectl describe pod <pod-name> -n registration-app

# Check logs for errors
kubectl logs <pod-name> -n registration-app
```

### Images not found

```bash
# Verify images exist in Minikube
eval $(minikube docker-env)
docker images | grep registration

# If missing, rebuild
docker build -t registration-backend:latest ./backend
docker build -t registration-frontend-blue:latest ./frontend-blue
docker build -t registration-frontend-green:latest ./frontend-green
```

### Services not accessible

```bash
# Check ingress configuration
kubectl describe ingress registration-ingress -n registration-app

# Check hosts file (make sure entries are added)
# Linux/Mac: cat /etc/hosts | grep registration
# Windows: type C:\Windows\System32\drivers\etc\hosts | findstr registration

# Try accessing via NodePort directly (if ingress fails)
MINIKUBE_IP=$(minikube ip)
curl http://$MINIKUBE_IP:<NodePort>
```

### Blue-Green switch not working

```bash
# Verify service exists
kubectl get service frontend-lb -n registration-app

# Check if pods are running for both deployments
kubectl get pods -n registration-app -l app=frontend

# Manually switch (if script fails)
kubectl patch service frontend-lb -n registration-app \
  -p '{"spec":{"selector":{"deployment":"green"}}}'
```

## Cleanup

```bash
# Delete all resources
kubectl delete namespace registration-app

# Stop Minikube
minikube stop

# Delete Minikube (if needed)
minikube delete
```

## Production Considerations

For production deployment beyond Minikube:

1. **Use a real Kubernetes cluster** (AWS EKS, GCP GKE, Azure AKS, etc.)
2. **Use container registries** (Docker Hub, ECR, GCR, etc.)
3. **Implement SSL/TLS** with cert-manager
4. **Set up monitoring** with Prometheus and Grafana
5. **Add logging** with ELK stack or similar
6. **Implement resource quotas** for cost control
7. **Use RBAC** for access control
8. **Enable network policies** for security
9. **Implement pod disruption budgets** for availability
10. **Use GitOps** with ArgoCD or Flux

---

**Deployment Duration**: ~5-10 minutes  
**Resources Used**: ~4GB RAM, 4 CPU cores  
**Cluster Type**: Minikube (local development)
