#!/bin/bash

# Quick Test Script - Test both Supabase and Backend
# Usage: ./quick_test.sh

set -e

echo "🚀 FormulaQuizzer Quick Test"
echo "=============================="
echo ""

# Test 1: Supabase connection
echo "1️⃣ Testing Supabase connection..."
SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$SUPABASE_URL/rest/v1/" -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs")

if [ "$HEALTH_CHECK" = "200" ]; then
  echo "✅ Supabase: Connected"
else
  echo "❌ Supabase: Connection failed (HTTP $HEALTH_CHECK)"
fi

# Test 2: Backend server
echo ""
echo "2️⃣ Testing Backend server..."
BACKEND_URL="http://localhost:8787"
BACKEND_CHECK=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/api/health" 2>/dev/null || echo "000")

if [ "$BACKEND_CHECK" = "200" ]; then
  echo "✅ Backend: Running on localhost:8787"
elif [ "$BACKEND_CHECK" = "000" ]; then
  echo "❌ Backend: Not running (start with: cd server && npm run dev)"
else
  echo "⚠️ Backend: Responding but unexpected status (HTTP $BACKEND_CHECK)"
fi

# Test 3: User data summary
echo ""
echo "3️⃣ Testing user data (testing@gmail.com)..."
echo "Running Supabase auth test..."

# Run the auth script and capture just the summary
SUMMARY=$(./supabase_auth.sh testing@gmail.com testing 2>/dev/null | tail -n 10)

echo "$SUMMARY"

echo ""
echo "🎯 Quick Test Complete!"
echo ""
echo "Next steps:"
echo "- If Supabase ✅ but Backend ❌: Start backend with 'cd server && npm run dev'"
echo "- If both ✅: Your system is ready for testing"
echo "- If Supabase ❌: Check your internet connection and Supabase status"
