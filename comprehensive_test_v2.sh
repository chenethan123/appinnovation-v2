#!/bin/bash

# Comprehensive User Isolation Test Script V2
# Fixed: Token persistence, deletion by ID, better error handling

SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Stats
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Arrays to store user info
declare -A USER_TOKENS
declare -A USER_IDS
declare -A USER_SUBJECT_IDS

pass_test() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
}

fail_test() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
}

info() {
    echo -e "${BLUE}ℹ️  ${NC}$1"
}

section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

login_user() {
    local email=$1
    local password=$2
    
    local response=$(curl -s -X POST \
        "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
        -H "apikey: ${ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${email}\",\"password\":\"${password}\"}")
    
    local token=$(echo "$response" | jq -r '.access_token // empty')
    local user_id=$(echo "$response" | jq -r '.user.id // empty')
    
    if [ -z "$token" ] || [ "$token" == "null" ]; then
        echo ""
        return 1
    fi
    
    echo "${token}|${user_id}"
    return 0
}

create_account() {
    local email=$1
    local password=$2
    
    local response=$(curl -s -X POST \
        "${SUPABASE_URL}/auth/v1/signup" \
        -H "apikey: ${ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${email}\",\"password\":\"${password}\"}")
    
    local user_id=$(echo "$response" | jq -r '.user.id // empty')
    
    if [ -z "$user_id" ] || [ "$user_id" == "null" ]; then
        return 1
    fi
    
    return 0
}

get_subjects() {
    local token=$1
    
    local response=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?select=*&order=name.asc" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}")
    
    echo "$response"
}

count_subjects() {
    local subjects=$1
    echo "$subjects" | jq '. | length'
}

create_subject() {
    local token=$1
    local user_id=$2
    local name=$3
    
    local response=$(curl -s -X POST \
        "${SUPABASE_URL}/rest/v1/subjects" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "{
            \"user_id\": \"${user_id}\",
            \"name\": \"${name}\",
            \"description\": \"Test subject\",
            \"color\": \"#2196F3\",
            \"is_active\": true,
            \"total_questions\": 0,
            \"correct_answers\": 0,
            \"difficulty_weight\": 0.5
        }")
    
    # Return the ID of created subject
    echo "$response" | jq -r '.[0].id // empty'
}

delete_subject_by_id() {
    local token=$1
    local subject_id=$2
    
    curl -s -X DELETE \
        "${SUPABASE_URL}/rest/v1/subjects?id=eq.${subject_id}" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}"
}

delete_all_subjects() {
    local token=$1
    local user_id=$2
    
    curl -s -X DELETE \
        "${SUPABASE_URL}/rest/v1/subjects?user_id=eq.${user_id}" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}"
}

section "📋 STEP 1: RESET STATE - Clean slate for all accounts"

for i in {1..10}; do
    result=$(login_user "testing${i}@gmail.com" "testing${i}")
    if [ $? -eq 0 ]; then
        IFS='|' read -r token user_id <<< "$result"
        delete_all_subjects "$token" "$user_id"
        info "Cleared all subjects for testing${i}"
    fi
    sleep 0.3
done

section "📋 STEP 2: CREATE/VERIFY TEST ACCOUNTS"

for i in {3..10}; do
    email="testing${i}@gmail.com"
    password="testing${i}"
    
    result=$(login_user "$email" "$password")
    if [ $? -eq 0 ]; then
        info "Account exists: testing${i} (login successful)"
    else
        if create_account "$email" "$password"; then
            pass_test "Created new account: testing${i}"
        else
            fail_test "Could not create account: testing${i}"
        fi
    fi
    sleep 0.5
done

section "📋 STEP 3: MULTI-LOGIN STRESS TEST (5 logins each)"

for i in {1..10}; do
    success_count=0
    
    for attempt in {1..5}; do
        result=$(login_user "testing${i}@gmail.com" "testing${i}")
        if [ $? -eq 0 ]; then
            IFS='|' read -r token user_id <<< "$result"
            subjects=$(get_subjects "$token")
            count=$(count_subjects "$subjects")
            
            # Store token and user_id for later use
            if [ $attempt -eq 5 ]; then
                USER_TOKENS[$i]=$token
                USER_IDS[$i]=$user_id
            fi
            
            if [ "$count" == "0" ]; then
                ((success_count++))
            fi
        fi
        sleep 0.2
    done
    
    if [ $success_count -eq 5 ]; then
        pass_test "testing${i}: 5/5 logins successful, account clean (0 subjects)"
    else
        fail_test "testing${i}: Only $success_count/5 successful clean logins"
    fi
done

section "📋 STEP 4: SUBJECT CREATION (5 subjects per user)"

for i in {1..10}; do
    token=${USER_TOKENS[$i]}
    user_id=${USER_IDS[$i]}
    
    if [ -z "$token" ]; then
        fail_test "testing${i}: No token, skipping"
        continue
    fi
    
    subject_ids=""
    for j in {1..5}; do
        subject_id=$(create_subject "$token" "$user_id" "Subject ${j} for testing${i}")
        if [ ! -z "$subject_id" ]; then
            subject_ids="${subject_ids},${subject_id}"
        fi
        sleep 0.2
    done
    
    # Store subject IDs
    USER_SUBJECT_IDS[$i]=$subject_ids
    
    # Verify
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    if [ "$count" == "5" ]; then
        pass_test "testing${i}: Created 5 subjects successfully"
    else
        fail_test "testing${i}: Expected 5 subjects, got $count"
    fi
