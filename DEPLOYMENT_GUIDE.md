# Blue-Green Deployment Project - Complete Guide

## Overview
This project demonstrates a complete DevOps workflow for deploying a Node.js registration application using blue-green deployment strategy with Docker and Kubernetes (Minikube). The application consists of:

- **Backend**: Express.js REST API with MongoDB
- **Frontend-Blue**: Basic HTML/CSS registration form
- **Frontend-Green**: Enhanced multi-step registration form with Font Awesome icons

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                    │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐         ┌──────────────┐              │
│  │ Frontend-LB  │         │   Ingress    │              │
│  │  (Switched)  │◄────────┤  (NGINX)     │              │
│  └──────┬───────┘         └──────────────┘              │
│         │                                                │
│    ┌────┴────────────────────┐                          │
│    │                         │                          │
│  ┌─▼──────────┐        ┌─────▼───────┐                 │
│  │  Blue      │        │    Green    │                 │
│  │  (Basic)   │        │  (Enhanced) │                 │
│  └────────────┘        └─────────────┘                 │
│         │                    │                          │
│         └────────┬───────────┘                          │
│                  │                                      │
│          ┌───────▼────────┐                            │
│          │   Backend API  │                            │
│          └───────┬────────┘                            │
│                  │                                      │
│          ┌───────▼────────┐                            │
│          │    MongoDB     │                            │
│          └────────────────┘                            │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

- **Docker Desktop** or **Docker Engine**
- **Minikube** (version 1.20+)
- **kubectl** (version 1.20+)
- **Node.js** (version 16+)
- **Git**
- **bash** shell (for scripts)

## Project Structure

```
Blue-green-Deployment/
├── backend/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   ├── .env
│   ├── models/
│   │   └── user.js
│   └── routes/
│       └── users.js
├── frontend-blue/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   ├── .env
│   └── public/
│       ├── index.html
│       └── styles.css
├── frontend-green/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   ├── .env
│   └── public/
│       ├── app.js
│       ├── index.html
│       └── styles.css
├── docker-compose.yml
├── k8s/
│   ├── namespace.yaml
│   ├── backend-configmap.yaml
│   ├── frontend-configmap.yaml
│   ├── mongo-deployment.yaml
│   ├── backend-deployment.yaml
│   ├── frontend-blue-deployment.yaml
│   ├── frontend-green-deployment.yaml
│   └── ingress.yaml
├── scripts/
│   ├── deploy-to-k8s.sh
│   └── blue-green-switch.sh
└── README.md
```

## Part 1: Local Deployment

### Step 1: Clone and Setup

```bash
cd Blue-green-Deployment
```

### Step 2: Install Dependencies

```bash
# Backend
cd backend
npm install
cd ..

# Frontend Blue
cd frontend-blue
npm install
cd ..

# Frontend Green
cd frontend-green
npm install
cd ..
```

### Step 3: Verify Environment Files

Environment files are pre-configured:
- `backend/.env` - Backend configuration
- `frontend-blue/.env` - Blue frontend configuration
- `frontend-green/.env` - Green frontend configuration

### Step 4: Start Services with Docker Compose

```bash
# Build and start all services
docker-compose up --build

# Or detached mode
docker-compose up -d --build

# Check status
docker-compose ps

# View logs
docker-compose logs -f [service-name]
```

### Step 5: Verify Application

```bash
# Backend health
curl http://localhost:5000/health

# Frontend Blue
curl http://localhost:3100/health

# Frontend Green
curl http://localhost:3200/health

# MongoDB connection (via backend)
curl http://localhost:5000/api/users
```

### Access URLs

- **Backend API**: http://localhost:5000
- **Frontend Blue (Basic)**: http://localhost:3100
- **Frontend Green (Enhanced)**: http://localhost:3200
- **MongoDB**: mongodb://localhost:27017

### Stop Services

```bash
docker-compose down

# Remove volumes (clean database)
docker-compose down -v
```

## Part 2: Containerization

### Dockerfile Strategy

All components use multi-stage builds for optimization:

1. **Build Stage**: Install dependencies
2. **Runtime Stage**: Copy only production dependencies

### Key Features of Dockerfiles:

- **Multi-stage builds** for reduced image size
- **Health checks** built into containers
- **Non-root user** for security (UID 1000)
- **Alpine base images** for smaller footprint
- **Proper signal handling** for graceful shutdown

