import { useState, useMemo } from 'react'
import {
  MagnifyingGlassIcon,
  FunnelIcon,
  XMarkIcon,
  ClockIcon,
  UserGroupIcon,
  ChartBarIcon,
  EyeIcon
} from '@heroicons/react/24/outline'
import type { Possession } from '../../services/gameTracking'

interface PossessionHistoryProps {
  possessions: Possession[]
  homeTeamId: number
  awayTeamId: number
  homeTeamName: string
  awayTeamName: string
}

interface FilterState {
  search: string
  quarter: string
  outcome: string
  team: string
  player: string
  offensiveSet: string
  defensiveSet: string
  timeRange: string
}

export function PossessionHistory({ 
  possessions, 
  homeTeamId, 
  awayTeamId, 
  homeTeamName, 
  awayTeamName 
}: PossessionHistoryProps) {
  const [showFilters, setShowFilters] = useState(false)
  const [filters, setFilters] = useState<FilterState>({
    search: '',
    quarter: '',
    outcome: '',
    team: '',
    player: '',
    offensiveSet: '',
    defensiveSet: '',
    timeRange: ''
  })

  // Get unique values for filter options
  const filterOptions = useMemo(() => {
    const quarters = [...new Set(possessions.map(p => p.quarter))].sort()
    const outcomes = [...new Set(possessions.map(p => p.outcome))].sort()
    const offensiveSets = [...new Set(possessions.map(p => p.offensive_set).filter(Boolean))].sort()
    const defensiveSets = [...new Set(possessions.map(p => p.defensive_set).filter(Boolean))].sort()
    
    // Get all players involved in possessions
    const players = new Set<string>()
    possessions.forEach(possession => {
      if (possession.scorer) {
        players.add(`${possession.scorer.first_name} ${possession.scorer.last_name}`)
      }
      if (possession.assisted_by) {
        players.add(`${possession.assisted_by.first_name} ${possession.assisted_by.last_name}`)
      }
      if (possession.blocked_by) {
        players.add(`${possession.blocked_by.first_name} ${possession.blocked_by.last_name}`)
      }
      if (possession.stolen_by) {
        players.add(`${possession.stolen_by.first_name} ${possession.stolen_by.last_name}`)
      }
    })

    return {
      quarters,
      outcomes,
      offensiveSets,
      defensiveSets,
      players: Array.from(players).sort()
    }
  }, [possessions])

  // Filter possessions based on current filters
  const filteredPossessions = useMemo(() => {
    return possessions.filter(possession => {
      // Search filter
      if (filters.search) {
        const searchLower = filters.search.toLowerCase()
        const searchableText = [
          possession.scorer?.first_name,
          possession.scorer?.last_name,
          possession.assisted_by?.first_name,
          possession.assisted_by?.last_name,
          possession.outcome,
          possession.offensive_set,
          possession.defensive_set
        ].filter(Boolean).join(' ').toLowerCase()
        
        if (!searchableText.includes(searchLower)) {
          return false
        }
      }

      // Quarter filter
      if (filters.quarter && possession.quarter.toString() !== filters.quarter) {
        return false
      }

      // Outcome filter
      if (filters.outcome && possession.outcome !== filters.outcome) {
        return false
      }

      // Team filter
      if (filters.team) {
        if (filters.team === 'home' && possession.team.team.id !== homeTeamId) {
          return false
        }
        if (filters.team === 'away' && possession.team.team.id !== awayTeamId) {
          return false
        }
      }

      // Player filter
      if (filters.player) {
        const playerName = filters.player
        const hasPlayer = 
          (possession.scorer && `${possession.scorer.first_name} ${possession.scorer.last_name}` === playerName) ||
          (possession.assisted_by && `${possession.assisted_by.first_name} ${possession.assisted_by.last_name}` === playerName) ||
          (possession.blocked_by && `${possession.blocked_by.first_name} ${possession.blocked_by.last_name}` === playerName) ||
          (possession.stolen_by && `${possession.stolen_by.first_name} ${possession.stolen_by.last_name}` === playerName)
        
        if (!hasPlayer) {
          return false
        }
      }

      // Offensive set filter
      if (filters.offensiveSet && possession.offensive_set !== filters.offensiveSet) {
        return false
      }

      // Defensive set filter
      if (filters.defensiveSet && possession.defensive_set !== filters.defensiveSet) {
        return false
      }

      // Time range filter
      if (filters.timeRange) {
        const timeInSeconds = parseTimeToSeconds(possession.start_time_in_game)
        switch (filters.timeRange) {
          case 'early':
            if (timeInSeconds < 300) return false // Less than 5 minutes
            break
          case 'mid':
            if (timeInSeconds < 600 || timeInSeconds > 1200) return false // 5-20 minutes
            break
          case 'late':
            if (timeInSeconds > 1200) return false // More than 20 minutes
            break
        }
      }

      return true
    })
  }, [possessions, filters, homeTeamId, awayTeamId])

  const parseTimeToSeconds = (timeString: string): number => {
    const [minutes, seconds] = timeString.split(':').map(Number)
    return minutes * 60 + seconds
  }

  const clearFilters = () => {
    setFilters({
      search: '',
      quarter: '',
      outcome: '',
      team: '',
      player: '',
      offensiveSet: '',
      defensiveSet: '',
      timeRange: ''
    })
  }

  const activeFiltersCount = Object.values(filters).filter(value => value !== '').length

  const getOutcomeColor = (outcome: string) => {
    if (outcome.includes('MADE')) return 'bg-green-100 text-green-800'
    if (outcome.includes('MISSED')) return 'bg-red-100 text-red-800'
    if (outcome === 'TURNOVER') return 'bg-orange-100 text-orange-800'
    if (outcome === 'FOUL') return 'bg-yellow-100 text-yellow-800'
    if (outcome === 'REBOUND') return 'bg-blue-100 text-blue-800'
    if (outcome === 'STEAL') return 'bg-purple-100 text-purple-800'
    if (outcome === 'BLOCK') return 'bg-indigo-100 text-indigo-800'
    return 'bg-gray-100 text-gray-800'
  }

  const getTeamColor = (teamId: number) => {
    return teamId === homeTeamId ? 'bg-blue-600' : 'bg-yellow-600'
  }

  return (
    <div className="space-y-4">
      {/* Search and Filter Bar */}
      <div className="bg-white rounded-lg shadow p-4">
        <div className="flex items-center space-x-4">
          {/* Search Input */}
          <div className="flex-1 relative">
            <MagnifyingGlassIcon className="h-5 w-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Search possessions..."
              value={filters.search}
              onChange={(e) => setFilters(prev => ({ ...prev, search: e.target.value }))}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
            />
          </div>

          {/* Filter Toggle Button */}
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`flex items-center px-4 py-2 rounded-md border transition-colors ${
              showFilters || activeFiltersCount > 0
                ? 'bg-blue-600 text-white border-blue-600'
                : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
            }`}
          >
            <FunnelIcon className="h-4 w-4 mr-2" />
            Filters
            {activeFiltersCount > 0 && (
              <span className="ml-2 bg-white text-blue-600 text-xs font-semibold px-2 py-1 rounded-full">
                {activeFiltersCount}
              </span>
            )}
          </button>
        </div>

        {/* Filter Panel */}
        {showFilters && (
          <div className="mt-4 pt-4 border-t border-gray-200">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              {/* Quarter Filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Quarter</label>
                <select
                  value={filters.quarter}
                  onChange={(e) => setFilters(prev => ({ ...prev, quarter: e.target.value }))}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">All Quarters</option>
                  {filterOptions.quarters.map(quarter => (
                    <option key={quarter} value={quarter}>Q{quarter}</option>
                  ))}
                </select>
              </div>

              {/* Outcome Filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Outcome</label>
                <select
                  value={filters.outcome}
                  onChange={(e) => setFilters(prev => ({ ...prev, outcome: e.target.value }))}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">All Outcomes</option>
                  {filterOptions.outcomes.map(outcome => (
                    <option key={outcome} value={outcome}>
                      {outcome.replace(/_/g, ' ').toLowerCase()}
                    </option>
                  ))}
                </select>
              </div>

              {/* Team Filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Team</label>
                <select
                  value={filters.team}
                  onChange={(e) => setFilters(prev => ({ ...prev, team: e.target.value }))}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">All Teams</option>
                  <option value="home">{homeTeamName}</option>
                  <option value="away">{awayTeamName}</option>
                </select>
              </div>

              {/* Player Filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Player</label>
                <select
                  value={filters.player}
                  onChange={(e) => setFilters(prev => ({ ...prev, player: e.target.value }))}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">All Players</option>
                  {filterOptions.players.map(player => (
                    <option key={player} value={player}>{player}</option>
                  ))}
                </select>
              </div>

              {/* Offensive Set Filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Offensive Set</label>
                <select
                  value={filters.offensiveSet}
                  onChange={(e) => setFilters(prev => ({ ...prev, offensiveSet: e.target.value }))}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">All Sets</option>
                  {filterOptions.offensiveSets.map(set => (
                    <option key={set} value={set}>{set}</option>
                  ))}
                </select>
              </div>

              {/* Defensive Set Filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Defensive Set</label>
                <select
                  value={filters.defensiveSet}
                  onChange={(e) => setFilters(prev => ({ ...prev, defensiveSet: e.target.value }))}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">All Sets</option>
                  {filterOptions.defensiveSets.map(set => (
                    <option key={set} value={set}>{set}</option>
                  ))}
                </select>
              </div>

              {/* Time Range Filter */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Time Range</label>
                <select
                  value={filters.timeRange}
                  onChange={(e) => setFilters(prev => ({ ...prev, timeRange: e.target.value }))}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">All Times</option>
                  <option value="early">Early Game (0-5 min)</option>
                  <option value="mid">Mid Game (5-20 min)</option>
                  <option value="late">Late Game (20+ min)</option>
                </select>
              </div>
            </div>

            {/* Clear Filters Button */}
            {activeFiltersCount > 0 && (
              <div className="mt-4 flex justify-end">
                <button
                  onClick={clearFilters}
                  className="flex items-center px-3 py-2 text-sm text-gray-600 hover:text-gray-800 transition-colors"
                >
                  <XMarkIcon className="h-4 w-4 mr-1" />
                  Clear all filters
                </button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Results Summary */}
      <div className="flex items-center justify-between text-sm text-gray-600">
        <span>
          Showing {filteredPossessions.length} of {possessions.length} possessions
        </span>
        {activeFiltersCount > 0 && (
          <span className="text-blue-600">
            {activeFiltersCount} filter{activeFiltersCount !== 1 ? 's' : ''} applied
          </span>
        )}
      </div>

      {/* Possessions List */}
      <div className="space-y-3">
        {filteredPossessions.length > 0 ? (
          filteredPossessions.map((possession) => (
            <div key={possession.id} className="bg-white rounded-lg shadow p-4 hover:shadow-md transition-shadow">
              <div className="flex items-start justify-between">
                <div className="flex items-start space-x-4">
                  {/* Team Indicator */}
                  <div className={`w-3 h-3 rounded-full mt-2 ${getTeamColor(possession.team.team.id)}`}></div>
                  
                  {/* Possession Details */}
                  <div className="flex-1">
                    <div className="flex items-center space-x-2 mb-2">
                      <span className="text-sm font-medium text-gray-900">
                        Q{possession.quarter} • {possession.start_time_in_game}
                      </span>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${getOutcomeColor(possession.outcome)}`}>
                        {possession.outcome.replace(/_/g, ' ').toLowerCase()}
                      </span>
                      {possession.points_scored > 0 && (
                        <span className="text-sm font-semibold text-green-600">
                          +{possession.points_scored} pts
                        </span>
                      )}
                    </div>

                    {/* Player Information */}
                    <div className="text-sm text-gray-600 mb-2">
                      {possession.scorer && (
                        <span>
                          Scored by: <strong>{possession.scorer.first_name} {possession.scorer.last_name}</strong>
                        </span>
                      )}
                      {possession.assisted_by && (
                        <span className="ml-4">
                          Assisted by: <strong>{possession.assisted_by.first_name} {possession.assisted_by.last_name}</strong>
                        </span>
                      )}
                    </div>

                    {/* Sets and Additional Info */}
                    <div className="flex items-center space-x-4 text-xs text-gray-500">
                      {possession.offensive_set && (
                        <span className="flex items-center">
                          <ChartBarIcon className="h-3 w-3 mr-1" />
                          Off: {possession.offensive_set}
                        </span>
                      )}
                      {possession.defensive_set && (
                        <span className="flex items-center">
                          <UserGroupIcon className="h-3 w-3 mr-1" />
                          Def: {possession.defensive_set}
                        </span>
                      )}
                      <span className="flex items-center">
                        <ClockIcon className="h-3 w-3 mr-1" />
                        {possession.duration_seconds}s
                      </span>
                    </div>
                  </div>
                </div>

                {/* Team Name */}
                <div className="text-right">
                  <div className="text-sm font-medium text-gray-900">
                    {possession.team.team.name}
                  </div>
                  <div className="text-xs text-gray-500">
                    {new Date(possession.created_at).toLocaleTimeString()}
                  </div>
                </div>
              </div>
            </div>
          ))
        ) : (
          <div className="text-center py-12">
            <EyeIcon className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No possessions found</h3>
            <p className="text-gray-500">
              {activeFiltersCount > 0 
                ? 'Try adjusting your filters to see more results.'
                : 'No possessions have been recorded for this game yet.'
              }
            </p>
            {activeFiltersCount > 0 && (
              <button
                onClick={clearFilters}
                className="mt-4 text-blue-600 hover:text-blue-800 transition-colors"
              >
                Clear all filters
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
