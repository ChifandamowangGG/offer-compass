<script setup>
defineProps({ total: Number, friendly: Number })
</script>
<template>
  <div class="stats-bar">
    <div class="stat-item">
      <span class="stat-value">{{ total }}</span>
      <span class="stat-label">个实习岗位</span>
    </div>
    <div class="stat-item">
      <span class="stat-value">{{ friendly }}</span>
      <span class="stat-label">个</span>
      <span class="stat-badge">大专友好</span>
    </div>
    <div style="flex:1"></div>
    <div style="font-size:13px;color:var(--gray-400)">
      数据来源：用户投稿 + 管理员收录
    </div>
  </div>
</template>