### Building Images Manually

```bash
# Backend
docker build -t registration-backend:latest ./backend

# Frontend Blue
docker build -t registration-frontend-blue:latest ./frontend-blue

# Frontend Green
docker build -t registration-frontend-green:latest ./frontend-green

# Verify images
docker images | grep registration
```

### Running Individual Containers

```bash
# MongoDB
docker run -d --name mongo \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD=password \
  -p 27017:27017 \
  mongo:7.0-alpine

# Backend
docker run -d --name backend \
  -e MONGO_URI="mongodb://admin:password@mongo:27017/registration-db?authSource=admin" \
  -e PORT=5000 \
  -p 5000:5000 \
  --link mongo \
  registration-backend:latest

# Frontend Blue
docker run -d --name frontend-blue \
  -e PORT=3100 \
  -p 3100:3100 \
  registration-frontend-blue:latest

# Frontend Green
docker run -d --name frontend-green \
  -e PORT=3200 \
  -p 3200:3200 \
  registration-frontend-green:latest
```

## Part 3: Kubernetes Deployment

### Step 1: Start Minikube

```bash
# Start Minikube with sufficient resources
minikube start --driver=docker --cpus=4 --memory=4096

# Check status
minikube status

# Get Minikube IP
minikube ip
```

### Step 2: Set Up Docker Environment

```bash
# Configure Docker to use Minikube's Docker daemon
eval $(minikube docker-env)

# Verify connection
docker ps
```

### Step 3: Build Images for Minikube

```bash
# Build all images (in Minikube's Docker environment)
docker build -t registration-backend:latest ./backend
docker build -t registration-frontend-blue:latest ./frontend-blue
docker build -t registration-frontend-green:latest ./frontend-green
```

### Step 4: Enable Required Addons

```bash
# Enable Ingress controller
minikube addons enable ingress

# Enable metrics
minikube addons enable metrics-server

# Verify addons
minikube addons list
```

### Step 5: Deploy Application

**Automated Deployment** (Recommended):

```bash
# Make script executable
chmod +x scripts/deploy-to-k8s.sh

# Run deployment script
bash scripts/deploy-to-k8s.sh
```

**Manual Deployment**:

```bash
# Create namespace
kubectl create namespace registration-app

# Apply manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/backend-configmap.yaml
kubectl apply -f k8s/frontend-configmap.yaml
kubectl apply -f k8s/mongo-deployment.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-blue-deployment.yaml
kubectl apply -f k8s/frontend-green-deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

### Step 6: Verify Deployment

```bash
# Check namespace
kubectl get namespace

# Check pods
kubectl get pods -n registration-app

# Check services
kubectl get services -n registration-app

# Check deployments
kubectl get deployments -n registration-app

# Check ingress
kubectl get ingress -n registration-app

# View pod logs
kubectl logs -n registration-app -l app=backend
```

### Step 7: Configure Hosts File

Get Minikube IP and add to `/etc/hosts`:

```bash
# Get IP
MINIKUBE_IP=$(minikube ip)

# Add to /etc/hosts (Windows: C:\Windows\System32\drivers\etc\hosts)
# Linux/Mac: /etc/hosts
# Add these lines:
# $MINIKUBE_IP registration.local
# $MINIKUBE_IP frontend-blue.local
# $MINIKUBE_IP frontend-green.local
```

### Access Kubernetes Application

```bash
# Main application (default to blue)
http://registration.local

# Direct access to blue
http://frontend-blue.local

# Direct access to green
http://frontend-green.local

# Backend API
http://registration.local/api
```

## Part 4: Blue-Green Deployment Implementation

### Strategy Overview

The blue-green deployment uses two identical production environments running different frontend versions:

- **Blue Environment**: Basic HTML/CSS UI
- **Green Environment**: Enhanced multi-step UI with Font Awesome

### How It Works

1. **Two Separate Deployments**: Both versions run simultaneously in Kubernetes
2. **Single Load Balancer Service**: Routes traffic based on selector
3. **Zero-Downtime Switching**: Change service selector to switch traffic
4. **Easy Rollback**: Switch back to previous version instantly

### Switching Deployments

```bash
# Make script executable
chmod +x scripts/blue-green-switch.sh

# View current status
bash scripts/blue-green-switch.sh status

