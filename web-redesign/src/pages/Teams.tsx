import { useEffect, useState } from 'react'
import { 
  UserGroupIcon, 
  PlusIcon,
  PencilIcon,
  TrashIcon,
  EyeIcon,
  ExclamationTriangleIcon,
  UserIcon,
  MapPinIcon,
  CalendarIcon
} from '@heroicons/react/24/outline'
import { useTeamsStore } from '../store/teamsStore'
import type { Team, Player } from '../services/teams'
import { TeamsLoading } from '../components/ui/LoadingStates'
import { ExportButton } from '../components/ui/ExportButton'

export function Teams() {
  const { 
    teams, 
    players, 
    isLoading, 
    error, 
    fetchTeams, 
    fetchPlayers,
    deleteTeam,
    deletePlayer,
    clearError 
  } = useTeamsStore()

  const [showCreateModal, setShowCreateModal] = useState(false)
  const [showPlayerModal, setShowPlayerModal] = useState(false)
  const [selectedTeam, setSelectedTeam] = useState<Team | null>(null)
  const [selectedPlayer, setSelectedPlayer] = useState<Player | null>(null)
  const [activeView, setActiveView] = useState<'teams' | 'players'>('teams')

  useEffect(() => {
    fetchTeams()
  }, [fetchTeams])

  const handleDeleteTeam = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this team?')) {
      await deleteTeam(id)
    }
  }

  const handleDeletePlayer = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this player?')) {
      await deletePlayer(id)
    }
  }

  const handleViewTeam = async (team: Team) => {
    setSelectedTeam(team)
    setActiveView('players')
    await fetchPlayers(team.id)
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-6">
        <div className="flex items-center">
          <ExclamationTriangleIcon className="w-6 h-6 text-red-600 mr-3" />
          <div>
            <h3 className="text-lg font-medium text-red-800">Error loading teams</h3>
            <p className="text-red-600 mt-1">{error}</p>
            <button
              onClick={() => {
                clearError()
                fetchTeams()
              }}
              className="mt-3 bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors"
            >
              Try Again
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div>
      {/* Page Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Teams</h1>
          <p className="mt-2 text-gray-600">Manage your teams and players.</p>
        </div>
        <div className="flex space-x-3">
          <ExportButton
            data={activeView === 'teams' ? teams : players}
            dataType={activeView === 'teams' ? 'teams' : 'players'}
            title={`${activeView === 'teams' ? 'Teams' : 'Players'} Export`}
            size="md"
            variant="outline"
          />
          {activeView === 'teams' && (
            <button 
              onClick={() => setShowCreateModal(true)}
              className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center"
            >
              <PlusIcon className="w-5 h-5 mr-2" />
              Add Team
            </button>
          )}
          {activeView === 'players' && selectedTeam && (
            <button 
              onClick={() => setShowPlayerModal(true)}
              className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center"
            >
              <PlusIcon className="w-5 h-5 mr-2" />
              Add Player
            </button>
          )}
        </div>
      </div>

      {/* Navigation */}
      <div className="mb-6">
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            <button
              onClick={() => setActiveView('teams')}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeView === 'teams'
                  ? 'border-fortaleza-blue text-fortaleza-blue'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              Teams ({teams.length})
            </button>
            {selectedTeam && (
              <button
                onClick={() => setActiveView('players')}
                className={`py-2 px-1 border-b-2 font-medium text-sm ${
                  activeView === 'players'
                    ? 'border-fortaleza-blue text-fortaleza-blue'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                {selectedTeam.name} Players ({players.length})
              </button>
            )}
          </nav>
        </div>
      </div>

      {/* Loading State */}
      {isLoading && <TeamsLoading />}

      {/* Teams View */}
      {activeView === 'teams' && !isLoading && (
        <>
          {teams.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {teams.map((team) => (
                <div key={team.id} className="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
                  <div className="flex items-center justify-between mb-4">
                    <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                      <UserGroupIcon className="w-6 h-6 text-blue-600" />
                    </div>
                    <div className="flex items-center space-x-1">
                      <button 
                        onClick={() => handleViewTeam(team)}
                        className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                        title="View Players"
                      >
                        <EyeIcon className="w-4 h-4" />
                      </button>
                      <button 
                        className="p-2 text-gray-600 hover:text-yellow-600 hover:bg-yellow-50 rounded-lg transition-colors"
                        title="Edit Team"
                      >
                        <PencilIcon className="w-4 h-4" />
                      </button>
                      <button 
                        onClick={() => handleDeleteTeam(team.id)}
                        className="p-2 text-gray-600 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                        title="Delete Team"
                      >
                        <TrashIcon className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                  
                  <h3 className="text-lg font-semibold text-gray-900 mb-2">{team.name}</h3>
                  <p className="text-sm text-gray-600 mb-2">{team.short_name}</p>
                  
                  <div className="space-y-2 text-sm text-gray-500">
                    <div className="flex items-center">
                      <MapPinIcon className="w-4 h-4 mr-2" />
                      {team.city}, {team.state}
                    </div>
                    {team.founded_year && (
                      <div className="flex items-center">
                        <CalendarIcon className="w-4 h-4 mr-2" />
                        Founded {team.founded_year}
                      </div>
                    )}
                    <div className="flex items-center">
                      <UserIcon className="w-4 h-4 mr-2" />
                      {team.players?.length || 0} players
                    </div>
                  </div>
                  
                  <button 
                    onClick={() => handleViewTeam(team)}
                    className="w-full mt-4 bg-fortaleza-blue text-white py-2 rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    View Players
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <div className="bg-white rounded-lg shadow p-12 text-center">
              <UserGroupIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No teams found</h3>
              <p className="text-gray-500 mb-6">Create your first team to get started.</p>
              <button 
                onClick={() => setShowCreateModal(true)}
                className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
              >
                Create Your First Team
              </button>
            </div>
          )}
        </>
      )}

      {/* Players View */}
      {activeView === 'players' && selectedTeam && !isLoading && (
        <>
          <div className="mb-6">
            <button 
              onClick={() => setActiveView('teams')}
              className="text-fortaleza-blue hover:text-blue-700 flex items-center"
            >
              ← Back to Teams
            </button>
            <h2 className="text-2xl font-bold text-gray-900 mt-2">{selectedTeam.name} Players</h2>
          </div>

          {players.length > 0 ? (
            <div className="bg-white rounded-lg shadow overflow-hidden">
              <div className="px-6 py-4 border-b border-gray-200">
                <h3 className="text-lg font-medium text-gray-900">Roster</h3>
              </div>
              <div className="divide-y divide-gray-200">
                {players.map((player) => (
                  <div key={player.id} className="p-6 hover:bg-gray-50">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-4">
                        <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                          <span className="text-lg font-semibold text-blue-600">
                            {player.jersey_number}
                          </span>
                        </div>
                        <div>
                          <h4 className="text-lg font-semibold text-gray-900">
                            {player.first_name} {player.last_name}
                          </h4>
                          <div className="flex items-center space-x-4 text-sm text-gray-500">
                            <span>Position: {player.position}</span>
                            <span>Height: {player.height}</span>
                            <span>Weight: {player.weight} lbs</span>
                            <span className={`px-2 py-1 rounded-full text-xs ${
                              player.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                            }`}>
                              {player.is_active ? 'Active' : 'Inactive'}
                            </span>
                          </div>
                        </div>
                      </div>
                      <div className="flex items-center space-x-1">
                        <button 
                          onClick={() => setSelectedPlayer(player)}
                          className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="View Details"
                        >
                          <EyeIcon className="w-4 h-4" />
                        </button>
                        <button 
                          className="p-2 text-gray-600 hover:text-yellow-600 hover:bg-yellow-50 rounded-lg transition-colors"
                          title="Edit Player"
                        >
                          <PencilIcon className="w-4 h-4" />
                        </button>
                        <button 
                          onClick={() => handleDeletePlayer(player.id)}
                          className="p-2 text-gray-600 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                          title="Delete Player"
                        >
                          <TrashIcon className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div className="bg-white rounded-lg shadow p-12 text-center">
              <UserIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No players found</h3>
              <p className="text-gray-500 mb-6">Add players to {selectedTeam.name} to build your roster.</p>
              <button 
                onClick={() => setShowPlayerModal(true)}
                className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
              >
                Add Your First Player
              </button>
            </div>
          )}
        </>
      )}

      {/* Create Team Modal - Placeholder */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Create New Team</h3>
            <p className="text-gray-600 mb-4">Team creation form will be implemented here.</p>
            <div className="flex justify-end space-x-3">
              <button 
                onClick={() => setShowCreateModal(false)}
                className="px-4 py-2 text-gray-600 hover:text-gray-800"
              >
                Cancel
              </button>
              <button 
                onClick={() => setShowCreateModal(false)}
                className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700"
              >
                Create Team
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Create Player Modal - Placeholder */}
      {showPlayerModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Add New Player</h3>
            <p className="text-gray-600 mb-4">Player creation form will be implemented here.</p>
            <div className="flex justify-end space-x-3">
              <button 
                onClick={() => setShowPlayerModal(false)}
                className="px-4 py-2 text-gray-600 hover:text-gray-800"
              >
                Cancel
              </button>
              <button 
                onClick={() => setShowPlayerModal(false)}
                className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700"
              >
                Add Player
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Player Details Modal - Placeholder */}
      {selectedPlayer && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Player Details</h3>
            <div className="space-y-4">
              <div>
                <h4 className="font-semibold text-gray-900">
                  #{selectedPlayer.jersey_number} {selectedPlayer.first_name} {selectedPlayer.last_name}
                </h4>
                <p className="text-gray-600">Position: {selectedPlayer.position}</p>
                <p className="text-gray-600">Height: {selectedPlayer.height}</p>
                <p className="text-gray-600">Weight: {selectedPlayer.weight} lbs</p>
                <p className="text-gray-600">Date of Birth: {new Date(selectedPlayer.date_of_birth).toLocaleDateString()}</p>
                <p className="text-gray-600">Status: {selectedPlayer.is_active ? 'Active' : 'Inactive'}</p>
              </div>
            </div>
            <div className="flex justify-end mt-6">
              <button 
                onClick={() => setSelectedPlayer(null)}
                className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}