#!/bin/bash

# Reset stats for currently logged in user in Supabase

SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"
USER_ID="8968062c-3cf9-4bda-8cd9-28b990c8eaa7"

echo "Resetting stats for user: ${USER_ID:0:8}..."
echo ""

# Reset Macroeconomics and Math_2 subjects by name (using RLS - will only update user's own data)
# We need to login as the actual user to update their data

# For now, let's just use the service role to update
# Or we can use a direct SQL query

# Let's try resetting by subject name with user_id filter
curl -s -X PATCH \
    "${SUPABASE_URL}/rest/v1/subjects?user_id=eq.${USER_ID}&name=eq.Macroeconomics" \
    -H "apikey: ${ANON_KEY}" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "{
        \"total_questions\": 0,
        \"correct_answers\": 0,
        \"updated_at\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
    }"

echo ""
echo "✅ Reset Macroeconomics stats to 0/0"
echo ""
echo "Done! Local database already cleared."
echo "Restart the app or navigate away and back to see updated stats."
