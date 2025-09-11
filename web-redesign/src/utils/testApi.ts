// Test utility to debug API responses
import { adminApi } from '../services/api'

export const testPlaysApi = async () => {
  try {
    console.log('🧪 Testing plays API...')
    
    // Test the health endpoint first
    const healthResponse = await adminApi.get('/api/health/')
    console.log('✅ Health check:', healthResponse.data)
    
    // Test the plays endpoint
    const playsResponse = await adminApi.get('/api/plays/')
    console.log('✅ Plays API response:', playsResponse)
    console.log('✅ Plays data:', playsResponse.data)
    console.log('✅ Plays count:', Array.isArray(playsResponse.data) ? playsResponse.data.length : 'Not an array')
    
    return playsResponse.data
  } catch (error) {
    console.error('❌ API test failed:', error)
    if (error.response) {
      console.error('❌ Response status:', error.response.status)
      console.error('❌ Response data:', error.response.data)
    }
    throw error
  }
}

// Call this from browser console: window.testPlaysApi()
if (typeof window !== 'undefined') {
  (window as any).testPlaysApi = testPlaysApi
}
