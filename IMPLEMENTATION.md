# Implementation Details & Technical Architecture

## Application Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────┐
│                 User's Browser                       │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP/HTTPS
        ┌──────────────┴──────────────┐
        │                             │
   ┌────▼────────────┐        ┌──────▼────────────┐
   │  Kubernetes     │        │  Docker Compose   │
   │  (Production)   │        │  (Development)    │
   └────┬────────────┘        └──────┬────────────┘
        │                            │
   ┌────▼────────────────────────────▼──────────┐
   │         Frontend Layer                      │
   ├────────────────────────────────────────────┤
   │  Blue (Basic UI)    │    Green (Enhanced)   │
   │  Port: 3100         │    Port: 3200         │
   │  Replicas: 2        │    Replicas: 2        │
   └────────────┬────────────────────┬──────────┘
                │ HTTP               │
                └────────┬───────────┘
                         │
        ┌────────────────▼───────────────────┐
        │      Backend API Layer             │
        ├───────────────────────────────────┤
        │  Express.js Server                │
        │  Port: 5000                       │
        │  Replicas: 3                      │
        │  Routes:                          │
        │    - POST /api/users              │
        │    - GET /api/users               │
        │    - GET /api/users/count         │
        │    - GET /health                  │
        └────────────┬──────────────────────┘
                     │ MongoDB Protocol
        ┌────────────▼──────────────────────┐
        │    Data Persistence Layer         │
        ├───────────────────────────────────┤
        │  MongoDB                          │
        │  Port: 27017                      │
        │  Replicas: 1                      │
        │  Volume: 5Gi PVC                  │
        └───────────────────────────────────┘
```

## Frontend Implementations

### Blue Frontend (Basic UI)

**Technology Stack**:
- HTML5
- CSS3
- Vanilla JavaScript
- Express.js server

**Features**:
- Single-page form
- All fields displayed at once
- Simple validation
- Direct API submission
- Minimal styling

**Form Fields**:
```html
├── Name (text input)
├── Surname (text input)
├── Date of Birth (date input)
├── Job (text input)
├── Place (text input)
├── Interests (comma-separated text)
└── Known Languages (comma-separated text)
```

**Styling**: Basic CSS with standard form elements

### Green Frontend (Enhanced UI)

**Technology Stack**:
- HTML5
- CSS3
- Vanilla JavaScript with DOM manipulation
- Font Awesome Icons (v6.4)
- Express.js server

**Features**:
- Multi-step form (3 steps)
- Progress indicator with numbered steps
- Step-by-step validation
- Icon-based field labels
- Tag input for interests and languages
- Better UX with visual feedback
- Professional styling

**Form Steps**:
```
Step 1: Personal Information
├── Name
├── Surname
└── Date of Birth

Step 2: Professional Information
├── Job
└── Place

Step 3: Personal Interests
├── Interests (tag input)
└── Known Languages (tag input)
```

**UI Features**:
- Progress bar showing completion
- Next/Previous navigation
- Field validation at each step
- Tag management (add/remove)
- Success/Error messages

## Backend API

### Technology Stack

- **Runtime**: Node.js 18
- **Framework**: Express.js 4.18
- **Database**: MongoDB 7.0
- **ODM**: Mongoose 8.0
- **Middleware**: CORS, Body Parser

### Architecture

```
Express Server (0.0.0.0:5000)
│
├─ Middleware Layer
│  ├── CORS Handling
│  ├── JSON Body Parser
│  ├── URL-encoded Parser
│  └── Error Handler
│
├─ Routes Layer (/api/users)
│  ├── POST / - Create user
│  ├── GET / - Get all users
│  └── GET /count - Get statistics
│
├─ Models Layer
│  └── User Schema (Mongoose)
│
└─ Database Layer
   └── MongoDB Connection
```

### User Schema

```javascript
{
  name: String (required),
  surname: String (required),
  dob: Date (required),
  job: String (required),
  place: String (required),
  interests: [String] (required),
  knownLanguages: [String] (required),
  registrationDate: Date (default: Date.now),
  registeredFrom: String (enum: ['basic', 'enhanced'])
}
```

### API Endpoints

#### 1. Create User
```
POST /api/users
Content-Type: application/json

Request Body:
{
  "name": "John",
  "surname": "Doe",
  "dob": "1990-01-15",
  "job": "Software Engineer",
  "place": "New York",
  "interests": ["Coding", "Gaming", "Reading"],
  "knownLanguages": ["English", "Spanish", "Python"],
  "registeredFrom": "basic"
}