# Switch to blue deployment (basic UI)
bash scripts/blue-green-switch.sh blue

# Switch to green deployment (enhanced UI)
bash scripts/blue-green-switch.sh green
```

### Manual Switching with kubectl

```bash
# Switch to blue
kubectl patch service frontend-lb -n registration-app \
  -p '{"spec":{"selector":{"deployment":"blue"}}}'

# Switch to green
kubectl patch service frontend-lb -n registration-app \
  -p '{"spec":{"selector":{"deployment":"green"}}}'

# Verify current selection
kubectl get service frontend-lb -n registration-app -o jsonpath='{.spec.selector}'
```

### Monitoring Deployments

```bash
# Watch deployment status
kubectl rollout status deployment/frontend-blue -n registration-app
kubectl rollout status deployment/frontend-green -n registration-app

# Get deployment history
kubectl rollout history deployment/frontend-blue -n registration-app

# Scale replicas
kubectl scale deployment frontend-blue -n registration-app --replicas=3
kubectl scale deployment frontend-green -n registration-app --replicas=3
```

### Testing Blue-Green Switch

1. **Access Blue Version**:
   ```bash
   bash scripts/blue-green-switch.sh blue
   # Visit http://registration.local
   # Should see "Version: Basic UI"
   ```

2. **Access Green Version**:
   ```bash
   bash scripts/blue-green-switch.sh green
   # Visit http://registration.local
   # Should see "Version: Enhanced UI" with multi-step form
   ```

3. **Verify Traffic Switch**:
   ```bash
   # Check service labels before and after switching
   bash scripts/blue-green-switch.sh status
   ```

## Key Kubernetes Concepts Implemented

### 1. Deployments
- Replicas for high availability (3 for backend, 2 for frontends)
- Rolling update strategy
- Resource requests and limits

### 2. Services
- ClusterIP services for internal communication
- Service selectors for traffic routing
- Loadbalancer service for blue-green switching

### 3. ConfigMaps
- Environment variable management
- Centralized configuration
- Easy updates without container rebuild

### 4. Health Checks
- **Liveness Probes**: Restart unhealthy containers
- **Readiness Probes**: Remove from service load balancing
- HTTP-based health endpoints
- Initial delay and failure thresholds

### 5. Resource Management
- **Requests**: Minimum guaranteed resources
- **Limits**: Maximum allowed resources
- CPU and Memory constraints

### 6. Security Context
- Non-root user execution (UID 1000)
- Privilege escalation prevention
- Read-only filesystem for select volumes

### 7. Persistent Volumes
- MongoDB data persistence
- 5Gi storage allocation
- Lifecycle management

### 8. Ingress
- NGINX ingress controller
- Path-based routing
- Virtual host configuration

## Troubleshooting

### Common Issues and Solutions

#### Pods not starting
```bash
# Check pod status and events
kubectl describe pod <pod-name> -n registration-app

# Check logs
kubectl logs <pod-name> -n registration-app

# Common reasons:
# - Image not found: Ensure images are built in Minikube's Docker
# - Port conflicts: Check if ports are already in use
# - Insufficient resources: Allocate more memory to Minikube
```

#### Services not accessible
```bash
# Check service configuration
kubectl get service <service-name> -n registration-app -o yaml

# Test connectivity
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# Inside pod:
wget http://backend:5000/health

# Check ingress
kubectl describe ingress registration-ingress -n registration-app
```

#### MongoDB connection issues
```bash
# Check MongoDB pod logs
kubectl logs -n registration-app -l app=mongo

# Test MongoDB connection from another pod
kubectl exec -it <backend-pod> -n registration-app -- \
  mongosh mongodb://admin:password@mongo:27017/registration-db
```

#### Blue-Green switch not working
```bash
# Verify service selector
kubectl get service frontend-lb -n registration-app -o jsonpath='{.spec.selector}' | jq

# Verify deployment labels
kubectl get pods -n registration-app --show-labels

# Check if pods are ready
kubectl get pods -n registration-app -o wide
```

## Cleanup

### Remove from Kubernetes
```bash
# Delete all resources in namespace
kubectl delete namespace registration-app

# Or delete specific resources
kubectl delete -f k8s/
```

### Remove Docker Containers
```bash
# Stop all containers
docker-compose down -v

