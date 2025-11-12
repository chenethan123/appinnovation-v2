#!/bin/bash

# =============================================================================
# Clean Database via API and Run Tests
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

echo -e "${BLUE}Cleaning database via API...${NC}\n"

# Login as user 1
TOKEN1=$(curl -s -X POST \
    "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"email":"testing1@gmail.com","password":"testing1"}' | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

# Login as user 2
TOKEN2=$(curl -s -X POST \
    "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d '{"email":"testing2@gmail.com","password":"testing2"}' | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

# Delete all subjects for user 1
echo -e "${BLUE}Deleting User 1 subjects...${NC}"
curl -s -X DELETE \
    "${SUPABASE_URL}/rest/v1/subjects?user_id=eq.*" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Authorization: Bearer ${TOKEN1}" > /dev/null

# Delete all subjects for user 2
echo -e "${BLUE}Deleting User 2 subjects...${NC}"
curl -s -X DELETE \
    "${SUPABASE_URL}/rest/v1/subjects?user_id=eq.*" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Authorization: Bearer ${TOKEN2}" > /dev/null

echo -e "${GREEN}✅ Database cleaned!${NC}\n"
sleep 1

# Run tests
echo -e "${BLUE}Running tests...${NC}\n"
cd "$(dirname "$0")"
echo "" | ./curl_tests.sh
