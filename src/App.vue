<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { initSupabase, getSupabase, fetchApprovedJobs, signOut, getCurrentUser, onAuthChange, fetchUserBookmarks, getUserRole, getUserProfile } from './supabase.js'
import { SUPABASE_URL, SUPABASE_ANON_KEY } from './config.js'
import NavBar from './components/NavBar.vue'
import LoginModal from './components/LoginModal.vue'
import JobCard from './components/JobCard.vue'
import JobFilters from './components/JobFilters.vue'
import WeatherWidget from './components/WeatherWidget.vue'
import JobStats from './components/JobStats.vue'
import JobSubmission from './components/JobSubmission.vue'
import AdminPanel from './components/AdminPanel.vue'

// ---- Init ----
const ready = ref(false)
const initError = ref('')

try {
  initSupabase(SUPABASE_URL, SUPABASE_ANON_KEY)
  ready.value = true
} catch (e) {
  initError.value = 'Supabase 未配置，请在 .env 中设置 VITE_SUPABASE_URL 和 VITE_SUPABASE_ANON_KEY'
}

// ---- Auth ----
const user = ref(null)
const role = ref('user')
const showLogin = ref(false)
const toasts = ref([])

function toast(msg) {
  toasts.value.push(msg)
  setTimeout(() => toasts.value.shift(), 3000)
}

onMounted(async () => {
  if (!ready.value) return
  const u = await getCurrentUser()
  if (u) {
    user.value = u
    const r = await getUserRole(u.id)
    role.value = r
    await loadBookmarks()
  }
  loadJobs()

  onAuthChange(async (event, session) => {
    if (session?.user) {
      user.value = session.user
      const r = await getUserRole(session.user.id)
      role.value = r
      await loadBookmarks()
      loadJobs()
    } else if (event === 'SIGNED_OUT') {
      user.value = null
      role.value = 'user'
      bookmarks.value = []
    }
  })
})

async function onLogin(userData) {
  showLogin.value = false
  user.value = userData
  const r = await getUserRole(userData.id)
  role.value = r
  await loadBookmarks()
  toast('登录成功 🎉')
}

async function onLogout() {
  await signOut()
  currentView.value = 'browse'
  toast('已退出登录')
}

// ---- Views ----
const currentView = ref('browse')
const isAdmin = computed(() => role.value === 'admin')

// ---- Jobs ----
const jobs = reactive([])
const loading = ref(true)

const filters = reactive({
  city: 'all', type: 'all', education: 'all', search: '', friendlyOnly: false
})

const cities = ['武汉','合肥','南京','上海','杭州','北京','深圳','成都','广州','长沙']
const jobTypes = [
  { value: 'frontend', label: '前端开发' },
  { value: 'backend', label: '后端开发' },
  { value: 'fullstack', label: '全栈开发' },
  { value: 'test', label: '测试' },
  { value: 'ops', label: '运维' },
  { value: 'product', label: '产品' },
  { value: 'design', label: '设计' }
]

async function loadJobs() {
  if (!ready.value) return
  loading.value = true
  const { data } = await fetchApprovedJobs(filters)
  jobs.length = 0
  if (data) jobs.push(...data)
  loading.value = false
}

const filteredJobs = computed(() => {
  let list = [...jobs]
  if (filters.friendlyOnly) list = list.filter(j => j.friendly_label)
  return list
})

const totalJobs = computed(() => filteredJobs.value.length)
const friendlyCount = computed(() => filteredJobs.value.filter(j => j.friendly_label).length)

watch(filters, () => { loadJobs() }, { deep: true })

// ---- Bookmarks ----
const bookmarks = ref([])
async function onJobUpdate() { await loadJobs(); await loadBookmarks(); }

async function loadBookmarks() {
  if (!user.value) { bookmarks.value = []; return }
  const { data } = await fetchUserBookmarks(user.value.id)
  bookmarks.value = data || []
}

// ---- Weather ----
const weatherCity = computed(() => {
  if (filters.city !== 'all') return filters.city
  return '武汉'
})

// ---- Initial ----

</script>

<template>
  <div v-if="initError" style="padding:40px;text-align:center;color:var(--danger)">
    <h2>⚠️ {{ initError }}</h2>
    <p style="margin-top:12px;color:var(--gray-500);font-size:14px">
      在项目根目录创建 <code>.env</code> 文件：<br>
      <code>VITE_SUPABASE_URL=你的Supabase项目URL</code><br>
      <code>VITE_SUPABASE_ANON_KEY=你的Supabase匿名Key</code>
    </p>
  </div>

  <template v-else>
    <NavBar
      :user="user"
      :currentView="currentView"
      :isAdmin="isAdmin"
      @viewChange="currentView = $event"
      @login="showLogin = true"
      @logout="onLogout"
    />

    <div class="app-container">
      <!-- Browse View -->
      <template v-if="currentView === 'browse'">
        <JobStats :total="totalJobs" :friendly="friendlyCount" />
        <JobFilters
          :filters="filters"
          :cities="cities"
          :types="jobTypes"
          @update:filters="Object.assign(filters, $event)"
        />
        <WeatherWidget :city="weatherCity" />
        <div v-if="loading" class="loading">加载中...</div>
        <div v-else-if="filteredJobs.length === 0" class="empty-state">
          <div class="icon">🔍</div>
          <p>没有找到匹配的岗位，试试调整筛选条件</p>
          <button v-if="user" class="btn btn-primary" style="margin-top:12px" @click="currentView='submit'">投稿一个新岗位</button>
        </div>
        <div v-else class="job-grid">
          <JobCard
            v-for="job in filteredJobs"
            :key="job.id"
            :job="job"
            :userId="user?.id"
            :bookmarks="bookmarks"
            :isAdmin="isAdmin"
            @update="onJobUpdate"
          />
        </div>
      </template>

      <!-- Submit View -->
      <template v-if="currentView === 'submit'">
        <JobSubmission
          v-if="user"
          @submitted="currentView = 'browse'; loadJobs()"
          @cancel="currentView = 'browse'"
        />
        <div v-else class="empty-state">
          <div class="icon">🔒</div>
          <p>请先登录后再投稿</p>
          <button class="btn btn-primary" style="margin-top:12px" @click="showLogin = true">去登录</button>
        </div>
      </template>

      <!-- Admin View -->
      <template v-if="currentView === 'admin'">
        <AdminPanel v-if="isAdmin" @update="loadJobs" />
        <div v-else class="empty-state">
          <div class="icon">🚫</div>
          <p>你没有管理员权限</p>
        </div>
      </template>
    </div>

    <!-- Login Modal -->
    <LoginModal v-if="showLogin" @close="showLogin = false" @success="onLogin" />

    <!-- Toast -->
    <div v-for="(msg, i) in toasts" :key="i" class="toast">{{ msg }}</div>
  </template>
</template>
