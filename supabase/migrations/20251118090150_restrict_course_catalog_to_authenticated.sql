-- ============================================
-- RESTRICT COURSE CATALOG TO AUTHENTICATED USERS
-- ============================================

-- Drop the public policy
DROP POLICY IF EXISTS "Anyone can view active courses" ON course_catalog;

-- Create new policy: Only authenticated users can view courses
CREATE POLICY "Authenticated users can view courses" ON course_catalog
  FOR SELECT 
  USING (auth.role() = 'authenticated' AND is_active = true);

-- Verify the policy
SELECT 
  policyname,
  cmd as command,
  qual as using_expression
FROM pg_policies
WHERE tablename = 'course_catalog'
ORDER BY policyname;

-- ✅ Course catalog now requires authentication
