import api from './api'

export interface Player {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  role: string
  coach_type: string
  staff_type: string
  jersey_number: number | null
}

export interface Coach {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  role: string
  coach_type: string
  staff_type: string
  jersey_number: number | null
}

export interface Staff {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  role: string
  coach_type: string
  staff_type: string
  jersey_number: number | null
}

export interface Team {
  id: number
  name: string
  created_by: {
    id: number
    username: string
    email: string
    first_name: string
    last_name: string
    role: string
    coach_type: string
    staff_type: string
    jersey_number: number | null
  }
  players: Player[]
  coaches: Coach[]
  staff: Staff[]
  competition: number
}

export interface TeamCreate {
  name: string
  competition: number
}

export interface TeamMember {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  role: 'PLAYER' | 'COACH' | 'STAFF'
  coach_type?: string
  staff_type?: string
  jersey_number?: number | null
  is_active: boolean
  team?: number
}

export interface TeamMemberCreate {
  username: string
  email: string
  first_name: string
  last_name: string
  role: 'PLAYER' | 'COACH' | 'STAFF'
  coach_type?: string
  staff_type?: string
  jersey_number?: number
  team: number
  password?: string
}

export interface TeamMemberUpdate {
  username?: string
  email?: string
  first_name?: string
  last_name?: string
  coach_type?: string
  staff_type?: string
  jersey_number?: number | null
  is_active?: boolean
}

export interface ExistingUser {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  role: 'PLAYER' | 'COACH' | 'STAFF'
  coach_type?: string
  staff_type?: string
  jersey_number?: number | null
}

export interface PlayerCreate {
  username: string
  email: string
  first_name: string
  last_name: string
  jersey_number: number
  team: number
}

export interface CoachCreate {
  username: string
  email: string
  first_name: string
  last_name: string
  coach_type: string
  team: number
}

export interface StaffCreate {
  username: string
  email: string
  first_name: string
  last_name: string
  staff_type: string
  team: number
}

