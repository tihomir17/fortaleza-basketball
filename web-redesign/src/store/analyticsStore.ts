import { create } from 'zustand'
import { analyticsService, type ComprehensiveAnalytics, type AnalyticsFilters, type PlayerStats } from '../services/analytics'

interface AnalyticsState {
  // Data
  analytics: ComprehensiveAnalytics | null
  playerStats: PlayerStats[]
  
  // UI State
  isLoading: boolean
  error: string | null
  
  // Filters
  filters: AnalyticsFilters
  
  // Actions
  fetchAnalytics: (filters?: AnalyticsFilters) => Promise<void>
  fetchPlayerStats: (gameId: number) => Promise<void>
  exportPDF: (filters?: AnalyticsFilters) => Promise<void>
  setFilters: (filters: AnalyticsFilters) => void
  clearError: () => void
}

export const useAnalyticsStore = create<AnalyticsState>((set, get) => ({
  // Initial state
  analytics: null,
  playerStats: [],
  isLoading: false,
  error: null,
  filters: {},

  // Actions
  fetchAnalytics: async (filters?: AnalyticsFilters) => {
    set({ isLoading: true, error: null })
    try {
      const currentFilters = filters || get().filters
      const analytics = await analyticsService.getComprehensiveAnalytics(currentFilters)
      console.info('[analyticsStore] fetched analytics:', analytics)
      set({ analytics, isLoading: false, filters: currentFilters })
    } catch (error: any) {
      console.error('[analyticsStore] fetchAnalytics error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.response?.data?.error || error?.message || 'Failed to fetch analytics',
        isLoading: false 
      })
    }
  },

  fetchPlayerStats: async (gameId: number) => {
    set({ isLoading: true, error: null })
    try {
      const playerStats = await analyticsService.getPlayerStats(gameId)
      console.info('[analyticsStore] fetched player stats:', playerStats)
      set({ playerStats, isLoading: false })
    } catch (error: any) {
      console.error('[analyticsStore] fetchPlayerStats error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.response?.data?.error || error?.message || 'Failed to fetch player stats',
        isLoading: false 
      })
    }
  },

  exportPDF: async (filters?: AnalyticsFilters) => {
    set({ isLoading: true, error: null })
    try {
      const currentFilters = filters || get().filters
      const blob = await analyticsService.exportAnalyticsPDF(currentFilters)
      
      // Create download link
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `analytics-report-${new Date().toISOString().split('T')[0]}.pdf`
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      window.URL.revokeObjectURL(url)
      
      console.info('[analyticsStore] exported PDF successfully')
      set({ isLoading: false })
    } catch (error: any) {
      console.error('[analyticsStore] exportPDF error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.response?.data?.error || error?.message || 'Failed to export PDF',
        isLoading: false 
      })
    }
  },

  setFilters: (filters: AnalyticsFilters) => {
    set({ filters })
  },

  clearError: () => {
    set({ error: null })
  }
}))
