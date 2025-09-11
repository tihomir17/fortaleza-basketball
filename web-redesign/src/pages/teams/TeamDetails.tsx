import { useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useTeamsStore } from '../../store/teamsStore'
// TeamMember type not used in this component
import { 
  Users, 
  Edit, 
  Settings, 
  User, 
  UserCheck, 
  UserX,
  Shirt
} from 'lucide-react'

export function TeamDetails() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const teamId = id ? parseInt(id) : 0
  
  const {
    currentTeam,
    isLoading,
    error,
    fetchTeam,
    fetchTeamMembers,
    clearError
  } = useTeamsStore()

  useEffect(() => {
    if (teamId) {
      fetchTeam(teamId)
      fetchTeamMembers(teamId)
    }
  }, [teamId, fetchTeam, fetchTeamMembers])

  const formatCoachType = (coachType?: string) => {
    if (!coachType || coachType === 'NONE') return 'Coach'
    return coachType
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map(word => word[0].toUpperCase() + word.substring(1))
      .join(' ')
  }

  const formatStaffType = (staffType?: string) => {
    if (!staffType || staffType === 'NONE') return 'Staff'
    return staffType
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map(word => word[0].toUpperCase() + word.substring(1))
      .join(' ')
  }

  const getDisplayName = (member: { first_name?: string; last_name?: string; username: string }) => {
    if (member.first_name && member.last_name) {
      return `${member.first_name} ${member.last_name}`
    }
    return member.username
  }

  if (isLoading && !currentTeam) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="animate-fade-in">
        <div className="bg-red-50 border border-red-200 rounded-md p-4">
          <div className="flex">
            <div className="flex-shrink-0">
              <UserX className="h-5 w-5 text-red-400" />
            </div>
            <div className="ml-3">
              <h3 className="text-sm font-medium text-red-800">Error loading team</h3>
              <div className="mt-2 text-sm text-red-700">
                <p>{error}</p>
              </div>
              <div className="mt-4">
                <button
                  onClick={() => {
                    clearError()
                    if (teamId) {
                      fetchTeam(teamId)
                      fetchTeamMembers(teamId)
                    }
                  }}
                  className="bg-red-100 px-3 py-2 rounded-md text-sm font-medium text-red-800 hover:bg-red-200"
                >
                  Try again
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (!currentTeam) {
    return (
      <div className="animate-fade-in">
        <div className="text-center py-12">
          <UserX className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900 dark:text-white">Team not found</h3>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            The team you're looking for doesn't exist or you don't have permission to view it.
          </p>
          <div className="mt-6">
            <button
              onClick={() => navigate('/teams')}
              className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
            >
              Back to Teams
            </button>
          </div>
        </div>
      </div>
    )
  }

  // Sort players by jersey number, then by name
  const sortedPlayers = [...(currentTeam.players || [])].sort((a, b) => {
    const numA = a.jersey_number ?? 1000
    const numB = b.jersey_number ?? 1000
    if (numA === numB) return getDisplayName(a).localeCompare(getDisplayName(b))
    return numA - numB
  })

  // Sort coaches so HEAD_COACH appears first
  const sortedCoaches = [...(currentTeam.coaches || [])].sort((a, b) => {
    if (a.coach_type === 'HEAD_COACH' && b.coach_type !== 'HEAD_COACH') return -1
    if (a.coach_type !== 'HEAD_COACH' && b.coach_type === 'HEAD_COACH') return 1
    return 0
  })

  return (
    <div className="animate-fade-in">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white uppercase">
              {currentTeam.name}
            </h1>
            <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
              Created by {getDisplayName(currentTeam.created_by)} • {currentTeam.total_members} members
            </p>
          </div>
          <div className="flex space-x-3">
            <button
              onClick={() => navigate(`/teams/${teamId}/manage-roster`)}
              className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 dark:bg-gray-800 dark:text-gray-300 dark:border-gray-600 dark:hover:bg-gray-700"
            >
              <Users className="h-4 w-4 mr-2" />
              Manage Roster
            </button>
            <button
              onClick={() => navigate(`/teams/${teamId}/edit`)}
              className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
            >
              <Edit className="h-4 w-4 mr-2" />
              Edit Team
            </button>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <div className="bg-white dark:bg-gray-800 overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <UserCheck className="h-6 w-6 text-blue-600" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 dark:text-gray-400 truncate">
                    Coaches
                  </dt>
                  <dd className="text-lg font-medium text-gray-900 dark:text-white">
                    {currentTeam.coach_count}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Shirt className="h-6 w-6 text-green-600" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 dark:text-gray-400 truncate">
                    Players
                  </dt>
                  <dd className="text-lg font-medium text-gray-900 dark:text-white">
                    {currentTeam.player_count}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Settings className="h-6 w-6 text-purple-600" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 dark:text-gray-400 truncate">
                    Staff
                  </dt>
                  <dd className="text-lg font-medium text-gray-900 dark:text-white">
                    {currentTeam.staff_count}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <Users className="h-6 w-6 text-orange-600" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 dark:text-gray-400 truncate">
                    Total Members
                  </dt>
                  <dd className="text-lg font-medium text-gray-900 dark:text-white">
                    {currentTeam.total_members}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Coaching Staff Section */}
      <div className="bg-white dark:bg-gray-800 shadow rounded-lg mb-6">
        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h2 className="text-lg font-medium text-gray-900 dark:text-white">Coaching Staff</h2>
        </div>
        <div className="divide-y divide-gray-200 dark:divide-gray-700">
          {sortedCoaches.length === 0 ? (
            <div className="px-6 py-8 text-center">
              <UserCheck className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900 dark:text-white">No coaches assigned</h3>
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Get started by adding coaches to your team.
              </p>
            </div>
          ) : (
            sortedCoaches.map((coach) => (
              <div key={coach.id} className="px-6 py-4 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <div className="h-10 w-10 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center">
                      <User className="h-5 w-5 text-blue-600 dark:text-blue-400" />
                    </div>
                  </div>
                  <div className="ml-4">
                    <div className="text-sm font-medium text-gray-900 dark:text-white">
                      {getDisplayName(coach)}
                    </div>
                    <div className="text-sm text-gray-500 dark:text-gray-400">
                      {formatCoachType(coach.coach_type)}
                    </div>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => navigate(`/users/${coach.id}/edit`)}
                    className="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                  >
                    <Edit className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Staff Section */}
      <div className="bg-white dark:bg-gray-800 shadow rounded-lg mb-6">
        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h2 className="text-lg font-medium text-gray-900 dark:text-white">Staff</h2>
        </div>
        <div className="divide-y divide-gray-200 dark:divide-gray-700">
          {currentTeam.staff.length === 0 ? (
            <div className="px-6 py-8 text-center">
              <Settings className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900 dark:text-white">No staff assigned</h3>
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Add staff members to support your team.
              </p>
            </div>
          ) : (
            currentTeam.staff.map((staff) => (
              <div key={staff.id} className="px-6 py-4 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <div className="h-10 w-10 rounded-full bg-purple-100 dark:bg-purple-900 flex items-center justify-center">
                      <Settings className="h-5 w-5 text-purple-600 dark:text-purple-400" />
                    </div>
                  </div>
                  <div className="ml-4">
                    <div className="text-sm font-medium text-gray-900 dark:text-white">
                      {getDisplayName(staff)}
                    </div>
                    <div className="text-sm text-gray-500 dark:text-gray-400">
                      {formatStaffType(staff.staff_type)}
                    </div>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => navigate(`/users/${staff.id}/edit`)}
                    className="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                  >
                    <Edit className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Players Section */}
      <div className="bg-white dark:bg-gray-800 shadow rounded-lg">
        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h2 className="text-lg font-medium text-gray-900 dark:text-white">Players</h2>
        </div>
        <div className="divide-y divide-gray-200 dark:divide-gray-700">
          {sortedPlayers.length === 0 ? (
            <div className="px-6 py-8 text-center">
              <Shirt className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-2 text-sm font-medium text-gray-900 dark:text-white">No players assigned</h3>
              <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                Start building your roster by adding players.
              </p>
            </div>
          ) : (
            sortedPlayers.map((player) => (
              <div key={player.id} className="px-6 py-4 flex items-center justify-between">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <div className="h-10 w-10 rounded-full bg-green-100 dark:bg-green-900 flex items-center justify-center">
                      <span className="text-sm font-bold text-green-600 dark:text-green-400">
                        {player.jersey_number || '#'}
                      </span>
                    </div>
                  </div>
                  <div className="ml-4">
                    <div className="text-sm font-medium text-gray-900 dark:text-white">
                      {getDisplayName(player)}
                    </div>
                    <div className="text-sm text-gray-500 dark:text-gray-400">
                      Player
                    </div>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => navigate(`/users/${player.id}/edit`)}
                    className="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300"
                  >
                    <Edit className="h-4 w-4" />
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  )
}
