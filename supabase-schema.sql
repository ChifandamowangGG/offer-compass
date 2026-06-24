-- ================================
-- OfferCompass 完整建表 + 数据
-- ================================

-- 1. Profiles
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Jobs
CREATE TABLE IF NOT EXISTS jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company TEXT NOT NULL,
  title TEXT NOT NULL,
  city TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('frontend','backend','fullstack','test','ops','product','design','other')),
  education TEXT DEFAULT '不限',
  friendly_label BOOLEAN DEFAULT false,
  salary TEXT,
  deadline DATE,
  link TEXT,
  source TEXT DEFAULT '用户投稿',
  notes TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  submitted_by UUID REFERENCES auth.users(id),
  rejected_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Bookmarks
CREATE TABLE IF NOT EXISTS bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  application_status TEXT DEFAULT 'wish' CHECK (application_status IN ('wish','applied','interviewing','offered','closed')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, job_id)
);

-- 4. Auto profile
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$ BEGIN
  INSERT INTO profiles (id, username, role)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'username', NEW.email), 'user');
  RETURN NEW;
END; $$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- 5. Updated at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$ BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS jobs_updated_at ON jobs;
CREATE TRIGGER jobs_updated_at
  BEFORE UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 6. Enable RLS
ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS bookmarks ENABLE ROW LEVEL SECURITY;

-- 7. Profiles policies
DROP POLICY IF EXISTS "view own" ON profiles;
DROP POLICY IF EXISTS "admin view all" ON profiles;
DROP POLICY IF EXISTS "update own" ON profiles;
CREATE POLICY "view own" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "admin view all" ON profiles FOR SELECT USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
CREATE POLICY "update own" ON profiles FOR UPDATE USING (auth.uid() = id);

-- 8. Jobs policies
DROP POLICY IF EXISTS "view approved" ON jobs;
DROP POLICY IF EXISTS "admin view all jobs" ON jobs;
DROP POLICY IF EXISTS "users insert" ON jobs;
DROP POLICY IF EXISTS "admin update" ON jobs;
DROP POLICY IF EXISTS "admin delete" ON jobs;
CREATE POLICY "view approved" ON jobs FOR SELECT USING (status = 'approved');
CREATE POLICY "admin view all jobs" ON jobs FOR SELECT USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
CREATE POLICY "users insert" ON jobs FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "admin update" ON jobs FOR UPDATE USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');
CREATE POLICY "admin delete" ON jobs FOR DELETE USING ((SELECT role FROM profiles WHERE id = auth.uid()) = 'admin');

-- 9. Bookmarks policies
DROP POLICY IF EXISTS "view own bm" ON bookmarks;
DROP POLICY IF EXISTS "insert own bm" ON bookmarks;
DROP POLICY IF EXISTS "update own bm" ON bookmarks;
DROP POLICY IF EXISTS "delete own bm" ON bookmarks;
CREATE POLICY "view own bm" ON bookmarks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "insert own bm" ON bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "update own bm" ON bookmarks FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "delete own bm" ON bookmarks FOR DELETE USING (auth.uid() = user_id);

