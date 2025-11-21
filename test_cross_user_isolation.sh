#!/bin/bash

# ============================================
# COMPREHENSIVE CROSS-USER DATA ISOLATION TEST
# ============================================
# This script tests that subjects added to one user
# DO NOT appear in another user's account
# ============================================

SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

USER1_EMAIL="testing1@gmail.com"
USER1_PASSWORD="testing1"

USER2_EMAIL="testing2@gmail.com"
USER2_PASSWORD="testing2"

echo "🧪 CROSS-USER DATA ISOLATION TEST"
echo "===================================="
echo ""
echo "This test verifies that:"
echo "  1. User 1 can create subjects"
echo "  2. User 2 cannot see User 1's subjects"
echo "  3. User 2 can create their own subjects"
echo "  4. User 1 cannot see User 2's subjects"
echo ""

# ============================================
# TEST 1: Login User 1 and Create a Subject
# ============================================
echo "📋 Test 1: User 1 Creates a Subject"
echo "------------------------------------"

USER1_TOKEN=$(curl -s -X POST \
  "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${USER1_EMAIL}\",\"password\":\"${USER1_PASSWORD}\"}")

USER1_ID=$(echo "$USER1_TOKEN" | jq -r '.user.id')
USER1_ACCESS=$(echo "$USER1_TOKEN" | jq -r '.access_token')

if [ "$USER1_ACCESS" = "null" ]; then
  echo "❌ User 1 login failed"
  exit 1
fi

echo "✅ User 1 logged in: $USER1_ID"

# Create a unique subject name with timestamp
SUBJECT1_NAME="User1 Test Subject $(date +%s)"

echo "📝 Creating subject: ${SUBJECT1_NAME}"

CREATE1_RESULT=$(curl -s -X POST \
  "${SUPABASE_URL}/rest/v1/subjects" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER1_ACCESS}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"user_id\": \"${USER1_ID}\",
    \"name\": \"${SUBJECT1_NAME}\",
    \"description\": \"Test subject for User 1 - should NOT appear in User 2's account\",
    \"color\": \"#FF0000\",
    \"is_active\": true,
    \"total_questions\": 0,
    \"correct_answers\": 0,
    \"difficulty_weight\": 0.5
  }")

if echo "$CREATE1_RESULT" | jq -e '.code' > /dev/null 2>&1; then
  echo "❌ Failed to create subject for User 1"
  echo "$CREATE1_RESULT" | jq
  exit 1
fi

SUBJECT1_ID=$(echo "$CREATE1_RESULT" | jq -r '.[0].id')
echo "✅ Subject created with ID: ${SUBJECT1_ID:0:8}..."
echo ""

# ============================================
# TEST 2: Verify User 1 Can See Their Subject
# ============================================
echo "📋 Test 2: Verify User 1 Can See Their Subject"
echo "------------------------------------------------"

USER1_SUBJECTS=$(curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/subjects?select=name,user_id&name=eq.${SUBJECT1_NAME}" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER1_ACCESS}")

USER1_COUNT=$(echo "$USER1_SUBJECTS" | jq 'length')

if [ "$USER1_COUNT" -eq 1 ]; then
  echo "✅ User 1 can see their subject"
  echo "   Subject: ${SUBJECT1_NAME}"
else
  echo "❌ User 1 cannot see their own subject!"
  exit 1
fi
echo ""

# ============================================
# TEST 3: Login User 2 and Check They DON'T See User 1's Subject
# ============================================
echo "📋 Test 3: Verify User 2 CANNOT See User 1's Subject"
echo "------------------------------------------------------"

USER2_TOKEN=$(curl -s -X POST \
  "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${USER2_EMAIL}\",\"password\":\"${USER2_PASSWORD}\"}")

USER2_ID=$(echo "$USER2_TOKEN" | jq -r '.user.id')
USER2_ACCESS=$(echo "$USER2_TOKEN" | jq -r '.access_token')

if [ "$USER2_ACCESS" = "null" ]; then
  echo "❌ User 2 login failed"
  exit 1
fi

echo "✅ User 2 logged in: $USER2_ID"

# Try to access User 1's subject
USER2_VIEW_USER1=$(curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/subjects?select=name,user_id&name=eq.${SUBJECT1_NAME}" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER2_ACCESS}")

USER2_VIEW_COUNT=$(echo "$USER2_VIEW_USER1" | jq 'length')

if [ "$USER2_VIEW_COUNT" -eq 0 ]; then
  echo "✅ CORRECT: User 2 cannot see User 1's subject"
else
  echo "❌ SECURITY BUG: User 2 can see User 1's subject!"
  echo "$USER2_VIEW_USER1" | jq
  exit 1
fi
echo ""

