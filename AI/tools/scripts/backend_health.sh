#!/bin/bash

# Backend Health Check Script
# Tests the Node.js backend endpoints

set -e

# Backend configuration
BACKEND_URL="http://localhost:8787"

echo "🏥 Backend Health Check"
echo "URL: $BACKEND_URL"
echo ""

# Test health endpoint
echo "📡 Testing /api/health..."
HEALTH_RESPONSE=$(curl -s -X GET "$BACKEND_URL/api/health" || echo "Connection failed")
echo "Health Response:"
echo "$HEALTH_RESPONSE" | jq '.' 2>/dev/null || echo "$HEALTH_RESPONSE"
echo ""

# Test cache stats
echo "📊 Testing /api/cache/stats..."
CACHE_RESPONSE=$(curl -s -X GET "$BACKEND_URL/api/cache/stats" || echo "Connection failed")
echo "Cache Stats Response:"
echo "$CACHE_RESPONSE" | jq '.' 2>/dev/null || echo "$CACHE_RESPONSE"
echo ""

# Test MCQ generation (this will fail without auth, but shows the endpoint exists)
echo "🤖 Testing /api/generate-mcq (should fail without auth)..."
MCQ_RESPONSE=$(curl -s -X POST \
  "$BACKEND_URL/api/generate-mcq" \
  -H "Content-Type: application/json" \
  -d '{"subject": "Mathematics", "choices": 4}' || echo "Connection failed")
echo "MCQ Response:"
echo "$MCQ_RESPONSE" | jq '.' 2>/dev/null || echo "$MCQ_RESPONSE"
echo ""

echo "✅ Health check complete!"
