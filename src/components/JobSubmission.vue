<script setup>
import { ref } from 'vue'
import { submitJob } from '../supabase.js'

const emit = defineEmits(['submitted', 'cancel'])
const loading = ref(false)
const success = ref(false)
const error = ref('')

const form = ref({
  company: '', title: '', city: '', type: 'frontend',
  education: '不限', friendly_label: true, salary: '',
  deadline: '', link: '', notes: ''
})

const cities = ['武汉','合肥','南京','上海','杭州','北京','深圳','成都','广州','长沙','重庆','西安','郑州','苏州','天津']
const types = [
  { value: 'frontend', label: '前端开发' }, { value: 'backend', label: '后端开发' },
  { value: 'fullstack', label: '全栈开发' }, { value: 'test', label: '测试' },
  { value: 'ops', label: '运维' }, { value: 'product', label: '产品' },
  { value: 'design', label: 'UI/UX设计' }, { value: 'other', label: '其他' }
]

async function handleSubmit() {
  loading.value = true; error.value = ''
  try {
    const { error: err } = await submitJob(form.value)
    if (err) { error.value = err.message; return }
    success.value = true
    emit('submitted')
  } catch (e) { error.value = '提交失败，请重试' }
  finally { loading.value = false }
}
</script>
<template>
  <div class="submit-form">
    <template v-if="success">
      <h2>✅ 提交成功！</h2>
      <p class="subtitle">岗位已进入审核队列，管理员审核通过后就会展示在列表中。</p>
      <button class="btn btn-primary" @click="$emit('cancel')">返回浏览</button>
    </template>
    <template v-else>
      <h2>📮 投稿实习岗位</h2>
      <p class="subtitle">你知道的实习机会，分享给更多同学</p>
      <form @submit.prevent="handleSubmit">
        <div class="form-row">
          <div class="form-group">
            <label>公司名称 *</label>
            <input v-model="form.company" placeholder="例：武汉众创科技" required />
          </div>
          <div class="form-group">
            <label>职位名称 *</label>
            <input v-model="form.title" placeholder="例：前端开发实习生" required />
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>城市 *</label>
            <select v-model="form.city" required>
              <option value="" disabled>选择城市</option>
              <option v-for="c in cities" :key="c" :value="c">{{ c }}</option>
            </select>
          </div>
          <div class="form-group">
            <label>岗位类型 *</label>
            <select v-model="form.type" required>
              <option v-for="t in types" :key="t.value" :value="t.value">{{ t.label }}</option>
            </select>
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>学历要求</label>
            <select v-model="form.education">
              <option value="不限">不限</option>
              <option value="大专及以上">大专及以上</option>
              <option value="本科及以上">本科及以上</option>
            </select>
          </div>
          <div class="form-group">
            <label>薪资待遇</label>
            <input v-model="form.salary" placeholder="例：3-5K" />
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>截止日期</label>
            <input v-model="form.deadline" type="date" />
          </div>
          <div class="form-group">
            <label>投递链接</label>
            <input v-model="form.link" placeholder="https://..." type="url" />
          </div>
        </div>
        <div class="form-checkbox">
          <input v-model="form.friendly_label" type="checkbox" id="friendly" />
          <label for="friendly">🎯 这个岗位明确接受大专学历</label>
        </div>
        <div class="form-group">
          <label>补充说明</label>
          <textarea v-model="form.notes" placeholder="面试难度、福利待遇、团队氛围等..." rows="3"></textarea>
        </div>
        <div v-if="error" class="form-error">{{ error }}</div>
        <div style="display:flex;gap:8px">
          <button type="button" class="btn btn-outline" @click="$emit('cancel')">取消</button>
          <button type="submit" class="btn btn-primary" :disabled="loading">
            {{ loading ? '提交中...' : '提交审核' }}
          </button>
        </div>
      </form>
    </template>
  </div>
</template>
