import api from './api'
import { mockDashboardData } from './mockData'

export interface DashboardData {
  quickStats: {
    totalGames: number
    wins: number
    losses: number
    winPercentage: number
    upcomingGames: number
    activePlayers: number
  }
  upcomingGames: Array<{
    id: number
    home_team_name: string
    away_team_name: string
    date: string
    time: string
    venue: string
  }>
  recentGames: Array<{
    id: number
    home_team_name: string
    away_team_name: string
    home_score: number
    away_score: number
    date: string
    result: 'W' | 'L'
  }>
  topPerformers: Array<{
    player_name: string
    jersey_number: number
    points_per_game: number
    rebounds_per_game: number
    assists_per_game: number
  }>
  recentActivity: Array<{
    id: number
    type: 'GAME' | 'PLAYER' | 'TEAM' | 'SCOUTING'
    message: string
    timestamp: string
  }>
  lastUpdated?: string
}

export const dashboardService = {
  async getDashboardData(): Promise<DashboardData> {
    try {
      const response = await api.get('/dashboard/')
      return (response as any).data
    } catch {
      console.log('Using mock data for dashboard')
      return mockDashboardData
    }
  },

  async getQuickStats(): Promise<DashboardData['quickStats']> {
    try {
      const response = await api.get('/dashboard/quick-stats/')
      return (response as any).data
    } catch {
      console.log('Using mock data for quick stats')
      return mockDashboardData.quickStats
    }
  },

  async getUpcomingGames(): Promise<DashboardData['upcomingGames']> {
    try {
      const response = await api.get('/dashboard/upcoming-games/')
      return (response as any).data
    } catch {
      console.log('Using mock data for upcoming games')
      return mockDashboardData.upcomingGames
    }
  },

  async getRecentGames(): Promise<DashboardData['recentGames']> {
    try {
      const response = await api.get('/dashboard/recent-games/')
      return (response as any).data
    } catch {
      console.log('Using mock data for recent games')
      return mockDashboardData.recentGames
    }
  },

  async getTopPerformers(): Promise<DashboardData['topPerformers']> {
    try {
      const response = await api.get('/dashboard/top-performers/')
      return (response as any).data
    } catch {
      console.log('Using mock data for top performers')
      return mockDashboardData.topPerformers
    }
  },

  async getRecentActivity(): Promise<DashboardData['recentActivity']> {
    try {
      const response = await api.get('/dashboard/recent-activity/')
      return (response as any).data
    } catch {
      console.log('Using mock data for recent activity')
      return mockDashboardData.recentActivity
    }
  }
}
