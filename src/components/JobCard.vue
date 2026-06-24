<script setup>
import { ref, computed } from 'vue'
import { addBookmark, removeBookmark, updateApplicationStatus, updateJob, deleteJob } from '../supabase.js'

const props = defineProps({ job: Object, userId: String, bookmarks: Array, isAdmin: Boolean })
const emit = defineEmits(['update'])

const bm = computed(() => props.bookmarks?.find(b => b.job_id === props.job.id))
const isBookmarked = computed(() => !!bm.value)
const saving = ref(false)

const editing = ref(false)
const editForm = ref({})

async function toggleBookmark() {
  if (!props.userId) return
  saving.value = true
  if (isBookmarked.value && bm.value) {
    await removeBookmark(bm.value.id)
  } else {
    await addBookmark(props.userId, props.job.id)
  }
  saving.value = false
  emit('update')
}

async function changeStatus(e) {
  if (!bm.value) return
  saving.value = true
  await updateApplicationStatus(bm.value.id, e.target.value)
  saving.value = false
  emit('update')
}

function startEdit() {
  editForm.value = { ...props.job }
  editing.value = true
}
function cancelEdit() { editing.value = false }

async function saveEdit() {
  const { id, profiles, created_at, updated_at, status, submitted_by, ...updates } = editForm.value
  await updateJob(id, updates)
  editing.value = false
  emit('update')
}

async function confirmDelete() {
  if (!confirm('确定删除 ' + props.job.title + ' @ ' + props.job.company + ' 吗？')) return
  await deleteJob(props.job.id)
  emit('update')
}

const daysLeft = computed(() => {
  if (!props.job.deadline) return ''
  const diff = new Date(props.job.deadline) - new Date()
  if (diff <= 0) return '已截止'
  const d = Math.ceil(diff / (1000*60*60*24))
  return d + '天后截止'
})

const typeLabels = { frontend: '前端', backend: '后端', fullstack: '全栈', test: '测试', ops: '运维', product: '产品', design: '设计', other: '其他' }
const statusLabels = { wish: '想投', applied: '已投递', interviewing: '面试中', offered: '已拿 Offer', closed: '已结束' }
</script>

<template>
  <div class="job-card">
    <div class="job-card-header">
      <div>
        <div class="job-card-title">{{ job.title }}</div>
        <div class="job-card-company">{{ job.company }}</div>
      </div>
      <div style="display:flex;align-items:center;gap:4px">
        <span v-if="job.status === 'pending'" style="font-size:11px;padding:2px 6px;border-radius:4px;background:#fef3c7;color:#92400e">待审核</span>
        <button v-if="userId" class="bookmark-btn" :disabled="saving" @click="toggleBookmark" :title="isBookmarked ? '取消收藏' : '收藏'">
          {{ isBookmarked ? '❤️' : '🤍' }}
        </button>
      </div>
    </div>
    <div class="job-card-tags">
      <span class="tag tag-salary">{{ job.salary || '面议' }}</span>
      <span class="tag tag-city">{{ job.city }}</span>
      <span class="tag tag-type">{{ typeLabels[job.type] || job.type }}</span>
      <span class="tag">{{ job.education }}</span>
      <span v-if="job.friendly_label" class="tag tag-friendly">大专友好</span>
      <span v-if="job.deadline" class="tag tag-deadline">{{ daysLeft }}</span>
    </div>
    <div v-if="job.notes" class="job-card-notes">{{ job.notes }}</div>
    <div class="job-card-actions">
      <a :href="job.link" target="_blank" class="btn btn-primary btn-sm" rel="noopener">申请投递</a>
      <span v-if="isBookmarked && bm" style="flex:1"></span>
      <select v-if="isBookmarked && bm" class="app-status-select" :value="bm.application_status" @change="changeStatus" :disabled="saving">
        <option v-for="(label, key) in statusLabels" :key="key" :value="key">{{ label }}</option>
      </select>
    </div>

    <!-- Admin actions -->
    <div v-if="isAdmin" class="admin-actions" style="margin-top:8px;padding-top:8px;border-top:1px dashed var(--gray-200);display:flex;gap:6px;flex-wrap:wrap">
      <button class="btn btn-outline btn-sm" @click="startEdit">编辑</button>
      <button class="btn btn-danger btn-sm" @click="confirmDelete">删除</button>
    </div>
  </div>

<!-- Edit modal -->
  <div v-if="editing" class="modal-overlay" @click.self="cancelEdit">
    <div class="modal" style="max-width:500px">
      <h3 style="margin-bottom:8px">编辑岗位</h3>
      <p style="font-size:13px;color:var(--gray-500);margin-bottom:16px">{{ job.company }} - {{ job.title }}</p>
      <div class="form-row">
        <div class="form-group"><label>公司</label><input v-model="editForm.company" /></div>
        <div class="form-group"><label>职位</label><input v-model="editForm.title" /></div>
      </div>
      <div class="form-row">
        <div class="form-group"><label>城市</label><input v-model="editForm.city" /></div>
        <div class="form-group"><label>薪资</label><input v-model="editForm.salary" /></div>
      </div>
      <div class="form-row">
        <div class="form-group"><label>链接</label><input v-model="editForm.link" style="font-size:12px" /></div>
        <div class="form-group"><label>学历要求</label>
          <select v-model="editForm.education">
            <option>不限</option><option>大专及以上</option><option>本科及以上</option>
          </select>
        </div>
      </div>
      <div class="form-group"><label>备注</label><textarea v-model="editForm.notes" rows="2"></textarea></div>
      <div class="form-checkbox">
        <input v-model="editForm.friendly_label" type="checkbox" :id="'ef-' + job.id" />
        <label :for="'ef-' + job.id">🎯 大专友好</label>
      </div>
      <div style="display:flex;gap:8px;margin-top:12px">
        <button class="btn btn-primary btn-sm" @click="saveEdit">保存</button>
        <button class="btn btn-outline btn-sm" @click="cancelEdit">取消</button>
      </div>
    </div>
  </div>
</template>
