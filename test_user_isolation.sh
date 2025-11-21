#!/bin/bash

# ============================================
# USER DATA ISOLATION TEST SCRIPT
# ============================================
# This script verifies that users can only access their own data
# and that RLS policies are working correctly
# ============================================

SUPABASE_URL="https://dsknaaziujrfavhaschj.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs"

USER1_EMAIL="testing1@gmail.com"
USER1_PASSWORD="testing1"

USER2_EMAIL="testing2@gmail.com"
USER2_PASSWORD="testing2"

echo "🔒 USER DATA ISOLATION TEST"
echo "================================"
echo ""

# Test 1: Login User 1
echo "📋 Test 1: Login User 1"
echo "------------------------"
USER1_RESPONSE=$(curl -s -X POST \
  "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${USER1_EMAIL}\",\"password\":\"${USER1_PASSWORD}\"}")

USER1_TOKEN=$(echo "$USER1_RESPONSE" | jq -r '.access_token')
USER1_ID=$(echo "$USER1_RESPONSE" | jq -r '.user.id')

if [ "$USER1_TOKEN" != "null" ]; then
  echo "✅ User 1 logged in successfully"
  echo "   Email: ${USER1_EMAIL}"
  echo "   User ID: ${USER1_ID}"
else
  echo "❌ User 1 login failed"
  exit 1
fi
echo ""

# Test 2: Get User 1's subjects
echo "📋 Test 2: Get User 1's Subjects"
echo "------------------------"
USER1_SUBJECTS=$(curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/subjects?select=name,user_id" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER1_TOKEN}")

USER1_COUNT=$(echo "$USER1_SUBJECTS" | jq 'length')
echo "✅ User 1 has ${USER1_COUNT} subjects:"
echo "$USER1_SUBJECTS" | jq -r '.[] | "   - \(.name) (user_id: \(.user_id))"'

# Verify all subjects belong to User 1
USER1_SUBJECTS_VERIFIED=$(echo "$USER1_SUBJECTS" | jq -r --arg uid "$USER1_ID" 'all(.user_id == $uid)')
if [ "$USER1_SUBJECTS_VERIFIED" = "true" ]; then
  echo "✅ All subjects belong to User 1"
else
  echo "❌ SECURITY ISSUE: Found subjects not belonging to User 1!"
  exit 1
fi
echo ""

# Test 3: Login User 2
echo "📋 Test 3: Login User 2"
echo "------------------------"
USER2_RESPONSE=$(curl -s -X POST \
  "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: ${ANON_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${USER2_EMAIL}\",\"password\":\"${USER2_PASSWORD}\"}")

USER2_TOKEN=$(echo "$USER2_RESPONSE" | jq -r '.access_token')
USER2_ID=$(echo "$USER2_RESPONSE" | jq -r '.user.id')

if [ "$USER2_TOKEN" != "null" ]; then
  echo "✅ User 2 logged in successfully"
  echo "   Email: ${USER2_EMAIL}"
  echo "   User ID: ${USER2_ID}"
else
  echo "❌ User 2 login failed"
  exit 1
fi
echo ""

# Test 4: Get User 2's subjects
echo "📋 Test 4: Get User 2's Subjects"
echo "------------------------"
USER2_SUBJECTS=$(curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/subjects?select=name,user_id" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER2_TOKEN}")

USER2_COUNT=$(echo "$USER2_SUBJECTS" | jq 'length')
echo "✅ User 2 has ${USER2_COUNT} subjects:"
echo "$USER2_SUBJECTS" | jq -r '.[] | "   - \(.name) (user_id: \(.user_id))"'

# Verify all subjects belong to User 2
USER2_SUBJECTS_VERIFIED=$(echo "$USER2_SUBJECTS" | jq -r --arg uid "$USER2_ID" 'all(.user_id == $uid)')
if [ "$USER2_SUBJECTS_VERIFIED" = "true" ]; then
  echo "✅ All subjects belong to User 2"
else
  echo "❌ SECURITY ISSUE: Found subjects not belonging to User 2!"
  exit 1
fi
echo ""

# Test 5: Verify no overlap
echo "📋 Test 5: Verify No Cross-User Data"
echo "------------------------"
if [ "$USER1_ID" = "$USER2_ID" ]; then
  echo "❌ ERROR: Users have the same ID!"
  exit 1
fi

USER1_SUBJECT_NAMES=$(echo "$USER1_SUBJECTS" | jq -r '.[].name' | sort)
USER2_SUBJECT_NAMES=$(echo "$USER2_SUBJECTS" | jq -r '.[].name' | sort)

OVERLAP=$(comm -12 <(echo "$USER1_SUBJECT_NAMES") <(echo "$USER2_SUBJECT_NAMES") | wc -l)

if [ "$OVERLAP" -eq 0 ]; then
  echo "✅ No subject overlap between users"
else
  echo "⚠️  Found ${OVERLAP} subjects with same names (OK if intentional)"
fi
echo ""

# Test 6: Unauthenticated access
echo "📋 Test 6: Unauthenticated Access"
echo "------------------------"
UNAUTH_SUBJECTS=$(curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/subjects?select=name" \
  -H "apikey: ${ANON_KEY}")

UNAUTH_COUNT=$(echo "$UNAUTH_SUBJECTS" | jq 'length')

if [ "$UNAUTH_COUNT" -eq 0 ]; then
  echo "✅ Unauthenticated requests return no data"
else
  echo "❌ SECURITY ISSUE: Unauthenticated access returned ${UNAUTH_COUNT} subjects!"
  exit 1
fi
echo ""

# Test 7: Try to access User 1's data with User 2's token
echo "📋 Test 7: Cross-User Access Attempt"
echo "------------------------"
CROSS_ACCESS=$(curl -s -X GET \
  "${SUPABASE_URL}/rest/v1/subjects?select=name&user_id=eq.${USER1_ID}" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${USER2_TOKEN}")

CROSS_ACCESS_COUNT=$(echo "$CROSS_ACCESS" | jq 'length')

if [ "$CROSS_ACCESS_COUNT" -eq 0 ]; then
  echo "✅ User 2 cannot access User 1's data"
else
  echo "❌ SECURITY ISSUE: User 2 accessed ${CROSS_ACCESS_COUNT} of User 1's subjects!"
  exit 1
fi
echo ""

# Final Summary
echo "================================"
echo "🎉 ALL SECURITY TESTS PASSED!"
echo "================================"
echo ""
echo "Summary:"
echo "  ✅ User 1 can access ${USER1_COUNT} subjects"
echo "  ✅ User 2 can access ${USER2_COUNT} subjects"
echo "  ✅ All subjects properly filtered by user_id"
echo "  ✅ No cross-user data access possible"
echo "  ✅ Unauthenticated requests blocked"
echo "  ✅ RLS policies working correctly"
echo ""
echo "Status: SECURE ✅"
