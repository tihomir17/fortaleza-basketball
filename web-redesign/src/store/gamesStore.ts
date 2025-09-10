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
      // Use mocks only if explicitly enabled
      console.info('[gamesStore] fetchGames VITE_USE_MOCKS=', import.meta.env.VITE_USE_MOCKS, 'API_BASE=', import.meta.env.VITE_API_BASE_URL)
      if (import.meta.env.VITE_USE_MOCKS === 'true') {
        set({ games: mockGames, isLoading: false })
        console.info('[gamesStore] using mockGames count=', mockGames.length)
        return
      }
      const games = await gamesService.getGames()
      console.info('[gamesStore] fetched games from API count=', (games as any)?.length ?? 'unknown', games)
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
      console.info('[gamesStore] fetchUpcomingGames VITE_USE_MOCKS=', import.meta.env.VITE_USE_MOCKS)
      if (import.meta.env.VITE_USE_MOCKS === 'true') {
        const upcomingGames = mockGames.filter(game => game.status === 'SCHEDULED')
        set({ upcomingGames, isLoading: false })
        console.info('[gamesStore] using mock upcomingGames count=', upcomingGames.length)
        return
      }
      const upcomingGames = await gamesService.getUpcomingGames()
      console.info('[gamesStore] fetched upcomingGames from API count=', (upcomingGames as any)?.length ?? 'unknown')
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
      console.info('[gamesStore] fetchRecentGames VITE_USE_MOCKS=', import.meta.env.VITE_USE_MOCKS)
      if (import.meta.env.VITE_USE_MOCKS === 'true') {
        const recentGames = mockGames.filter(game => game.status === 'COMPLETED')
        set({ recentGames, isLoading: false })
        console.info('[gamesStore] using mock recentGames count=', recentGames.length)
        return
      }
      const recentGames = await gamesService.getRecentGames()
      console.info('[gamesStore] fetched recentGames from API count=', (recentGames as any)?.length ?? 'unknown')
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
