import { api } from './api'
import { apiWithFallback } from './apiWithFallback'

export interface AnalyticsFilters {
  team_id?: number
  quarter?: number
  last_games?: number
  outcome?: 'W' | 'L'
  home_away?: 'Home' | 'Away'
  opponent?: number
  min_possessions?: number
}

export interface PlayerStats {
  id: number
  username: string
  first_name: string
  last_name: string
  jersey_number: number | null
  role: string
  games_played: number
  possessions: number
  points: number
  assists: number
  rebounds: number
  steals: number
  blocks: number
  turnovers: number
  field_goals_made: number
  field_goals_attempted: number
  three_pointers_made: number
  three_pointers_attempted: number
  free_throws_made: number
  free_throws_attempted: number
  field_goal_percentage: number
  three_point_percentage: number
  free_throw_percentage: number
  points_per_game: number
  assists_per_game: number
  rebounds_per_game: number
  steals_per_game: number
  blocks_per_game: number
  turnovers_per_game: number
  efficiency_rating: number
  plus_minus: number
}

export interface TeamStats {
  team_id: number
  team_name: string
  games_played: number
  wins: number
  losses: number
  win_percentage: number
  points_for: number
  points_against: number
  point_differential: number
  possessions: number
  pace: number
  offensive_efficiency: number
  defensive_efficiency: number
  net_efficiency: number
  field_goal_percentage: number
  three_point_percentage: number
  free_throw_percentage: number
  rebounds: number
  assists: number
  turnovers: number
  steals: number
  blocks: number
}

export interface GameAnalytics {
  game_id: number
  game_date: string
  home_team: string
  away_team: string
  home_score: number
  away_score: number
  outcome: 'W' | 'L'
  possessions: number
  pace: number
  offensive_efficiency: number
  defensive_efficiency: number
  field_goal_percentage: number
  three_point_percentage: number
  free_throw_percentage: number
  rebounds: number
  assists: number
  turnovers: number
  steals: number
  blocks: number
}

// Backend response structure
export interface BackendAnalyticsResponse {
  summary: {
    total_possessions: number
    offensive_possessions: number
    defensive_possessions: number
    total_points: number
    offensive_points: number
    defensive_points: number
    offensive_ppp: number
    defensive_ppp: number
    avg_possession_time: number
    total_ppp: number
    total_games: number
    wins: number
    losses: number
  }
  player_analysis: {
    players: Record<string, {
      player_name: string
      possessions: number
      points: number
      offensive_possessions: number
      defensive_possessions: number
      ppp: number
      offensive_ppp: number
    }>
    min_possessions_threshold: number
  }
  detailed_breakdown: {
    quarter_breakdown: Record<string, {
      possessions: number
      points: number
      ppp: number
    }>
    home_away_breakdown: Record<string, {
      possessions: number
      points: number
      ppp: number
    }>
  }
  filters_applied: {
    team_id: number | null
    quarter_filter: number | null
    last_games: number | null
    outcome_filter: string | null
    home_away_filter: string | null
    opponent_filter: number | null
    total_possessions_analyzed: number
  }
}

export interface ComprehensiveAnalytics {
  team_stats: TeamStats
  player_stats: PlayerStats[]
  game_analytics: GameAnalytics[]
  summary: {
    total_games: number
    total_wins: number
    total_losses: number
    win_percentage: number
    average_points_for: number
    average_points_against: number
    average_point_differential: number
    average_pace: number
    average_offensive_efficiency: number
    average_defensive_efficiency: number
    average_net_efficiency: number
  }
  trends: {
    recent_form: ('W' | 'L')[]
    points_trend: number[]
    efficiency_trend: number[]
    pace_trend: number[]
  }
}