export const teamsService = {
  async getTeams(): Promise<Team[]> {
    try {
      console.log('Fetching teams from /teams/')
      console.log('API Base URL:', import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api')
      console.log('Auth token present:', !!localStorage.getItem('auth_token'))
      
      const response = await api.get<{ results: Team[] }>('/teams/')
      console.log('Teams response:', response)
      return response.results
    } catch (error: any) {
      console.error('Failed to fetch teams:', error)
      console.error('Error response:', error.response)
      console.error('Error status:', error.response?.status)
      console.error('Error data:', error.response?.data)
      console.error('Error config:', error.config)
      throw error
    }
  },

  async getTeam(id: number): Promise<Team> {
    try {
      console.log(`Fetching team ${id} from /teams/${id}/`)
      
      if (!id || id <= 0) {
        throw new Error(`Invalid team ID: ${id}`)
      }
      
      const response = await api.get<Team>(`/teams/${id}/`)
      console.log('Team response:', response)
      return response
    } catch (error) {
      console.error(`Failed to fetch team ${id}:`, error)
      throw error
    }
  },

  async createTeam(teamData: TeamCreate): Promise<Team> {
    try {
      console.log('Creating team:', teamData)
      const response = await api.post<Team>('/teams/', teamData)
      console.log('Team created:', response)
      return response
    } catch (error) {
      console.error('Failed to create team:', error)
      throw error
    }
  },

  async updateTeam(id: number, teamData: Partial<TeamCreate>): Promise<Team> {
    try {
      console.log(`Updating team ${id}:`, teamData)
      const response = await api.patch<Team>(`/teams/${id}/`, teamData)
      console.log('Team updated:', response)
      return response
    } catch (error) {
      console.error(`Failed to update team ${id}:`, error)
      throw error
    }
  },

  async deleteTeam(id: number): Promise<void> {
    try {
      console.log(`Deleting team ${id}`)
      await api.delete(`/teams/${id}/`)
      console.log('Team deleted successfully')
    } catch (error) {
      console.error(`Failed to delete team ${id}:`, error)
      throw error
    }
  },

  // Legacy methods removed - team members are managed through /users/ endpoint

  // Unified Team Member Management
  async getTeamMembers(teamId: number): Promise<TeamMember[]> {
    try {
      console.log(`Fetching all members for team ${teamId}`)
      
      if (!teamId || teamId <= 0) {
        console.warn('Invalid team ID provided:', teamId)
        return []
      }
      
      const team = await this.getTeam(teamId)
      
      if (!team) {
        console.warn('Team not found for ID:', teamId)
        return []
      }
      
      const allMembers: TeamMember[] = [
        ...(team.players || []).map(player => ({ 
          ...player, 
          role: 'PLAYER' as const, 
          is_active: true 
        })),
        ...(team.coaches || []).map(coach => ({ 
          ...coach, 
          role: 'COACH' as const, 
          is_active: true 
        })),
        ...(team.staff || []).map(staff => ({ 
          ...staff, 
          role: 'STAFF' as const, 
          is_active: true 
        }))
      ]
      
      console.log(`Found ${allMembers.length} members for team ${teamId}`)
      return allMembers
    } catch (error) {
      console.error(`Failed to fetch members for team ${teamId}:`, error)
      // Return empty array instead of throwing to prevent UI crashes
      return []
    }
  },

  async createTeamMember(teamId: number, memberData: TeamMemberCreate): Promise<TeamMember> {
    try {
      console.log(`Creating ${memberData.role} member for team ${teamId}:`, memberData)
      
      let userResponse: any
      
      if (memberData.role === 'PLAYER') {
        // Use the team-specific endpoint for creating players
        const playerData = {
          username: memberData.username,
          email: memberData.email,
          first_name: memberData.first_name,
          last_name: memberData.last_name,
          jersey_number: memberData.jersey_number
        }
        
        console.log('Creating player via team endpoint:', playerData)
        userResponse = await api.post(`/teams/${teamId}/create_and_add_player/`, playerData)
        console.log('Player created successfully:', userResponse)
        
      } else if (memberData.role === 'COACH') {
        // Use the team-specific endpoint for creating coaches
        const coachData = {
          username: memberData.username,
          email: memberData.email,
          first_name: memberData.first_name,
          last_name: memberData.last_name,
          coach_type: memberData.coach_type || 'ASSISTANT_COACH'
        }
        
        console.log('Creating coach via team endpoint:', coachData)
        userResponse = await api.post(`/teams/${teamId}/create_and_add_coach/`, coachData)
        console.log('Coach created successfully:', userResponse)
        
      } else if (memberData.role === 'STAFF') {
        // For staff, we need to create the user first, then add them to the team
        const userData = {
          username: memberData.username,
          email: memberData.email,
          first_name: memberData.first_name,
          last_name: memberData.last_name,
          role: 'STAFF',
          staff_type: memberData.staff_type || 'PHYSIO',
          password: memberData.password || 'defaultpassword123'
        }
        
        console.log('Creating staff user:', userData)
        const createdUser = await api.post('/users/', userData) as any
        console.log('Staff user created:', createdUser)
        
        // Now add them to the team
        const addMemberData = {
          user_id: createdUser.id,
          role: 'staff',
          staff_type: memberData.staff_type || 'PHYSIO'
        }
        
        console.log('Adding staff to team:', addMemberData)
        await api.post(`/teams/${teamId}/add_member/`, addMemberData)
        console.log('Staff added to team successfully')
        
        userResponse = createdUser
      } else {
        throw new Error(`Unsupported role: ${memberData.role}`)
      }
      
      // Return the created user as a TeamMember
      return {
        id: userResponse.id,
        username: userResponse.username,
        email: userResponse.email,
        first_name: userResponse.first_name,
        last_name: userResponse.last_name,
        role: userResponse.role,
        coach_type: userResponse.coach_type,
        staff_type: userResponse.staff_type,
        jersey_number: userResponse.jersey_number,
        is_active: userResponse.is_active || true,
        team: teamId
      } as TeamMember
    } catch (error: any) {
      console.error(`Failed to create ${memberData.role} member for team ${teamId}:`, error)
      console.error('Error response:', error.response)
      console.error('Error status:', error.response?.status)
      console.error('Error data:', error.response?.data)
      console.error('Request data that failed:', memberData)
      throw error
    }
  },

  async getAllUsers(): Promise<ExistingUser[]> {
    try {
      console.log('Fetching all users from /users/')
      const response = await api.get<{ results: any[] }>('/users/')
      console.log('Users response:', response)
      return response.results.map(user => ({
        id: user.id,
        username: user.username,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role,
        coach_type: user.coach_type,
        staff_type: user.staff_type,
        jersey_number: user.jersey_number
      }))
    } catch (error: any) {
      console.error('Failed to fetch users:', error)
      console.error('Error response:', error.response)
      console.error('Error status:', error.response?.status)
      console.error('Error data:', error.response?.data)
      return []
    }
  },

  async addExistingMemberToTeam(teamId: number, userId: number, role: string): Promise<void> {
    try {
      console.log(`Adding existing user ${userId} as ${role} to team ${teamId}`)
      
      const addMemberData: any = {
        user_id: userId,
        role: role.toLowerCase()
      }
      
      // Add staff_type for staff members
      if (role.toLowerCase() === 'staff') {
        addMemberData.staff_type = 'PHYSIO' // Default staff type
      }
      
      console.log('Adding existing member to team:', addMemberData)
      await api.post(`/teams/${teamId}/add_member/`, addMemberData)
      console.log('Existing member added to team successfully')
    } catch (error: any) {
      console.error(`Failed to add existing member to team ${teamId}:`, error)
      console.error('Error response:', error.response)
      console.error('Error status:', error.response?.status)
      console.error('Error data:', error.response?.data)
      throw error
    }
  },

  async updateTeamMember(memberId: number, memberData: TeamMemberUpdate): Promise<TeamMember> {
    try {
      console.log(`Updating member ${memberId}:`, memberData)
      const response = await api.patch(`/users/${memberId}/`, memberData) as any
      console.log('Member updated:', response)
      return {
        id: response.id,
        username: response.username,
        email: response.email,
        first_name: response.first_name,
        last_name: response.last_name,
        role: response.role,
        coach_type: response.coach_type,
        staff_type: response.staff_type,
        jersey_number: response.jersey_number,
        is_active: response.is_active,
        team: response.team
      } as TeamMember
    } catch (error) {
      console.error(`Failed to update member ${memberId}:`, error)
      throw error
    }
  },

  async deleteTeamMember(memberId: number): Promise<void> {
    try {
      console.log(`Deleting member ${memberId}`)
      await api.delete(`/users/${memberId}/`)
      console.log('Member deleted successfully')
    } catch (error) {
      console.error(`Failed to delete member ${memberId}:`, error)
      throw error
    }
  },

  async toggleMemberStatus(memberId: number, isActive: boolean): Promise<TeamMember> {
    try {
      console.log(`Toggling member ${memberId} status to ${isActive}`)
      const response = await api.patch(`/users/${memberId}/`, { is_active: isActive }) as any
      console.log('Member status updated:', response)
      return {
        id: response.id,
        username: response.username,
        email: response.email,
        first_name: response.first_name,
        last_name: response.last_name,
        role: response.role,
        coach_type: response.coach_type,
        staff_type: response.staff_type,
        jersey_number: response.jersey_number,
        is_active: response.is_active,
        team: response.team
      } as TeamMember
    } catch (error) {
      console.error(`Failed to toggle member ${memberId} status:`, error)
      throw error
    }
  },

  async getAvailableJerseyNumbers(teamId: number): Promise<number[]> {
    try {
      console.log(`Getting available jersey numbers for team ${teamId}`)
      const team = await this.getTeam(teamId)
      const usedNumbers = team.players.map(player => player.jersey_number).filter(num => num !== null) as number[]
      const availableNumbers = []
      for (let i = 1; i <= 99; i++) {
        if (!usedNumbers.includes(i)) {
          availableNumbers.push(i)
        }
      }
      console.log(`Found ${availableNumbers.length} available jersey numbers`)
      return availableNumbers
    } catch (error) {
      console.error(`Failed to get available jersey numbers for team ${teamId}:`, error)
      throw error
    }
  }
}