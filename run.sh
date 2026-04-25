#!/bin/bash
# SmartChain AI Launcher
# Usage: ./run.sh
# This script starts the MCP Server, ML Service, and Flutter Web App in parallel.

echo "🚀 Starting SmartChain AI..."

# Start MCP Server
echo "Starting MCP Server on port 3001..."
cd mcp_server && npm install --silent && node index.js &
MCP_PID=$!
echo "✅ MCP Server started (PID: $MCP_PID)"

# Start ML Service  
echo "Starting ML Service on port 5000..."
cd ../ml_service && python3 app.py &
ML_PID=$!
echo "✅ ML Service started (PID: $ML_PID)"

# Wait for servers to start
sleep 3

# Start Flutter
echo "Starting Flutter Web App..."
cd ..
flutter run -d web-server --web-port 8080