# Remove images
docker rmi registration-backend:latest
docker rmi registration-frontend-blue:latest
docker rmi registration-frontend-green:latest
docker rmi mongo:7.0-alpine
```

### Stop Minikube
```bash
# Stop Minikube
minikube stop

# Delete Minikube (if needed)
minikube delete
```

## Implementation Details

### Backend API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/users | Create new user |
| GET | /api/users | Get all users |
| GET | /api/users/count | Get user count statistics |
| GET | /health | Health check |

### Frontend Differences

#### Blue (Basic)
- Simple single-page form
- All fields on one page
- Basic CSS styling
- Direct to backend submission

#### Green (Enhanced)
- Multi-step form (3 steps)
- Progress indicator
- Font Awesome icons
- Tag-based input for interests and languages
- Better UX with step-by-step validation
- Professional styling

### Database Schema

```javascript
{
  _id: ObjectId,
  name: String (required),
  surname: String (required),
  dob: Date (required),
  job: String (required),
  place: String (required),
  interests: [String] (required),
  knownLanguages: [String] (required),
  registrationDate: Date (default: now),
  registeredFrom: String (enum: ['basic', 'enhanced'], required)
}
```

## Performance Optimization

### Docker Image Size
- **Alpine base images**: ~5MB
- **Multi-stage builds**: Only production dependencies
- **Average image size**: 50-80MB

### Kubernetes Resource Usage
- **Backend**: 256Mi requested, 512Mi limit
- **Frontend**: 128Mi requested, 256Mi limit
- **MongoDB**: 256Mi requested, 512Mi limit

### Scaling
```bash
# Scale backend to 5 replicas
kubectl scale deployment backend -n registration-app --replicas=5

# Scale frontend blue to 3 replicas
kubectl scale deployment frontend-blue -n registration-app --replicas=3
```

## Best Practices Implemented

1. ✅ **Infrastructure as Code**: All configs in YAML
2. ✅ **Health Checks**: Liveness and readiness probes
3. ✅ **Resource Limits**: CPU and memory constraints
4. ✅ **Security**: Non-root users, no privilege escalation
5. ✅ **Logging**: Container and Kubernetes logging
6. ✅ **Monitoring**: Health endpoints and metrics
7. ✅ **Zero-Downtime Updates**: Rolling updates
8. ✅ **High Availability**: Multiple replicas
9. ✅ **Easy Rollback**: Blue-green strategy
10. ✅ **Environment Separation**: ConfigMaps for config

## Learning Outcomes

Through this project, you'll learn:

1. **Docker**: Multi-stage builds, health checks, image optimization
2. **Docker Compose**: Service orchestration locally
3. **Kubernetes**: Deployments, Services, ConfigMaps, Ingress
4. **Blue-Green Deployment**: Zero-downtime switching strategy
5. **DevOps**: Complete deployment pipeline
6. **YAML**: Kubernetes manifest configuration
7. **Scripting**: Bash automation for deployment
8. **Monitoring**: Health checks and logging

## Verification Checklist

- [ ] All dependencies installed (Node.js, Docker, Minikube, kubectl)
- [ ] Docker Compose services start successfully
- [ ] All containers have health checks passing
- [ ] Minikube cluster is running with sufficient resources
- [ ] All Kubernetes resources deployed successfully
- [ ] Pods are in "Running" state
- [ ] Services are accessible via ingress
- [ ] Blue-green switching works correctly
- [ ] Database persistence verified
- [ ] Logs are accessible and readable

## Conclusion

This project demonstrates a complete, production-ready DevOps workflow:

- **Local Development**: Docker Compose for easy setup
- **Containerization**: Optimized Docker images
- **Orchestration**: Full Kubernetes deployment
- **Deployment Strategy**: Blue-green for zero-downtime updates
- **Monitoring**: Health checks at every level

The blue-green deployment strategy provides:
- **Safety**: Easy instant rollback
- **Zero Downtime**: No service interruption during updates
- **Testing**: Full environment for testing before switch
- **Reliability**: Both versions remain active and verified

## Support

For issues or questions:
1. Check the Troubleshooting section
2. Review Kubernetes logs: `kubectl logs`
3. Describe resources: `kubectl describe`
4. Check Docker logs: `docker logs`

---

**Last Updated**: 2024
**Version**: 1.0
**Status**: Production Ready
