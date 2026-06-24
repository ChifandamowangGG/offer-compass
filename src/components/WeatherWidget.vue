<script setup>
import { ref, watch, computed } from 'vue'
import { WEATHER_API_BASE } from '../config.js'

const props = defineProps({ city: String })
const weather = ref(null)
const loading = ref(false)
const error = ref('')

const cityMap = {
  '武汉': 'Wuhan', '合肥': 'Hefei', '南京': 'Nanjing', '上海': 'Shanghai',
  '杭州': 'Hangzhou', '北京': 'Beijing', '深圳': 'Shenzhen', '成都': 'Chengdu',
  '广州': 'Guangzhou', '长沙': 'Changsha', '重庆': 'Chongqing', '西安': 'Xian',
  '郑州': 'Zhengzhou', '苏州': 'Suzhou', '天津': 'Tianjin', '厦门': 'Xiamen',
  '青岛': 'Qingdao', '大连': 'Dalian', '昆明': 'Kunming', '贵阳': 'Guiyang',
  '海口': 'Haikou', '珠海': 'Zhuhai', '宁波': 'Ningbo', '无锡': 'Wuxi',
  '佛山': 'Foshan', '东莞': 'Dongguan', '济南': 'Jinan', '福州': 'Fuzhou',
  'all': 'Wuhan'
}

// Temperature color palette: cold=blue, hot=red
const tempColors = [
  { max: 0,   c1: '#1a1a6e', c2: '#2d2d86' },
  { max: 5,   c1: '#1e3c72', c2: '#2a5298' },
  { max: 10,  c1: '#1a5276', c2: '#2980b9' },
  { max: 15,  c1: '#0f6b8a', c2: '#3498db' },
  { max: 20,  c1: '#0e7c7b', c2: '#1abc9c' },
  { max: 24,  c1: '#5d8a3c', c2: '#82c91e' },
  { max: 27,  c1: '#b8860b', c2: '#f39c12' },
  { max: 30,  c1: '#d35400', c2: '#e67e22' },
  { max: 33,  c1: '#c0392b', c2: '#e74c3c' },
  { max: 36,  c1: '#8b0000', c2: '#dc143c' },
  { max: 99,  c1: '#4a0000', c2: '#8b0000' },
]

const gradientStyle = computed(() => {
  if (!weather.value) return 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
  const temp = parseFloat(weather.value.temp_C) || 20
  const match = tempColors.find(t => temp <= t.max) || tempColors[tempColors.length - 1]
  return `linear-gradient(135deg, ${match.c1} 0%, ${match.c2} 100%)`
})

async function fetchWeather() {
  const cityName = cityMap[props.city] || 'Wuhan'
  loading.value = true; error.value = ''
  try {
    const res = await fetch(`${WEATHER_API_BASE}/${cityName}?format=j1&lang=zh&m=`)
    const data = await res.json()
    if (data?.current_condition?.[0]) {
      weather.value = data.current_condition[0]
    } else {
      throw new Error('No data')
    }
  } catch (e) {
    error.value = '天气服务暂时不可用'
    weather.value = null
  } finally { loading.value = false }
}

function icon(code) {
  if (!code) return '🌤️'
  if (code <= 1) return '☀️'
  if (code <= 3) return '⛅'
  if (code <= 5) return '🌫️'
  if (code <= 8) return '🌧️'
  return '🌤️'
}

watch(() => props.city, fetchWeather, { immediate: true })
</script>

<template>
  <div v-if="loading && !weather" class="weather-widget" :style="{ background: gradientStyle, opacity: 0.6 }">
    加载天气中...
  </div>
  <div v-else-if="error && !weather" class="weather-error">{{ error }}</div>
  <div v-else-if="weather" class="weather-widget" :style="{ background: gradientStyle }">
    <div class="weather-main">
      <div class="weather-temp">{{ weather.temp_C }}&deg;C</div>
      <div class="weather-real">体感 {{ weather.FeelsLikeC || weather.temp_C }}&deg;C</div>
    </div>
    <div class="weather-info">
      <div class="weather-city">{{ city === 'all' ? '武汉' : city }}</div>
      <div class="weather-desc">{{ weather.weatherDesc?.[0]?.value || '未知' }}</div>
      <div class="weather-detail">
        <span>&#128167; 湿度 {{ weather.humidity }}%</span>
        <span>&#128168; 风速 {{ weather.windspeedKmph }}km/h</span>
        <span v-if="weather.uvIndex">&#9728;&#65039; UV {{ weather.uvIndex }}</span>
        <span v-if="weather.visibility">&#128065;&#65039; {{ (weather.visibility / 10).toFixed(1) }}km</span>
      </div>
    </div>
    <div class="weather-right">
      <div class="weather-icon">{{ icon(weather.weatherCode) }}</div>
      <div class="weather-refresh" @click="fetchWeather">&#128260;</div>
    </div>
  </div>
</template>

<style scoped>
.weather-main { text-align: center; min-width: 80px; }
.weather-temp { font-size: 36px; font-weight: 700; line-height: 1; }
.weather-real { font-size: 12px; opacity: 0.8; margin-top: 4px; }
.weather-info { flex: 1; min-width: 0; }
.weather-city { font-size: 16px; font-weight: 600; margin-bottom: 2px; }
.weather-desc { font-size: 13px; opacity: 0.85; margin-bottom: 6px; }
.weather-detail { display: flex; flex-wrap: wrap; gap: 8px; font-size: 11px; opacity: 0.8; }
.weather-right { display: flex; flex-direction: column; align-items: center; gap: 8px; }
.weather-icon { font-size: 28px; }
.weather-refresh { font-size: 14px; opacity: 0.6; cursor: pointer; }
.weather-refresh:hover { opacity: 1; }
.weather-error {
  background: var(--gray-100); color: var(--gray-500);
  padding: 8px 12px; border-radius: var(--radius-sm);
  font-size: 13px; margin-bottom: 12px;
}
</style>