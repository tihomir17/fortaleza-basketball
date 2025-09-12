import { create } from 'zustand'
import { gameTrackingService, type Game, type Possession, type PaginatedPossessions, type GameStats } from '../services/gameTracking'

interface GameTrackingState {
  // Current game state
  currentGame: Game | null
  selectedGameId: number | null
  
  // Possessions data
  possessions: Possession[]
  paginatedPossessions: PaginatedPossessions | null
  isLoadingPossessions: boolean
  possessionsError: string | null
  
  // Games list for selection
  availableGames: Game[]
  isLoadingGames: boolean
  gamesError: string | null
  
  // Game stats
  gameStats: GameStats | null
  isLoadingStats: boolean
  statsError: string | null
  
  // Pagination
  currentPage: number
  pageSize: number
  hasMorePossessions: boolean
  
  // Actions
  setCurrentGame: (game: Game | null) => void
  setSelectedGameId: (gameId: number | null) => void
  
  // Games management
  fetchAvailableGames: (teamId: number) => Promise<void>
  selectGame: (gameId: number) => Promise<void>
  
  // Possessions management
  fetchGamePossessions: (gameId: number, page?: number, pageSize?: number) => Promise<void>
  loadMorePossessions: () => Promise<void>
  refreshPossessions: () => Promise<void>
  
  // Possession CRUD
  createPossession: (possessionData: any) => Promise<Possession | null>
  updatePossession: (possessionData: any) => Promise<Possession | null>
  deletePossession: (possessionId: number) => Promise<boolean>
  
  // Stats management
  fetchGameStats: (gameId: number) => Promise<void>
  
  // Utility actions
  clearGameData: () => void
  resetPagination: () => void
}

export const useGameTrackingStore = create<GameTrackingState>((set, get) => ({
  // Initial state
  currentGame: null,
  selectedGameId: null,
  possessions: [],
  paginatedPossessions: null,
  isLoadingPossessions: false,
  possessionsError: null,
  availableGames: [],
  isLoadingGames: false,
  gamesError: null,
  gameStats: null,
  isLoadingStats: false,
  statsError: null,
  currentPage: 1,
  pageSize: 20,
  hasMorePossessions: false,

  // Actions
  setCurrentGame: (game) => set({ currentGame: game }),
  setSelectedGameId: (gameId) => set({ selectedGameId: gameId }),

  // Fetch available games for a team
  fetchAvailableGames: async (teamId: number) => {
    set({ isLoadingGames: true, gamesError: null })
    try {
      const games = await gameTrackingService.getTeamGames(teamId)
      set({ 
        availableGames: games, 
        isLoadingGames: false 
      })
    } catch (error: any) {
      set({ 
        gamesError: error.message || 'Failed to fetch games',
        isLoadingGames: false 
      })
    }
  },

  // Select a game and load its data
  selectGame: async (gameId: number) => {
    set({ selectedGameId: gameId, isLoadingPossessions: true, possessionsError: null })
    try {
      // Fetch game details
      const game = await gameTrackingService.getGame(gameId)
      set({ currentGame: game })
      
      // Reset pagination and fetch first page of possessions
      set({ currentPage: 1, possessions: [] })
      await get().fetchGamePossessions(gameId, 1, get().pageSize)
      
      // Fetch game stats
      await get().fetchGameStats(gameId)
    } catch (error: any) {
      console.error('Error selecting game:', error)
      set({ 
        possessionsError: error.message || 'Failed to load game data',
        isLoadingPossessions: false 
      })
    }
  },

  // Fetch possessions for a game with pagination
  fetchGamePossessions: async (gameId: number, page: number = 1, pageSize: number = 20) => {
    set({ isLoadingPossessions: true, possessionsError: null })
    try {
      const response = await gameTrackingService.getGamePossessions(gameId, page, pageSize)
      
      set(state => ({
        paginatedPossessions: response,
        possessions: page === 1 ? response.results : [...state.possessions, ...response.results],
        currentPage: page,
        pageSize: pageSize,
        hasMorePossessions: !!response.next,
        isLoadingPossessions: false
      }))
    } catch (error: any) {
      set({ 
        possessionsError: error.message || 'Failed to fetch possessions',
        isLoadingPossessions: false 
      })
    }
  },

  // Load more possessions (pagination)
  loadMorePossessions: async () => {
    const { selectedGameId, currentPage, pageSize, hasMorePossessions } = get()
    
    if (!selectedGameId || !hasMorePossessions) return
    
    const nextPage = currentPage + 1
    await get().fetchGamePossessions(selectedGameId, nextPage, pageSize)
  },

  // Refresh possessions (reload from beginning)
  refreshPossessions: async () => {
    const { selectedGameId, pageSize } = get()
    if (!selectedGameId) return
    
    set({ currentPage: 1, possessions: [] })
    await get().fetchGamePossessions(selectedGameId, 1, pageSize)
  },

  // Create a new possession
  createPossession: async (possessionData: any) => {
    try {
      const newPossession = await gameTrackingService.createPossession(possessionData)
      
      // Add to the beginning of the list (most recent first)
      set(state => ({
        possessions: [newPossession, ...state.possessions]
      }))
      
      return newPossession
    } catch (error: any) {
      console.error('Failed to create possession:', error)
      return null
    }
  },

  // Update a possession
  updatePossession: async (possessionData: any) => {
    try {
      const updatedPossession = await gameTrackingService.updatePossession(possessionData)
      
      // Update in the list
      set(state => ({
        possessions: state.possessions.map(p => 
          p.id === updatedPossession.id ? updatedPossession : p
        )
      }))
      
      return updatedPossession
    } catch (error: any) {
      console.error('Failed to update possession:', error)
      return null
    }
  },

  // Delete a possession
  deletePossession: async (possessionId: number) => {
    try {
      await gameTrackingService.deletePossession(possessionId)
      
      // Remove from the list
      set(state => ({
        possessions: state.possessions.filter(p => p.id !== possessionId)
      }))
      
      return true
    } catch (error: any) {
      console.error('Failed to delete possession:', error)
      return false
    }
  },

  // Fetch game stats
  fetchGameStats: async (gameId: number) => {
    set({ isLoadingStats: true, statsError: null })
    try {
      const stats = await gameTrackingService.getGamePlayerStats(gameId)
      set({ 
        gameStats: stats, 
        isLoadingStats: false 
      })
    } catch (error: any) {
      set({ 
        statsError: error.message || 'Failed to fetch game stats',
        isLoadingStats: false 
      })
    }
  },

  // Clear all game data
  clearGameData: () => set({
    currentGame: null,
    selectedGameId: null,
    possessions: [],
    paginatedPossessions: null,
    gameStats: null,
    possessionsError: null,
    statsError: null,
    currentPage: 1,
    hasMorePossessions: false
  }),

  // Reset pagination
  resetPagination: () => set({
    currentPage: 1,
    hasMorePossessions: false,
    possessions: []
  })
}))
