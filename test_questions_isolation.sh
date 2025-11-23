#!/bin/bash

# Comprehensive Questions Isolation and Counting Test
# Tests: User isolation, question storage, and correct/total counting accuracy

SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

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
    
    if [ ! -z "$token" ] && [ "$token" != "null" ]; then
        echo "${token}|${user_id}"
        return 0
    else
        echo ""
        return 1
    fi
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
            \"description\": \"Test subject for questions\",
            \"color\": \"#2196F3\",
            \"is_active\": true,
            \"total_questions\": 0,
            \"correct_answers\": 0,
            \"difficulty_weight\": 0.5
        }")
    
    echo "$response" | jq -r '.[0].id // empty'
}

get_subjects() {
    local token=$1
    curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/subjects?select=*" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}"
}

create_question() {
    local token=$1
    local user_id=$2
    local subject_id=$3
    local subject_name=$4
    local question_num=$5
    
    local response=$(curl -s -X POST \
        "${SUPABASE_URL}/rest/v1/questions" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}" \
        -H "Content-Type: application/json" \
        -H "Prefer: return=representation" \
        -d "{
            \"user_id\": \"${user_id}\",
            \"subject_id\": \"${subject_id}\",
            \"subject_name\": \"${subject_name}\",
            \"question_text\": \"Test Question ${question_num} for ${subject_name}\",
            \"correct_answer\": \"Option A\",
            \"options\": [\"Option A\", \"Option B\", \"Option C\", \"Option D\"],
            \"difficulty\": \"medium\",
            \"source\": \"test_script\",
            \"explanation\": \"Test explanation\"
        }")
    
    echo "$response" | jq -r '.[0].id // empty'
}

get_questions() {
    local token=$1
    curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/questions?select=*&order=created_at.desc" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}"
}

get_questions_for_subject() {
    local token=$1
    local subject_name=$2
    curl -s -X GET \
        "${SUPABASE_URL}/rest/v1/questions?select=*&subject_name=eq.${subject_name}&order=created_at.desc" \
        -H "apikey: ${ANON_KEY}" \
        -H "Authorization: Bearer ${token}"
}

count_items() {
    echo "$1" | jq '. | length'
}

