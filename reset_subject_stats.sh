#!/bin/bash

# Reset subject stats in Supabase cloud database

SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

# Login
echo "Logging in..."
RESPONSE=$(curl -s -X POST \
    "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
    -H "apikey: ${ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"email":"testing1@gmail.com","password":"testing1"}')

TOKEN=$(echo "$RESPONSE" | jq -r '.access_token')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
    echo "❌ Login failed"
    exit 1
fi

echo "✅ Logged in successfully"

# Get all subjects
echo "Fetching subjects..."
SUBJECTS=$(curl -s -X GET \
    "${SUPABASE_URL}/rest/v1/subjects?select=*" \
    -H "apikey: ${ANON_KEY}" \
    -H "Authorization: Bearer ${TOKEN}")

echo "Current subjects:"
echo "$SUBJECTS" | jq -r '.[] | "\(.name): \(.total_questions)/\(.correct_answers)"'

# Reset all subject stats to 0/0
echo ""
echo "Resetting all subject stats to 0/0..."

for subject_id in $(echo "$SUBJECTS" | jq -r '.[] | .id'); do
    subject_name=$(echo "$SUBJECTS" | jq -r ".[] | select(.id==\"$subject_id\") | .name")
    
    curl -s -X PATCH \
        "${SUPABASE_URL}/rest/v1/subjects?id=eq.${subject_id}" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "{
            \"total_questions\": 0,
            \"correct_answers\": 0,
            \"updated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
        }" > /dev/null
    
    echo "✅ Reset: $subject_name (ID: ${subject_id:0:8}...)"
done

echo ""
echo "🎉 All subject stats reset to 0/0"
echo ""
echo "Verifying..."
SUBJECTS_AFTER=$(curl -s -X GET \
    "${SUPABASE_URL}/rest/v1/subjects?select=*" \
    -H "apikey: ${ANON_KEY}" \
    -H "Authorization: Bearer ${TOKEN}")

echo "$SUBJECTS_AFTER" | jq -r '.[] | "\(.name): \(.total_questions)/\(.correct_answers)"'
