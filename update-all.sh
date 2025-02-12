#!/bin/bash

# Update API
echo "Updating API..."
cd api
git pull
sudo docker compose down -v
sudo docker compose up -d

# Update Frontend
echo "Updating Frontend..."
cd ../fe
git pull
sudo docker compose up --build -d

# Update Cleaner App
echo "Updating Cleaner App..."
cd ../app/cleaner
git pull
sudo docker compose restart

# Update App
echo "Updating App..."
cd ../app/admin
git pull
sudo docker compose restart

echo "All updates completed!" 