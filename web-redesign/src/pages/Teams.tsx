import { useEffect, useState } from 'react'
import { useTeamsStore } from '../store/teamsStore'
import { PlusIcon, UserGroupIcon, UserIcon, CogIcon, FunnelIcon } from '@heroicons/react/24/outline'
import { TeamMemberForm } from '../components/teams/TeamMemberForm'
import { TeamMemberCard } from '../components/teams/TeamMemberCard'
import type { Team, TeamMember, TeamMemberCreate, TeamMemberUpdate, ExistingUser } from '../services/teams'
import { teamsService } from '../services/teams'

export default function Teams() {
  const { 
    teams, 
    teamMembers,
    availableJerseyNumbers,
    isLoading, 
    error, 
    fetchTeams, 
    fetchTeam, 
    fetchTeamMembers,
    fetchAvailableJerseyNumbers,
    createTeamMember,
    updateTeamMember,
    deleteTeamMember,
    toggleMemberStatus,
    setCurrentTeam,
    clearError,
    setTeamMembers
  } = useTeamsStore()
  
  const [selectedTeam, setSelectedTeam] = useState<Team | null>(null)
  const [activeTab, setActiveTab] = useState<'all' | 'players' | 'coaches' | 'staff'>('all')
  const [isFormOpen, setIsFormOpen] = useState(false)
  const [editingMember, setEditingMember] = useState<TeamMember | null>(null)
  const [roleFilter, setRoleFilter] = useState<'ALL' | 'PLAYER' | 'COACH' | 'STAFF'>('ALL')
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE'>('ALL')
  const [existingUsers, setExistingUsers] = useState<ExistingUser[]>([])

  useEffect(() => {
    fetchTeams()
  }, [fetchTeams])

  // Fetch existing users when form opens
  useEffect(() => {
    if (isFormOpen && existingUsers.length === 0) {
      const loadExistingUsers = async () => {
        try {
          const users = await teamsService.getAllUsers()
          setExistingUsers(users)
        } catch (error) {
          console.error('Failed to load existing users:', error)
        }
      }
      loadExistingUsers()
    }
  }, [isFormOpen, existingUsers.length])

  useEffect(() => {
    if (selectedTeam && selectedTeam.id) {
      console.log('Fetching data for selected team:', selectedTeam.id)
      fetchTeam(selectedTeam.id)
      fetchTeamMembers(selectedTeam.id)
      fetchAvailableJerseyNumbers(selectedTeam.id)
    } else {
      console.log('No team selected, clearing team members')
      // Clear team members when no team is selected
      setTeamMembers([])
    }
  }, [selectedTeam, fetchTeam, fetchTeamMembers, fetchAvailableJerseyNumbers, setTeamMembers])

  const handleTeamSelect = (team: Team) => {
    setSelectedTeam(team)
    setCurrentTeam(team)
    setRoleFilter('ALL')
    setStatusFilter('ALL')
    setActiveTab('all')
  }

  const handleAddMember = () => {
    setEditingMember(null)
    setIsFormOpen(true)
  }

  const handleEditMember = (member: TeamMember) => {
    setEditingMember(member)
    setIsFormOpen(true)
  }

  const handleFormSubmit = async (data: TeamMemberCreate | TeamMemberUpdate) => {
    if (!selectedTeam) return

    try {
      if (editingMember) {
        await updateTeamMember(editingMember.id, data as TeamMemberUpdate)
      } else {
        await createTeamMember(selectedTeam.id, data as TeamMemberCreate)
      }
      // Close form on success
      setIsFormOpen(false)
      setEditingMember(null)
    } catch (error: any) {
      console.error('Form submission error:', error)
      // Re-throw the error so the form can handle it
      throw error
    }
  }

  const handleExistingUserSubmit = async (userId: number, role: string) => {
    if (!selectedTeam) return

    try {
      // Use the add_member endpoint to add existing user to team
      await teamsService.addExistingMemberToTeam(selectedTeam.id, userId, role)
      // Close form on success
      setIsFormOpen(false)
      setEditingMember(null)
    } catch (error: any) {
      console.error('Add existing user error:', error)
      // Re-throw the error so the form can handle it
      throw error
    }
  }

  const handleDeleteMember = async (memberId: number) => {
    if (window.confirm('Are you sure you want to delete this team member?')) {
      await deleteTeamMember(memberId)
    }
  }

  const handleToggleStatus = async (memberId: number, isActive: boolean) => {
    await toggleMemberStatus(memberId, isActive)
  }

  const filteredMembers = teamMembers.filter(member => {
    const roleMatch = roleFilter === 'ALL' || member.role === roleFilter
    const statusMatch = statusFilter === 'ALL' || 
      (statusFilter === 'ACTIVE' && member.is_active) ||
      (statusFilter === 'INACTIVE' && !member.is_active)
    return roleMatch && statusMatch
  })

  const getMembersByRole = (role: 'PLAYER' | 'COACH' | 'STAFF') => {
    return teamMembers.filter(member => member.role === role)
  }


  if (error) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-md p-4">
          <div className="flex">
            <div className="ml-3">
              <h3 className="text-sm font-medium text-red-800">Error loading teams</h3>
              <div className="mt-2 text-sm text-red-700">{error}</div>
              <div className="mt-4">
                <button
                  onClick={() => {
                    clearError()
                    fetchTeams()
                  }}
                  className="bg-red-100 px-3 py-2 rounded-md text-sm font-medium text-red-800 hover:bg-red-200"
                >
                  Try Again
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">Teams & Roster Management</h1>
        <p className="mt-1 text-sm text-gray-500">
          Manage team rosters, players, coaches, and staff
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Teams List */}
        <div className="lg:col-span-1">
          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-lg font-medium text-gray-900">Teams</h2>
                <button className="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700">
                  <PlusIcon className="h-4 w-4 mr-1" />
                  Add Team
                </button>
              </div>
              
              {isLoading ? (
                <div className="space-y-3">
                  {[1, 2, 3].map((i) => (
                    <div key={i} className="animate-pulse">
                      <div className="h-16 bg-gray-200 rounded-md"></div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="space-y-3">
                  {teams.map((team) => (
                    <div
                      key={team.id}
                      onClick={() => handleTeamSelect(team)}
                      className={`p-4 border rounded-lg cursor-pointer transition-colors ${
                        selectedTeam?.id === team.id
                          ? 'border-blue-500 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <h3 className="text-sm font-medium text-gray-900">{team.name}</h3>
                          <p className="text-xs text-gray-500">
                            {team.players?.length || 0} players • {team.coaches?.length || 0} coaches • {team.staff?.length || 0} staff
                          </p>
                        </div>
                        <UserGroupIcon className="h-5 w-5 text-gray-400" />
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Team Details */}
        <div className="lg:col-span-2">
          {selectedTeam ? (
            <div className="bg-white shadow rounded-lg">
              <div className="px-4 py-5 sm:p-6">
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h2 className="text-lg font-medium text-gray-900">{selectedTeam.name}</h2>
                    <p className="text-sm text-gray-500">
                      Created by {selectedTeam.created_by.first_name} {selectedTeam.created_by.last_name}
                    </p>
                  </div>
                  <button 
                    onClick={handleAddMember}
                    className="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                  >
                    <PlusIcon className="h-4 w-4 mr-1" />
                    Add Member
                  </button>
                </div>

                {/* Tabs */}
                <div className="border-b border-gray-200 mb-6">
                  <nav className="-mb-px flex space-x-8">
                    <button
                      onClick={() => setActiveTab('all')}
                      className={`py-2 px-1 border-b-2 font-medium text-sm ${
                        activeTab === 'all'
                          ? 'border-blue-500 text-blue-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }`}
                    >
                      <UserGroupIcon className="h-4 w-4 inline mr-1" />
                      All Members ({teamMembers.length})
                    </button>
                    <button
                      onClick={() => setActiveTab('players')}
                      className={`py-2 px-1 border-b-2 font-medium text-sm ${
                        activeTab === 'players'
                          ? 'border-blue-500 text-blue-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }`}
                    >
                      <UserIcon className="h-4 w-4 inline mr-1" />
                      Players ({getMembersByRole('PLAYER').length})
                    </button>
                    <button
                      onClick={() => setActiveTab('coaches')}
                      className={`py-2 px-1 border-b-2 font-medium text-sm ${
                        activeTab === 'coaches'
                          ? 'border-blue-500 text-blue-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }`}
                    >
                      <CogIcon className="h-4 w-4 inline mr-1" />
                      Coaches ({getMembersByRole('COACH').length})
                    </button>
                    <button
                      onClick={() => setActiveTab('staff')}
                      className={`py-2 px-1 border-b-2 font-medium text-sm ${
                        activeTab === 'staff'
                          ? 'border-blue-500 text-blue-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }`}
                    >
                      <UserGroupIcon className="h-4 w-4 inline mr-1" />
                      Staff ({getMembersByRole('STAFF').length})
                    </button>
                  </nav>
                </div>

                {/* Filters */}
                <div className="mb-6 flex items-center space-x-4">
                  <div className="flex items-center space-x-2">
                    <FunnelIcon className="h-4 w-4 text-gray-400" />
                    <span className="text-sm text-gray-500">Filter:</span>
                  </div>
                  
                  <select
                    value={roleFilter}
                    onChange={(e) => setRoleFilter(e.target.value as any)}
                    className="text-sm border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="ALL">All Roles</option>
                    <option value="PLAYER">Players</option>
                    <option value="COACH">Coaches</option>
                    <option value="STAFF">Staff</option>
                  </select>
                  
                  <select
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value as any)}
                    className="text-sm border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
                  >
                    <option value="ALL">All Status</option>
                    <option value="ACTIVE">Active</option>
                    <option value="INACTIVE">Inactive</option>
                  </select>
                </div>

                {/* Tab Content */}
                <div className="space-y-4">
                  {isLoading ? (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {[1, 2, 3, 4].map((i) => (
                        <div key={i} className="animate-pulse">
                          <div className="h-24 bg-gray-200 rounded-lg"></div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {(() => {
                        let membersToShow = filteredMembers
                        
                        if (activeTab === 'players') {
                          membersToShow = filteredMembers.filter(member => member.role === 'PLAYER')
                        } else if (activeTab === 'coaches') {
                          membersToShow = filteredMembers.filter(member => member.role === 'COACH')
                        } else if (activeTab === 'staff') {
                          membersToShow = filteredMembers.filter(member => member.role === 'STAFF')
                        }
                        
                        return membersToShow.map((member) => (
                          <TeamMemberCard
                            key={member.id}
                            member={member}
                            onEdit={handleEditMember}
                            onDelete={handleDeleteMember}
                            onToggleStatus={handleToggleStatus}
                            isLoading={isLoading}
                          />
                        ))
                      })()}
                    </div>
                  )}
                  
                  {filteredMembers.length === 0 && !isLoading && (
                    <div className="text-center py-8">
                      <UserGroupIcon className="mx-auto h-12 w-12 text-gray-400" />
                      <h3 className="mt-2 text-sm font-medium text-gray-900">No members found</h3>
                      <p className="mt-1 text-sm text-gray-500">
                        {roleFilter !== 'ALL' || statusFilter !== 'ALL' 
                          ? 'Try adjusting your filters or add a new team member.'
                          : 'Get started by adding a new team member.'
                        }
                      </p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ) : (
            <div className="bg-white shadow rounded-lg">
              <div className="px-4 py-5 sm:p-6 text-center">
                <UserGroupIcon className="mx-auto h-12 w-12 text-gray-400" />
                <h3 className="mt-2 text-sm font-medium text-gray-900">No team selected</h3>
                <p className="mt-1 text-sm text-gray-500">
                  Select a team from the list to view its roster and details.
                </p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Team Member Form Modal */}
      <TeamMemberForm
        isOpen={isFormOpen}
        onClose={() => {
          setIsFormOpen(false)
          setEditingMember(null)
        }}
        onSubmit={handleFormSubmit}
        onSubmitExisting={handleExistingUserSubmit}
        member={editingMember}
        teamId={selectedTeam?.id || 0}
        availableJerseyNumbers={availableJerseyNumbers}
        existingUsers={existingUsers}
        isLoading={isLoading}
      />
    </div>
  )
}