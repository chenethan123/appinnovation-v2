#!/bin/bash

# =============================================================================
# Complete Test Suite - Creates Users and Runs All Tests
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     FormulaQuizzer Complete Test Suite                      ║
║     Step 1: Create Users                                     ║
║     Step 2: Run All Tests                                    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# =============================================================================
# Step 1: Create Test Users
# =============================================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 1: Creating Test Users${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Create User 1
echo -e "${YELLOW}Creating testing1@gmail.com...${NC}"
RESPONSE1=$(curl -s -X POST \
    "${SUPABASE_URL}/auth/v1/signup" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "testing1@gmail.com",
        "password": "testing1"
    }')

if echo "$RESPONSE1" | grep -q '"id"'; then
    USER1_ID=$(echo "$RESPONSE1" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo -e "${GREEN}✅ User 1 created: testing1@gmail.com (ID: ${USER1_ID:0:8}...)${NC}"
elif echo "$RESPONSE1" | grep -q "user_already_exists"; then
    echo -e "${YELLOW}⚠️  User 1 already exists: testing1@gmail.com${NC}"
else
    echo -e "${RED}❌ Failed to create User 1${NC}"
    echo "Response: $RESPONSE1"
fi

# Create User 2
echo -e "\n${YELLOW}Creating testing2@gmail.com...${NC}"
RESPONSE2=$(curl -s -X POST \
    "${SUPABASE_URL}/auth/v1/signup" \
    -H "apikey: ${SUPABASE_ANON_KEY}" \
    -H "Content-Type: application/json" \
    -d '{
        "email": "testing2@gmail.com",
        "password": "testing2"
    }')

if echo "$RESPONSE2" | grep -q '"id"'; then
    USER2_ID=$(echo "$RESPONSE2" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    echo -e "${GREEN}✅ User 2 created: testing2@gmail.com (ID: ${USER2_ID:0:8}...)${NC}"
elif echo "$RESPONSE2" | grep -q "user_already_exists"; then
    echo -e "${YELLOW}⚠️  User 2 already exists: testing2@gmail.com${NC}"
else
    echo -e "${RED}❌ Failed to create User 2${NC}"
    echo "Response: $RESPONSE2"
fi

echo -e "\n${GREEN}✅ User creation complete!${NC}\n"

# =============================================================================
# Step 2: Run Full Test Suite
# =============================================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}STEP 2: Running Full Test Suite${NC}"
echo -e "${BLUE}========================================${NC}\n"

sleep 2

# Run the main test suite (skip the cleanup prompt)
cd "$(dirname "$0")"
echo "" | ./curl_tests.sh
