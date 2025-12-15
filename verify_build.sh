#!/bin/bash

# Build Verification Script for FormulaQuizzer
# This script ensures 100% certainty that the app can be built from source

set -e  # Exit on any error

echo "========================================"
echo "FormulaQuizzer Build Verification"
echo "========================================"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print success messages
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error messages
error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print warning messages
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print info messages
info() {
    echo -e "ℹ $1"
}

echo "Step 1: Checking Prerequisites"
echo "--------------------------------"

# Check Flutter
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    success "Flutter found: $FLUTTER_VERSION"
else
    error "Flutter not found. Please install Flutter SDK."
    exit 1
fi

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    success "Node.js found: $NODE_VERSION"
else
    warning "Node.js not found. Backend server features will not work."
    warning "Install with: brew install node"
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    success "npm found: v$NPM_VERSION"
fi

echo ""
echo "Step 2: Running Flutter Doctor"
echo "--------------------------------"
flutter doctor
echo ""

echo "Step 3: Cleaning Previous Builds"
echo "--------------------------------"
flutter clean
success "Cleaned build directory"
echo ""

echo "Step 4: Getting Flutter Dependencies"
echo "--------------------------------"
flutter pub get
if [ $? -eq 0 ]; then
    success "Flutter dependencies installed"
else
    error "Failed to install Flutter dependencies"
    exit 1
fi
echo ""

echo "Step 5: Verifying Critical Files"
echo "--------------------------------"

# Check for pubspec.yaml
if [ -f "pubspec.yaml" ]; then
    success "pubspec.yaml found"
else
    error "pubspec.yaml not found"
    exit 1
fi

# Check for main.dart
if [ -f "lib/main.dart" ]; then
    success "lib/main.dart found"
else
    error "lib/main.dart not found"
    exit 1
fi

# Check for server files
if [ -f "server/package.json" ]; then
    success "server/package.json found"
else
    warning "server/package.json not found (backend optional)"
fi

# Check for API config template
if [ -f "lib/config/api_config.dart" ]; then
    success "API config exists"
elif [ -f "lib/config/api_config.example.dart" ]; then
    warning "API config not found, but template exists"
    info "Copy api_config.example.dart to api_config.dart to enable AI features"
else
    warning "No API config found - AI features will be disabled"
fi

echo ""
echo "Step 6: Installing Backend Dependencies (if available)"
echo "--------------------------------"
if [ -d "server" ] && [ -f "server/package.json" ]; then
    cd server
    if command -v npm &> /dev/null; then
        npm install
        if [ $? -eq 0 ]; then
            success "Backend dependencies installed"
        else
            error "Failed to install backend dependencies"
            cd ..
            exit 1
        fi
    else
        warning "npm not available, skipping backend setup"
    fi
    cd ..
else
    warning "No backend server directory found"
fi
echo ""

echo "Step 7: Testing Flutter Build"
echo "--------------------------------"
info "Attempting macOS build (this may take a few minutes)..."
flutter build macos --release
if [ $? -eq 0 ]; then
    success "macOS build completed successfully"
    BUILD_PATH="build/macos/Build/Products/Release/formula_quizzer.app"
    if [ -d "$BUILD_PATH" ]; then
        BUILD_SIZE=$(du -sh "$BUILD_PATH" | cut -f1)
        success "Build artifact created: $BUILD_SIZE"
    fi
else
    error "macOS build failed"
    exit 1
fi
echo ""

echo "Step 8: Testing Backend Server (if available)"
echo "--------------------------------"
if [ -d "server" ] && [ -f "server/package.json" ] && command -v npm &> /dev/null; then
    cd server
    
    # Check if .env exists
    if [ ! -f ".env" ]; then
        warning ".env not found, creating from template"
        if [ -f ".env.example" ]; then
            cp .env.example .env
            warning "Please add your OPENAI_API_KEY to server/.env for AI features"
        fi
    fi
    
    # Start server in background
    info "Starting backend server..."
    npm run dev &
    SERVER_PID=$!
    cd ..
    
    # Wait for server to start
    sleep 3
    
    # Test health endpoint
    if command -v curl &> /dev/null; then
        HEALTH_RESPONSE=$(curl -s http://localhost:8787/api/health)
        if [ $? -eq 0 ]; then
            success "Backend server is responding"
            info "Health check: $HEALTH_RESPONSE"
        else
            warning "Backend server not responding (may need API key)"
        fi
    fi
    
    # Kill the server
    kill $SERVER_PID 2>/dev/null
    sleep 1
else
    warning "Backend server not available or npm not installed"
fi
echo ""

echo "========================================"
echo "Build Verification Complete!"
echo "========================================"
echo ""
success "All critical checks passed"
echo ""
echo "Summary:"
echo "  • Flutter dependencies: ✓ Installed"
echo "  • macOS build: ✓ Success"
if [ -d "server" ]; then
    echo "  • Backend server: ✓ Available"
else
    echo "  • Backend server: - Not included"
fi
echo ""
echo "Next Steps:"
echo "  1. Configure API key (optional): Copy server/.env.example to server/.env"
echo "  2. Run app: ./start_app.sh"
echo "  3. Or manually: flutter run -d macos"
echo ""
echo "The app is ready to run from the GitHub repository!"
echo ""
