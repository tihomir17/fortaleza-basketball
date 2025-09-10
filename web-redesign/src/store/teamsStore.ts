import { create } from 'zustand'
import type { Team, TeamCreate, TeamMember, TeamMemberCreate, TeamMemberUpdate } from '../services/teams'
import { teamsService } from '../services/teams'

interface TeamsState {
  teams: Team[]
  currentTeam: Team | null
  teamMembers: TeamMember[]
  availableJerseyNumbers: number[]
  isLoading: boolean
  error: string | null
  
  // Actions
  fetchTeams: () => Promise<void>
  fetchTeam: (id: number) => Promise<void>
  createTeam: (teamData: TeamCreate) => Promise<void>
  updateTeam: (id: number, teamData: Partial<TeamCreate>) => Promise<void>
  deleteTeam: (id: number) => Promise<void>
  setCurrentTeam: (team: Team | null) => void
  
  // Unified Team Member Management
  fetchTeamMembers: (teamId: number) => Promise<void>
  createTeamMember: (teamId: number, memberData: TeamMemberCreate) => Promise<void>
  updateTeamMember: (memberId: number, memberData: TeamMemberUpdate) => Promise<void>
  deleteTeamMember: (memberId: number) => Promise<void>
  toggleMemberStatus: (memberId: number, isActive: boolean) => Promise<void>
  fetchAvailableJerseyNumbers: (teamId: number) => Promise<void>
  setTeamMembers: (members: TeamMember[]) => void
  
  // Legacy methods removed - using unified team member management
  
  clearError: () => void
}

