#!/bin/bash

# =============================================================================
# FormulaQuizzer Supabase API Testing Script
# Tests cross-user isolation, RLS policies, and data integrity
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Supabase Configuration
SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

# Test user credentials
USER1_EMAIL="testing1@gmail.com"
USER1_PASSWORD="testing1"
USER2_EMAIL="testing2@gmail.com"
USER2_PASSWORD="testing2"

# Global variables for tokens
USER1_TOKEN=""
USER2_TOKEN=""
USER1_ID=""
USER2_ID=""

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${YELLOW}[TEST $TESTS_RUN] $1${NC}"
}

print_success() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo -e "${GREEN}✅ PASS: $1${NC}\n"
}

print_fail() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}❌ FAIL: $1${NC}\n"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# =============================================================================
# Test 1: Database Cleanup
# =============================================================================

test_cleanup() {
    print_header "TEST 1: Database Cleanup"
    print_test "Cleaning all data from database"
    
    # Note: This requires admin access, will be done via Supabase dashboard
    print_info "Run this SQL in Supabase SQL Editor:"
    cat << 'EOF'
DELETE FROM quiz_answers;
DELETE FROM quiz_sessions;
DELETE FROM questions;
DELETE FROM subjects;

-- Verify cleanup
SELECT 'subjects' as table_name, COUNT(*) as count FROM subjects
UNION ALL
SELECT 'questions', COUNT(*) FROM questions
UNION ALL
SELECT 'quiz_sessions', COUNT(*) FROM quiz_sessions
UNION ALL
SELECT 'quiz_answers', COUNT(*) FROM quiz_answers;
EOF
    
    print_success "SQL provided for manual execution"
}

# =============================================================================
# Test 2: User Authentication
# =============================================================================

test_auth_user1() {
    print_header "TEST 2: Authenticate User 1 (testing@gmail.com)"
    print_test "Signing in as testing@gmail.com"
    
    RESPONSE=$(curl -s -X POST \
        "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${USER1_EMAIL}\",\"password\":\"${USER1_PASSWORD}\"}")
    
    # Extract access token and user ID
    USER1_TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    USER1_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ -n "$USER1_TOKEN" ] && [ -n "$USER1_ID" ]; then
        print_success "User 1 authenticated. ID: ${USER1_ID:0:8}..."
        echo "Token: ${USER1_TOKEN:0:20}..."
    else
        print_fail "Authentication failed"
        echo "Response: $RESPONSE"
    fi
}

test_auth_user2() {
    print_header "TEST 3: Authenticate User 2 (ethan@gmail.com)"
    print_test "Signing in as ethan@gmail.com"
    
    RESPONSE=$(curl -s -X POST \
        "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${USER2_EMAIL}\",\"password\":\"${USER2_PASSWORD}\"}")
    
    USER2_TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
    USER2_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ -n "$USER2_TOKEN" ] && [ -n "$USER2_ID" ]; then
        print_success "User 2 authenticated. ID: ${USER2_ID:0:8}..."
        echo "Token: ${USER2_TOKEN:0:20}..."
    else
        print_fail "Authentication failed"
        echo "Response: $RESPONSE"
    fi
}

# =============================================================================
# Test 4: Create Subjects for User 1
# =============================================================================