done

section "📋 STEP 5: CROSS-ACCOUNT ISOLATION TEST"

for i in {1..10}; do
    token=${USER_TOKENS[$i]}
    
    if [ -z "$token" ]; then
        fail_test "testing${i}: No token for isolation test"
        continue
    fi
    
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    # Check no other user's subjects appear
    violation=false
    for j in {1..10}; do
        if [ $i -ne $j ]; then
            other_subjects=$(echo "$subjects" | jq -r ".[] | select(.name | contains(\"testing${j}\")) | .name")
            if [ ! -z "$other_subjects" ]; then
                fail_test "CRITICAL: testing${i} can see testing${j}'s subjects!"
                violation=true
                break
            fi
        fi
    done
    
    if ! $violation && [ "$count" == "5" ]; then
        pass_test "testing${i}: Perfect isolation, sees only own 5 subjects"
    elif ! $violation; then
        fail_test "testing${i}: Isolation OK but expected 5, got $count"
    fi
done

section "📋 STEP 6: ADD MORE SUBJECTS (3 additional each)"

for i in {1..10}; do
    token=${USER_TOKENS[$i]}
    user_id=${USER_IDS[$i]}
    
    if [ -z "$token" ]; then
        fail_test "testing${i}: No token"
        continue
    fi
    
    for j in {6..8}; do
        subject_id=$(create_subject "$token" "$user_id" "Extra Subject ${j} for testing${i}")
        if [ ! -z "$subject_id" ]; then
            USER_SUBJECT_IDS[$i]="${USER_SUBJECT_IDS[$i]},${subject_id}"
        fi
        sleep 0.2
    done
    
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    if [ "$count" == "8" ]; then
        pass_test "testing${i}: Added 3 more subjects (total: 8)"
    else
        fail_test "testing${i}: Expected 8 subjects, got $count"
    fi
done

section "📋 STEP 7: DELETION TEST (delete 2 subjects by ID)"

for i in {1..10}; do
    token=${USER_TOKENS[$i]}
    
    if [ -z "$token" ]; then
        fail_test "testing${i}: No token for deletion"
        continue
    fi
    
    # Get current subjects and their IDs
    subjects=$(get_subjects "$token")
    
    # Get first 2 subject IDs
    first_id=$(echo "$subjects" | jq -r '.[0].id')
    second_id=$(echo "$subjects" | jq -r '.[1].id')
    
    # Delete them
    delete_subject_by_id "$token" "$first_id"
    sleep 0.3
    delete_subject_by_id "$token" "$second_id"
    sleep 0.3
    
    # Verify
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    # Check deleted subjects are gone
    first_exists=$(echo "$subjects" | jq -r ".[] | select(.id == \"$first_id\") | .id")
    second_exists=$(echo "$subjects" | jq -r ".[] | select(.id == \"$second_id\") | .id")
    
    if [ "$count" == "6" ] && [ -z "$first_exists" ] && [ -z "$second_exists" ]; then
        pass_test "testing${i}: Deleted 2 subjects, 6 remaining"
    else
        fail_test "testing${i}: Deletion failed (expected 6, got $count)"
    fi
done

section "📋 STEP 8: FINAL VERIFICATION - Re-login and check testing1"

# Fresh login as testing1
result=$(login_user "testing1@gmail.com" "testing1")
if [ $? -eq 0 ]; then
    IFS='|' read -r token user_id <<< "$result"
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    # Check for contamination
    contaminated=false
    for i in {2..10}; do
        other=$(echo "$subjects" | jq -r ".[] | select(.name | contains(\"testing${i}\")) | .name")
        if [ ! -z "$other" ]; then
            fail_test "CRITICAL: testing1 contaminated with testing${i} data!"
            contaminated=true
        fi
    done
    
    if ! $contaminated && [ "$count" == "6" ]; then
        pass_test "FINAL: testing1 perfect isolation with 6 subjects"
    elif ! $contaminated; then
        fail_test "FINAL: testing1 isolated but expected 6 subjects, got $count"
    fi
else
    fail_test "FINAL: Could not re-login as testing1"
fi

section "📊 TEST SUMMARY"
echo ""
echo -e "${CYAN}Total Tests Run:${NC} $TOTAL_TESTS"
echo -e "${GREEN}✅ Passed:${NC} $PASSED_TESTS"
echo -e "${RED}❌ Failed:${NC} $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    success_rate="100%"
else
    success_rate=$(echo "scale=1; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)"%"
fi
echo -e "${YELLOW}📈 Success Rate:${NC} $success_rate"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}✓ Authentication works perfectly${NC}"
    echo -e "${GREEN}✓ Cross-user isolation confirmed${NC}"
    echo -e "${GREEN}✓ CRUD operations function correctly${NC}"
    echo -e "${GREEN}✓ No data leakage detected${NC}"
    exit 0
else
    echo -e "${RED}⚠️  SOME TESTS FAILED${NC}"
    echo -e "${YELLOW}Review failures above for details${NC}"
    exit 1
fi
