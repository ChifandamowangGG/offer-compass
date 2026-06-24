<script setup>
import { ref } from 'vue'
import { signIn, signUp } from '../supabase.js'

const emit = defineEmits(['close', 'success'])
const isLogin = ref(true)
const email = ref('')
const password = ref('')
const username = ref('')
const loading = ref(false)
const error = ref('')

async function handleSubmit() {
  loading.value = true; error.value = ''
  try {
    const fn = isLogin.value ? signIn : signUp
    const { data, error: err } = await fn(email.value, password.value, username.value)
    if (err) { error.value = err.message; return }
    emit('success', data.user)
  } catch (e) { error.value = '网络错误，请重试' }
  finally { loading.value = false }
}
</script>
<template>
  <div class="modal-overlay" @click.self="emit('close')">
    <div class="modal">
      <h2>{{ isLogin ? '登录' : '注册' }}</h2>
      <form @submit.prevent="handleSubmit">
        <div v-if="!isLogin" class="form-group">
          <label>用户名</label>
          <input v-model="username" type="text" placeholder="你的昵称" required />
        </div>
        <div class="form-group">
          <label>邮箱</label>
          <input v-model="email" type="email" placeholder="example@email.com" required />
        </div>
        <div class="form-group">
          <label>密码</label>
          <input v-model="password" type="password" placeholder="至少 6 位" minlength="6" required />
        </div>
        <div v-if="error" class="form-error">{{ error }}</div>
        <div class="form-actions">
          <button type="button" class="btn btn-outline" @click="emit('close')">取消</button>
          <button type="submit" class="btn btn-primary" :disabled="loading">
            {{ loading ? '处理中...' : (isLogin ? '登录' : '注册') }}
          </button>
        </div>
        <div class="form-switch">
          <a @click="isLogin = !isLogin; error=''">
            {{ isLogin ? '没有账号？去注册' : '已有账号？去登录' }}
          </a>
        </div>
      </form>
    </div>
  </div>
</template>
