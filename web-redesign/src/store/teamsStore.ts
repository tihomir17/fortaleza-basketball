import { create } from 'zustand'
import type { Team, Player } from '../services/teams'
import { teamsService } from '../services/teams'
import { mockTeams, mockPlayers } from '../services/mockData'

interface TeamsState {
  teams: Team[]
  currentTeam: Team | null
  players: Player[]
  isLoading: boolean
  error: string | null
  
  // Actions
  fetchTeams: () => Promise<void>
  fetchTeam: (id: number) => Promise<void>
  fetchPlayers: (teamId: number) => Promise<void>
  createTeam: (team: Partial<Team>) => Promise<void>
  updateTeam: (id: number, team: Partial<Team>) => Promise<void>
  deleteTeam: (id: number) => Promise<void>
  addPlayer: (teamId: number, player: Partial<Player>) => Promise<void>
  updatePlayer: (playerId: number, player: Partial<Player>) => Promise<void>
  deletePlayer: (playerId: number) => Promise<void>
  clearError: () => void
}

export const useTeamsStore = create<TeamsState>((set) => ({
  teams: [],
  currentTeam: null,
  players: [],
  isLoading: false,
  error: null,

  fetchTeams: async () => {
    set({ isLoading: true, error: null })
    try {
      // Use mock data in development mode
      if (import.meta.env.DEV) {
        set({ teams: mockTeams, isLoading: false })
        return
      }
      const teams = await teamsService.getTeams()
      set({ teams, isLoading: false })
    } catch (error: unknown) {
      set({ 
        error: (error as any)?.response?.data?.detail || 'Failed to fetch teams',
        isLoading: false 
      })
    }
  },

  fetchTeam: async (id: number) => {
    set({ isLoading: true, error: null })
    try {
      const currentTeam = await teamsService.getTeam(id)
      set({ currentTeam, isLoading: false })
    } catch (error: unknown) {
      set({ 
        error: (error as any)?.response?.data?.detail || 'Failed to fetch team',
        isLoading: false 
      })
    }
  },

  fetchPlayers: async (teamId: number) => {
    set({ isLoading: true, error: null })
    try {
      // Use mock data in development mode
      if (import.meta.env.DEV) {
        const players = mockPlayers.filter(player => player.team === teamId)
        set({ players, isLoading: false })
        return
      }
      const players = await teamsService.getPlayers(teamId)
      set({ players, isLoading: false })
    } catch (error: unknown) {
      set({ 
        error: (error as any)?.response?.data?.detail || 'Failed to fetch players',
        isLoading: false 
      })
    }
  },

  createTeam: async (team: Partial<Team>) => {
    set({ isLoading: true, error: null })
    try {
      const newTeam = await teamsService.createTeam(team)
      set(state => ({ 
        teams: [...state.teams, newTeam],
        isLoading: false 
      }))
    } catch (error: unknown) {
      set({ 
        error: (error as any)?.response?.data?.detail || 'Failed to create team',
        isLoading: false 
      })
    }
  },

  updateTeam: async (id: number, team: Partial<Team>) => {
    set({ isLoading: true, error: null })
    try {
      const updatedTeam = await teamsService.updateTeam(id, team)
      set(state => ({
        teams: state.teams.map(t => t.id === id ? updatedTeam : t),
        currentTeam: state.currentTeam?.id === id ? updatedTeam : state.currentTeam,
        isLoading: false
      }))
    } catch (error: unknown) {
      set({ 
        error: (error as any)?.response?.data?.detail || 'Failed to update team',
        isLoading: false 
      })
    }
  },

  deleteTeam: async (id: number) => {
    set({ isLoading: true, error: null })
    try {
      await teamsService.deleteTeam(id)
      set(state => ({
        teams: state.teams.filter(t => t.id !== id),
        currentTeam: state.currentTeam?.id === id ? null : state.currentTeam,
        isLoading: false
      }))
    } catch (error: unknown) {
      set({ 
        error: (error as any)?.response?.data?.detail || 'Failed to delete team',
        isLoading: false 
      })
    }
  },

  addPlayer: async (teamId: number, player: Partial<Player>) => {
    set({ isLoading: true, error: null })
    try {
      const newPlayer = await teamsService.addPlayer(teamId, player)
      set(state => ({
        players: [...state.players, newPlayer],
        isLoading: false
      }))
    } catch (error: unknown) {
      set({ 
        error: (error as any)?.response?.data?.detail || 'Failed to add player',
        isLoading: false 
      })
    }
  },

  updatePlayer: async (playerId: number, player: Partial<Player>) => {
    set({ isLoading: true, error: null })
    try {
      const updatedPlayer = await teamsService.updatePlayer(playerId, player)
      set(state => ({
        players: state.players.map(p => p.id === playerId ? updatedPlayer : p),
        isLoading: false
      }))
    } catch (error: unknown) {
      set({ 
        error: (error as any)?.response?.data?.detail || 'Failed to update player',
        isLoading: false 
      })
    }
  },

  deletePlayer: async (playerId: number) => {
    set({ isLoading: true, error: null })
    try {
      await teamsService.deletePlayer(playerId)
      set(state => ({
        players: state.players.filter(p => p.id !== playerId),
        isLoading: false
      }))
    } catch (error: unknown) {
      set({ 
        error: (error as any)?.response?.data?.detail || 'Failed to delete player',
        isLoading: false 
      })
    }
  },

  clearError: () => {
    set({ error: null })
  }
}))
