<script setup>
defineProps({ user: Object, currentView: String, isAdmin: Boolean })
const emit = defineEmits(['viewChange', 'login', 'logout'])
</script>
<template>
  <nav class="navbar">
    <div class="navbar-inner">
      <div class="logo">
        <span class="logo-icon">OC</span>
        OfferCompass
      </div>
      <div class="nav-tabs">
        <button class="nav-tab" :class="{ active: currentView === 'browse' }" @click="emit('viewChange', 'browse')">岗位浏览</button>
        <button class="nav-tab" :class="{ active: currentView === 'submit' }" @click="emit('viewChange', 'submit')">投稿岗位</button>
        <button v-if="isAdmin" class="nav-tab" :class="{ active: currentView === 'admin' }" @click="emit('viewChange', 'admin')">审核管理</button>
      </div>
      <div class="nav-user">
        <template v-if="user">
          <div class="avatar">{{ user.email?.charAt(0).toUpperCase() }}</div>
          <span style="font-size:13px;color:var(--text-secondary)">{{ user.email?.split('@')[0] }}</span>
          <button class="btn btn-outline btn-sm" @click="emit('logout')">退出</button>
        </template>
        <button v-else class="btn btn-primary btn-sm" @click="emit('login')">登录</button>
      </div>
    </div>
  </nav>
</template>
