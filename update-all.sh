#!/bin/bash

# Stop all existing containers
echo "Stopping all containers..."
sudo docker compose down -v
cd api && sudo docker compose down -v
cd ../fe && sudo docker compose down -v
cd ..

# Remove existing networks
echo "Removing existing networks..."
sudo docker network rm crm_network frontend_network api_crm_network || true

# Create networks
echo "Creating networks..."
sudo docker network create crm_network || true
sudo docker network create frontend_network || true
sudo docker network create api_crm_network || true

# Update API
echo "Updating API..."
cd api
git reset --hard
git pull
sudo docker compose up -d

# Update Frontend
echo "Updating Frontend..."
cd ../fe
git reset --hard
git pull
sudo docker compose up --build -d

# Start root nginx
echo "Starting root nginx..."
cd ..
sudo docker compose up -d

# Verify networks
echo "Verifying networks..."
sudo docker network ls | grep -E 'crm_network|frontend_network|api_crm_network'

echo "Deployment completed!"