test_create_subjects_user1() {
    print_header "TEST 4: Create Subjects for User 1"
    
    # Create subject 1
    print_test "Creating 'Testing Math' for User 1"
    RESPONSE=$(curl -s -X POST \
        "${SUPABASE_URL}/rest/v1/subjects" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER1_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "{
            \"user_id\": \"${USER1_ID}\",
            \"name\": \"Testing Math\",
            \"description\": \"Mathematics for testing\",
            \"color\": \"#FF5722\",
            \"is_active\": true,
            \"total_questions\": 0,
            \"correct_answers\": 0,
            \"difficulty_weight\": 0.5,
            \"created_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",
            \"updated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
        }")
    
    if echo "$RESPONSE" | grep -q "Testing Math"; then
        print_success "Subject 'Testing Math' created"
    else
        print_fail "Failed to create subject"
        echo "Response: $RESPONSE"
    fi
    
    # Create subject 2
    print_test "Creating 'Testing Physics' for User 1"
    RESPONSE=$(curl -s -X POST \
        "${SUPABASE_URL}/rest/v1/subjects" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER1_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "{
            \"user_id\": \"${USER1_ID}\",
            \"name\": \"Testing Physics\",
            \"description\": \"Physics for testing\",
            \"color\": \"#2196F3\",
            \"is_active\": true,
            \"total_questions\": 0,
            \"correct_answers\": 0,
            \"difficulty_weight\": 0.5,
            \"created_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",
            \"updated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
        }")
    
    if echo "$RESPONSE" | grep -q "Testing Physics"; then
        print_success "Subject 'Testing Physics' created"
    else
        print_fail "Failed to create subject"
        echo "Response: $RESPONSE"
    fi
}

# =============================================================================
# Test 5: Verify User 1 Can See Their Subjects
# =============================================================================

test_read_subjects_user1() {
    print_header "TEST 5: Verify User 1 Can Read Their Subjects"
    print_test "Fetching subjects for User 1"
    
    RESPONSE=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?user_id=eq.${USER1_ID}&select=*" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER1_TOKEN}")
    
    COUNT=$(echo "$RESPONSE" | grep -o '"name"' | wc -l)
    
    if [ "$COUNT" -eq 2 ]; then
        print_success "User 1 can see 2 subjects (correct)"
        echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
    else
        print_fail "User 1 sees $COUNT subjects (expected 2)"
        echo "$RESPONSE"
    fi
}

# =============================================================================
# Test 6: Verify User 2 CANNOT See User 1's Subjects (RLS Test)
# =============================================================================

test_isolation_user2_cannot_see_user1() {
    print_header "TEST 6: CRITICAL - Cross-User Isolation Test"
    print_test "User 2 attempting to read User 1's subjects"
    
    RESPONSE=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?select=*" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER2_TOKEN}")
    
    COUNT=$(echo "$RESPONSE" | grep -o '"name"' | wc -l)
    
    if [ "$COUNT" -eq 0 ]; then
        print_success "✅ CRITICAL: User 2 CANNOT see User 1's subjects (isolation working)"
    else
        print_fail "❌ CRITICAL: User 2 can see $COUNT subjects (DATA LEAK!)"
        echo "$RESPONSE"
    fi
}

# =============================================================================
# Test 7: Create Subjects for User 2
# =============================================================================

test_create_subjects_user2() {
    print_header "TEST 7: Create Subjects for User 2"
    
    print_test "Creating 'Ethan Chemistry' for User 2"
    RESPONSE=$(curl -s -X POST \
        "${SUPABASE_URL}/rest/v1/subjects" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER2_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "{
            \"user_id\": \"${USER2_ID}\",
            \"name\": \"Ethan Chemistry\",
            \"description\": \"Chemistry for Ethan\",
            \"color\": \"#4CAF50\",
            \"is_active\": true,
            \"total_questions\": 0,
            \"correct_answers\": 0,
            \"difficulty_weight\": 0.5,
            \"created_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",
            \"updated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
        }")
    
    if echo "$RESPONSE" | grep -q "Ethan Chemistry"; then
        print_success "Subject 'Ethan Chemistry' created for User 2"
    else
        print_fail "Failed to create subject"
        echo "Response: $RESPONSE"
    fi
}

# =============================================================================
# Test 8: Verify Each User Sees Only Their Own Data
# =============================================================================

