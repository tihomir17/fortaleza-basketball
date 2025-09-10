import api from './api'
import { mockTeams, mockPlayers } from './mockData'

export interface Team {
  id: number
  name: string
  short_name: string
  logo?: string
  city: string
  state: string
  country: string
  founded_year?: number
  coach?: string
  assistant_coaches?: string[]
  players: Player[]
}

export interface Player {
  id: number
  first_name: string
  last_name: string
  jersey_number: number
  position: 'PG' | 'SG' | 'SF' | 'PF' | 'C'
  height: string
  weight: number
  date_of_birth: string
  team: number
  is_active: boolean
  stats?: PlayerStats
}

export interface PlayerStats {
  games_played: number
  points_per_game: number
  rebounds_per_game: number
  assists_per_game: number
  steals_per_game: number
  blocks_per_game: number
  field_goal_percentage: number
  three_point_percentage: number
  free_throw_percentage: number
}

export const teamsService = {
  async getTeams(): Promise<Team[]> {
    try {
      const response = await api.get('/teams/')
      return (response as any).data
    } catch {
      console.log('Using mock data for teams')
      return mockTeams
    }
  },

  async getTeam(id: number): Promise<Team> {
    try {
      const response = await api.get(`/teams/${id}/`)
      return (response as any).data
    } catch {
      console.log('Using mock data for team')
      const team = mockTeams.find(t => t.id === id)
      if (!team) throw new Error('Team not found')
      return team
    }
  },

  async createTeam(team: Partial<Team>): Promise<Team> {
    try {
      const response = await api.post('/teams/', team)
      return (response as any).data
    } catch {
      console.log('Mock: Team created')
      const newTeam: Team = {
        id: Date.now(),
        name: team.name || 'New Team',
        short_name: team.short_name || 'NEW',
        city: team.city || 'City',
        state: team.state || 'State',
        country: team.country || 'Country',
        players: []
      }
      return newTeam
    }
  },

  async updateTeam(id: number, team: Partial<Team>): Promise<Team> {
    try {
      const response = await api.patch(`/teams/${id}/`, team)
      return (response as any).data
    } catch {
      console.log('Mock: Team updated')
      const existingTeam = mockTeams.find(t => t.id === id)
      if (!existingTeam) throw new Error('Team not found')
      return { ...existingTeam, ...team }
    }
  },

  async deleteTeam(id: number): Promise<void> {
    try {
      await api.delete(`/teams/${id}/`)
    } catch {
      console.log('Mock: Team deleted')
    }
  },

  async getPlayers(teamId: number): Promise<Player[]> {
    try {
      const response = await api.get(`/teams/${teamId}/players/`)
      return (response as any).data
    } catch {
      console.log('Using mock data for players')
      return mockPlayers.filter(p => p.team === teamId)
    }
  },

  async addPlayer(teamId: number, player: Partial<Player>): Promise<Player> {
    try {
      const response = await api.post(`/teams/${teamId}/players/`, player)
      return (response as any).data
    } catch {
      console.log('Mock: Player added')
      const newPlayer: Player = {
        id: Date.now(),
        first_name: player.first_name || 'New',
        last_name: player.last_name || 'Player',
        jersey_number: player.jersey_number || 0,
        position: player.position || 'PG',
        height: player.height || '6\'0"',
        weight: player.weight || 180,
        date_of_birth: player.date_of_birth || '1990-01-01',
        team: teamId,
        is_active: true
      }
      return newPlayer
    }
  },

  async updatePlayer(playerId: number, player: Partial<Player>): Promise<Player> {
    try {
      const response = await api.patch(`/players/${playerId}/`, player)
      return (response as any).data
    } catch {
      console.log('Mock: Player updated')
      const existingPlayer = mockPlayers.find(p => p.id === playerId)
      if (!existingPlayer) throw new Error('Player not found')
      return { ...existingPlayer, ...player }
    }
  },

  async deletePlayer(playerId: number): Promise<void> {
    try {
      await api.delete(`/players/${playerId}/`)
    } catch {
      console.log('Mock: Player deleted')
    }
  }
}