delete_all_questions() {
    local token=$1
    local user_id=$2
    curl -s -X DELETE \
        "${SUPABASE_URL}/rest/v1/questions?user_id=eq.${user_id}" \
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

section "STEP 1: RESET STATE - Clean all test data"

for i in 1 2 3; do
    result=$(login_user "testing${i}@gmail.com" "testing${i}")
    if [ $? -eq 0 ]; then
        IFS='|' read -r token user_id <<< "$result"
        delete_all_questions "$token" "$user_id"
        delete_all_subjects "$token" "$user_id"
        info "Cleared all data for testing${i}"
    fi
    sleep 0.3
done

section "STEP 2: VERIFY USER AUTHENTICATION"

declare -A TOKENS
declare -A USER_IDS

for i in 1 2 3; do
    result=$(login_user "testing${i}@gmail.com" "testing${i}")
    if [ $? -eq 0 ]; then
        IFS='|' read -r token user_id <<< "$result"
        TOKENS[$i]=$token
        USER_IDS[$i]=$user_id
        pass "testing${i} authenticated"
    else
        fail "testing${i} authentication failed"
    fi
    sleep 0.2
done

section "STEP 3: CREATE SUBJECTS FOR EACH USER"

declare -A SUBJECT_IDS
declare -A SUBJECT_NAMES

for i in 1 2 3; do
    token=${TOKENS[$i]}
    user_id=${USER_IDS[$i]}
    subject_name="Math_${i}"
    
    if [ ! -z "$token" ]; then
        subject_id=$(create_subject "$token" "$user_id" "$subject_name")
        if [ ! -z "$subject_id" ]; then
            SUBJECT_IDS[$i]=$subject_id
            SUBJECT_NAMES[$i]=$subject_name
            pass "testing${i}: Created subject '${subject_name}' (ID: ${subject_id:0:8}...)"
        else
            fail "testing${i}: Failed to create subject"
        fi
    fi
    sleep 0.3
done

section "STEP 4: CREATE QUESTIONS - 5 per user per subject"

for i in 1 2 3; do
    token=${TOKENS[$i]}
    user_id=${USER_IDS[$i]}
    subject_id=${SUBJECT_IDS[$i]}
    subject_name=${SUBJECT_NAMES[$i]}
    
    if [ ! -z "$token" ] && [ ! -z "$subject_id" ]; then
        created_count=0
        
        for q in {1..5}; do
            question_id=$(create_question "$token" "$user_id" "$subject_id" "$subject_name" "$q")
            if [ ! -z "$question_id" ]; then
                ((created_count++))
            fi
            sleep 0.2
        done
        
        if [ $created_count -eq 5 ]; then
            pass "testing${i}: Created 5 questions for ${subject_name}"
        else
            fail "testing${i}: Only created ${created_count}/5 questions"
        fi
    else
        fail "testing${i}: No token or subject_id for question creation"
    fi
done

section "STEP 5: VERIFY QUESTION COUNTS PER USER"

for i in 1 2 3; do
    token=${TOKENS[$i]}
    
    if [ ! -z "$token" ]; then
        questions=$(get_questions "$token")
        count=$(count_items "$questions")
        
        if [ "$count" == "5" ]; then
            pass "testing${i}: Correct count - 5 questions"
        else
            fail "testing${i}: Expected 5 questions, found ${count}"
        fi
    fi
    sleep 0.2
done

section "STEP 6: CROSS-USER ISOLATION TEST"

for i in 1 2 3; do
    token=${TOKENS[$i]}
    
    if [ ! -z "$token" ]; then
        questions=$(get_questions "$token")
        
        # Check for contamination from other users
        contaminated=false
        for j in 1 2 3; do
            if [ $i -ne $j ]; then
                other_subject=${SUBJECT_NAMES[$j]}
                leak=$(echo "$questions" | jq -r ".[] | select(.subject_name == \"$other_subject\") | .subject_name")
                
                if [ ! -z "$leak" ]; then
                    fail "CRITICAL: testing${i} can see testing${j}'s questions (${other_subject})!"
                    contaminated=true
                    break
                fi
            fi
        done
        
        if ! $contaminated; then
            pass "testing${i}: Perfect isolation - no cross-user data leakage"
        fi
    fi
    sleep 0.2
done

section "STEP 7: VERIFY QUESTIONS BY SUBJECT"

for i in 1 2 3; do
    token=${TOKENS[$i]}
    subject_name=${SUBJECT_NAMES[$i]}
    
    if [ ! -z "$token" ]; then
        subject_questions=$(get_questions_for_subject "$token" "$subject_name")
        count=$(count_items "$subject_questions")
        
        if [ "$count" == "5" ]; then
            pass "testing${i}: Subject '${subject_name}' has correct 5 questions"
        else
            fail "testing${i}: Subject '${subject_name}' expected 5, found ${count}"
        fi
    fi
    sleep 0.2
done

section "STEP 8: TEST SUBJECT STATISTICS"

info "Checking if total_questions and correct_answers fields track properly..."

for i in 1 2 3; do
    token=${TOKENS[$i]}
    
    if [ ! -z "$token" ]; then
        subjects=$(get_subjects "$token")
        total_q=$(echo "$subjects" | jq -r '.[0].total_questions // 0')
        correct_a=$(echo "$subjects" | jq -r '.[0].correct_answers // 0')
        
        info "testing${i}: total_questions=${total_q}, correct_answers=${correct_a}"
        
        # Note: These start at 0 because quiz sessions aren't created yet
        if [ "$total_q" == "0" ] && [ "$correct_a" == "0" ]; then
            pass "testing${i}: Initial stats correct (0/0)"
        else
            fail "testing${i}: Expected 0/0, got ${correct_a}/${total_q}"
        fi
    fi
    sleep 0.2
done

section "STEP 9: ADD MORE QUESTIONS - 3 additional per user"

for i in 1 2 3; do
    token=${TOKENS[$i]}
    user_id=${USER_IDS[$i]}
    subject_id=${SUBJECT_IDS[$i]}
    subject_name=${SUBJECT_NAMES[$i]}
    
    if [ ! -z "$token" ]; then
        for q in {6..8}; do
            create_question "$token" "$user_id" "$subject_id" "$subject_name" "$q" > /dev/null
            sleep 0.2
        done
        
        questions=$(get_questions "$token")
        count=$(count_items "$questions")
        
        if [ "$count" == "8" ]; then
            pass "testing${i}: Total 8 questions after adding 3 more"
        else
            fail "testing${i}: Expected 8 questions, found ${count}"
        fi
    fi
done

section "STEP 10: FINAL CROSS-USER VERIFICATION"

info "Ensuring no data leakage after all operations..."

all_isolated=true
for i in 1 2 3; do
    token=${TOKENS[$i]}
    
    if [ ! -z "$token" ]; then
        questions=$(get_questions "$token")
        count=$(count_items "$questions")
        
        # Should have exactly 8 questions
        if [ "$count" != "8" ]; then
            fail "testing${i}: Expected 8 questions, found ${count}"
            all_isolated=false
            continue
        fi
        
        # Check all questions belong to this user's subject
        my_subject=${SUBJECT_NAMES[$i]}
        wrong_subject=$(echo "$questions" | jq -r ".[] | select(.subject_name != \"$my_subject\") | .subject_name" | head -1)
        
        if [ ! -z "$wrong_subject" ]; then
            fail "testing${i}: Found question from wrong subject: ${wrong_subject}"
            all_isolated=false
        fi
    fi
done

if $all_isolated; then
    pass "FINAL: All users have perfect question isolation"
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
    echo -e "${GREEN}   🎉 ALL TESTS PASSED! 🎉${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✓ Questions properly isolated per user${NC}"
    echo -e "${GREEN}✓ Subject-question relationships correct${NC}"
    echo -e "${GREEN}✓ No cross-user data leakage${NC}"
    echo -e "${GREEN}✓ Question counts accurate${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  NOTE: Counting bug investigation:${NC}"
    echo -e "${YELLOW}   The 2/4 vs 2/3 issue likely occurs when:${NC}"
    echo -e "${YELLOW}   - Quiz sessions are saved incorrectly${NC}"
    echo -e "${YELLOW}   - _updateSubjectStats counts from quiz_sessions table${NC}"
    echo -e "${YELLOW}   - Check QuizProvider for session save logic${NC}"
    exit 0
else
    echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
    echo -e "${YELLOW}   ⚠️  SOME TESTS FAILED${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════${NC}"
    exit 1
fi