export const useTeamsStore = create<TeamsState>((set, get) => ({
  teams: [],
  currentTeam: null,
  teamMembers: [],
  availableJerseyNumbers: [],
  isLoading: false,
  error: null,

  fetchTeams: async () => {
    set({ isLoading: true, error: null })
    try {
      console.log('[teamsStore] Starting to fetch teams...')
      const teams = await teamsService.getTeams()
      console.info('[teamsStore] fetched teams from API count=', teams?.length ?? 'unknown', teams)
      set({ teams, isLoading: false })
    } catch (error: any) {
      console.error('[teamsStore] fetchTeams error:', error)
      console.error('[teamsStore] Error details:', {
        status: error?.response?.status,
        statusText: error?.response?.statusText,
        data: error?.response?.data,
        message: error?.message,
        config: error?.config
      })
      set({ 
        error: error?.response?.data?.detail || error?.response?.data?.message || error?.message || 'Failed to fetch teams',
        isLoading: false 
      })
    }
  },

  fetchTeam: async (id: number) => {
    set({ isLoading: true, error: null })
    try {
      const team = await teamsService.getTeam(id)
      console.info('[teamsStore] fetched team from API:', team)
      set({ currentTeam: team, isLoading: false })
    } catch (error: any) {
      console.error('[teamsStore] fetchTeam error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.message || `Failed to fetch team ${id}`,
        isLoading: false 
      })
    }
  },

  createTeam: async (teamData: TeamCreate) => {
    set({ isLoading: true, error: null })
    try {
      const newTeam = await teamsService.createTeam(teamData)
      console.info('[teamsStore] created team:', newTeam)
      const { teams } = get()
      set({ teams: [...teams, newTeam], isLoading: false })
    } catch (error: any) {
      console.error('[teamsStore] createTeam error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.message || 'Failed to create team',
        isLoading: false 
      })
    }
  },

  updateTeam: async (id: number, teamData: Partial<TeamCreate>) => {
    set({ isLoading: true, error: null })
    try {
      const updatedTeam = await teamsService.updateTeam(id, teamData)
      console.info('[teamsStore] updated team:', updatedTeam)
      const { teams } = get()
      set({ 
        teams: teams.map(team => team.id === id ? updatedTeam : team),
        currentTeam: get().currentTeam?.id === id ? updatedTeam : get().currentTeam,
        isLoading: false 
      })
    } catch (error: any) {
      console.error('[teamsStore] updateTeam error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.message || `Failed to update team ${id}`,
        isLoading: false 
      })
    }
  },

  deleteTeam: async (id: number) => {
    set({ isLoading: true, error: null })
    try {
      await teamsService.deleteTeam(id)
      console.info('[teamsStore] deleted team:', id)
      const { teams, currentTeam } = get()
      set({ 
        teams: teams.filter(team => team.id !== id),
        currentTeam: currentTeam?.id === id ? null : currentTeam,
        isLoading: false 
      })
    } catch (error: any) {
      console.error('[teamsStore] deleteTeam error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.message || `Failed to delete team ${id}`,
        isLoading: false 
      })
    }
  },

  setCurrentTeam: (team: Team | null) => {
    set({ currentTeam: team })
  },

  // Unified Team Member Management
  fetchTeamMembers: async (teamId: number) => {
    set({ isLoading: true, error: null })
    try {
      if (!teamId || teamId <= 0) {
        console.warn('[teamsStore] Invalid team ID for fetchTeamMembers:', teamId)
        set({ teamMembers: [], isLoading: false })
        return
      }
      
      const members = await teamsService.getTeamMembers(teamId)
      console.info('[teamsStore] fetched team members from API count=', members?.length ?? 'unknown')
      set({ teamMembers: members || [], isLoading: false })
    } catch (error: any) {
      console.error('[teamsStore] fetchTeamMembers error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.message || `Failed to fetch members for team ${teamId}`,
        teamMembers: [], // Set empty array on error
        isLoading: false 
      })
    }
  },

  createTeamMember: async (teamId: number, memberData: TeamMemberCreate) => {
    set({ isLoading: true, error: null })
    try {
      const newMember = await teamsService.createTeamMember(teamId, memberData)
      console.info('[teamsStore] created team member:', newMember)
      const { teamMembers } = get()
      
      // Update team members list
      set({ teamMembers: [...teamMembers, newMember], isLoading: false })
      
      // Refresh the team data to get updated member arrays
      await get().fetchTeam(teamId)
    } catch (error: any) {
      console.error('[teamsStore] createTeamMember error:', error)
      
      // Handle specific error cases
      let errorMessage = 'Failed to create team member'
      if (error?.response?.data?.error?.details?.username) {
        errorMessage = `Username "${memberData.username}" already exists. Please choose a different username.`
      } else if (error?.response?.data?.error?.details?.email) {
        errorMessage = `Email "${memberData.email}" already exists. Please use a different email.`
      } else if (error?.response?.data?.error?.message) {
        errorMessage = error.response.data.error.message
      } else if (error?.response?.data?.detail) {
        errorMessage = error.response.data.detail
      } else if (error?.message) {
        errorMessage = error.message
      }
      
      set({ 
        error: errorMessage,
        isLoading: false 
      })
    }
  },

  updateTeamMember: async (memberId: number, memberData: TeamMemberUpdate) => {
    set({ isLoading: true, error: null })
    try {
      const updatedMember = await teamsService.updateTeamMember(memberId, memberData)
      console.info('[teamsStore] updated team member:', updatedMember)
      const { teamMembers } = get()
      set({ 
        teamMembers: teamMembers.map(member => member.id === memberId ? updatedMember : member),
        isLoading: false 
      })
    } catch (error: any) {
      console.error('[teamsStore] updateTeamMember error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.message || `Failed to update member ${memberId}`,
        isLoading: false 
      })
    }
  },

  deleteTeamMember: async (memberId: number) => {
    set({ isLoading: true, error: null })
    try {
      const { teamMembers } = get()
      
      await teamsService.deleteTeamMember(memberId)
      console.info('[teamsStore] deleted team member:', memberId)
      
      // Update team members list
      set({ 
        teamMembers: teamMembers.filter(member => member.id !== memberId),
        isLoading: false 
      })
      
      // Refresh the team data to get updated member arrays
      const memberToDelete = teamMembers.find(member => member.id === memberId)
      if (memberToDelete?.team) {
        await get().fetchTeam(memberToDelete.team)
      }
    } catch (error: any) {
      console.error('[teamsStore] deleteTeamMember error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.message || `Failed to delete member ${memberId}`,
        isLoading: false 
      })
    }
  },

  toggleMemberStatus: async (memberId: number, isActive: boolean) => {
    set({ isLoading: true, error: null })
    try {
      const updatedMember = await teamsService.toggleMemberStatus(memberId, isActive)
      console.info('[teamsStore] toggled member status:', updatedMember)
      const { teamMembers } = get()
      set({ 
        teamMembers: teamMembers.map(member => member.id === memberId ? updatedMember : member),
        isLoading: false 
      })
    } catch (error: any) {
      console.error('[teamsStore] toggleMemberStatus error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.message || `Failed to toggle member ${memberId} status`,
        isLoading: false 
      })
    }
  },

  fetchAvailableJerseyNumbers: async (teamId: number) => {
    try {
      const availableNumbers = await teamsService.getAvailableJerseyNumbers(teamId)
      console.info('[teamsStore] fetched available jersey numbers:', availableNumbers.length)
      set({ availableJerseyNumbers: availableNumbers })
    } catch (error: any) {
      console.error('[teamsStore] fetchAvailableJerseyNumbers error:', error)
      set({ 
        error: error?.response?.data?.detail || error?.message || `Failed to fetch available jersey numbers for team ${teamId}`
      })
    }
  },

  // Legacy methods removed - using unified team member management

  setTeamMembers: (members: TeamMember[]) => {
    set({ teamMembers: members })
  },

  clearError: () => {
    set({ error: null })
  }
}))