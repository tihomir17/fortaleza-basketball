import { api, adminApi } from './api'
// Using dynamic imports for mock data to avoid Vite chunking conflicts

// Configuration for fallback behavior
const USE_MOCK_FALLBACK = import.meta.env.VITE_USE_MOCKS === 'true' || 
                          import.meta.env.VITE_ENABLE_MOCK_FALLBACK === 'true'

// Helper function to check if we should use mock data
const shouldUseMockData = (error: any): boolean => {
  // Use mock data if:
  // 1. Explicitly enabled via environment variable
  // 2. Network error (backend not running)
  // 3. 404 errors (endpoint not found)
  // 4. 500+ server errors (backend issues)
  // 5. Timeout errors
  return USE_MOCK_FALLBACK || 
         !error.response || 
         error.response?.status === 404 ||
         error.response?.status >= 500 ||
         error.code === 'ECONNABORTED' ||
         error.message?.includes('Network Error')
}

// Enhanced API with fallback to mock data
export const apiWithFallback = {
  // Dashboard API with fallback
  getDashboardData: async () => {
    try {
      console.log('Attempting to fetch dashboard data from backend...')
      const data = await api.get('/games/dashboard_data/')
      console.log('✅ Dashboard data fetched successfully from backend')
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.warn('⚠️ Backend unavailable, using mock dashboard data:', errorMessage)
      if (shouldUseMockData(error)) {
        const { mockDashboardData, simulateApiDelay } = await import('./mockData')
        await simulateApiDelay(300) // Simulate network delay
        return mockDashboardData
      }
      throw error
    }
  },

  // Games API with fallback
  getGames: async () => {
    try {
      console.log('Attempting to fetch games from backend...')
      const data = await api.get('/games/')
      console.log('✅ Games fetched successfully from backend')
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.warn('⚠️ Backend unavailable, using mock games data:', errorMessage)
      if (shouldUseMockData(error)) {
        const { mockGamesData, simulateApiDelay } = await import('./mockData')
        await simulateApiDelay(400)
        return mockGamesData
      }
      throw error
    }
  },

  getUpcomingGames: async () => {
    try {
      console.log('Attempting to fetch upcoming games from backend...')
      const data = await api.get('/games/upcoming/')
      console.log('✅ Upcoming games fetched successfully from backend')
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.warn('⚠️ Backend unavailable, using mock upcoming games:', errorMessage)
      if (shouldUseMockData(error)) {
        const { mockGamesData, simulateApiDelay } = await import('./mockData')
        await simulateApiDelay(200)
        return mockGamesData.filter(game => game.status === 'SCHEDULED')
      }
      throw error
    }
  },

  getRecentGames: async () => {
    try {
      console.log('Attempting to fetch recent games from backend...')
      const data = await api.get('/games/recent/')
      console.log('✅ Recent games fetched successfully from backend')
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.warn('⚠️ Backend unavailable, using mock recent games:', errorMessage)
      if (shouldUseMockData(error)) {
        const { mockGamesData, simulateApiDelay } = await import('./mockData')
        await simulateApiDelay(250)
        return mockGamesData.filter(game => game.status === 'COMPLETED')
      }
      throw error
    }
  },

  // Scouting API with fallback
  getScoutingReports: async () => {
    try {
      console.log('Attempting to fetch scouting reports from backend...')
      const data = await api.get('/scouting/reports/')
      console.log('✅ Scouting reports fetched successfully from backend')
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.warn('⚠️ Backend unavailable, using mock scouting reports:', errorMessage)
      if (shouldUseMockData(error)) {
        const { mockScoutingReports, simulateApiDelay } = await import('./mockData')
        await simulateApiDelay(350)
        return mockScoutingReports
      }
      throw error
    }
  },

  // Analytics API with fallback
  getAnalytics: async (filters?: any) => {
    try {
      console.log('Attempting to fetch analytics from backend...')
      const data = await api.get('/analytics/comprehensive/', { params: filters })
      console.log('✅ Analytics fetched successfully from backend')
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.warn('⚠️ Backend unavailable, using mock analytics data:', errorMessage)
      if (shouldUseMockData(error)) {
        const { mockAnalyticsData, simulateApiDelay } = await import('./mockData')
        await simulateApiDelay(400)
        return mockAnalyticsData
      }
      throw error
    }
  },

  // Playbook API with fallback - Using existing backend endpoints
  getPlays: async (filters?: any) => {
    try {
      console.log('Attempting to fetch plays from backend...')
      const data = await api.get('/plays/', { params: filters })
      console.log('✅ Plays fetched successfully from backend')
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.error('❌ Failed to fetch plays from backend:', errorMessage)
      throw error
    }
  },

  getPlay: async (id: string) => {
    try {
      console.log(`Attempting to fetch play ${id} from backend...`)
      const data = await api.get(`/plays/${id}/`)
      console.log(`✅ Play ${id} fetched successfully from backend`)
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.error(`❌ Failed to fetch play ${id} from backend:`, errorMessage)
      throw error
    }
  },

  createPlay: async (playData: any) => {
    try {
      console.log('Attempting to create play in backend...')
      const data = await api.post('/plays/', playData)
      console.log('✅ Play created successfully in backend')
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.error('❌ Failed to create play in backend:', errorMessage)
      throw error
    }
  },

  updatePlay: async (id: string, playData: any) => {
    try {
      console.log(`Attempting to update play ${id} in backend...`)
      console.log('📤 Sending data:', JSON.stringify(playData, null, 2))
      const data = await adminApi.patch(`/api/plays/${id}/`, playData)
      console.log(`✅ Play ${id} updated successfully in backend`)
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.error(`❌ Failed to update play ${id} in backend:`, errorMessage)
      if ((error as any).response) {
        console.error('📥 Response data:', (error as any).response.data)
        console.error('📥 Response status:', (error as any).response.status)
      }
      throw error
    }
  },

  deletePlay: async (id: string) => {
    try {
      console.log(`Attempting to delete play ${id} from backend...`)
      await adminApi.delete(`/api/plays/${id}/`)
      console.log(`✅ Play ${id} deleted successfully from backend`)
      return { success: true }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.error(`❌ Failed to delete play ${id} from backend:`, errorMessage)
      throw error
    }
  },

  toggleFavorite: async (id: string) => {
    try {
      console.log(`Attempting to toggle favorite for play ${id} in backend...`)
      const data = await adminApi.patch(`/api/plays/${id}/favorite/`)
      console.log(`✅ Play ${id} favorite toggled successfully in backend`)
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.error(`❌ Failed to toggle favorite for play ${id} in backend:`, errorMessage)
      throw error
    }
  },

  duplicatePlay: async (id: string, newName?: string) => {
    try {
      console.log(`Attempting to duplicate play ${id} in backend...`)
      const data = await adminApi.post(`/api/plays/${id}/duplicate/`, { name: newName })
      console.log(`✅ Play ${id} duplicated successfully in backend`)
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.error(`❌ Failed to duplicate play ${id} in backend:`, errorMessage)
      throw error
    }
  },

  // Generic API method with fallback
  get: async <T = any>(url: string, fallbackData?: T): Promise<T> => {
    try {
      console.log(`Attempting to fetch ${url} from backend...`)
      const data = await api.get<T>(url)
      console.log(`✅ ${url} fetched successfully from backend`)
      return data
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error'
      console.warn(`⚠️ Backend unavailable for ${url}, using fallback:`, errorMessage)
      if (shouldUseMockData(error) && fallbackData) {
        const { simulateApiDelay } = await import('./mockData')
        await simulateApiDelay(300)
        return fallbackData
      }
      throw error
    }
  }
}

// Backend health check
export const checkBackendHealth = async (): Promise<boolean> => {
  try {
    await api.get('/health/')
    console.log('✅ Backend is healthy')
    return true
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    console.warn('⚠️ Backend health check failed:', errorMessage)
    return false
  }
}

// Initialize backend connection status
export const initializeBackendStatus = async () => {
  const isHealthy = await checkBackendHealth()
  if (isHealthy) {
    console.log('🚀 Backend connected successfully')
  } else {
    console.log('🔄 Using mock data fallback - backend unavailable')
  }
  return isHealthy
}
