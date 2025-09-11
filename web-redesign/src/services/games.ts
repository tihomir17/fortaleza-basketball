import api from './api'

// Alias for backward compatibility
export type Game = GameDetails

export interface GameCreate {
  home_team: number
  away_team: number
  competition: number
  game_date: string
  home_team_score?: number
  away_team_score?: number
  quarter?: number
}

export interface GameDetails {
  id: number
  home_team: {
    id: number
    name: string
  }
  away_team: {
    id: number
    name: string
  }
  competition: {
    id: number
    name: string
  }
  game_date: string
  home_team_score?: number
  away_team_score?: number
  quarter?: number
  created_by?: number
  created_at: string
  updated_at: string
}

export interface PlayerStats {
  id: number
  username: string
  first_name: string
  last_name: string
  jersey_number?: number
  position?: string
  points: number
  rebounds: number
  assists: number
  steals: number
  blocks: number
  turnovers: number
  field_goals_made: number
  field_goals_attempted: number
  three_pointers_made: number
  three_pointers_attempted: number
  free_throws_made: number
  free_throws_attempted: number
  minutes_played: number
}

export interface TeamStats {
  team: {
    id: number
    name: string
  }
  points: number
  rebounds: number
  assists: number
  steals: number
  blocks: number
  turnovers: number
  field_goals_made: number
  field_goals_attempted: number
  three_pointers_made: number
  three_pointers_attempted: number
  free_throws_made: number
  free_throws_attempted: number
  total_possessions: number
  offensive_possessions: number
  defensive_possessions: number
  avg_offensive_possession_time: number
}

export interface GameAnalytics {
  summary: {
    total_possessions: number
    total_points: number
    offensive_ppp: number
    defensive_ppp: number
    avg_possession_time: number
  }
  offensive_analysis: any
  defensive_analysis: any
  player_analysis: any
  detailed_breakdown: any
}

export interface PostGameReport {
  game: GameDetails
  team_stats: TeamStats
  player_stats: PlayerStats[]
  analytics: GameAnalytics
}

export const gamesService = {
  // Get game details
  async getGame(gameId: number): Promise<GameDetails> {
    try {
      const response = await api.get<GameDetails>(`/games/${gameId}/`)
      return response
    } catch (error: any) {
      console.error('Error fetching game:', error)
      throw error
    }
  },

  // Get post-game report for a specific team
  async getPostGameReport(gameId: number, teamId: number): Promise<PostGameReport> {
    try {
      const response = await api.get<PostGameReport>(`/games/${gameId}/post-game-report/?team_id=${teamId}`)
      return response
    } catch (error: any) {
      console.error('Error fetching post-game report:', error)
      throw error
    }
  },

  // Get player stats for a specific game and team
  async getPlayerStats(gameId: number, teamId: number): Promise<{ players: PlayerStats[] }> {
    try {
      const response = await api.get<{ players: PlayerStats[] }>(`/games/${gameId}/player-stats/?team_id=${teamId}`)
      return response
    } catch (error: any) {
      console.error('Error fetching player stats:', error)
      throw error
    }
  },

  // Get comprehensive analytics
  async getComprehensiveAnalytics(params?: {
    team_id?: number
    quarter?: number
    last_games?: number
    outcome?: string
    home_away?: string
    opponent?: number
    min_possessions?: number
  }): Promise<GameAnalytics> {
    try {
      const response = await api.get<GameAnalytics>('/games/comprehensive_analytics/', { params })
      return response
    } catch (error: any) {
      console.error('Error fetching comprehensive analytics:', error)
      throw error
    }
  },

  // Get all games with basic info
  async getGames(params?: {
    home_team?: number
    away_team?: number
    game_date__gte?: string
    game_date__lte?: string
    competition?: number
  }): Promise<{ results: GameDetails[]; count: number }> {
    try {
      const response = await api.get<{ results: GameDetails[]; count: number }>('/games/', { params })
      return response
    } catch (error: any) {
      console.error('Error fetching games:', error)
      throw error
    }
  },

  // Get upcoming games
  async getUpcomingGames(): Promise<GameDetails[]> {
    try {
      const now = new Date().toISOString()
      const response = await this.getGames({ game_date__gte: now })
      return response.results
    } catch (error: any) {
      console.error('Error fetching upcoming games:', error)
      throw error
    }
  },

  // Get recent games
  async getRecentGames(): Promise<GameDetails[]> {
    try {
      const now = new Date().toISOString()
      const response = await this.getGames({ game_date__lte: now })
      return response.results.slice(0, 10) // Get last 10 games
    } catch (error: any) {
      console.error('Error fetching recent games:', error)
      throw error
    }
  },

  // Create a new game
  async createGame(game: GameCreate): Promise<GameDetails> {
    try {
      const response = await api.post<GameDetails>('/games/', game)
      return response
    } catch (error: any) {
      console.error('Error creating game:', error)
      throw error
    }
  },

  // Update a game
  async updateGame(id: number, game: Partial<GameCreate>): Promise<GameDetails> {
    try {
      const response = await api.patch<GameDetails>(`/games/${id}/`, game)
      return response
    } catch (error: any) {
      console.error('Error updating game:', error)
      throw error
    }
  },

  // Delete a game
  async deleteGame(id: number): Promise<void> {
    try {
      await api.delete(`/games/${id}/`)
    } catch (error: any) {
      console.error('Error deleting game:', error)
      throw error
    }
  }
}