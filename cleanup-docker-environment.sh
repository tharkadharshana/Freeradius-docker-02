#!/bin/bash

# FreeRADIUS Docker Environment Cleanup Script
# This script completely cleans your Docker environment for a fresh start

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================"
echo -e "🐳 Docker Environment Cleanup Script"
echo -e "========================================${NC}"
echo
echo -e "${YELLOW}⚠️  WARNING: This script will remove ALL Docker containers, networks, volumes, and images!${NC}"
echo -e "${YELLOW}⚠️  This is a complete cleanup - make sure you don't need any existing data!${NC}"
echo

# Ask for confirmation
read -p "Are you sure you want to continue? Type 'YES' to confirm: " confirmation
if [[ "$confirmation" != "YES" ]]; then
    echo -e "${RED}❌ Cleanup cancelled by user${NC}"
    exit 1
fi

echo
echo -e "${BLUE}Starting Docker environment cleanup...${NC}"
echo

# Step 1: Stop all running containers
echo -e "${YELLOW}Step 1: Stopping all running containers...${NC}"
if docker ps -q | grep -q .; then
    echo "Found running containers, stopping them..."
    docker stop $(docker ps -q)
    echo -e "${GREEN}✅ All containers stopped${NC}"
else
    echo -e "${GREEN}✅ No running containers found${NC}"
fi

# Step 2: Remove all containers
echo
echo -e "${YELLOW}Step 2: Removing all containers...${NC}"
if docker ps -aq | grep -q .; then
    echo "Found containers, removing them..."
    docker rm $(docker ps -aq)
    echo -e "${GREEN}✅ All containers removed${NC}"
else
    echo -e "${GREEN}✅ No containers found${NC}"
fi

# Step 3: Remove all networks (except default ones)
echo
echo -e "${YELLOW}Step 3: Removing custom networks...${NC}"
if docker network ls --format "{{.Name}}" | grep -v "^bridge$\|^host$\|^none$" | grep -q .; then
    echo "Found custom networks, removing them..."
    docker network ls --format "{{.Name}}" | grep -v "^bridge$\|^host$\|^none$" | xargs -r docker network rm
    echo -e "${GREEN}✅ Custom networks removed${NC}"
else
    echo -e "${GREEN}✅ No custom networks found${NC}"
fi

# Step 4: Remove all volumes
echo
echo -e "${YELLOW}Step 4: Removing all volumes...${NC}"
if docker volume ls -q | grep -q .; then
    echo "Found volumes, removing them..."
    docker volume rm $(docker volume ls -q)
    echo -e "${GREEN}✅ All volumes removed${NC}"
else
    echo -e "${GREEN}✅ No volumes found${NC}"
fi

# Step 5: Remove all images
echo
echo -e "${YELLOW}Step 5: Removing all images...${NC}"
if docker images -q | grep -q .; then
    echo "Found images, removing them..."
    docker rmi $(docker images -q) --force
    echo -e "${GREEN}✅ All images removed${NC}"
else
    echo -e "${GREEN}✅ No images found${NC}"
fi

# Step 6: Clean up system
echo
echo -e "${YELLOW}Step 6: Cleaning up Docker system...${NC}"
docker system prune -a -f --volumes
echo -e "${GREEN}✅ Docker system cleaned${NC}"

# Step 7: Verify cleanup
echo
echo -e "${YELLOW}Step 7: Verifying cleanup...${NC}"
echo "Checking remaining containers:"
if docker ps -aq | grep -q .; then
    echo -e "${RED}❌ Found remaining containers:${NC}"
    docker ps -a
else
    echo -e "${GREEN}✅ No containers remaining${NC}"
fi

echo
echo "Checking remaining networks:"
if docker network ls --format "{{.Name}}" | grep -v "^bridge$\|^host$\|^none$" | grep -q .; then
    echo -e "${RED}❌ Found remaining custom networks:${NC}"
    docker network ls
else
    echo -e "${GREEN}✅ Only default networks remaining${NC}"
fi

echo
echo "Checking remaining volumes:"
if docker volume ls -q | grep -q .; then
    echo -e "${RED}❌ Found remaining volumes:${NC}"
    docker volume ls
else
    echo -e "${GREEN}✅ No volumes remaining${NC}"
fi

echo
echo "Checking remaining images:"
if docker images -q | grep -q .; then
    echo -e "${RED}❌ Found remaining images:${NC}"
    docker images
else
    echo -e "${GREEN}✅ No images remaining${NC}"
fi

echo
echo -e "${GREEN}========================================"
echo -e "🎉 Docker environment cleanup completed!"
echo -e "========================================${NC}"
echo
echo -e "${BLUE}Your Docker environment is now completely clean and ready for:${NC}"
echo -e "✅ Fresh FreeRADIUS container deployment"
echo -e "✅ Clean network creation"
echo -e "✅ No port conflicts"
echo -e "✅ No volume conflicts"
echo
echo -e "${BLUE}Next steps:${NC}"
echo -e "1. Run: ./setup-complete-system-linux.sh"
echo -e "2. Or manually: docker-compose -f docker-compose-simple.yml up -d"
echo
echo -e "${GREEN}Press Enter to continue...${NC}"
read