Response (201 Created):
{
  "_id": "507f1f77bcf86cd799439011",
  "name": "John",
  "surname": "Doe",
  "dob": "1990-01-15T00:00:00.000Z",
  "job": "Software Engineer",
  "place": "New York",
  "interests": ["Coding", "Gaming", "Reading"],
  "knownLanguages": ["English", "Spanish", "Python"],
  "registeredFrom": "basic",
  "registrationDate": "2024-01-10T12:34:56.789Z"
}
```

#### 2. Get All Users
```
GET /api/users

Response (200 OK):
[
  { User object 1 },
  { User object 2 },
  ...
]
```

#### 3. Get User Statistics
```
GET /api/users/count

Response (200 OK):
{
  "total": 42,
  "basicUI": 28,
  "enhancedUI": 14
}
```

#### 4. Health Check
```
GET /health

Response (200 OK):
{
  "status": "ok",
  "message": "Backend API is running"
}
```

## Docker Implementation

### Dockerfile Strategy

All Dockerfiles use **multi-stage builds**:

1. **Builder Stage**
   - Starts with Node.js Alpine image
   - Installs dependencies with npm ci
   - Optimized for dependency installation

2. **Runtime Stage**
   - Fresh Alpine image (smaller size)
   - Copies only production dependencies
   - Copies application code
   - Removes development artifacts

### Benefits of Multi-stage Builds

- **Reduced Image Size**: ~80MB vs ~200MB with single stage
- **Security**: No build tools in production image
- **Performance**: Smaller images = faster deployment
- **Best Practices**: Follows Docker best practices

### Dockerfile Components

```dockerfile
# Build Stage (Deps installation)
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Runtime Stage (Production)
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 5000
HEALTHCHECK ...
CMD ["npm", "start"]
```

### Health Checks

Each Dockerfile includes health checks:

```dockerfile
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:PORT/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})" || exit 1
```

**Parameters**:
- **--interval**: Check every 10 seconds
- **--timeout**: Allow 3 seconds for response
- **--start-period**: Wait 5 seconds before first check
- **--retries**: Fail after 3 consecutive failures

## Docker Compose Setup

### Service Dependencies

```
Graph: mongo <- backend <- frontend-blue/green

Startup Order:
1. MongoDB starts (no dependencies)
2. Backend waits for MongoDB health check
3. Frontends wait for backend
4. All services have health checks
5. Services auto-restart if unhealthy
```

### Network Configuration

- **Network Type**: Bridge (default Docker network)
- **Network Name**: app-network
- **Service Discovery**: Docker DNS allows `service_name:port` resolution

### Volume Configuration

```yaml
mongo:
  volumes:
    - mongo_data:/data/db  # Named volume for persistence

frontend services:
  volumes:
    - ./frontend-blue:/app           # Bind mount for development
    - /app/node_modules              # Named volume to preserve node_modules
```

### Environment Variable Passing

- Backend: Via .env file
- Frontends: Via .env file
- Database credentials: Via compose environment section

## Kubernetes Implementation

### Namespace Strategy

All resources deployed in `registration-app` namespace for:
- Resource isolation
- Easy deletion (delete namespace = delete all)
- Access control (RBAC per namespace)
- Resource quotas
- Network policies

### Deployment Strategy

#### Backend Deployment
- **Replicas**: 3 (for high availability)
- **Update Strategy**: RollingUpdate
  - Max surge: 1 (one extra pod during update)
  - Max unavailable: 0 (always at least 3 running)

#### Frontend Deployments (Blue/Green)
- **Replicas**: 2 each
- **Labels**: Different deployment labels for switching
- **Service**: Separate service per deployment

### Resource Management

```yaml
Requests (minimum guaranteed):
- Backend: 250m CPU, 256Mi RAM
- Frontend: 100m CPU, 128Mi RAM
- MongoDB: 250m CPU, 256Mi RAM

Limits (maximum allowed):
- Backend: 500m CPU, 512Mi RAM
- Frontend: 250m CPU, 256Mi RAM
- MongoDB: 500m CPU, 512Mi RAM
```

### Health Checks in Kubernetes

```yaml
# Liveness Probe (restart if failing)
livenessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 30  # Wait before first check
  periodSeconds: 10        # Check every 10 seconds
  failureThreshold: 3      # Restart after 3 failures

# Readiness Probe (remove from service if failing)
readinessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 10  # Wait before first check
  periodSeconds: 5        # Check every 5 seconds
  failureThreshold: 3      # Remove after 3 failures
```

### Security Context

```yaml
securityContext:
  runAsNonRoot: true        # Don't run as root
  runAsUser: 1000          # Run as non-privileged user
  allowPrivilegeEscalation: false  # Prevent privilege escalation
```

### Blue-Green Switching Mechanism

**Service Selector Pattern**:

```yaml
# Frontend Load Balancer Service
service/frontend-lb:
  selector:
    app: frontend
    deployment: blue  # <-- Switch this label

