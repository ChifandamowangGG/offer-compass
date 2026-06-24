<script setup>
import { computed } from 'vue'

const props = defineProps({
  filters: Object, cities: Array, types: Array
})
const emit = defineEmits(['update:filters'])

function set(key, val) {
  emit('update:filters', { ...props.filters, [key]: val })
}
</script>
<template>
  <div class="filters-bar">
    <select :value="filters.city" @change="set('city', $event.target.value)">
      <option value="all">🌆 全部城市</option>
      <option v-for="c in cities" :key="c" :value="c">{{ c }}</option>
    </select>
    <select :value="filters.type" @change="set('type', $event.target.value)">
      <option value="all">📋 全部类型</option>
      <option v-for="t in types" :key="t.value" :value="t.value">{{ t.label }}</option>
    </select>
    <select :value="filters.education" @change="set('education', $event.target.value)">
      <option value="all">🎓 学历不限</option>
      <option value="大专及以上">大专及以上</option>
      <option value="本科及以上">本科及以上</option>
      <option value="不限">不限</option>
    </select>
    <input :value="filters.search" @input="set('search', $event.target.value)" type="text" placeholder="🔍 搜索公司/职位..." />
    <button class="filter-toggle" :class="{ active: filters.friendlyOnly }" @click="set('friendlyOnly', !filters.friendlyOnly)">
      🎯 仅看大专友好
    </button>
  </div>
</template>