# ============================================
# TEST 4: User 2 Creates Their Own Subject
# ============================================
echo "📋 Test 4: User 2 Creates Their Own Subject"
echo "--------------------------------------------"

SUBJECT2_NAME="User2 Test Subject $(date +%s)"

echo "📝 Creating subject: ${SUBJECT2_NAME}"

CREATE2_RESULT=$(curl -s -X POST \
  "${SUPABASE_URL}/rest/v1/subjects" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER2_ACCESS}" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"user_id\": \"${USER2_ID}\",
    \"name\": \"${SUBJECT2_NAME}\",
    \"description\": \"Test subject for User 2 - should NOT appear in User 1's account\",
    \"color\": \"#00FF00\",
    \"is_active\": true,
    \"total_questions\": 0,
    \"correct_answers\": 0,
    \"difficulty_weight\": 0.5
  }")

if echo "$CREATE2_RESULT" | jq -e '.code' > /dev/null 2>&1; then
  echo "❌ Failed to create subject for User 2"
  echo "$CREATE2_RESULT" | jq
  exit 1
fi

SUBJECT2_ID=$(echo "$CREATE2_RESULT" | jq -r '.[0].id')
echo "✅ Subject created with ID: ${SUBJECT2_ID:0:8}..."
echo ""

# ============================================
# TEST 5: Verify User 1 CANNOT See User 2's Subject
# ============================================
echo "📋 Test 5: Verify User 1 CANNOT See User 2's Subject"
echo "------------------------------------------------------"

USER1_VIEW_USER2=$(curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/subjects?select=name,user_id&name=eq.${SUBJECT2_NAME}" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER1_ACCESS}")

USER1_VIEW_COUNT=$(echo "$USER1_VIEW_USER2" | jq 'length')

if [ "$USER1_VIEW_COUNT" -eq 0 ]; then
  echo "✅ CORRECT: User 1 cannot see User 2's subject"
else
  echo "❌ SECURITY BUG: User 1 can see User 2's subject!"
  echo "$USER1_VIEW_USER2" | jq
  exit 1
fi
echo ""

# ============================================
# TEST 6: Verify Each User Only Sees Their Own Total Subjects
# ============================================
echo "📋 Test 6: Verify Subject Counts"
echo "----------------------------------"

USER1_ALL=$(curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/subjects?select=name" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER1_ACCESS}")

USER2_ALL=$(curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/subjects?select=name" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER2_ACCESS}")

USER1_TOTAL=$(echo "$USER1_ALL" | jq 'length')
USER2_TOTAL=$(echo "$USER2_ALL" | jq 'length')

echo "📊 User 1 total subjects: ${USER1_TOTAL}"
echo "📊 User 2 total subjects: ${USER2_TOTAL}"

# Verify neither list contains the other's test subject
USER1_HAS_USER2_SUBJECT=$(echo "$USER1_ALL" | jq -e --arg name "$SUBJECT2_NAME" '.[] | select(.name == $name)' && echo "yes" || echo "no")
USER2_HAS_USER1_SUBJECT=$(echo "$USER2_ALL" | jq -e --arg name "$SUBJECT1_NAME" '.[] | select(.name == $name)' && echo "yes" || echo "no")

if [ "$USER1_HAS_USER2_SUBJECT" = "no" ] && [ "$USER2_HAS_USER1_SUBJECT" = "no" ]; then
  echo "✅ CORRECT: No cross-contamination detected"
else
  echo "❌ SECURITY BUG: Cross-contamination detected!"
  exit 1
fi
echo ""

# ============================================
# CLEANUP: Delete Test Subjects
# ============================================
echo "📋 Cleanup: Deleting Test Subjects"
echo "-----------------------------------"

curl -s -X DELETE \
  "${SUPABASE_URL}/rest/v1/subjects?id=eq.${SUBJECT1_ID}" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER1_ACCESS}" > /dev/null

curl -s -X DELETE \
  "${SUPABASE_URL}/rest/v1/subjects?id=eq.${SUBJECT2_ID}" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER2_ACCESS}" > /dev/null

echo "✅ Test subjects deleted"
echo ""

# ============================================
# FINAL SUMMARY
# ============================================
echo "===================================="
echo "🎉 ALL TESTS PASSED!"
echo "===================================="
echo ""
echo "✅ User 1 created subject successfully"
echo "✅ User 1 can see their own subjects"
echo "✅ User 2 cannot see User 1's subjects"
echo "✅ User 2 created subject successfully"
echo "✅ User 1 cannot see User 2's subjects"
echo "✅ No cross-user data contamination"
echo ""
echo "Status: SECURE ✅"
echo "Cross-user data isolation working correctly!"
