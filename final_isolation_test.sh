#!/bin/bash

# Final Comprehensive User Isolation Test
# Compatible with all bash versions

SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0
TOTAL=0

pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED++))
    ((TOTAL++))
}

fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED++))
    ((TOTAL++))
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

section() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════${NC}"
}

# Create temp files for storing tokens
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

get_user_data() {
    local user_num=$1
    local email="testing${user_num}@gmail.com"
    local password="testing${user_num}"
    
    local response=$(curl -s -X POST \
        "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
        -H "apikey: ${ANON_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${email}\",\"password\":\"${password}\"}")
    
    local token=$(echo "$response" | jq -r '.access_token // empty')
    local user_id=$(echo "$response" | jq -r '.user.id // empty')
    
    if [ ! -z "$token" ] && [ "$token" != "null" ]; then
        echo "$token" > "$TEMP_DIR/token_${user_num}"
        echo "$user_id" > "$TEMP_DIR/userid_${user_num}"
        echo "success"
    else
        echo "fail"
    fi
}

get_token() {
    local user_num=$1
    if [ -f "$TEMP_DIR/token_${user_num}" ]; then
        cat "$TEMP_DIR/token_${user_num}"
    fi
}

get_userid() {
    local user_num=$1
    if [ -f "$TEMP_DIR/userid_${user_num}" ]; then
        cat "$TEMP_DIR/userid_${user_num}"
    fi
}

get_subjects() {
    local token=$1
    curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?select=*&order=name.asc" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}"
}

count_subjects() {
    echo "$1" | jq '. | length'
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
    
    echo "$response" | jq -r '.[0].id // empty'
}

delete_subject() {
    local token=$1
    local subject_id=$2
    
    curl -s -X DELETE \
        "${SUPABASE_URL}/rest/v1/subjects?id=eq.${subject_id}" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}"
}

delete_all() {
    local token=$1
    local user_id=$2
    
    curl -s -X DELETE \
        "${SUPABASE_URL}/rest/v1/subjects?user_id=eq.${user_id}" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}"
}

section "STEP 1: RESET - Clean all test accounts"

for i in {1..10}; do
    if [ "$(get_user_data $i)" == "success" ]; then
        token=$(get_token $i)
        userid=$(get_userid $i)
        delete_all "$token" "$userid"
        info "Cleared testing${i}"
    fi
    sleep 0.2
done

section "STEP 2: VERIFY ALL 10 ACCOUNTS EXIST"

all_exist=true
for i in {1..10}; do
    if [ "$(get_user_data $i)" == "success" ]; then
        pass "testing${i} authenticated"
    else
        fail "testing${i} authentication failed"
        all_exist=false
    fi
    sleep 0.2
done

if $all_exist; then
    pass "All 10 accounts verified"
fi

section "STEP 3: MULTI-LOGIN STRESS TEST"

for i in {1..10}; do
    clean_count=0
    
    for attempt in {1..5}; do
        if [ "$(get_user_data $i)" == "success" ]; then
            token=$(get_token $i)
            subjects=$(get_subjects "$token")
            count=$(count_subjects "$subjects")
            
            if [ "$count" == "0" ]; then
                ((clean_count++))
            fi
        fi
        sleep 0.1
    done
    
    if [ $clean_count -eq 5 ]; then
        pass "testing${i}: 5/5 logins successful, all clean"
    else
        fail "testing${i}: Only ${clean_count}/5 clean logins"
    fi
done

section "STEP 4: CREATE 5 SUBJECTS PER USER"

for i in {1..10}; do
    token=$(get_token $i)
    userid=$(get_userid $i)
    
    if [ -z "$token" ]; then
        fail "testing${i}: No token"
        continue
    fi
    
    for j in {1..5}; do
        create_subject "$token" "$userid" "Subject ${j} for testing${i}" > /dev/null
        sleep 0.1
    done
    
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    if [ "$count" == "5" ]; then
        pass "testing${i}: Created 5 subjects"
    else
        fail "testing${i}: Expected 5, got ${count}"
    fi
done

section "STEP 5: CROSS-USER ISOLATION TEST"

