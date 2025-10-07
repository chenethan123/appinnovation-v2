#!/bin/bash

# FormulaQuizzer - Startup Script
# This script starts the backend server and Flutter app together

set -e  # Exit on error

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     FormulaQuizzer Startup Script     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SERVER_DIR="$SCRIPT_DIR/server"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed!${NC}"
    echo -e "${YELLOW}Please install Node.js first:${NC}"
    echo -e "   brew install node"
    echo -e ""
    echo -e "${YELLOW}Or visit: https://nodejs.org/${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Node.js found: $(node --version)${NC}"

# Check if npm dependencies are installed
if [ ! -d "$SERVER_DIR/node_modules" ]; then
    echo -e "${YELLOW}⚠ Backend dependencies not installed${NC}"
    echo -e "${BLUE}Installing dependencies...${NC}"
    cd "$SERVER_DIR"
    npm install
    cd "$SCRIPT_DIR"
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${GREEN}✓ Backend dependencies found${NC}"
fi

# Check if .env file exists
if [ ! -f "$SERVER_DIR/.env" ]; then
    echo -e "${RED}❌ .env file not found in server directory${NC}"
    echo -e "${YELLOW}Creating .env from .env.example...${NC}"
    cp "$SERVER_DIR/.env.example" "$SERVER_DIR/.env"
    echo -e "${YELLOW}⚠ Please edit server/.env and add your OPENAI_API_KEY${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Environment configuration found${NC}"
echo ""

# Function to cleanup background processes on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down...${NC}"
    if [ ! -z "$BACKEND_PID" ]; then
        echo -e "${BLUE}Stopping backend server (PID: $BACKEND_PID)${NC}"
        kill $BACKEND_PID 2>/dev/null || true
    fi
    exit 0
}

trap cleanup EXIT INT TERM

# Start the backend server
echo -e "${BLUE}Starting backend server...${NC}"
cd "$SERVER_DIR"
npm run dev > backend.log 2>&1 &
BACKEND_PID=$!
cd "$SCRIPT_DIR"

# Wait for backend to be ready
echo -e "${YELLOW}Waiting for backend to start...${NC}"
sleep 3

# Check if backend is running
if ps -p $BACKEND_PID > /dev/null; then
    echo -e "${GREEN}✓ Backend server started (PID: $BACKEND_PID)${NC}"
    echo -e "${GREEN}✓ Backend running at http://localhost:8787${NC}"
else
    echo -e "${RED}❌ Backend failed to start${NC}"
    echo -e "${YELLOW}Check server/backend.log for errors${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Starting Flutter app...${NC}"
echo ""

# Start Flutter app (macOS)
flutter run -d macos

# Cleanup will be called automatically on exit
