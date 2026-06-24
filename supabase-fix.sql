-- 终极修复：用独立管理员表，不启用 RLS

-- 1. 创建管理员表（不启用 RLS）
CREATE TABLE IF NOT EXISTS admin_users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
);
ALTER TABLE admin_users DISABLE ROW LEVEL SECURITY;

-- 2. 重建 is_admin 函数（查询无 RLS 的 admin_users 表）
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM admin_users WHERE user_id = auth.uid());
$$ LANGUAGE sql;

-- 3. 删掉旧的 profiles 策略中可能导致递归的
DROP POLICY IF EXISTS "admin view all" ON profiles;
DROP POLICY IF EXISTS "view own" ON profiles;
DROP POLICY IF EXISTS "update own" ON profiles;
CREATE POLICY "view own" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "update own" ON profiles FOR UPDATE USING (auth.uid() = id);

-- 4. 重建 jobs 策略
DROP POLICY IF EXISTS "view approved" ON jobs;
DROP POLICY IF EXISTS "admin view all jobs" ON jobs;
DROP POLICY IF EXISTS "users insert" ON jobs;
DROP POLICY IF EXISTS "admin update" ON jobs;
DROP POLICY IF EXISTS "admin delete" ON jobs;
CREATE POLICY "view approved" ON jobs FOR SELECT USING (status = 'approved');
CREATE POLICY "admin view all jobs" ON jobs FOR SELECT USING (is_admin());
CREATE POLICY "users insert" ON jobs FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "admin update" ON jobs FOR UPDATE USING (is_admin());
CREATE POLICY "admin delete" ON jobs FOR DELETE USING (is_admin());

-- 5. 重建 bookmarks 策略
DROP POLICY IF EXISTS "view own bm" ON bookmarks;
DROP POLICY IF EXISTS "insert own bm" ON bookmarks;
DROP POLICY IF EXISTS "update own bm" ON bookmarks;
DROP POLICY IF EXISTS "delete own bm" ON bookmarks;
CREATE POLICY "view own bm" ON bookmarks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "insert own bm" ON bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update own bm" ON bookmarks FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "delete own bm" ON bookmarks FOR DELETE USING (auth.uid() = user_id);