export const analyticsService = {
  async getComprehensiveAnalytics(filters: AnalyticsFilters = {}): Promise<ComprehensiveAnalytics> {
    try {
      console.log('Fetching comprehensive analytics with fallback support...')
      
      const response = await apiWithFallback.getAnalytics(filters)
      console.log('Analytics response:', response)
      
      // If response is already in the correct format (from mock data), return it
      if ((response as any).summary && (response as any).trends && (response as any).team_stats) {
        console.log('✅ Using mock analytics data')
        return response as ComprehensiveAnalytics
      }
      
      // Transform backend response to frontend format
      const backendResponse = response as BackendAnalyticsResponse
      const transformedResponse: ComprehensiveAnalytics = {
        team_stats: {
          team_id: filters.team_id || 0,
          team_name: 'Team', // We'll need to get this from teams endpoint
          games_played: backendResponse.summary.total_games,
          wins: backendResponse.summary.wins,
          losses: backendResponse.summary.losses,
          win_percentage: backendResponse.summary.total_games > 0 ? (backendResponse.summary.wins / backendResponse.summary.total_games) * 100 : 0,
          points_for: backendResponse.summary.offensive_points,
          points_against: backendResponse.summary.defensive_points,
          point_differential: backendResponse.summary.offensive_points - backendResponse.summary.defensive_points,
          possessions: backendResponse.summary.total_possessions,
          pace: backendResponse.summary.avg_possession_time,
          offensive_efficiency: backendResponse.summary.offensive_ppp * 100,
          defensive_efficiency: backendResponse.summary.defensive_ppp * 100,
          net_efficiency: (backendResponse.summary.offensive_ppp - backendResponse.summary.defensive_ppp) * 100,
          field_goal_percentage: 0, // Not available in backend response
          three_point_percentage: 0, // Not available in backend response
          free_throw_percentage: 0, // Not available in backend response
          rebounds: 0, // Not available in backend response
          assists: 0, // Not available in backend response
          turnovers: 0, // Not available in backend response
          steals: 0, // Not available in backend response
          blocks: 0 // Not available in backend response
        },
        player_stats: Object.entries(backendResponse.player_analysis.players).map(([id, player]) => ({
          id: parseInt(id),
          username: player.player_name.toLowerCase().replace(/\s+/g, '.'),
          first_name: player.player_name.split(' ')[0],
          last_name: player.player_name.split(' ').slice(1).join(' '),
          jersey_number: null,
          role: 'PLAYER',
          games_played: 0, // Not available in backend response
          possessions: player.possessions,
          points: player.points,
          assists: 0, // Not available in backend response
          rebounds: 0, // Not available in backend response
          steals: 0, // Not available in backend response
          blocks: 0, // Not available in backend response
          turnovers: 0, // Not available in backend response
          field_goals_made: 0, // Not available in backend response
          field_goals_attempted: 0, // Not available in backend response
          three_pointers_made: 0, // Not available in backend response
          three_pointers_attempted: 0, // Not available in backend response
          free_throws_made: 0, // Not available in backend response
          free_throws_attempted: 0, // Not available in backend response
          field_goal_percentage: 0, // Not available in backend response
          three_point_percentage: 0, // Not available in backend response
          free_throw_percentage: 0, // Not available in backend response
          points_per_game: player.possessions > 0 ? player.points / player.possessions : 0,
          assists_per_game: 0, // Not available in backend response
          rebounds_per_game: 0, // Not available in backend response
          steals_per_game: 0, // Not available in backend response
          blocks_per_game: 0, // Not available in backend response
          turnovers_per_game: 0, // Not available in backend response
          efficiency_rating: player.ppp * 100,
          plus_minus: 0 // Not available in backend response
        })),
        game_analytics: [], // Not available in backend response
        summary: {
          total_games: backendResponse.summary.total_games,
          total_wins: backendResponse.summary.wins,
          total_losses: backendResponse.summary.losses,
          win_percentage: backendResponse.summary.total_games > 0 ? (backendResponse.summary.wins / backendResponse.summary.total_games) * 100 : 0,
          average_points_for: backendResponse.summary.total_games > 0 ? backendResponse.summary.offensive_points / backendResponse.summary.total_games : 0,
          average_points_against: backendResponse.summary.total_games > 0 ? backendResponse.summary.defensive_points / backendResponse.summary.total_games : 0,
          average_point_differential: backendResponse.summary.total_games > 0 ? (backendResponse.summary.offensive_points - backendResponse.summary.defensive_points) / backendResponse.summary.total_games : 0,
          average_pace: backendResponse.summary.avg_possession_time,
          average_offensive_efficiency: backendResponse.summary.offensive_ppp * 100,
          average_defensive_efficiency: backendResponse.summary.defensive_ppp * 100,
          average_net_efficiency: (backendResponse.summary.offensive_ppp - backendResponse.summary.defensive_ppp) * 100
        },
        trends: {
          recent_form: [], // Not available in backend response
          points_trend: [], // Not available in backend response
          efficiency_trend: [], // Not available in backend response
          pace_trend: [] // Not available in backend response
        }
      }
      
      return transformedResponse
    } catch (error: any) {
      console.error('Failed to fetch comprehensive analytics, using mock data:', error)
      console.error('Error response:', error.response)
      console.error('Error status:', error.response?.status)
      console.error('Error data:', error.response?.data)
      
      // Always return mock data as fallback
      const { mockAnalyticsData } = await import('./mockData')
      console.log('✅ Falling back to mock analytics data')
      return mockAnalyticsData as ComprehensiveAnalytics
    }
  },

  async getPlayerStats(gameId: number): Promise<PlayerStats[]> {
    try {
      console.log(`Fetching player stats for game ${gameId}`)
      const response = await api.get<PlayerStats[]>(`/games/${gameId}/player-stats/`)
      console.log('Player stats response:', response)
      return response
    } catch (error: any) {
      console.error(`Failed to fetch player stats for game ${gameId}:`, error)
      throw error
    }
  },

  async exportAnalyticsPDF(filters: AnalyticsFilters = {}): Promise<Blob> {
    try {
      console.log('Exporting analytics to PDF with filters:', filters)
      
      const params = new URLSearchParams()
      Object.entries(filters).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          params.append(key, value.toString())
        }
      })
      
      const response = await api.get(`/games/export_analytics_pdf/?${params.toString()}`, {
        responseType: 'blob'
      })
      
      console.log('PDF export response:', response)
      return response as Blob
    } catch (error: any) {
      console.error('Failed to export analytics PDF:', error)
      throw error
    }
  }
}
