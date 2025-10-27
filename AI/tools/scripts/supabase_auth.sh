#!/bin/bash

# Supabase API Testing Script
# Usage: ./supabase_auth.sh [email] [password]

set -e

# Supabase configuration
SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

# Default credentials if not provided
EMAIL=${1:-"testing@gmail.com"}
PASSWORD=${2:-"testing"}

echo "🔐 Authenticating with Supabase..."
echo "Email: $EMAIL"
echo "URL: $SUPABASE_URL"
echo ""

# Step 1: Authenticate and get session
echo "📡 Step 1: Signing in..."
AUTH_RESPONSE=$(curl -s -X POST \
  "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$EMAIL\",
    \"password\": \"$PASSWORD\"
  }")

echo "Auth Response:"
echo "$AUTH_RESPONSE" | jq '.' 2>/dev/null || echo "$AUTH_RESPONSE"
echo ""

# Extract access token
ACCESS_TOKEN=$(echo "$AUTH_RESPONSE" | jq -r '.access_token' 2>/dev/null)

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Authentication failed!"
  echo "Response: $AUTH_RESPONSE"
  exit 1
fi

echo "✅ Authentication successful!"
echo "Access Token: ${ACCESS_TOKEN:0:20}..."
echo ""

# Step 2: Get user info
echo "👤 Step 2: Getting user info..."
USER_RESPONSE=$(curl -s -X GET \
  "$SUPABASE_URL/auth/v1/user" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "User Info:"
echo "$USER_RESPONSE" | jq '.' 2>/dev/null || echo "$USER_RESPONSE"
echo ""

# Extract user ID
USER_ID=$(echo "$USER_RESPONSE" | jq -r '.id' 2>/dev/null)
echo "User ID: $USER_ID"
echo ""

# Step 3: Query subjects for this user
echo "📚 Step 3: Fetching subjects for user..."
SUBJECTS_RESPONSE=$(curl -s -X GET \
  "$SUPABASE_URL/rest/v1/subjects?user_id=eq.$USER_ID&select=*" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

echo "Subjects Response:"
echo "$SUBJECTS_RESPONSE" | jq '.' 2>/dev/null || echo "$SUBJECTS_RESPONSE"
echo ""

# Step 4: Query questions for this user
echo "❓ Step 4: Fetching questions for user..."
QUESTIONS_RESPONSE=$(curl -s -X GET \
  "$SUPABASE_URL/rest/v1/questions?user_id=eq.$USER_ID&select=*" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

echo "Questions Response:"
echo "$QUESTIONS_RESPONSE" | jq '.' 2>/dev/null || echo "$QUESTIONS_RESPONSE"
echo ""

# Step 5: Query quiz sessions for this user
echo "📊 Step 5: Fetching quiz sessions for user..."
SESSIONS_RESPONSE=$(curl -s -X GET \
  "$SUPABASE_URL/rest/v1/quiz_sessions?user_id=eq.$USER_ID&select=*" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json")

echo "Quiz Sessions Response:"
echo "$SESSIONS_RESPONSE" | jq '.' 2>/dev/null || echo "$SESSIONS_RESPONSE"
echo ""

echo "✅ Query complete!"
echo ""
echo "Summary:"
echo "- User ID: $USER_ID"
echo "- Subjects count: $(echo "$SUBJECTS_RESPONSE" | jq '. | length' 2>/dev/null || echo "Unknown")"
echo "- Questions count: $(echo "$QUESTIONS_RESPONSE" | jq '. | length' 2>/dev/null || echo "Unknown")"
echo "- Quiz sessions count: $(echo "$SESSIONS_RESPONSE" | jq '. | length' 2>/dev/null || echo "Unknown")"
