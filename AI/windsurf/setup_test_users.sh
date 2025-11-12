#!/bin/bash

# =============================================================================
# Create Test Users for FormulaQuizzer
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

echo -e "${BLUE}Creating Test Users...${NC}\n"

# Create User 1
echo -e "${BLUE}Creating testing@gmail.com...${NC}"
RESPONSE1=$(curl -s -X POST \
    "${SUPABASE_URL}/auth/v1/signup" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "testing@gmail.com",
        "password": "password123"
    }')

if echo "$RESPONSE1" | grep -q '"id"'; then
    echo -e "${GREEN}✅ User 1 created: testing@gmail.com${NC}"
else
    echo -e "${RED}User 1 may already exist or creation failed${NC}"
    echo "Response: $RESPONSE1"
fi

# Create User 2
echo -e "\n${BLUE}Creating ethan@gmail.com...${NC}"
RESPONSE2=$(curl -s -X POST \
    "${SUPABASE_URL}/auth/v1/signup" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "ethan@gmail.com",
        "password": "password123"
    }')

if echo "$RESPONSE2" | grep -q '"id"'; then
    echo -e "${GREEN}✅ User 2 created: ethan@gmail.com${NC}"
else
    echo -e "${RED}User 2 may already exist or creation failed${NC}"
    echo "Response: $RESPONSE2"
fi

echo -e "\n${GREEN}Setup complete! Users ready for testing.${NC}"
