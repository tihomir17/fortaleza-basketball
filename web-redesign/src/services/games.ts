import api from './api'
import { mockGames } from './mockData'

export interface Game {
  id: number
  home_team: number
  away_team: number
  home_team_name: string
  away_team_name: string
  date: string
  time: string
  venue: string
  status: 'SCHEDULED' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED'
  home_score?: number
  away_score?: number
  season: number
  competition: number
}

export interface GameCreate {
  home_team: number
  away_team: number
  date: string
  time: string
  venue: string
  season: number
  competition: number
}

export const gamesService = {
  async getGames(): Promise<Game[]> {
    try {
      const response = await api.get('/games/')
      return (response as any).data
    } catch {
      console.log('Using mock data for games')
      return mockGames
    }
  },

  async getGame(id: number): Promise<Game> {
    try {
      const response = await api.get(`/games/${id}/`)
      return (response as any).data
    } catch {
      console.log('Using mock data for game')
      const game = mockGames.find(g => g.id === id)
      if (!game) throw new Error('Game not found')
      return game
    }
  },

  async createGame(game: GameCreate): Promise<Game> {
    try {
      const response = await api.post('/games/', game)
      return (response as any).data
    } catch {
      console.log('Mock: Game created')
      const newGame: Game = {
        id: Date.now(),
        ...game,
        home_team_name: 'Home Team',
        away_team_name: 'Away Team',
        status: 'SCHEDULED'
      }
      return newGame
    }
  },

  async updateGame(id: number, game: Partial<GameCreate>): Promise<Game> {
    try {
      const response = await api.patch(`/games/${id}/`, game)
      return (response as any).data
    } catch {
      console.log('Mock: Game updated')
      const existingGame = mockGames.find(g => g.id === id)
      if (!existingGame) throw new Error('Game not found')
      return { ...existingGame, ...game }
    }
  },

  async deleteGame(id: number): Promise<void> {
    try {
      await api.delete(`/games/${id}/`)
    } catch {
      console.log('Mock: Game deleted')
    }
  },

  async getUpcomingGames(): Promise<Game[]> {
    try {
      const response = await api.get('/games/upcoming/')
      return (response as any).data
    } catch {
      console.log('Using mock data for upcoming games')
      return mockGames.filter(g => g.status === 'SCHEDULED')
    }
  },

  async getRecentGames(): Promise<Game[]> {
    try {
      const response = await api.get('/games/recent/')
      return (response as any).data
    } catch {
      console.log('Using mock data for recent games')
      return mockGames.filter(g => g.status === 'COMPLETED')
    }
  }
}
