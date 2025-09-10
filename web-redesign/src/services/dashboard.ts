import api from './api'

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
      console.log('Fetching dashboard data from /games/dashboard_data/')
      const response = await api.get('/games/dashboard_data/')
      console.log('Dashboard response:', response)
      
      // Transform backend data to match frontend interface
      const backendData = response as any
      
      return {
        quickStats: {
          totalGames: backendData.quick_stats?.total_games || 0,
          wins: 0, // Calculate from recent games
          losses: 0, // Calculate from recent games
          winPercentage: 0, // Calculate from wins/losses
          upcomingGames: backendData.upcoming_games?.length || 0,
          activePlayers: 0 // Not available in backend response
        },
        upcomingGames: (backendData.upcoming_games || []).map((game: any) => ({
          id: game.id,
          home_team_name: game.home_team,
          away_team_name: game.away_team,
          date: new Date(game.game_date).toLocaleDateString(),
          time: new Date(game.game_date).toLocaleTimeString(),
          venue: 'Home Court' // Default venue
        })),
        recentGames: (backendData.recent_games || []).map((game: any) => ({
          id: game.id,
          home_team_name: game.home_team,
          away_team_name: game.away_team,
          home_score: game.home_team_score,
          away_score: game.away_team_score,
          date: new Date(game.game_date).toLocaleDateString(),
          result: game.home_team_score > game.away_team_score ? 'W' : 'L'
        })),
        topPerformers: [], // Not available in backend response
        recentActivity: [], // Not available in backend response
        lastUpdated: new Date().toISOString()
      }
    } catch (error) {
      console.error('Failed to fetch dashboard data:', error)
      throw error
    }
  },

  async getQuickStats(): Promise<DashboardData['quickStats']> {
    try {
      const response = await api.get('/games/dashboard_data/')
      const backendData = response as any
      return {
        totalGames: backendData.quick_stats?.total_games || 0,
        wins: 0, // Calculate from recent games
        losses: 0, // Calculate from recent games
        winPercentage: 0, // Calculate from wins/losses
        upcomingGames: backendData.upcoming_games?.length || 0,
        activePlayers: 0 // Not available in backend response
      }
    } catch (error) {
      console.error('Failed to fetch quick stats:', error)
      throw error
    }
  },

  async getUpcomingGames(): Promise<DashboardData['upcomingGames']> {
    try {
      const response = await api.get('/games/dashboard_data/')
      const backendData = response as any
      return (backendData.upcoming_games || []).map((game: any) => ({
        id: game.id,
        home_team_name: game.home_team,
        away_team_name: game.away_team,
        date: new Date(game.game_date).toLocaleDateString(),
        time: new Date(game.game_date).toLocaleTimeString(),
        venue: 'Home Court' // Default venue
      }))
    } catch (error) {
      console.error('Failed to fetch upcoming games:', error)
      throw error
    }
  },

  async getRecentGames(): Promise<DashboardData['recentGames']> {
    try {
      const response = await api.get('/games/dashboard_data/')
      const backendData = response as any
      return (backendData.recent_games || []).map((game: any) => ({
        id: game.id,
        home_team_name: game.home_team,
        away_team_name: game.away_team,
        home_score: game.home_team_score,
        away_score: game.away_team_score,
        date: new Date(game.game_date).toLocaleDateString(),
        result: game.home_team_score > game.away_team_score ? 'W' : 'L'
      }))
    } catch (error) {
      console.error('Failed to fetch recent games:', error)
      throw error
    }
  },

  async getTopPerformers(): Promise<DashboardData['topPerformers']> {
    // Top performers data not available in backend yet
    return []
  },

  async getRecentActivity(): Promise<DashboardData['recentActivity']> {
    // Recent activity data not available in backend yet
    return []
  }
}
