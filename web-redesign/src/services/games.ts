import api from './api'
import { apiWithFallback } from './apiWithFallback'

export interface Team {
  id: number
  name: string
  logo_url?: string
}

export interface Game {
  id: number
  competition: number
  home_team: Team
  away_team: Team
  game_date: string
  home_team_score: number
  away_team_score: number
  quarter: number
  lead_changes: number
  is_close_game: boolean
  is_blowout: boolean
  clutch_situations: number
  created_by?: number
  created_at: string
  updated_at: string
  total_possessions?: number
  offensive_possessions?: number
  defensive_possessions?: number
  avg_offensive_possession_time?: number
}

export interface GameCreate {
  home_team: number
  away_team: number
  competition: number
  game_date: string
}

export const gamesService = {
  async getGames(): Promise<Game[]> {
    try {
      console.log('Fetching all games with fallback support...')
      const response = await apiWithFallback.getGames()
      console.log('Games response:', response)
      
      // If response is already an array (from mock data), return it
      if (Array.isArray(response)) {
        return response as Game[]
      }
      
      // Transform backend response format
      return (response as any).results || []
    } catch (error) {
      console.error('Failed to fetch games:', error)
      throw error
    }
  },

  async getGame(id: number): Promise<Game> {
    try {
      const response = await api.get<Game>(`/games/${id}/`)
      return response
    } catch (error) {
      console.error('Failed to fetch game:', error)
      throw error
    }
  },

  async createGame(game: GameCreate): Promise<Game> {
    try {
      const response = await api.post<Game>('/games/', game)
      return response
    } catch (error) {
      console.error('Failed to create game:', error)
      throw error
    }
  },

  async updateGame(id: number, game: Partial<GameCreate>): Promise<Game> {
    try {
      const response = await api.patch<Game>(`/games/${id}/`, game)
      return response
    } catch (error) {
      console.error('Failed to update game:', error)
      throw error
    }
  },

  async deleteGame(id: number): Promise<void> {
    try {
      await api.delete(`/games/${id}/`)
    } catch (error) {
      console.error('Failed to delete game:', error)
      throw error
    }
  },

  async getUpcomingGames(): Promise<Game[]> {
    try {
      console.log('Fetching upcoming games with fallback support...')
      const response = await apiWithFallback.getUpcomingGames()
      console.log('Upcoming games response:', response)
      
      // If response is already an array (from mock data), return it
      if (Array.isArray(response)) {
        return response as Game[]
      }
      
      // Filter for upcoming games (game_date > now)
      const now = new Date()
      const upcomingGames = (response as any).results?.filter((game: Game) => new Date(game.game_date) > now) || []
      console.log('Upcoming games found:', upcomingGames.length)
      return upcomingGames
    } catch (error) {
      console.error('Failed to fetch upcoming games:', error)
      throw error
    }
  },

  async getRecentGames(): Promise<Game[]> {
    try {
      console.log('Fetching recent games with fallback support...')
      const response = await apiWithFallback.getRecentGames()
      console.log('Recent games response:', response)
      
      // If response is already an array (from mock data), return it
      if (Array.isArray(response)) {
        return response as Game[]
      }
      
      // Filter for recent games (game_date < now and has scores)
      const now = new Date()
      const recentGames = (response as any).results?.filter((game: Game) => {
        const gameDate = new Date(game.game_date)
        return gameDate < now && (game.home_team_score > 0 || game.away_team_score > 0)
      }) || []
      console.log('Recent games found:', recentGames.length)
      return recentGames
    } catch (error) {
      console.error('Failed to fetch recent games:', error)
      throw error
    }
  }
}