test_verify_isolation() {
    print_header "TEST 8: Verify Complete Isolation"
    
    # User 1 should see only their 2 subjects
    print_test "User 1 should see 2 subjects (Testing Math, Testing Physics)"
    RESPONSE1=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?select=name" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER1_TOKEN}")
    
    COUNT1=$(echo "$RESPONSE1" | grep -o '"name"' | wc -l)
    HAS_ETHAN=$(echo "$RESPONSE1" | grep -c "Ethan Chemistry" || true)
    
    if [ "$COUNT1" -eq 2 ] && [ "$HAS_ETHAN" -eq 0 ]; then
        print_success "User 1 sees only their 2 subjects (no contamination)"
    else
        print_fail "User 1 isolation failed (Count: $COUNT1, Has Ethan's: $HAS_ETHAN)"
        echo "$RESPONSE1"
    fi
    
    # User 2 should see only their 1 subject
    print_test "User 2 should see 1 subject (Ethan Chemistry)"
    RESPONSE2=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?select=name" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER2_TOKEN}")
    
    COUNT2=$(echo "$RESPONSE2" | grep -o '"name"' | wc -l)
    HAS_TESTING=$(echo "$RESPONSE2" | grep -c "Testing" || true)
    
    if [ "$COUNT2" -eq 1 ] && [ "$HAS_TESTING" -eq 0 ]; then
        print_success "User 2 sees only their 1 subject (no contamination)"
    else
        print_fail "User 2 isolation failed (Count: $COUNT2, Has Testing's: $HAS_TESTING)"
        echo "$RESPONSE2"
    fi
}

# =============================================================================
# Test 9: Attempt Unauthorized Access
# =============================================================================

test_unauthorized_access() {
    print_header "TEST 9: Security - Unauthorized Access Attempts"
    
    # Try to access without token
    print_test "Attempting to read subjects without authentication"
    RESPONSE=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?select=*" \
        -H "apikey: ${SUPABASE_ANON_KEY}")
    
    # Should return empty array due to RLS
    COUNT=$(echo "$RESPONSE" | grep -o '"name"' | wc -l)
    
    if [ "$COUNT" -eq 0 ]; then
        print_success "Unauthorized access blocked by RLS"
    else
        print_fail "SECURITY RISK: Unauthorized user can see $COUNT subjects"
        echo "$RESPONSE"
    fi
    
    # Try to modify User 1's data as User 2
    print_test "User 2 attempting to modify User 1's subject"
    RESPONSE=$(curl -s -X PATCH \
        "${SUPABASE_URL}/rest/v1/subjects?name=eq.Testing%20Math" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER2_TOKEN}" \
        -H "Content-Type: application/json" \
        -d '{"description": "HACKED BY USER 2"}')
    
    # Verify it wasn't modified
    VERIFY=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?name=eq.Testing%20Math&select=description" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER1_TOKEN}")
    
    if echo "$VERIFY" | grep -q "HACKED"; then
        print_fail "SECURITY BREACH: User 2 modified User 1's data!"
    else
        print_success "Cross-user modification blocked"
    fi
}

# =============================================================================
# Test 10: Update Operations
# =============================================================================

test_update_operations() {
    print_header "TEST 10: Update Operations"
    
    print_test "User 1 updating their own subject"
    RESPONSE=$(curl -s -X PATCH \
        "${SUPABASE_URL}/rest/v1/subjects?name=eq.Testing%20Math" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER1_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "{
            \"description\": \"Updated mathematics description\",
            \"total_questions\": 10,
            \"correct_answers\": 7,
            \"updated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
        }")
    
    if echo "$RESPONSE" | grep -q "Updated mathematics"; then
        print_success "User 1 successfully updated their subject"
    else
        print_fail "Update failed"
        echo "$RESPONSE"
    fi
}

# =============================================================================
# Test 11: Delete Operations
# =============================================================================

