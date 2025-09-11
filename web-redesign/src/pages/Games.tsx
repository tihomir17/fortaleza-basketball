import { useEffect, useState } from 'react'
import { 
  CalendarDaysIcon, 
  ClockIcon, 
  MapPinIcon,
  PlusIcon,
  PencilIcon,
  TrashIcon,
  EyeIcon,
  ExclamationTriangleIcon,
  FunnelIcon,
  MagnifyingGlassIcon,
  AdjustmentsHorizontalIcon
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

  const [selectedGame, setSelectedGame] = useState<Game | null>(null)
  const [activeTab, setActiveTab] = useState<'upcoming' | 'recent' | 'all'>('upcoming')
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [showFilters, setShowFilters] = useState(false)
  const [sortBy, setSortBy] = useState<'date' | 'team' | 'status'>('date')
  const [sortOrder, setSortOrder] = useState<'asc' | 'desc'>('asc')
  
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
      try {
        await deleteGame(id)
        // Refresh the appropriate list
        if (activeTab === 'upcoming') {
          fetchUpcomingGames()
        } else if (activeTab === 'recent') {
          fetchRecentGames()
        } else {
          fetchGames()
        }
      } catch (error) {
        console.error('Failed to delete game:', error)
      }
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
          game.home_team.name.toLowerCase().includes(searchLower) ||
          game.away_team.name.toLowerCase().includes(searchLower)
        
        if (!matchesSearch) return false
      }

      // Status filter - determine status based on game date and scores
      if (statusFilter) {
        const gameDate = new Date(game.game_date)
        const now = new Date()
        let gameStatus = 'SCHEDULED'
        
        if (gameDate < now) {
          gameStatus = 'COMPLETED'
        } else if (gameDate.toDateString() === now.toDateString()) {
          gameStatus = 'IN_PROGRESS'
        }
        
        if (gameStatus !== statusFilter) {
          return false
        }
      }

      // Team filter
      if (teamFilter) {
        const matchesTeam = game.home_team.name === teamFilter || game.away_team.name === teamFilter
        if (!matchesTeam) return false
      }

      // Date filter
      if (dateFilter) {
        const gameDate = new Date(game.game_date)
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
    }).sort((a, b) => {
      let comparison = 0
      
      switch (sortBy) {
        case 'date':
          comparison = new Date(a.game_date).getTime() - new Date(b.game_date).getTime()
          break
        case 'team':
          comparison = a.home_team.name.localeCompare(b.home_team.name)
          break
        case 'status': {
          const getGameStatus = (game: Game) => {
            const gameDate = new Date(game.game_date)
            const now = new Date()
            if (gameDate < now) return 'COMPLETED'
            if (gameDate.toDateString() === now.toDateString()) return 'IN_PROGRESS'
            return 'SCHEDULED'
          }
          comparison = getGameStatus(a).localeCompare(getGameStatus(b))
          break
        }
      }
      
      return sortOrder === 'asc' ? comparison : -comparison
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
      <div className="mb-8">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Games</h1>
            <p className="mt-2 text-gray-600 dark:text-gray-400">Manage your team's games and schedule.</p>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              Showing {getCurrentGames().length} games
            </p>
          </div>
          <div className="flex items-center space-x-3 mt-4 sm:mt-0">
            <ExportButton
              data={getCurrentGames()}
              dataType="games"
              title="Games Export"
              size="md"
              variant="outline"
            />
            <button 
              onClick={() => window.location.href = '/games/add'}
              className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center"
            >
              <PlusIcon className="w-5 h-5 mr-2" />
              Add Game
            </button>
          </div>
        </div>

        {/* Enhanced Controls */}
        <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between space-y-4 lg:space-y-0">
          {/* Search and Filters */}
          <div className="flex flex-col sm:flex-row sm:items-center space-y-3 sm:space-y-0 sm:space-x-4">
            <div className="relative">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search games..."
                value={searchValue}
                onChange={(e) => setSearchValue(e.target.value)}
                className="pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
              />
            </div>
            
            <button
              onClick={() => setShowFilters(!showFilters)}
              className={`flex items-center space-x-2 px-4 py-2 rounded-lg border transition-colors ${
                showFilters 
                  ? 'bg-blue-50 border-blue-200 text-blue-700 dark:bg-blue-900/50 dark:border-blue-700 dark:text-blue-300'
                  : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-600'
              }`}
            >
              <FunnelIcon className="w-4 h-4" />
              <span>Filters</span>
            </button>
          </div>

          {/* View and Sort Controls */}
          <div className="flex items-center space-x-4">
            {/* View Mode Toggle */}
            <div className="flex items-center bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
              <button
                onClick={() => setViewMode('grid')}
                className={`p-2 rounded-md transition-colors ${
                  viewMode === 'grid' 
                    ? 'bg-white dark:bg-gray-600 shadow-sm' 
                    : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
                }`}
              >
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path d="M5 3a2 2 0 00-2 2v2a2 2 0 002 2h2a2 2 0 002-2V5a2 2 0 00-2-2H5zM5 11a2 2 0 00-2 2v2a2 2 0 002 2h2a2 2 0 002-2v-2a2 2 0 00-2-2H5zM11 5a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V5zM11 13a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
                </svg>
              </button>
              <button
                onClick={() => setViewMode('list')}
                className={`p-2 rounded-md transition-colors ${
                  viewMode === 'list' 
                    ? 'bg-white dark:bg-gray-600 shadow-sm' 
                    : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300'
                }`}
              >
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M3 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clipRule="evenodd" />
                </svg>
              </button>
            </div>

            {/* Sort Controls */}
            <div className="flex items-center space-x-2">
              <AdjustmentsHorizontalIcon className="w-4 h-4 text-gray-400" />
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as 'date' | 'team' | 'status')}
                className="px-3 py-1 border border-gray-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:border-gray-600 dark:text-white"
              >
                <option value="date">Date</option>
                <option value="team">Team</option>
                <option value="status">Status</option>
              </select>
              <button
                onClick={() => setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc')}
                className="p-1 hover:bg-gray-100 dark:hover:bg-gray-600 rounded transition-colors"
                title={`Sort ${sortOrder === 'asc' ? 'Descending' : 'Ascending'}`}
              >
                {sortOrder === 'asc' ? (
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M14.707 12.707a1 1 0 01-1.414 0L10 9.414l-3.293 3.293a1 1 0 01-1.414-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 010 1.414z" clipRule="evenodd" />
                  </svg>
                ) : (
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clipRule="evenodd" />
                  </svg>
                )}
              </button>
            </div>
          </div>
        </div>

        {/* Advanced Filters Panel */}
        {showFilters && (
          <div className="mt-4 p-4 bg-gray-50 dark:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Status</label>
                <select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-600 dark:border-gray-500 dark:text-white"
                >
                  <option value="">All Status</option>
                  <option value="SCHEDULED">Scheduled</option>
                  <option value="IN_PROGRESS">In Progress</option>
                  <option value="COMPLETED">Completed</option>
                  <option value="CANCELLED">Cancelled</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Team</label>
                <select
                  value={teamFilter}
                  onChange={(e) => setTeamFilter(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-600 dark:border-gray-500 dark:text-white"
                >
                  <option value="">All Teams</option>
                  <option value="Fortaleza">Fortaleza</option>
                  <option value="Lakers">Lakers</option>
                  <option value="Warriors">Warriors</option>
                  <option value="Celtics">Celtics</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">Date Range</label>
                <select
                  value={dateFilter}
                  onChange={(e) => setDateFilter(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-600 dark:border-gray-500 dark:text-white"
                >
                  <option value="">All Dates</option>
                  <option value="today">Today</option>
                  <option value="tomorrow">Tomorrow</option>
                  <option value="this_week">This Week</option>
                  <option value="upcoming">Upcoming</option>
                  <option value="past">Past</option>
                </select>
              </div>
              
              <div className="flex items-end">
                <button
                  onClick={() => {
                    setSearchValue('')
                    setStatusFilter('')
                    setTeamFilter('')
                    setDateFilter('')
                  }}
                  className="w-full px-4 py-2 bg-gray-200 dark:bg-gray-600 text-gray-700 dark:text-gray-300 rounded-md hover:bg-gray-300 dark:hover:bg-gray-500 transition-colors text-sm"
                >
                  Clear Filters
                </button>
              </div>
            </div>
          </div>
        )}
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
                        {game.home_team.name} vs {game.away_team.name}
                      </h4>
                      <div className="flex items-center space-x-4 text-sm text-gray-500">
                        <div className="flex items-center">
                          <ClockIcon className="w-4 h-4 mr-1" />
                          {new Date(game.game_date).toLocaleDateString()} at {new Date(game.game_date).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                        </div>
                        <div className="flex items-center">
                          <MapPinIcon className="w-4 h-4 mr-1" />
                          Home Court
                        </div>
                        {(game.home_team_score > 0 || game.away_team_score > 0) && (
                          <div className="font-semibold text-gray-900">
                            {game.home_team_score} - {game.away_team_score}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <span className={`px-3 py-1 text-sm rounded-full ${(() => {
                      const gameDate = new Date(game.game_date)
                      const now = new Date()
                      let status = 'SCHEDULED'
                      if (gameDate < now) status = 'COMPLETED'
                      else if (gameDate.toDateString() === now.toDateString()) status = 'IN_PROGRESS'
                      return getStatusColor(status)
                    })()}`}>
                      {(() => {
                        const gameDate = new Date(game.game_date)
                        const now = new Date()
                        if (gameDate < now) return 'COMPLETED'
                        if (gameDate.toDateString() === now.toDateString()) return 'IN_PROGRESS'
                        return 'SCHEDULED'
                      })().replace('_', ' ')}
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
            onClick={() => window.location.href = '/games/add'}
            className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Add Your First Game
          </button>
        </div>
      )}


      {/* Game Details Modal - Placeholder */}
      {selectedGame && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Game Details</h3>
            <div className="space-y-4">
              <div>
                <h4 className="font-semibold text-gray-900">{selectedGame.home_team.name} vs {selectedGame.away_team.name}</h4>
                <p className="text-gray-600">Date: {new Date(selectedGame.game_date).toLocaleDateString()}</p>
                <p className="text-gray-600">Time: {new Date(selectedGame.game_date).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</p>
                <p className="text-gray-600">Venue: Home Court</p>
                <p className="text-gray-600">Score: {selectedGame.home_team_score} - {selectedGame.away_team_score}</p>
                <p className="text-gray-600">Quarter: {selectedGame.quarter}</p>
                <p className="text-gray-600">Lead Changes: {selectedGame.lead_changes}</p>
                <p className="text-gray-600">Clutch Situations: {selectedGame.clutch_situations}</p>
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