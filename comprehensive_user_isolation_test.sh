#!/bin/bash

# Comprehensive User Isolation Test Script
# Tests authentication, subject creation, isolation, and deletion across 10 users

SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test statistics
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print test results
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
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to login and get access token
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

# Function to create a new account
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

# Function to get subjects for a user
get_subjects() {
    local token=$1
    
    local response=$(curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?select=*&order=name.asc" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}")
    
    echo "$response"
}

# Function to count subjects
count_subjects() {
    local subjects=$1
    echo "$subjects" | jq '. | length'
}

# Function to create a subject
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
    
    echo "$response"
}

# Function to delete a subject by name
delete_subject() {
    local token=$1
    local user_id=$2
    local name=$3
    
    curl -s -X DELETE \
        "${SUPABASE_URL}/rest/v1/subjects?user_id=eq.${user_id}&name=eq.${name}" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}"
}

# Function to delete all subjects for a user
delete_all_subjects() {
    local token=$1
    local user_id=$2
    
    curl -s -X DELETE \
        "${SUPABASE_URL}/rest/v1/subjects?user_id=eq.${user_id}" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}"
}

section "📋 STEP 1: RESET STATE"
info "Clearing all subjects for existing test accounts..."

# Clear testing1 and testing2
for i in 1 2; do
    result=$(login_user "testing${i}@gmail.com" "testing${i}")
    if [ $? -eq 0 ]; then
        IFS='|' read -r token user_id <<< "$result"
        delete_all_subjects "$token" "$user_id"
        info "Cleared subjects for testing${i}@gmail.com"
    fi
done

section "📋 STEP 2: CREATE TEST ACCOUNTS"
info "Creating accounts testing3 through testing10..."

for i in {3..10}; do
    email="testing${i}@gmail.com"
    password="testing${i}"
    
    if create_account "$email" "$password"; then
        pass_test "Created account: $email"
    else
        # Account might already exist, try to login
        result=$(login_user "$email" "$password")
        if [ $? -eq 0 ]; then
            info "Account already exists: $email (login successful)"
            # Clear any existing subjects
            IFS='|' read -r token user_id <<< "$result"
            delete_all_subjects "$token" "$user_id"
        else
            fail_test "Failed to create or login to: $email"
        fi
    fi
    sleep 0.5
done

section "📋 STEP 3: MULTI-LOGIN STRESS TEST"
info "Testing multiple logins for each account..."

for i in {1..10}; do
    email="testing${i}@gmail.com"
    password="testing${i}"
    
    login_success_count=0
    for attempt in {1..5}; do
        result=$(login_user "$email" "$password")
        if [ $? -eq 0 ]; then
            IFS='|' read -r token user_id <<< "$result"
            subjects=$(get_subjects "$token")
            count=$(count_subjects "$subjects")
            
            if [ "$count" == "0" ]; then
                ((login_success_count++))
            fi
        fi
        sleep 0.3
    done
    
    if [ $login_success_count -eq 5 ]; then
        pass_test "testing${i}: All 5 logins successful, account starts with 0 subjects"
    else
        fail_test "testing${i}: Only $login_success_count/5 successful logins"
    fi
done

section "📋 STEP 4: SUBJECT CREATION TESTS"
info "Creating subjects for each user..."

declare -A USER_TOKENS
declare -A USER_IDS

for i in {1..10}; do
    email="testing${i}@gmail.com"
    password="testing${i}"
    
    result=$(login_user "$email" "$password")
    if [ $? -eq 0 ]; then
        IFS='|' read -r token user_id <<< "$result"
        USER_TOKENS[$i]=$token
        USER_IDS[$i]=$user_id
        
        # Create 5 subjects for this user
        for j in {1..5}; do
            create_subject "$token" "$user_id" "Subject ${j} for testing${i}"
            sleep 0.2
        done
        
        # Verify subjects were created
        subjects=$(get_subjects "$token")
        count=$(count_subjects "$subjects")
        
        if [ "$count" == "5" ]; then
            pass_test "testing${i}: Created and verified 5 subjects"
        else
            fail_test "testing${i}: Expected 5 subjects, found $count"
        fi
    else
        fail_test "testing${i}: Failed to login"
    fi
done

section "📋 STEP 5: CROSS-ACCOUNT ISOLATION TESTS"
info "Testing data isolation between users..."

