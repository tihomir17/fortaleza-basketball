import { useEffect, useState } from 'react'
import { useTeamsStore } from '../store/teamsStore'
import { 
  PlusIcon, 
  UserGroupIcon, 
  UserIcon, 
  CogIcon, 
  FunnelIcon,
  HeartIcon,
  ChartBarIcon,
  CalendarIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
  ClockIcon,
  AcademicCapIcon,
  EyeIcon,
  PencilIcon
} from '@heroicons/react/24/outline'
import { TeamMemberForm } from '../components/teams/TeamMemberForm'
import { TeamMemberCard } from '../components/teams/TeamMemberCard'
import { TeamForm } from '../components/teams/TeamForm'
import type { Team, TeamMember, TeamMemberCreate, TeamMemberUpdate, ExistingUser, TeamCreate } from '../services/teams'
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
    setTeamMembers,
    createTeam,
    updateTeam,
    deleteTeam
  } = useTeamsStore()
  
  const [selectedTeam, setSelectedTeam] = useState<Team | null>(null)
  const [activeTab, setActiveTab] = useState<'all' | 'players' | 'coaches' | 'staff' | 'health' | 'training'>('all')
  const [isFormOpen, setIsFormOpen] = useState(false)
  const [editingMember, setEditingMember] = useState<TeamMember | null>(null)
  const [roleFilter, setRoleFilter] = useState<'ALL' | 'PLAYER' | 'COACH' | 'STAFF'>('ALL')
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'INACTIVE'>('ALL')
  const [existingUsers, setExistingUsers] = useState<ExistingUser[]>([])
  const [showHealthDetails, setShowHealthDetails] = useState(false)
  const [showTrainingDetails, setShowTrainingDetails] = useState(false)
  const [isTeamFormOpen, setIsTeamFormOpen] = useState(false)
  const [editingTeam, setEditingTeam] = useState<Team | null>(null)

  // Mock health and training data
  const [healthData] = useState([
    { id: 1, playerId: 1, playerName: 'John Smith', status: 'Healthy', lastCheckup: '2024-01-15', injuries: [], fitnessScore: 95 },
    { id: 2, playerId: 2, playerName: 'Mike Johnson', status: 'Injured', lastCheckup: '2024-01-10', injuries: ['Ankle Sprain'], fitnessScore: 78 },
    { id: 3, playerId: 3, playerName: 'David Wilson', status: 'Recovering', lastCheckup: '2024-01-12', injuries: ['Knee Strain'], fitnessScore: 85 },
    { id: 4, playerId: 4, playerName: 'Chris Brown', status: 'Healthy', lastCheckup: '2024-01-14', injuries: [], fitnessScore: 92 },
    { id: 5, playerId: 5, playerName: 'Alex Davis', status: 'Healthy', lastCheckup: '2024-01-13', injuries: [], fitnessScore: 88 }
  ])

  const [trainingData] = useState([
    { id: 1, playerId: 1, playerName: 'John Smith', program: 'Strength & Conditioning', progress: 85, nextSession: '2024-01-16', coach: 'Coach Smith' },
    { id: 2, playerId: 2, playerName: 'Mike Johnson', program: 'Rehabilitation', progress: 60, nextSession: '2024-01-17', coach: 'Physical Therapist' },
    { id: 3, playerId: 3, playerName: 'David Wilson', program: 'Recovery Training', progress: 70, nextSession: '2024-01-16', coach: 'Assistant Coach' },
    { id: 4, playerId: 4, playerName: 'Chris Brown', program: 'Skill Development', progress: 90, nextSession: '2024-01-18', coach: 'Skills Coach' },
    { id: 5, playerId: 5, playerName: 'Alex Davis', program: 'Conditioning', progress: 80, nextSession: '2024-01-17', coach: 'Conditioning Coach' }
  ])

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

  // Team management functions
  const handleCreateTeam = () => {
    setEditingTeam(null)
    setIsTeamFormOpen(true)
  }

  const handleEditTeam = (team: Team) => {
    setEditingTeam(team)
    setIsTeamFormOpen(true)
  }

  const handleDeleteTeam = async (team: Team) => {
    if (window.confirm(`Are you sure you want to delete "${team.name}"? This action cannot be undone.`)) {
      try {
        await deleteTeam(team.id)
        if (selectedTeam?.id === team.id) {
          setSelectedTeam(null)
          setCurrentTeam(null)
        }
      } catch (error) {
        console.error('Failed to delete team:', error)
      }
    }
  }

  const handleTeamFormSubmit = async (data: TeamCreate) => {
    try {
      if (editingTeam) {
        await updateTeam(editingTeam.id, data)
      } else {
        await createTeam(data)
      }
      setIsTeamFormOpen(false)
      setEditingTeam(null)
    } catch (error) {
      console.error('Team form submission error:', error)
      throw error
    }
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
                <button 
                  onClick={handleCreateTeam}
                  className="inline-flex items-center px-3 py-2 border border-transparent text-sm leading-4 font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                >
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
                      className={`p-4 border rounded-lg transition-colors ${
                        selectedTeam?.id === team.id
                          ? 'border-blue-500 bg-blue-50'
                          : 'border-gray-200 hover:border-gray-300'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <div 
                          onClick={() => handleTeamSelect(team)}
                          className="flex-1 cursor-pointer"
                        >
                          <h3 className="text-sm font-medium text-gray-900">{team.name}</h3>
                          <p className="text-xs text-gray-500">
                            {team.players?.length || 0} players • {team.coaches?.length || 0} coaches • {team.staff?.length || 0} staff
                          </p>
                        </div>
                        <div className="flex items-center space-x-2">
                          <button
                            onClick={(e) => {
                              e.stopPropagation()
                              handleEditTeam(team)
                            }}
                            className="p-1 text-gray-400 hover:text-blue-600 transition-colors"
                            title="Edit team"
                          >
                            <PencilIcon className="h-4 w-4" />
                          </button>
                          <button
                            onClick={(e) => {
                              e.stopPropagation()
                              handleDeleteTeam(team)
                            }}
                            className="p-1 text-gray-400 hover:text-red-600 transition-colors"
                            title="Delete team"
                          >
                            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                            </svg>
                          </button>
                          <UserGroupIcon className="h-5 w-5 text-gray-400" />
                        </div>
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
                  <nav className="-mb-px flex space-x-8 overflow-x-auto">
                    <button
                      onClick={() => setActiveTab('all')}
                      className={`py-2 px-1 border-b-2 font-medium text-sm whitespace-nowrap ${
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
                      className={`py-2 px-1 border-b-2 font-medium text-sm whitespace-nowrap ${
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
                      className={`py-2 px-1 border-b-2 font-medium text-sm whitespace-nowrap ${
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
                      className={`py-2 px-1 border-b-2 font-medium text-sm whitespace-nowrap ${
                        activeTab === 'staff'
                          ? 'border-blue-500 text-blue-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }`}
                    >
                      <UserGroupIcon className="h-4 w-4 inline mr-1" />
                      Staff ({getMembersByRole('STAFF').length})
                    </button>
                    <button
                      onClick={() => setActiveTab('health')}
                      className={`py-2 px-1 border-b-2 font-medium text-sm whitespace-nowrap ${
                        activeTab === 'health'
                          ? 'border-blue-500 text-blue-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }`}
                    >
                      <HeartIcon className="h-4 w-4 inline mr-1" />
                      Health ({healthData.filter(h => h.status !== 'Healthy').length} issues)
                    </button>
                    <button
                      onClick={() => setActiveTab('training')}
                      className={`py-2 px-1 border-b-2 font-medium text-sm whitespace-nowrap ${
                        activeTab === 'training'
                          ? 'border-blue-500 text-blue-600'
                          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                      }`}
                    >
                      <AcademicCapIcon className="h-4 w-4 inline mr-1" />
                      Training ({trainingData.length} programs)
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
                  {activeTab === 'health' && (
                    <div className="space-y-6">
                      {/* Health Overview Stats */}
                      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                          <div className="flex items-center">
                            <CheckCircleIcon className="h-8 w-8 text-green-600" />
                            <div className="ml-3">
                              <p className="text-sm font-medium text-green-800">Healthy</p>
                              <p className="text-2xl font-bold text-green-900">
                                {healthData.filter(h => h.status === 'Healthy').length}
                              </p>
                            </div>
                          </div>
                        </div>
                        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                          <div className="flex items-center">
                            <ExclamationTriangleIcon className="h-8 w-8 text-red-600" />
                            <div className="ml-3">
                              <p className="text-sm font-medium text-red-800">Injured</p>
                              <p className="text-2xl font-bold text-red-900">
                                {healthData.filter(h => h.status === 'Injured').length}
                              </p>
                            </div>
                          </div>
                        </div>
                        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                          <div className="flex items-center">
                            <ClockIcon className="h-8 w-8 text-yellow-600" />
                            <div className="ml-3">
                              <p className="text-sm font-medium text-yellow-800">Recovering</p>
                              <p className="text-2xl font-bold text-yellow-900">
                                {healthData.filter(h => h.status === 'Recovering').length}
                              </p>
                            </div>
                          </div>
                        </div>
                        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                          <div className="flex items-center">
                            <ChartBarIcon className="h-8 w-8 text-blue-600" />
                            <div className="ml-3">
                              <p className="text-sm font-medium text-blue-800">Avg Fitness</p>
                              <p className="text-2xl font-bold text-blue-900">
                                {Math.round(healthData.reduce((acc, h) => acc + h.fitnessScore, 0) / healthData.length)}%
                              </p>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* Health Details */}
                      <div className="bg-white border border-gray-200 rounded-lg">
                        <div className="px-4 py-3 border-b border-gray-200">
                          <div className="flex items-center justify-between">
                            <h3 className="text-lg font-medium text-gray-900">Player Health Status</h3>
                            <button
                              onClick={() => setShowHealthDetails(!showHealthDetails)}
                              className="text-sm text-blue-600 hover:text-blue-800"
                            >
                              {showHealthDetails ? 'Hide Details' : 'Show Details'}
                            </button>
                          </div>
                        </div>
                        <div className="p-4">
                          <div className="space-y-3">
                            {healthData.map((health) => (
                              <div key={health.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                                <div className="flex items-center space-x-3">
                                  <div className={`w-3 h-3 rounded-full ${
                                    health.status === 'Healthy' ? 'bg-green-500' :
                                    health.status === 'Injured' ? 'bg-red-500' : 'bg-yellow-500'
                                  }`} />
                                  <div>
                                    <p className="font-medium text-gray-900">{health.playerName}</p>
                                    <p className="text-sm text-gray-500">
                                      Last checkup: {health.lastCheckup} • Fitness: {health.fitnessScore}%
                                    </p>
                                  </div>
                                </div>
                                <div className="text-right">
                                  <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                                    health.status === 'Healthy' ? 'bg-green-100 text-green-800' :
                                    health.status === 'Injured' ? 'bg-red-100 text-red-800' : 'bg-yellow-100 text-yellow-800'
                                  }`}>
                                    {health.status}
                                  </span>
                                  {health.injuries.length > 0 && (
                                    <p className="text-xs text-red-600 mt-1">
                                      {health.injuries.join(', ')}
                                    </p>
                                  )}
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>
                    </div>
                  )}

                  {activeTab === 'training' && (
                    <div className="space-y-6">
                      {/* Training Overview Stats */}
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                          <div className="flex items-center">
                            <AcademicCapIcon className="h-8 w-8 text-blue-600" />
                            <div className="ml-3">
                              <p className="text-sm font-medium text-blue-800">Active Programs</p>
                              <p className="text-2xl font-bold text-blue-900">{trainingData.length}</p>
                            </div>
                          </div>
                        </div>
                        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                          <div className="flex items-center">
                            <ChartBarIcon className="h-8 w-8 text-green-600" />
                            <div className="ml-3">
                              <p className="text-sm font-medium text-green-800">Avg Progress</p>
                              <p className="text-2xl font-bold text-green-900">
                                {Math.round(trainingData.reduce((acc, t) => acc + t.progress, 0) / trainingData.length)}%
                              </p>
                            </div>
                          </div>
                        </div>
                        <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
                          <div className="flex items-center">
                            <CalendarIcon className="h-8 w-8 text-purple-600" />
                            <div className="ml-3">
                              <p className="text-sm font-medium text-purple-800">Next Sessions</p>
                              <p className="text-2xl font-bold text-purple-900">
                                {trainingData.filter(t => new Date(t.nextSession) <= new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)).length}
                              </p>
                            </div>
                          </div>
                        </div>
                      </div>

                      {/* Training Programs */}
                      <div className="bg-white border border-gray-200 rounded-lg">
                        <div className="px-4 py-3 border-b border-gray-200">
                          <div className="flex items-center justify-between">
                            <h3 className="text-lg font-medium text-gray-900">Training Programs</h3>
                            <button
                              onClick={() => setShowTrainingDetails(!showTrainingDetails)}
                              className="text-sm text-blue-600 hover:text-blue-800"
                            >
                              {showTrainingDetails ? 'Hide Details' : 'Show Details'}
                            </button>
                          </div>
                        </div>
                        <div className="p-4">
                          <div className="space-y-4">
                            {trainingData.map((training) => (
                              <div key={training.id} className="border border-gray-200 rounded-lg p-4">
                                <div className="flex items-center justify-between mb-3">
                                  <div>
                                    <h4 className="font-medium text-gray-900">{training.playerName}</h4>
                                    <p className="text-sm text-gray-500">{training.program}</p>
                                  </div>
                                  <div className="text-right">
                                    <p className="text-sm font-medium text-gray-900">{training.progress}% Complete</p>
                                    <p className="text-xs text-gray-500">Coach: {training.coach}</p>
                                  </div>
                                </div>
                                <div className="w-full bg-gray-200 rounded-full h-2 mb-2">
                                  <div 
                                    className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                                    style={{ width: `${training.progress}%` }}
                                  />
                                </div>
                                <div className="flex items-center justify-between text-sm text-gray-500">
                                  <span>Next session: {training.nextSession}</span>
                                  <div className="flex items-center space-x-2">
                                    <button className="text-blue-600 hover:text-blue-800">
                                      <EyeIcon className="h-4 w-4" />
                                    </button>
                                    <button className="text-green-600 hover:text-green-800">
                                      <PencilIcon className="h-4 w-4" />
                                    </button>
                                  </div>
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Original member tabs content */}
                  {(activeTab === 'all' || activeTab === 'players' || activeTab === 'coaches' || activeTab === 'staff') && (
                    <>
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
                    </>
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
        availableJerseyNumbers={availableJerseyNumbers?.available_numbers || []}
        existingUsers={existingUsers}
        isLoading={isLoading}
      />

      {/* Team Form Modal */}
      <TeamForm
        isOpen={isTeamFormOpen}
        onClose={() => {
          setIsTeamFormOpen(false)
          setEditingTeam(null)
        }}
        onSubmit={handleTeamFormSubmit}
        team={editingTeam}
        isLoading={isLoading}
      />
    </div>
  )
}