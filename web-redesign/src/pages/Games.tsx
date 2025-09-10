import { useEffect, useState } from 'react'
import { 
  CalendarDaysIcon, 
  ClockIcon, 
  MapPinIcon,
  PlusIcon,
  PencilIcon,
  TrashIcon,
  EyeIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline'
import { useGamesStore } from '../store/gamesStore'
import type { Game } from '../services/games'
import { GamesLoading } from '../components/ui/LoadingStates'
import { GamesBreadcrumb } from '../components/ui/Breadcrumb'
import { GameSearchFilter } from '../components/ui/SearchFilter'
import { ExportButton } from '../components/ui/ExportButton'

export function Games() {
  const { 
    games, 
    upcomingGames, 
    recentGames, 
    isLoading, 
    error, 
    fetchGames, 
    fetchUpcomingGames, 
    fetchRecentGames,
    deleteGame,
    clearError 
  } = useGamesStore()

  const [showCreateModal, setShowCreateModal] = useState(false)
  const [selectedGame, setSelectedGame] = useState<Game | null>(null)
  const [activeTab, setActiveTab] = useState<'upcoming' | 'recent' | 'all'>('upcoming')
  
  // Search and filter states
  const [searchValue, setSearchValue] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [teamFilter, setTeamFilter] = useState('')
  const [dateFilter, setDateFilter] = useState('')

  useEffect(() => {
    fetchUpcomingGames()
    fetchRecentGames()
    fetchGames()
  }, [fetchUpcomingGames, fetchRecentGames, fetchGames])

  const handleDeleteGame = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this game?')) {
      await deleteGame(id)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'SCHEDULED':
        return 'bg-blue-100 text-blue-800'
      case 'IN_PROGRESS':
        return 'bg-yellow-100 text-yellow-800'
      case 'COMPLETED':
        return 'bg-green-100 text-green-800'
      case 'CANCELLED':
        return 'bg-red-100 text-red-800'
      default:
        return 'bg-gray-100 text-gray-800'
    }
  }

  const getCurrentGames = () => {
    let currentGames: Game[] = []
    switch (activeTab) {
      case 'upcoming':
        currentGames = upcomingGames
        break
      case 'recent':
        currentGames = recentGames
        break
      case 'all':
        currentGames = games
        break
      default:
        currentGames = []
    }

    // Apply search and filters
    return currentGames.filter(game => {
      // Search filter
      if (searchValue) {
        const searchLower = searchValue.toLowerCase()
        const matchesSearch = 
          game.home_team_name.toLowerCase().includes(searchLower) ||
          game.away_team_name.toLowerCase().includes(searchLower) ||
          game.venue?.toLowerCase().includes(searchLower)
        
        if (!matchesSearch) return false
      }

      // Status filter
      if (statusFilter && game.status !== statusFilter) {
        return false
      }

      // Team filter
      if (teamFilter) {
        const matchesTeam = game.home_team_name === teamFilter || game.away_team_name === teamFilter
        if (!matchesTeam) return false
      }

      // Date filter
      if (dateFilter) {
        const gameDate = new Date(game.date)
        const today = new Date()
        today.setHours(0, 0, 0, 0)

        switch (dateFilter) {
          case 'today':
            if (gameDate.toDateString() !== today.toDateString()) return false
            break
          case 'tomorrow': {
            const tomorrow = new Date(today)
            tomorrow.setDate(tomorrow.getDate() + 1)
            if (gameDate.toDateString() !== tomorrow.toDateString()) return false
            break
          }
          case 'this_week': {
            const weekStart = new Date(today)
            weekStart.setDate(today.getDate() - today.getDay())
            const weekEnd = new Date(weekStart)
            weekEnd.setDate(weekStart.getDate() + 6)
            if (gameDate < weekStart || gameDate > weekEnd) return false
            break
          }
          case 'upcoming':
            if (gameDate < today) return false
            break
          case 'past':
            if (gameDate >= today) return false
            break
        }
      }

      return true
    })
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-6">
        <div className="flex items-center">
          <ExclamationTriangleIcon className="w-6 h-6 text-red-600 mr-3" />
          <div>
            <h3 className="text-lg font-medium text-red-800">Error loading games</h3>
            <p className="text-red-600 mt-1">{error}</p>
            <button
              onClick={() => {
                clearError()
                fetchGames()
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
      {/* Breadcrumb */}
      <div className="mb-6">
        <GamesBreadcrumb />
      </div>

      {/* Page Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Games</h1>
          <p className="mt-2 text-gray-600 dark:text-gray-400">Manage your team's games and schedule.</p>
        </div>
        <div className="flex items-center space-x-3">
          <ExportButton
            data={getCurrentGames()}
            dataType="games"
            title="Games Export"
            size="md"
            variant="outline"
          />
          <button 
            onClick={() => setShowCreateModal(true)}
            className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center"
          >
            <PlusIcon className="w-5 h-5 mr-2" />
            Add Game
          </button>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="mb-6">
        <GameSearchFilter
          searchValue={searchValue}
          onSearchChange={setSearchValue}
          statusFilter={statusFilter}
          onStatusChange={setStatusFilter}
          teamFilter={teamFilter}
          onTeamChange={setTeamFilter}
          dateFilter={dateFilter}
          onDateChange={setDateFilter}
          teams={[
            { id: 'fortaleza', name: 'Fortaleza' },
            { id: 'lakers', name: 'Lakers' },
            { id: 'warriors', name: 'Warriors' },
            { id: 'celtics', name: 'Celtics' }
          ]}
        />
      </div>

      {/* Tabs */}
      <div className="mb-6">
        <div className="border-b border-gray-200 dark:border-gray-700">
          <nav className="-mb-px flex space-x-8">
            <button
              onClick={() => setActiveTab('upcoming')}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'upcoming'
                  ? 'border-fortaleza-blue text-fortaleza-blue'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              Upcoming ({upcomingGames.length})
            </button>
            <button
              onClick={() => setActiveTab('recent')}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'recent'
                  ? 'border-fortaleza-blue text-fortaleza-blue'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              Recent ({recentGames.length})
            </button>
            <button
              onClick={() => setActiveTab('all')}
              className={`py-2 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'all'
                  ? 'border-fortaleza-blue text-fortaleza-blue'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              All Games ({games.length})
            </button>
          </nav>
        </div>
      </div>

      {/* Loading State */}
      {isLoading && getCurrentGames().length === 0 && <GamesLoading />}

      {/* Games List */}
      {getCurrentGames().length > 0 ? (
        <div className="bg-white rounded-lg shadow">
          <div className="divide-y divide-gray-200">
            {getCurrentGames().map((game) => (
              <div key={game.id} className="p-6 hover:bg-gray-50">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                      <CalendarDaysIcon className="w-6 h-6 text-blue-600" />
                    </div>
                    <div>
                      <h4 className="text-lg font-semibold text-gray-900">
                        {game.home_team_name} vs {game.away_team_name}
                      </h4>
                      <div className="flex items-center space-x-4 text-sm text-gray-500">
                        <div className="flex items-center">
                          <ClockIcon className="w-4 h-4 mr-1" />
                          {new Date(game.date).toLocaleDateString()} at {game.time}
                        </div>
                        <div className="flex items-center">
                          <MapPinIcon className="w-4 h-4 mr-1" />
                          {game.venue}
                        </div>
                        {game.home_score !== undefined && game.away_score !== undefined && (
                          <div className="font-semibold text-gray-900">
                            {game.home_score} - {game.away_score}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className={`px-3 py-1 text-sm rounded-full ${getStatusColor(game.status)}`}>
                      {game.status.replace('_', ' ')}
                    </span>
                    <div className="flex items-center space-x-1">
                      <button 
                        onClick={() => setSelectedGame(game)}
                        className="p-2 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                        title="View Details"
                      >
                        <EyeIcon className="w-4 h-4" />
                      </button>
                      <button 
                        className="p-2 text-gray-600 hover:text-yellow-600 hover:bg-yellow-50 rounded-lg transition-colors"
                        title="Edit Game"
                      >
                        <PencilIcon className="w-4 h-4" />
                      </button>
                      <button 
                        onClick={() => handleDeleteGame(game.id)}
                        className="p-2 text-gray-600 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                        title="Delete Game"
                      >
                        <TrashIcon className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      ) : !isLoading && (
        <div className="bg-white rounded-lg shadow p-12 text-center">
          <CalendarDaysIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No games found</h3>
          <p className="text-gray-500 mb-6">
            {activeTab === 'upcoming' 
              ? "You don't have any upcoming games scheduled."
              : activeTab === 'recent'
              ? "No recent games to display."
              : "No games have been created yet."
            }
          </p>
          <button 
            onClick={() => setShowCreateModal(true)}
            className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Add Your First Game
          </button>
        </div>
      )}

      {/* Create Game Modal - Placeholder */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Create New Game</h3>
            <p className="text-gray-600 mb-4">Game creation form will be implemented here.</p>
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
                Create Game
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Game Details Modal - Placeholder */}
      {selectedGame && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Game Details</h3>
            <div className="space-y-4">
              <div>
                <h4 className="font-semibold text-gray-900">{selectedGame.home_team_name} vs {selectedGame.away_team_name}</h4>
                <p className="text-gray-600">Date: {new Date(selectedGame.date).toLocaleDateString()}</p>
                <p className="text-gray-600">Time: {selectedGame.time}</p>
                <p className="text-gray-600">Venue: {selectedGame.venue}</p>
                <p className="text-gray-600">Status: {selectedGame.status}</p>
              </div>
            </div>
            <div className="flex justify-end mt-6">
              <button 
                onClick={() => setSelectedGame(null)}
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