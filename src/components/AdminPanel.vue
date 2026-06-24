<script setup>
import { ref, computed, onMounted } from 'vue'
import { fetchPendingJobs, fetchAllJobs, approveJob, rejectJob, updateJob, deleteJob } from '../supabase.js'

const emit = defineEmits(['update'])
const tab = ref('pending')
const jobs = ref([])
const loading = ref(true)
const editing = ref(null)
const editForm = ref({})
const rejectReason = ref('')

const pendingJobs = computed(() => jobs.value.filter(j => j.status === 'pending'))
const approvedJobs = computed(() => jobs.value.filter(j => j.status === 'approved'))
const rejectedJobs = computed(() => jobs.value.filter(j => j.status === 'rejected'))

async function load() {
  loading.value = true
  const { data } = await fetchAllJobs()
  jobs.value = data || []
  loading.value = false
}

async function doApprove(id) {
  await approveJob(id)
  await load(); emit('update')
}

function startReject(id) {
  rejectReason.value = ''
  // use prompt for simplicity
  const reason = prompt('请输入拒绝原因（可选）：')
  doReject(id, reason || undefined)
}

async function doReject(id, reason) {
  await rejectJob(id, reason)
  await load(); emit('update')
}

function startEdit(job) {
  editing.value = job.id
  editForm.value = { ...job }
}

async function saveEdit() {
  const { id, profiles, created_at, updated_at, status, submitted_by, ...updates } = editForm.value
  await updateJob(id, updates)
  editing.value = null
  await load(); emit('update')
}

async function doDelete(id) {
  if (!confirm('确定删除这个岗位吗？')) return
  await deleteJob(id)
  await load(); emit('update')
}

const typeLabels = { frontend: '前端', backend: '后端', fullstack: '全栈', test: '测试', ops: '运维', product: '产品', design: '设计', other: '其他' }

onMounted(load)
</script>
<template>
  <div class="admin-panel">
    <h2>🛡️ 审核管理中心</h2>
    <div class="admin-tabs">
      <button class="nav-tab" :class="{ active: tab === 'pending' }" @click="tab='pending'">
        待审核 ({{ pendingJobs.length }})
      </button>
      <button class="nav-tab" :class="{ active: tab === 'approved' }" @click="tab='approved'">
        已通过 ({{ approvedJobs.length }})
      </button>
      <button class="nav-tab" :class="{ active: tab === 'rejected' }" @click="tab='rejected'">
        已拒绝 ({{ rejectedJobs.length }})
      </button>
    </div>

    <div v-if="loading" class="loading">加载中...</div>

    <!-- Pending -->
    <template v-if="tab === 'pending'">
      <div v-if="pendingJobs.length === 0" class="empty-state">
        <div class="icon">✅</div>
        <p>暂无待审核的投稿</p>
      </div>
      <div v-for="job in pendingJobs" :key="job.id" class="admin-card pending">
        <div class="admin-card-header">
          <div>
            <div class="admin-card-title">{{ job.title }} · {{ job.company }}</div>
            <div class="admin-card-meta">
              <span>📍 {{ job.city }}</span>
              <span>📋 {{ typeLabels[job.type] }}</span>
              <span>👤 {{ job.profiles?.username || '匿名' }}</span>
              <span>💰 {{ job.salary || '面议' }}</span>
            </div>
          </div>
        </div>
        <div v-if="job.notes" style="font-size:13px;color:var(--gray-500);margin-bottom:8px">📝 {{ job.notes }}</div>
        <div class="admin-actions">
          <button class="btn btn-success btn-sm" @click="doApprove(job.id)">✅ 通过</button>
          <button class="btn btn-warning btn-sm" @click="startReject(job.id)">❌ 拒绝</button>
          <button class="btn btn-outline btn-sm" @click="startEdit(job)">✏️ 编辑</button>
        </div>
        <div v-if="editing === job.id" class="admin-edit-form">
          <div class="form-row" style="margin-bottom:8px">
            <div class="form-group"><label>公司</label><input v-model="editForm.company" /></div>
            <div class="form-group"><label>职位</label><input v-model="editForm.title" /></div>
          </div>
          <div class="form-row" style="margin-bottom:8px">
            <div class="form-group"><label>城市</label><input v-model="editForm.city" /></div>
            <div class="form-group"><label>薪资</label><input v-model="editForm.salary" /></div>
          </div>
          <div class="form-group"><label>链接</label><input v-model="editForm.link" /></div>
          <div style="display:flex;gap:6px;margin-top:8px">
            <button class="btn btn-primary btn-sm" @click="saveEdit">保存</button>
            <button class="btn btn-outline btn-sm" @click="editing=null">取消</button>
          </div>
        </div>
      </div>
    </template>

    <!-- Approved -->
    <template v-if="tab === 'approved'">
      <div v-if="approvedJobs.length === 0" class="empty-state"><p>暂无已通过岗位</p></div>
      <div v-for="job in approvedJobs" :key="job.id" class="admin-card">
        <div class="admin-card-header">
          <div>
            <div class="admin-card-title">{{ job.title }} · {{ job.company }}</div>
            <div class="admin-card-meta">
              <span>📍 {{ job.city }}</span>
              <span>📋 {{ typeLabels[job.type] }}</span>
              <span>🎯 {{ job.friendly_label ? '大专友好' : '无' }}</span>
            </div>
          </div>
        </div>
        <div class="admin-actions">
          <button class="btn btn-outline btn-sm" @click="startEdit(job)">✏️ 编辑</button>
          <button class="btn btn-danger btn-sm" @click="doDelete(job.id)">🗑️ 删除</button>
        </div>
        <div v-if="editing === job.id" class="admin-edit-form">
          <div class="form-row" style="margin-bottom:8px">
            <div class="form-group"><label>公司</label><input v-model="editForm.company" /></div>
            <div class="form-group"><label>职位</label><input v-model="editForm.title" /></div>
          </div>
          <div style="display:flex;gap:6px;margin-top:8px">
            <button class="btn btn-primary btn-sm" @click="saveEdit">保存</button>
            <button class="btn btn-outline btn-sm" @click="editing=null">取消</button>
          </div>
        </div>
      </div>
    </template>

    <!-- Rejected -->
    <template v-if="tab === 'rejected'">
      <div v-if="rejectedJobs.length === 0" class="empty-state"><p>暂无已拒绝岗位</p></div>
      <div v-for="job in rejectedJobs" :key="job.id" class="admin-card">
        <div class="admin-card-header">
          <div>
            <div class="admin-card-title">{{ job.title }} · {{ job.company }}</div>
            <div class="admin-card-meta">
              <span>📍 {{ job.city }}</span>
              <span v-if="job.rejected_reason">❌ {{ job.rejected_reason }}</span>
            </div>
          </div>
        </div>
        <div class="admin-actions">
          <button class="btn btn-success btn-sm" @click="doApprove(job.id)">✅ 恢复通过</button>
          <button class="btn btn-danger btn-sm" @click="doDelete(job.id)">🗑️ 删除</button>
        </div>
      </div>
    </template>
  </div>
</template>