for i in {1..10}; do
    token=${USER_TOKENS[$i]}
    
    if [ -z "$token" ]; then
        fail_test "testing${i}: No token available for isolation test"
        continue
    fi
    
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    # Check that we only see this user's subjects
    isolation_pass=true
    for j in {1..10}; do
        if [ $i -ne $j ]; then
            # Check if any subjects contain other user's name
            other_user_subjects=$(echo "$subjects" | jq -r ".[] | select(.name | contains(\"testing${j}\")) | .name")
            if [ ! -z "$other_user_subjects" ]; then
                fail_test "testing${i}: Can see testing${j}'s subjects!"
                isolation_pass=false
                break
            fi
        fi
    done
    
    if $isolation_pass && [ "$count" == "5" ]; then
        pass_test "testing${i}: Perfect isolation - sees only own 5 subjects"
    elif $isolation_pass; then
        fail_test "testing${i}: Isolation OK but expected 5 subjects, found $count"
    fi
done

section "📋 STEP 6: ADDITIONAL SUBJECT ADDITIONS"
info "Adding more subjects to each user..."

for i in {1..10}; do
    token=${USER_TOKENS[$i]}
    user_id=${USER_IDS[$i]}
    
    if [ -z "$token" ]; then
        fail_test "testing${i}: No token available"
        continue
    fi
    
    # Add 3 more subjects
    for j in {6..8}; do
        create_subject "$token" "$user_id" "Extra Subject ${j} for testing${i}"
        sleep 0.2
    done
    
    # Verify total is now 8
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    if [ "$count" == "8" ]; then
        pass_test "testing${i}: Successfully added 3 more subjects (total: 8)"
    else
        fail_test "testing${i}: Expected 8 subjects after additions, found $count"
    fi
done

section "📋 STEP 7: DELETION TESTS"
info "Testing subject deletion..."

for i in {1..10}; do
    token=${USER_TOKENS[$i]}
    user_id=${USER_IDS[$i]}
    
    if [ -z "$token" ]; then
        fail_test "testing${i}: No token available for deletion test"
        continue
    fi
    
    # Delete 2 subjects
    delete_subject "$token" "$user_id" "Subject 1 for testing${i}"
    sleep 0.2
    delete_subject "$token" "$user_id" "Subject 2 for testing${i}"
    sleep 0.2
    
    # Verify count is now 6
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    if [ "$count" == "6" ]; then
        # Verify deleted subjects are gone
        subject1_exists=$(echo "$subjects" | jq -r ".[] | select(.name == \"Subject 1 for testing${i}\") | .name")
        subject2_exists=$(echo "$subjects" | jq -r ".[] | select(.name == \"Subject 2 for testing${i}\") | .name")
        
        if [ -z "$subject1_exists" ] && [ -z "$subject2_exists" ]; then
            pass_test "testing${i}: Successfully deleted 2 subjects (remaining: 6)"
        else
            fail_test "testing${i}: Subjects not properly deleted"
        fi
    else
        fail_test "testing${i}: Expected 6 subjects after deletion, found $count"
    fi
done

section "📋 STEP 8: FINAL VERIFICATION"
info "Final cross-user isolation check..."

# Re-login as testing1 and verify data
result=$(login_user "testing1@gmail.com" "testing1")
if [ $? -eq 0 ]; then
    IFS='|' read -r token user_id <<< "$result"
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    # Check for contamination from other users
    contamination_found=false
    for i in {2..10}; do
        other_subjects=$(echo "$subjects" | jq -r ".[] | select(.name | contains(\"testing${i}\")) | .name")
        if [ ! -z "$other_subjects" ]; then
            fail_test "CRITICAL: testing1 can see testing${i}'s subjects!"
            contamination_found=true
        fi
    done
    
    if ! $contamination_found && [ "$count" == "6" ]; then
        pass_test "FINAL: testing1 has perfect isolation with 6 subjects"
    elif ! $contamination_found; then
        fail_test "FINAL: testing1 isolation OK but expected 6 subjects, found $count"
    fi
else
    fail_test "FINAL: Could not re-login as testing1"
fi

section "📊 TEST SUMMARY"
echo ""
echo -e "${CYAN}Total Tests:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Passed:${NC} $PASSED_TESTS"
echo -e "${RED}Failed:${NC} $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Perfect user isolation confirmed.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  SOME TESTS FAILED. Review output above for details.${NC}"
    exit 1
fi
