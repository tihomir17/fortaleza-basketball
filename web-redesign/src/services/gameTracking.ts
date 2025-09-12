import { api } from './api'

export interface Possession {
  id: number
  game: number
  team: {
    id: number
    team: {
      id: number
      name: string
    }
  }
  opponent: {
    id: number
    team: {
      id: number
      name: string
    }
  }
  quarter: number
  start_time_in_game: string
  duration_seconds: number
  outcome: string
  points_scored: number
  is_offensive_rebound: boolean
  offensive_rebound_count: number
  players_on_court: Array<{
    id: number
    first_name: string
    last_name: string
    jersey_number: number
    position: string
  }>
  defensive_players_on_court: Array<{
    id: number
    first_name: string
    last_name: string
    jersey_number: number
    position: string
  }>
  offensive_rebound_players: Array<{
    id: number
    first_name: string
    last_name: string
    jersey_number: number
    position: string
  }>
  offensive_set?: string
  defensive_set?: string
  offensive_sequence?: string
  defensive_sequence?: string
  scorer?: {
    id: number
    first_name: string
    last_name: string
    jersey_number: number
    position: string
  }
  assisted_by?: {
    id: number
    first_name: string
    last_name: string
    jersey_number: number
    position: string
  }
  blocked_by?: {
    id: number
    first_name: string
    last_name: string
    jersey_number: number
    position: string
  }
  stolen_by?: {
    id: number
    first_name: string
    last_name: string
    jersey_number: number
    position: string
  }
  fouled_by?: {
    id: number
    first_name: string
    last_name: string
    jersey_number: number
    position: string
  }
  created_at: string
  updated_at: string
}

export interface Game {
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

export interface PossessionCreate {
  game_id: number
  team_id: number
  opponent_id?: number
  quarter: number
  start_time_in_game: string
  duration_seconds: number
  outcome: string
  points_scored?: number
  is_offensive_rebound?: boolean
  offensive_rebound_count?: number
  players_on_court?: number[]
  defensive_players_on_court?: number[]
  offensive_rebound_players?: number[]
  offensive_set?: string
  defensive_set?: string
  offensive_sequence?: string
  defensive_sequence?: string
  scorer_id?: number
  assisted_by_id?: number
  blocked_by_id?: number
  stolen_by_id?: number
  fouled_by_id?: number
}

export interface PossessionUpdate extends Partial<PossessionCreate> {
  id: number
}

export interface PaginatedPossessions {
  count: number
  next?: string
  previous?: string
  results: Possession[]
  page: number
  page_size: number
}

export interface GamePlayerStats {
  player: {
    id: number
    first_name: string
    last_name: string
    jersey_number: number
    position: string
  }
  stats: {
    total_points: number
    field_goals_made: number
    field_goals_attempted: number
    three_pointers_made: number
    three_pointers_attempted: number
    free_throws_made: number
    free_throws_attempted: number
    field_goal_percentage: number
    three_point_percentage: number
    free_throw_percentage: number
  }
}

export interface GameStats {
  game: {
    id: number
    home_team: string
    away_team: string
    home_team_score: number
    away_team_score: number
  }
  home_team_player_stats: GamePlayerStats[]
  away_team_player_stats: GamePlayerStats[]
}

class GameTrackingService {
  // Get all games for a team (for game selection)
  async getTeamGames(teamId: number): Promise<Game[]> {
    // Use the calendar endpoint which supports team filtering
    const response = await api.get(`/games/calendar-data/?team_id=${teamId}`)
    
    console.log('🎮 Game Tracking Service: API response:', response)
    
    // Check if response exists and has games property
    if (!response) {
      console.error('🎮 Game Tracking Service: No response from API')
      return []
    }
    
    if (!(response as any).games) {
      console.error('🎮 Game Tracking Service: No games property in response:', response)
      return []
    }
    
    return (response as any).games || []
  }

  // Get a specific game
  async getGame(gameId: number): Promise<Game> {
    console.log('🌐 Service: Making API call to get game', gameId)
    console.log('🌐 Service: URL:', `/games/${gameId}/`)
    const token = localStorage.getItem('auth_token')
    console.log('🌐 Service: Auth token:', token ? 'Present' : 'Missing')
    if (token) {
      console.log('🌐 Service: Token preview:', token.substring(0, 50) + '...')
    }
    const response = await api.get(`/games/${gameId}/`)
    console.log('🌐 Service: API response successful')
    console.log('🌐 Service: Response data:', response)
    return response as Game
  }

  // Get paginated possessions for a game
  async getGamePossessions(
    gameId: number, 
    page: number = 1, 
    pageSize: number = 20
  ): Promise<PaginatedPossessions> {
    const response = await api.get(
      `/games/${gameId}/possessions/?page=${page}&page_size=${pageSize}`
    )
    console.log('🎮 Game Tracking Service: Possessions response:', response)
    return response as PaginatedPossessions
  }

  // Get all possessions for a game (for complete game analysis)
  async getAllGamePossessions(gameId: number): Promise<Possession[]> {
    const allPossessions: Possession[] = []
    let page = 1
    let hasMore = true

    while (hasMore) {
      const response = await this.getGamePossessions(gameId, page, 50) // Larger page size for efficiency
      allPossessions.push(...response.results)
      hasMore = !!response.next
      page++
    }

    return allPossessions
  }

  // Create a new possession
  async createPossession(possessionData: PossessionCreate): Promise<Possession> {
    const response = await api.post('/possessions/', possessionData)
    return response as Possession
  }

  // Update a possession
  async updatePossession(possessionData: PossessionUpdate): Promise<Possession> {
    const { id, ...updateData } = possessionData
    const response = await api.patch(`/possessions/${id}/`, updateData)
    return response as Possession
  }

  // Delete a possession
  async deletePossession(possessionId: number): Promise<void> {
    await api.delete(`/possessions/${possessionId}/`)
  }

  // Get player stats for a specific game
  async getGamePlayerStats(gameId: number): Promise<GameStats> {
    const response = await api.get(`/games/${gameId}/player-stats/`)
    return response as GameStats
  }

  // Get team stats for a specific game
  async getGameTeamStats(gameId: number, teamId: number): Promise<any> {
    const response = await api.get(`/possessions/quarter_stats/?team_id=${teamId}&game_id=${gameId}`)
    return response as any
  }

  // Get comprehensive game analytics
  async getGameAnalytics(gameId: number, teamId: number): Promise<any> {
    const response = await api.get(`/games/comprehensive_analytics/?team_id=${teamId}&game_id=${gameId}`)
    return response as any
  }
}

export const gameTrackingService = new GameTrackingService()