test_delete_operations() {
    print_header "TEST 11: Delete Operations"
    
    # User 2 tries to delete User 1's subject (should fail)
    print_test "User 2 attempting to delete User 1's subject (should fail)"
    RESPONSE=$(curl -s -X DELETE \
        "${SUPABASE_URL}/rest/v1/subjects?name=eq.Testing%20Math" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER2_TOKEN}")
    
    # Verify subject still exists
    VERIFY=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?name=eq.Testing%20Math&select=name" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER1_TOKEN}")
    
    if echo "$VERIFY" | grep -q "Testing Math"; then
        print_success "Cross-user deletion blocked"
    else
        print_fail "SECURITY BREACH: User 2 deleted User 1's subject!"
    fi
    
    # User 1 deletes their own subject (should succeed)
    print_test "User 1 deleting their own subject"
    curl -s -X DELETE \
        "${SUPABASE_URL}/rest/v1/subjects?name=eq.Testing%20Physics" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER1_TOKEN}" > /dev/null
    
    # Verify deletion
    VERIFY=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?name=eq.Testing%20Physics&select=name" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER1_TOKEN}")
    
    if [ "$VERIFY" = "[]" ]; then
        print_success "User 1 successfully deleted their own subject"
    else
        print_fail "Deletion failed"
    fi
}

# =============================================================================
# Test 12: Final State Verification
# =============================================================================

test_final_state() {
    print_header "TEST 12: Final State Verification"
    
    print_test "Verifying final state for both users"
    
    # User 1 should have 1 subject (Testing Math - deleted Testing Physics)
    USER1_COUNT=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?select=name" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER1_TOKEN}" | grep -o '"name"' | wc -l)
    
    # User 2 should have 1 subject (Ethan Chemistry)
    USER2_COUNT=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?select=name" \
        -H "apikey: ${SUPABASE_ANON_KEY}" \
        -H "Authorization: Bearer ${USER2_TOKEN}" | grep -o '"name"' | wc -l)
    
    if [ "$USER1_COUNT" -eq 1 ] && [ "$USER2_COUNT" -eq 1 ]; then
        print_success "Final state correct: User 1 has 1 subject, User 2 has 1 subject"
    else
        print_fail "Final state incorrect: User 1 has $USER1_COUNT, User 2 has $USER2_COUNT"
    fi
}

# =============================================================================
# Test Summary
# =============================================================================

print_summary() {
    print_header "TEST SUMMARY"
    
    echo -e "${BLUE}Tests Run:    ${NC}$TESTS_RUN"
    echo -e "${GREEN}Tests Passed: ${NC}$TESTS_PASSED"
    echo -e "${RED}Tests Failed: ${NC}$TESTS_FAILED"
    
    PASS_RATE=$((TESTS_PASSED * 100 / TESTS_RUN))
    echo -e "${BLUE}Pass Rate:    ${NC}${PASS_RATE}%"
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "\n${GREEN}🎉 ALL TESTS PASSED!${NC}"
        echo -e "${GREEN}✅ Cross-user isolation is working correctly${NC}"
        echo -e "${GREEN}✅ RLS policies are functioning as expected${NC}"
        echo -e "${GREEN}✅ Database is production-ready${NC}\n"
    else
        echo -e "\n${RED}❌ SOME TESTS FAILED${NC}"
        echo -e "${RED}⚠️  Review failed tests above${NC}\n"
    fi
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    clear
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        FormulaQuizzer Supabase API Test Suite               ║
║        Testing Cross-User Isolation & RLS Policies           ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    test_cleanup
    echo -e "\n${YELLOW}⏸️  Press Enter after running the cleanup SQL in Supabase...${NC}"
    read -r
    
    test_auth_user1
    test_auth_user2
    test_create_subjects_user1
    test_read_subjects_user1
    test_isolation_user2_cannot_see_user1
    test_create_subjects_user2
    test_verify_isolation
    test_unauthorized_access
    test_update_operations
    test_delete_operations
    test_final_state
    
    print_summary
}

# Run tests
main
