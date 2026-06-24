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

// Weather background images (Unsplash)
const weatherBgs = {
  sunny: 'https://images.unsplash.com/photo-1601297183305-6df142704ea2?w=800&q=80',
  cloudy: 'https://images.unsplash.com/photo-1611928482473-7b27d24eab80?w=800&q=80',
  overcast: 'https://images.unsplash.com/photo-1501630834273-4b5604d2ee31?w=800&q=80',
  rainy: 'https://images.unsplash.com/photo-1519692933481-e162a57d6721?w=800&q=80',
  snowy: 'https://images.unsplash.com/photo-1516431883659-655f7410e6df?w=800&q=80',
  foggy: 'https://images.unsplash.com/photo-1487621167305-5d248087c724?w=800&q=80',
  night: 'https://images.unsplash.com/photo-1507400492013-162706c8c05e?w=800&q=80',
  default: 'https://images.unsplash.com/photo-1504608524841-42fe6f032b4b?w=800&q=80',
}

const bgStyle = computed(() => {
  if (!weather.value) {
    return { background: 'linear-gradient(135deg, #667eea, #764ba2)' }
  }
  const code = weather.value.weatherCode || 0
  const isNight = !weather.value.weatherDesc?.[0]?.value?.includes('晴') && code > 8
  let key = 'default'
  if (code <= 1) key = 'sunny'
  else if (code <= 3) key = isNight ? 'night' : 'cloudy'
  else if (code <= 5) key = 'foggy'
  else if (code <= 6) key = 'rainy'
  else if (code <= 8) key = 'rainy'
  // Snow codes from wttr.in
  const desc = (weather.value.weatherDesc?.[0]?.value || '').toLowerCase()
  if (desc.includes('雪') || desc.includes('snow')) key = 'snowy'
  if (desc.includes('阴')) key = 'overcast'
  if (desc.includes('晴')) key = 'sunny'

  const url = weatherBgs[key] || weatherBgs.default
  return {
    background: `linear-gradient(rgba(0,0,0,0.35), rgba(0,0,0,0.35)), url('${url}')`,
    backgroundSize: 'cover',
    backgroundPosition: 'center'
  }
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

function weatherLabel(code) {
  if (!code) return '-'
  if (code <= 1) return '晴'  // 晴
  if (code <= 3) return '多云'  // 多云
  if (code <= 5) return '雾'  // 雾
  if (code <= 8) return '雨'  // 雨
  return '-'
}

watch(() => props.city, fetchWeather, { immediate: true })
</script>

<template>
  <div v-if="loading && !weather" class="weather-card" style="background: linear-gradient(135deg, #667eea, #764ba2); opacity:0.5">
    <div class="weather-loading">加载中</div>
  </div>
  <div v-else-if="error && !weather" class="weather-card weather-card-error">
    <span class="weather-error-text">{{ error }}</span>
  </div>
  <div v-else-if="weather" class="weather-card" :style="bgStyle">
    <div class="weather-left">
      <div class="weather-city-label">{{ city === 'all' ? '武汉' : city }}</div>
      <div class="weather-temp">{{ weather.temp_C }}<span class="weather-temp-unit">&deg;C</span></div>
      <div class="weather-desc">{{ weather.weatherDesc?.[0]?.value || '-' }}</div>
    </div>
    <div class="weather-divider"></div>
    <div class="weather-right">
      <div class="weather-detail-row">
        <span class="weather-detail-label">体感</span>
        <span class="weather-detail-value">{{ weather.FeelsLikeC || weather.temp_C }}&deg;C</span>
      </div>
      <div class="weather-detail-row">
        <span class="weather-detail-label">湿度</span>
        <span class="weather-detail-value">{{ weather.humidity }}%</span>
      </div>
      <div class="weather-detail-row">
        <span class="weather-detail-label">风速</span>
        <span class="weather-detail-value">{{ weather.windspeedKmph }}km/h</span>
      </div>
      <div v-if="weather.uvIndex" class="weather-detail-row">
        <span class="weather-detail-label">UV</span>
        <span class="weather-detail-value">{{ weather.uvIndex }}</span>
      </div>
      <div v-if="weather.visibility" class="weather-detail-row">
        <span class="weather-detail-label">能见度</span>
        <span class="weather-detail-value">{{ (weather.visibility / 10).toFixed(1) }}km</span>
      </div>
    </div>
    <div class="weather-badge">{{ weatherLabel(weather.weatherCode) }}</div>
    <button class="weather-refresh" @click="fetchWeather" title="刷新">&#8635;</button>
  </div>
</template>

<style scoped>
.weather-card {
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 18px 24px;
  border-radius: 12px;
  color: white;
  margin-bottom: 16px;
  position: relative;
  overflow: hidden;
  min-height: 100px;
  text-shadow: 0 1px 3px rgba(0,0,0,0.2);
}
.weather-card-error {
  background: var(--bg-card) !important;
  border: 1px solid var(--border);
  color: var(--text-secondary);
  text-shadow: none;
}
.weather-loading {
  width: 100%;
  text-align: center;
  font-size: 14px;
  opacity: 0.7;
}
.weather-error-text {
  font-size: 13px;
  color: var(--text-secondary);
}
.weather-left {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 120px;
}
.weather-city-label {
  font-size: 15px;
  font-weight: 500;
  opacity: 0.95;
  letter-spacing: 0.5px;
}
.weather-temp {
  font-size: 42px;
  font-weight: 700;
  line-height: 1;
  letter-spacing: -1px;
}
.weather-temp-unit {
  font-size: 20px;
  font-weight: 400;
  opacity: 0.7;
  vertical-align: super;
  margin-left: 1px;
}
.weather-desc {
  font-size: 13px;
  opacity: 0.85;
  margin-top: 2px;
}
.weather-divider {
  width: 1px;
  height: 60px;
  background: rgba(255,255,255,0.25);
  flex-shrink: 0;
}
.weather-right {
  display: flex;
  flex-direction: column;
  gap: 4px;
  flex: 1;
}
.weather-detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
  line-height: 1.6;
}
.weather-detail-label {
  opacity: 0.75;
}
.weather-detail-value {
  font-weight: 500;
}
.weather-badge {
  position: absolute;
  top: 12px;
  right: 40px;
  font-size: 11px;
  padding: 2px 10px;
  border-radius: 999px;
  background: rgba(255,255,255,0.2);
  font-weight: 500;
  letter-spacing: 1px;
}
.weather-refresh {
  position: absolute;
  top: 10px;
  right: 10px;
  background: none;
  border: none;
  color: white;
  font-size: 16px;
  cursor: pointer;
  opacity: 0.5;
  padding: 4px 6px;
  border-radius: 4px;
  transition: var(--transition);
  line-height: 1;
}
.weather-refresh:hover {
  opacity: 1;
  background: rgba(255,255,255,0.15);
}
</style>