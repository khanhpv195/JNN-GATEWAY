#!/bin/bash

# Exit on error
set -e

# Function to check Docker login
check_docker_login() {
    echo "Checking Docker login status..."
    if ! docker info >/dev/null 2>&1; then
        echo "Docker daemon not running or not accessible"
        exit 1
    fi
    
    # Try to log in to Docker Hub using credentials from config
    if ! docker pull hello-world >/dev/null 2>&1; then
        echo "Docker Hub login required. Please run:"
        echo "docker login"
        exit 1
    fi
}

# Function to pull Docker image with retry
pull_image() {
    local image=$1
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempting to pull $image (attempt $attempt/$max_attempts)..."
        if docker pull $image; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 5
    done
    
    echo "Failed to pull $image after $max_attempts attempts"
    return 1
}

# Stop all existing containers
echo "Stopping all containers..."
docker compose down -v
cd api && docker compose down -v && docker compose -f base_images.docker-compose.yml down -v
cd ../fe && docker compose down -v
cd ..

# Remove existing networks
echo "Removing existing networks..."
docker network rm crm_network frontend_network api_crm_network || true

# Create networks with proper labels
echo "Creating networks..."
docker network create \
    --label com.docker.compose.network=crm_network \
    crm_network || true

docker network create \
    --label com.docker.compose.network=frontend_network \
    frontend_network || true

docker network create \
    --label com.docker.compose.network=crm_network \
    api_crm_network || true

# Check Docker login before proceeding
check_docker_login

# Pull required images first
echo "Pulling required images..."
pull_image "nginx:stable-alpine"
pull_image "node:20.14.0-alpine"
pull_image "node:20.14.0-bullseye"
pull_image "nats:2.10.16-alpine"
pull_image "mongo:7.0.11"

# Update API
echo "Updating API..."
cd api
git reset --hard
git pull

# Build base images first
echo "Building base images..."
docker compose -f base_images.docker-compose.yml up --build -d
echo "Waiting for base images to be ready..."
sleep 15  # Increased wait time for node_modules installation

# Start API services
echo "Starting API services..."
docker compose up -d

# Wait for crm_nginx to be ready
echo "Waiting for CRM nginx to be ready..."
attempt=1
max_attempts=30
until docker ps | grep crm_nginx | grep -q "Up" || [ $attempt -gt $max_attempts ]; do
    echo "Waiting for crm_nginx to be up (attempt $attempt/$max_attempts)..."
    sleep 2
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    echo "Error: crm_nginx failed to start"
    exit 1
fi

# Update Frontend
echo "Updating Frontend..."
cd ../fe
git reset --hard
git pull
docker compose up --build -d

# Start root nginx with network connections
echo "Starting root nginx..."
cd ..
docker compose up -d

# Connect networks to root nginx
echo "Connecting networks to root nginx..."
docker network connect api_crm_network gateway-nginx-1 || true
docker network connect crm_network gateway-nginx-1 || true

# Restart nginx to apply network changes
echo "Restarting nginx to apply network changes..."
docker restart gateway-nginx-1

# Wait for nginx to be ready
echo "Waiting for nginx to be ready..."
sleep 5

# Verify networks
echo "Verifying networks..."
echo "Network details:"
for network in crm_network frontend_network api_crm_network; do
    echo "Network: $network"
    docker network inspect $network | grep -E "Name|Labels|Containers"
done

# Final verification
echo "Verifying services..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check nginx configuration and logs
echo "Checking nginx configuration and logs..."
docker logs gateway-nginx-1

echo "Deployment completed!"