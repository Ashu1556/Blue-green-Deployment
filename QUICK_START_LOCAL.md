# Local Deployment Quick Start

This guide will get the application running locally using Docker Compose.

## Prerequisites

- Docker Desktop (or Docker Engine + Docker Compose)
- Node.js 16+ (optional, for development)
- Git

## Quick Start (2 minutes)

### 1. Start All Services

```bash
cd Blue-green-Deployment

# Start services (will build images on first run)
docker-compose up --build
```

### 2. Wait for Services to Be Ready

Look for these messages:
```
backend         | Backend server running on port 5000
frontend-blue   | Basic frontend server running on port 3100
frontend-green  | Green frontend server running on port 3200
mongo           | Waiting for connections
```

### 3. Access the Application

Open your browser:

| Application | URL |
|-------------|-----|
| **Backend API** | http://localhost:5000 |
| **Frontend Blue (Basic)** | http://localhost:3100 |
| **Frontend Green (Enhanced)** | http://localhost:3200 |

### 4. Test the Services

```bash
# Test backend
curl http://localhost:5000/health

# Test blue frontend
curl http://localhost:3100/health

# Test green frontend
curl http://localhost:3200/health

# Register a user
curl -X POST http://localhost:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John",
    "surname": "Doe",
    "dob": "1990-01-01",
    "job": "Developer",
    "place": "New York",
    "interests": ["Coding", "Gaming"],
    "knownLanguages": ["English", "Spanish"],
    "registeredFrom": "basic"
  }'
```

## Common Commands

```bash
# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f backend

# Check service status
docker-compose ps

# Stop services
docker-compose stop

# Start services (after stopping)
docker-compose start

# Remove everything
docker-compose down -v

# Rebuild images (if code changed)
docker-compose up --build
```

## Accessing the Frontends

### Basic Frontend (Blue)
- **URL**: http://localhost:3100
- **Form Style**: Single page
- **Features**: All fields on one form

### Enhanced Frontend (Green)
- **URL**: http://localhost:3200
- **Form Style**: Multi-step wizard
- **Features**: 
  - Progress indicator
  - Step-by-step validation
  - Icon-based interface
  - Tag input for interests and languages

## Verify Data Persistence

1. Register a user in one frontend
2. Open the other frontend
3. Data is stored in MongoDB (persistent volume)
4. Stop and restart containers: `docker-compose restart`
5. Data remains after restart

## Troubleshooting

### Port Already in Use
```bash
# If port 5000, 3100, 3200, or 27017 is in use:
# Find and stop the process or use different ports in docker-compose.yml
```

### MongoDB Connection Error
```bash
# Wait longer for MongoDB to start (first run takes longer)
docker-compose logs mongo

# Or restart MongoDB specifically
docker-compose restart mongo
```

### Container Crashes
```bash
# Check logs
docker-compose logs [service-name]

# Rebuild and restart
docker-compose up --build [service-name]
```

## Next Steps

After local testing works:

1. **[Kubernetes Deployment](./DEPLOYMENT_GUIDE.md)** - Deploy to Minikube
2. **[Implementation Details](./IMPLEMENTATION.md)** - Technical deep dive

---

**Duration**: ~5 minutes for complete setup  
**Resources Used**: ~2GB RAM, ~500MB disk space
