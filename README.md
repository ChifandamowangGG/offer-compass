# OfferCompass · 实习校招信息聚合平台

专为大专/二本同学设计的实习岗位信息面板 — 过滤掉学历门槛，标注「大专友好」，让找实习更高效。

## 功能
- 实习岗位浏览：按城市、类型、学历要求筛选
- 大专友好标签：一眼识别接受大专的岗位
- 收藏 + 投递追踪：收藏岗位，记录投递进度
- 用户投稿：每个人都可以分享自己知道的实习机会
- 管理员审核：投稿的岗位需审核后才能展示
- 城市天气：筛选城市时显示当地天气(wttr.in API)
- 登录系统：普通用户/管理员两种角色

## 技术栈
| 前端 | 后端 | 部署 |
|------|------|------|
| Vue 3 (Composition API) | Supabase (PostgreSQL + Auth + RLS) | GitHub Pages |
| Vite | Supabase JavaScript SDK | - |
| CSS (原生变量系统) | Row Level Security | - |
| 自适应移动端 | - | - |

## 三步部署

### 第一步：配置 Supabase
1. 打开 supabase.com 注册免费账号
2. 创建一个新项目(Free 套餐，区域选 Singapore 或 Tokyo)
3. 进入 Project Settings → API，复制 Project URL 和 anon public key
4. 在项目根目录复制 .env.example 为 .env，填入上面的值

### 第二步：初始化数据库
1. 在 Supabase Dashboard 进入 SQL Editor
2. 打开 supabase-schema.sql 全选复制，粘贴运行
3. 等待执行完成(创建3张表 + 20条初始数据)

### 第三步：设置管理员
1. 在 Supabase Dashboard 进入 Authentication → Users
2. 注册一个账号(或在项目启动后注册)
3. 找到你的用户 UUID
4. 在 SQL Editor 执行: UPDATE profiles SET role = admin WHERE id = 你的UUID;

## 本地开发
npm install
npm run dev    # 启动开发服务器
npm run build  # 构建生产版本
npm run deploy # 部署到 GitHub Pages

## 项目结构
src/main.js - 入口
src/App.vue - 主应用
src/style.css - 全局样式
src/config.js - 环境配置
src/supabase.js - Supabase 客户端 + API
src/components/NavBar.vue - 导航栏
src/components/LoginModal.vue - 登录/注册
src/components/JobStats.vue - 统计
src/components/JobFilters.vue - 筛选
src/components/JobCard.vue - 岗位卡片
src/components/WeatherWidget.vue - 天气
src/components/JobSubmission.vue - 投稿