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
  const desc = (weather.value.weatherDesc?.[0]?.value || '').toLowerCase()
  let key = 'default'
  if (desc.includes('sunny') || desc.includes('clear')) key = 'sunny'
  else if (desc.includes('partly cloudy')) key = 'cloudy'
  else if (desc.includes('overcast')) key = 'overcast'
  else if (desc.includes('cloudy')) key = 'cloudy'
  else if (desc.includes('fog') || desc.includes('mist') || desc.includes('haze')) key = 'foggy'
  else if (desc.includes('rain') || desc.includes('drizzle') || desc.includes('shower') || desc.includes('thunder')) key = 'rainy'
  else if (desc.includes('snow') || desc.includes('blizzard') || desc.includes('sleet')) key = 'snowy'
  else if (desc.includes('thunder')) key = 'rainy'

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

function weatherLabel(desc) {
  const d = (desc || '').toLowerCase()
  if (d.includes('sunny') || d.includes('clear')) return '晴'
  if (d.includes('partly cloudy')) return '多云'
  if (d.includes('overcast')) return '阴'
  if (d.includes('cloudy')) return '多云'
  if (d.includes('mist') || d.includes('fog') || d.includes('haze')) return '雾'
  if (d.includes('rain') || d.includes('drizzle') || d.includes('shower')) return '雨'
  if (d.includes('snow') || d.includes('blizzard') || d.includes('sleet')) return '雪'
  if (d.includes('thunder') || d.includes('storm')) return '雷雨'
  return '-'
}

watch(() => props.city, fetchWeather, { immediate: true })
</script>

<template>
  <div v-if="loading && !weather" class="weather-card" style="background:linear-gradient(135deg,#667eea,#764ba2);opacity:.5">
    <div class="weather-loading">加载中</div>
  </div>
  <div v-else-if="error && !weather" class="weather-card weather-card-error">
    <span class="weather-error-text">{{ error }}</span>
  </div>
  <div v-else-if="weather" class="weather-card" :style="bgStyle">
    <div class="weather-top">
      <div class="weather-city-label">{{ city === 'all' ? '武汉' : city }}</div>
      <span class="weather-badge">{{ weatherLabel(weather.weatherDesc?.[0]?.value) }}</span>
    </div>
    <div class="weather-body">
      <div class="weather-temp">{{ weather.temp_C }}<span class="weather-temp-unit">&deg;C</span></div>
      <div class="weather-desc">{{ weather.weatherDesc?.[0]?.value || '-' }}</div>
      <div class="weather-divider"></div>
      <div class="weather-details">
        <div class="weather-detail-item">
          <span class="wd-label">体感</span>
          <span class="wd-value">{{ weather.FeelsLikeC || weather.temp_C }}&deg;C</span>
        </div>
        <div class="weather-detail-item">
          <span class="wd-label">湿度</span>
          <span class="wd-value">{{ weather.humidity }}%</span>
        </div>
        <div class="weather-detail-item">
          <span class="wd-label">风速</span>
          <span class="wd-value">{{ weather.windspeedKmph }}km/h</span>
        </div>
        <div v-if="weather.uvIndex" class="weather-detail-item">
          <span class="wd-label">UV</span>
          <span class="wd-value">{{ weather.uvIndex }}</span>
        </div>
        <div v-if="weather.visibility" class="weather-detail-item">
          <span class="wd-label">能见度</span>
          <span class="wd-value">{{ (weather.visibility / 10).toFixed(1) }}km</span>
        </div>
      </div>
    </div>
    <div class="weather-footer">
      <button class="weather-refresh" @click="fetchWeather">↻ 刷新</button>
    </div>
  </div>
</template>

<style scoped>
.weather-card {
  border-radius: 12px;
  color: white;
  margin-bottom: 16px;
  position: relative;
  overflow: hidden;
  min-height: 100px;
  text-shadow: 0 1px 3px rgba(0,0,0,0.2);
  display: flex;
  flex-direction: column;
}
.weather-card-error {
  background: var(--bg-card) !important;
  border: 1px solid var(--border);
  color: var(--text-secondary);
  text-shadow: none;
  min-height: auto;
  padding: 16px 20px;
}
.weather-loading {
  width: 100%;
  text-align: center;
  padding: 40px 20px;
  font-size: 14px;
  opacity: 0.7;
}
.weather-error-text { font-size: 13px; color: var(--text-secondary); }

.weather-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px 0;
}
.weather-city-label {
  font-size: 15px;
  font-weight: 500;
  opacity: 0.95;
  letter-spacing: 0.5px;
}
.weather-badge {
  font-size: 11px;
  padding: 3px 12px;
  border-radius: 999px;
  background: rgba(255,255,255,0.2);
  font-weight: 500;
  letter-spacing: 1px;
}

.weather-body {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 12px 20px;
  flex: 1;
}
.weather-temp {
  font-size: 44px;
  font-weight: 700;
  line-height: 1;
  letter-spacing: -1px;
  white-space: nowrap;
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
  white-space: nowrap;
}
.weather-divider {
  width: 1px;
  height: 48px;
  background: rgba(255,255,255,0.2);
  flex-shrink: 0;
}
.weather-details {
  display: flex;
  gap: 16px;
  flex-wrap: wrap;
}
.weather-detail-item {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 48px;
}
.wd-label {
  font-size: 11px;
  opacity: 0.7;
}
.wd-value {
  font-size: 14px;
  font-weight: 500;
}

.weather-footer {
  padding: 8px 20px 14px;
  display: flex;
  justify-content: flex-end;
}
.weather-refresh {
  background: rgba(255,255,255,0.12);
  border: 1px solid rgba(255,255,255,0.25);
  color: white;
  font-size: 12px;
  cursor: pointer;
  padding: 5px 14px;
  border-radius: 999px;
  transition: var(--transition);
  backdrop-filter: blur(4px);
  letter-spacing: 0.5px;
}
.weather-refresh:hover {
  background: rgba(255,255,255,0.25);
  border-color: rgba(255,255,255,0.4);
}
</style>