-- 10. Seed data
INSERT INTO jobs (company, title, city, type, education, friendly_label, salary, deadline, link, source, status, notes) VALUES
('武汉众创科技', '前端开发实习生', '武汉', 'frontend', '大专及以上', true, '3-5K', '2026-08-15', 'https://www.zhipin.com', '管理员录入', 'approved', 'Vue/React 基础即可，有导师带'),
('合肥智联网络', 'Java 后端实习生', '合肥', 'backend', '大专及以上', true, '3-4K', '2026-07-30', 'https://www.zhipin.com', '管理员录入', 'approved', 'Spring Boot 基础，提供转正'),
('南京星云科技', '测试实习生', '南京', 'test', '大专及以上', true, '3-5K', '2026-08-01', 'https://www.zhipin.com', '管理员录入', 'approved', '手工+自动化，可培养'),
('深圳华云科技', '运维实习生', '深圳', 'ops', '大专及以上', true, '4-6K', '2026-08-31', 'https://www.zhipin.com', '管理员录入', 'approved', 'Linux+网络基础即可'),
('成都极客科技', '全栈开发实习生', '成都', 'fullstack', '大专及以上', true, '3-6K', '2026-08-15', 'https://www.zhipin.com', '管理员录入', 'approved', 'Vue+Node.js 基础，全栈培养'),
('武汉斗鱼网络', '前端开发实习生', '武汉', 'frontend', '大专及以上', true, '4-6K', '2026-08-01', 'https://www.zhipin.com', '管理员录入', 'approved', '熟悉 Vue3 优先，有餐补'),
('合肥科大国创', 'Java 开发实习生', '合肥', 'backend', '大专及以上', true, '3-5K', '2026-08-20', 'https://www.zhipin.com', '管理员录入', 'approved', '有正式员工带，可开实习证明'),
('南京苏宁易购', '前端开发实习生', '南京', 'frontend', '大专及以上', true, '4-6K', '2026-07-31', 'https://www.shixiseng.com', '管理员录入', 'approved', '大厂履历，要求 Vue 基础'),
('武汉金山办公', '测试开发实习生', '武汉', 'test', '大专及以上', true, '4-6K', '2026-08-30', 'https://www.zhipin.com', '管理员录入', 'approved', '自动化测试方向，有 Python 基础'),
('合肥华米科技', '前端开发实习生', '合肥', 'frontend', '大专及以上', true, '3-5K', '2026-09-01', 'https://www.zhipin.com', '管理员录入', 'approved', '可远程实习，弹性时间'),
('南京中兴软创', '后端开发实习生', '南京', 'backend', '大专及以上', true, '4-6K', '2026-08-15', 'https://www.zhipin.com', '管理员录入', 'approved', 'Java/Go 均可，一对一导师'),
('上海哔哩哔哩', '前端开发实习生', '上海', 'frontend', '大专及以上', true, '5-7K', '2026-08-05', 'https://www.bilibili.com', '管理员录入', 'approved', 'B站平台，Vue 技术栈'),
('武汉明源云', '前端开发实习生', '武汉', 'frontend', '大专及以上', true, '3-5K', '2026-09-10', 'https://www.zhipin.com', '管理员录入', 'approved', '表现优秀可转正，免费三餐'),
('合肥美的集团', 'IT 运维实习生', '合肥', 'ops', '大专及以上', true, '3-4K', '2026-08-25', 'https://www.zhipin.com', '管理员录入', 'approved', '计算机相关专业即可'),
('南京途牛科技', '前端开发实习生', '南京', 'frontend', '大专及以上', true, '3-5K', '2026-08-20', 'https://www.zhipin.com', '管理员录入', 'approved', '旅游行业，氛围好'),
('成都字节跳动', '产品运营实习生', '成都', 'product', '大专及以上', true, '3-5K', '2026-08-10', 'https://www.shixiseng.com', '管理员录入', 'approved', '内容运营方向'),
('武汉小红书', '后端开发实习生', '武汉', 'backend', '大专及以上', true, '4-6K', '2026-08-15', 'https://www.zhipin.com', '管理员录入', 'approved', 'Go 语言方向'),
('杭州趣链科技', '前端开发实习生', '杭州', 'frontend', '大专及以上', true, '4-6K', '2026-08-25', 'https://www.shixiseng.com', '管理员录入', 'approved', '区块链+前端'),
('合肥智联网络', '前端开发实习生', '合肥', 'frontend', '大专及以上', true, '3-4K', '2026-08-10', 'https://www.zhipin.com', '管理员录入', 'approved', 'Vue 基础，有项目奖金'),
('武汉众创科技', '后端开发实习生', '武汉', 'backend', '大专及以上', true, '3-5K', '2026-08-20', 'https://www.zhipin.com', '管理员录入', 'approved', 'Java 基础即可')
ON CONFLICT DO NOTHING;