# Deployment Labels
Deployment: frontend-blue
  labels:
    app: frontend
    deployment: blue

Deployment: frontend-green
  labels:
    app: frontend
    deployment: green

# Switching Logic
# frontend-lb routes to pods with matching labels
# Patching service selector switches traffic instantly
```

**Switching Command**:
```bash
# Switch to green
kubectl patch service frontend-lb \
  -p '{"spec":{"selector":{"deployment":"green"}}}'

# Result: All traffic now routes to frontend-green pods
```

### Persistent Storage

- **Type**: PersistentVolumeClaim (PVC)
- **Size**: 5Gi
- **Access Mode**: ReadWriteOnce
- **Storage Class**: Default (Minikube uses hostPath)
- **Mount Path**: /data/db (MongoDB)

### Service Types

```yaml
mongo:
  type: ClusterIP
  spec:
    clusterIP: None  # Headless service (for StatefulSet pattern)

backend:
  type: ClusterIP  # Internal only

frontend-blue/green:
  type: ClusterIP  # Internal only

frontend-lb:
  type: ClusterIP  # Used by ingress

Ingress:
  type: nginx  # External access via ingress controller
```

## Performance Optimization

### Container Optimization

1. **Alpine Base Images**: 5MB vs 150MB+ with standard images
2. **Multi-stage Builds**: Remove build tools from final image
3. **npm ci vs npm install**: Faster, deterministic dependency resolution
4. **Health Checks**: Prevent unhealthy containers from receiving traffic

### Kubernetes Optimization

1. **Resource Requests**: Scheduler can place pods efficiently
2. **Resource Limits**: Prevent pods from consuming excess resources
3. **Readiness Probes**: Ensure traffic only goes to ready pods
4. **Horizontal Pod Autoscaling**: Can add more replicas under load

### Database Optimization

1. **MongoDB Indexes**: Automatic for _id field
2. **Connection Pooling**: Mongoose handles connection pool
3. **Persistent Volume**: Data survives pod restarts

## Monitoring & Logging

### Container Logs

```bash
# View logs
docker logs <container-id>

# Follow logs
docker logs -f <container-id>

# Last N lines
docker logs --tail=100 <container-id>
```

### Kubernetes Logs

```bash
# Pod logs
kubectl logs -n registration-app <pod-name>

# Follow logs
kubectl logs -f -n registration-app <pod-name>

# Previous pod logs (if crashed)
kubectl logs -p -n registration-app <pod-name>

# All pods of a deployment
kubectl logs -n registration-app -l app=backend
```

### Health Status

- **Container level**: Docker health check status
- **Pod level**: Ready/NotReady status
- **Service level**: Endpoints available/unavailable
- **Application level**: /health endpoint

## Troubleshooting Patterns

### Issue: Pod not starting

**Root Causes**:
1. Image not found - `imagePullPolicy` issues
2. Insufficient resources - Resource limits too strict
3. Port conflicts - Port already in use
4. Dependency not ready - Wait for dependencies

**Diagnosis**:
```bash
kubectl describe pod <pod-name> -n registration-app  # Events
kubectl logs <pod-name> -n registration-app          # Logs
kubectl top pod <pod-name> -n registration-app       # Resource usage
```

### Issue: Service not accessible

**Root Causes**:
1. No endpoints - Pods not ready
2. Wrong selector - Service not finding pods
3. Ingress misconfigured - Routing rules wrong
4. Hosts file not updated

**Diagnosis**:
```bash
kubectl get endpoints -n registration-app
kubectl get service -n registration-app -o wide
kubectl describe ingress -n registration-app
```

### Issue: Blue-Green switch not working

**Root Causes**:
1. Pods not ready - Status not Running/Ready
2. Labels mismatch - Deployment labels don't match selector
3. Service selector wrong - Patch didn't apply correctly

**Diagnosis**:
```bash
kubectl get pods -n registration-app --show-labels
kubectl get service frontend-lb -n registration-app -o yaml
kubectl describe service frontend-lb -n registration-app
```

## Cost Optimization

### Minikube
- Local single-node cluster
- Suitable for development/testing
- Minimal resource usage possible
- ~4GB RAM, 4 CPU cores

### Production Alternatives

| Option | Cost | Performance | Management |
|--------|------|-------------|-----------|
| EKS (AWS) | $$$ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| GKE (Google) | $$$ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| AKS (Azure) | $$$ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| DigitalOcean | $ | ⭐⭐⭐ | ⭐⭐⭐ |
| Docker Swarm | $$ | ⭐⭐⭐ | ⭐⭐⭐ |
| Self-hosted | $$ | ⭐⭐⭐ | ⭐ |

---

**Document Version**: 1.0  
**Last Updated**: 2024
