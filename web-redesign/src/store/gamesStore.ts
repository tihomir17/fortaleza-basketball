import { create } from 'zustand'
import type { Game, GameCreate } from '../services/games'
import { gamesService } from '../services/games'
import { mockGames } from '../services/mockData'

interface GamesState {
  games: Game[]
  upcomingGames: Game[]
  recentGames: Game[]
  currentGame: Game | null
  isLoading: boolean
  error: string | null
  
  // Actions
  fetchGames: () => Promise<void>
  fetchUpcomingGames: () => Promise<void>
  fetchRecentGames: () => Promise<void>
  fetchGame: (id: number) => Promise<void>
  createGame: (game: GameCreate) => Promise<void>
  updateGame: (id: number, game: Partial<GameCreate>) => Promise<void>
  deleteGame: (id: number) => Promise<void>
  clearError: () => void
}

export const useGamesStore = create<GamesState>((set) => ({
  games: [],
  upcomingGames: [],
  recentGames: [],
  currentGame: null,
  isLoading: false,
  error: null,

  fetchGames: async () => {
    set({ isLoading: true, error: null })
    try {
      // Use mock data in development mode
      if (import.meta.env.DEV) {
        set({ games: mockGames, isLoading: false })
        return
      }
      const games = await gamesService.getGames()
      set({ games, isLoading: false })
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || 'Failed to fetch games',
        isLoading: false 
      })
    }
  },

  fetchUpcomingGames: async () => {
    set({ isLoading: true, error: null })
    try {
      // Use mock data in development mode
      if (import.meta.env.DEV) {
        const upcomingGames = mockGames.filter(game => game.status === 'SCHEDULED')
        set({ upcomingGames, isLoading: false })
        return
      }
      const upcomingGames = await gamesService.getUpcomingGames()
      set({ upcomingGames, isLoading: false })
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || 'Failed to fetch upcoming games',
        isLoading: false 
      })
    }
  },

  fetchRecentGames: async () => {
    set({ isLoading: true, error: null })
    try {
      // Use mock data in development mode
      if (import.meta.env.DEV) {
        const recentGames = mockGames.filter(game => game.status === 'COMPLETED')
        set({ recentGames, isLoading: false })
        return
      }
      const recentGames = await gamesService.getRecentGames()
      set({ recentGames, isLoading: false })
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || 'Failed to fetch recent games',
        isLoading: false 
      })
    }
  },

  fetchGame: async (id: number) => {
    set({ isLoading: true, error: null })
    try {
      const currentGame = await gamesService.getGame(id)
      set({ currentGame, isLoading: false })
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || 'Failed to fetch game',
        isLoading: false 
      })
    }
  },

  createGame: async (game: GameCreate) => {
    set({ isLoading: true, error: null })
    try {
      const newGame = await gamesService.createGame(game)
      set(state => ({ 
        games: [...state.games, newGame],
        isLoading: false 
      }))
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || 'Failed to create game',
        isLoading: false 
      })
    }
  },

  updateGame: async (id: number, game: Partial<GameCreate>) => {
    set({ isLoading: true, error: null })
    try {
      const updatedGame = await gamesService.updateGame(id, game)
      set(state => ({
        games: state.games.map(g => g.id === id ? updatedGame : g),
        currentGame: state.currentGame?.id === id ? updatedGame : state.currentGame,
        isLoading: false
      }))
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || 'Failed to update game',
        isLoading: false 
      })
    }
  },

  deleteGame: async (id: number) => {
    set({ isLoading: true, error: null })
    try {
      await gamesService.deleteGame(id)
      set(state => ({
        games: state.games.filter(g => g.id !== id),
        currentGame: state.currentGame?.id === id ? null : state.currentGame,
        isLoading: false
      }))
    } catch (error: any) {
      set({ 
        error: error.response?.data?.detail || 'Failed to delete game',
        isLoading: false 
      })
    }
  },

  clearError: () => {
    set({ error: null })
  }
}))
