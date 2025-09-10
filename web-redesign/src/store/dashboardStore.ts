import { create } from 'zustand'
import type { DashboardData } from '../services/dashboard'
import { dashboardService } from '../services/dashboard'

interface DashboardState {
  data: DashboardData | null
  isLoading: boolean
  error: string | null
  lastUpdated: Date | null
  
  // Actions
  fetchDashboardData: () => Promise<void>
  refreshDashboard: () => Promise<void>
  clearError: () => void
}

export const useDashboardStore = create<DashboardState>((set, get) => ({
  data: null,
  isLoading: false,
  error: null,
  lastUpdated: null,

  fetchDashboardData: async () => {
    set({ isLoading: true, error: null })
    try {
      const data = await dashboardService.getDashboardData()
      set({ 
        data, 
        isLoading: false, 
        lastUpdated: new Date(),
        error: null 
      })
    } catch (error: unknown) {
      set({ 
        error: (error as any)?.response?.data?.detail || 'Failed to fetch dashboard data',
        isLoading: false 
      })
    }
  },

  refreshDashboard: async () => {
    const { fetchDashboardData } = get()
    await fetchDashboardData()
  },

  clearError: () => {
    set({ error: null })
  }
}))
