#!/bin/bash

# Backend Health Check Script
# This script verifies that your backend is properly configured and running

echo "================================================"
echo "Invento Backend Health Check"
echo "================================================"
echo ""

# Check if backend folder exists
if [ ! -d "backend" ]; then
    echo "❌ Backend folder not found!"
    echo "Make sure you're in the project root directory"
    exit 1
fi

echo "✅ Backend folder found"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    echo "Install from: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js installed: $(node --version)"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed"
    exit 1
fi

echo "✅ npm installed: $(npm --version)"

# Check if .env file exists
cd backend

if [ ! -f ".env" ]; then
    echo "❌ .env file not found in backend/"
    echo "Please create .env file with credentials"
    echo "See README.md for instructions"
    exit 1
fi

echo "✅ .env file found"

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "❌ package.json not found"
    exit 1
fi

echo "✅ package.json found"

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo ""
    echo "📦 Installing dependencies..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install dependencies"
        exit 1
    fi
    echo "✅ Dependencies installed"
else
    echo "✅ Dependencies installed"
fi

echo ""
echo "================================================"
echo "Backend Health Check Complete!"
echo "================================================"
echo ""
echo "Next step: Start the backend"
echo ""
echo "  npm run dev"
echo ""
echo "Once running, test with:"
echo ""
echo "  curl http://localhost:3000/health"
echo ""