for i in {1..10}; do
    token=$(get_token $i)
    
    if [ -z "$token" ]; then
        fail "testing${i}: No token"
        continue
    fi
    
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    # Check for contamination
    contaminated=false
    for j in {1..10}; do
        if [ $i -ne $j ]; then
            leak=$(echo "$subjects" | jq -r ".[] | select(.name | contains(\"testing${j}\")) | .name")
            if [ ! -z "$leak" ]; then
                fail "CRITICAL: testing${i} sees testing${j} data!"
                contaminated=true
                break
            fi
        fi
    done
    
    if ! $contaminated && [ "$count" == "5" ]; then
        pass "testing${i}: Perfect isolation (5 subjects)"
    elif ! $contaminated; then
        fail "testing${i}: Isolated but wrong count (${count})"
    fi
done

section "STEP 6: ADD 3 MORE SUBJECTS EACH"

for i in {1..10}; do
    token=$(get_token $i)
    userid=$(get_userid $i)
    
    if [ -z "$token" ]; then
        fail "testing${i}: No token"
        continue
    fi
    
    for j in {6..8}; do
        create_subject "$token" "$userid" "Extra ${j} for testing${i}" > /dev/null
        sleep 0.1
    done
    
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    
    if [ "$count" == "8" ]; then
        pass "testing${i}: Total 8 subjects"
    else
        fail "testing${i}: Expected 8, got ${count}"
    fi
done

section "STEP 7: DELETE 2 SUBJECTS BY ID"

for i in {1..10}; do
    token=$(get_token $i)
    
    if [ -z "$token" ]; then
        fail "testing${i}: No token"
        continue
    fi
    
    subjects=$(get_subjects "$token")
    id1=$(echo "$subjects" | jq -r '.[0].id')
    id2=$(echo "$subjects" | jq -r '.[1].id')
    
    delete_subject "$token" "$id1"
    sleep 0.2
    delete_subject "$token" "$id2"
    sleep 0.2
    
    subjects=$(get_subjects "$token")
    count=$(count_subjects "$subjects")
    still_there1=$(echo "$subjects" | jq -r ".[] | select(.id == \"$id1\") | .id")
    still_there2=$(echo "$subjects" | jq -r ".[] | select(.id == \"$id2\") | .id")
    
    if [ "$count" == "6" ] && [ -z "$still_there1" ] && [ -z "$still_there2" ]; then
        pass "testing${i}: Deleted 2, 6 remain"
    else
        fail "testing${i}: Deletion failed (count: ${count})"
    fi
done

section "STEP 8: FINAL VERIFICATION"

# Re-login testing1
get_user_data 1 > /dev/null
token=$(get_token 1)
subjects=$(get_subjects "$token")
count=$(count_subjects "$subjects")

# Check for any contamination
final_clean=true
for i in {2..10}; do
    leak=$(echo "$subjects" | jq -r ".[] | select(.name | contains(\"testing${i}\")) | .name")
    if [ ! -z "$leak" ]; then
        fail "FINAL: testing1 contaminated with testing${i}!"
        final_clean=false
    fi
done

if $final_clean && [ "$count" == "6" ]; then
    pass "FINAL: testing1 perfect isolation, 6 subjects"
elif $final_clean; then
    fail "FINAL: testing1 clean but expected 6, got ${count}"
fi

section "📊 FINAL RESULTS"
echo ""
echo -e "${CYAN}Total Tests:    ${NC}${TOTAL}"
echo -e "${GREEN}Passed:         ${NC}${PASSED}"
echo -e "${RED}Failed:         ${NC}${FAILED}"

if [ $TOTAL -gt 0 ]; then
    rate=$(echo "scale=1; $PASSED * 100 / $TOTAL" | bc)
    echo -e "${YELLOW}Success Rate:   ${NC}${rate}%"
fi

echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}   🎉 ALL TESTS PASSED - 100% SUCCESS! 🎉${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✓ Authentication: PERFECT${NC}"
    echo -e "${GREEN}✓ Data Isolation: PERFECT${NC}"
    echo -e "${GREEN}✓ CRUD Operations: PERFECT${NC}"
    echo -e "${GREEN}✓ Cross-User Security: PERFECT${NC}"
    echo ""
    exit 0
else
    echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
    echo -e "${YELLOW}   ⚠️  SOME TESTS FAILED${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
    exit 1
fi
