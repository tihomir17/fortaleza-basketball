import { useState } from 'react'
import { XMarkIcon } from '@heroicons/react/24/outline'
import type { AnalyticsFilters } from '../../services/analytics'
import type { Team } from '../../services/teams'

interface AnalyticsFiltersPanelProps {
  teams: Team[]
  filters: AnalyticsFilters
  onFiltersChange: (filters: AnalyticsFilters) => void
  onClose: () => void
}

export function AnalyticsFiltersPanel({ 
  teams, 
  filters, 
  onFiltersChange, 
  onClose 
}: AnalyticsFiltersPanelProps) {
  const [localFilters, setLocalFilters] = useState<AnalyticsFilters>(filters)

  const handleFilterChange = (key: keyof AnalyticsFilters, value: any) => {
    const newFilters = { ...localFilters, [key]: value }
    setLocalFilters(newFilters)
  }

  const handleApplyFilters = () => {
    onFiltersChange(localFilters)
  }

  const handleClearFilters = () => {
    const clearedFilters: AnalyticsFilters = {}
    setLocalFilters(clearedFilters)
    onFiltersChange(clearedFilters)
  }

  return (
    <div className="bg-white shadow rounded-lg p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-medium text-gray-900">Analytics Filters</h3>
        <button
          onClick={onClose}
          className="text-gray-400 hover:text-gray-600"
        >
          <XMarkIcon className="h-6 w-6" />
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {/* Team Filter */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Team</label>
          <select
            value={localFilters.team_id || ''}
            onChange={(e) => handleFilterChange('team_id', e.target.value ? parseInt(e.target.value) : undefined)}
            className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="">All Teams</option>
            {teams.map(team => (
              <option key={team.id} value={team.id}>
                {team.name}
              </option>
            ))}
          </select>
        </div>

        {/* Quarter Filter */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Quarter</label>
          <select
            value={localFilters.quarter || ''}
            onChange={(e) => handleFilterChange('quarter', e.target.value ? parseInt(e.target.value) : undefined)}
            className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="">All Quarters</option>
            <option value="1">1st Quarter</option>
            <option value="2">2nd Quarter</option>
            <option value="3">3rd Quarter</option>
            <option value="4">4th Quarter</option>
            <option value="5">Overtime</option>
          </select>
        </div>

        {/* Last Games Filter */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Last Games</label>
          <select
            value={localFilters.last_games || ''}
            onChange={(e) => handleFilterChange('last_games', e.target.value ? parseInt(e.target.value) : undefined)}
            className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="">All Games</option>
            <option value="5">Last 5 Games</option>
            <option value="10">Last 10 Games</option>
            <option value="15">Last 15 Games</option>
            <option value="20">Last 20 Games</option>
          </select>
        </div>

        {/* Outcome Filter */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Outcome</label>
          <select
            value={localFilters.outcome || ''}
            onChange={(e) => handleFilterChange('outcome', e.target.value || undefined)}
            className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="">All Games</option>
            <option value="W">Wins Only</option>
            <option value="L">Losses Only</option>
          </select>
        </div>

        {/* Home/Away Filter */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Home/Away</label>
          <select
            value={localFilters.home_away || ''}
            onChange={(e) => handleFilterChange('home_away', e.target.value || undefined)}
            className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="">All Games</option>
            <option value="Home">Home Games</option>
            <option value="Away">Away Games</option>
          </select>
        </div>

        {/* Opponent Filter */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Opponent</label>
          <select
            value={localFilters.opponent || ''}
            onChange={(e) => handleFilterChange('opponent', e.target.value ? parseInt(e.target.value) : undefined)}
            className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
          >
            <option value="">All Opponents</option>
            {teams.map(team => (
              <option key={team.id} value={team.id}>
                {team.name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex justify-end space-x-3 mt-6">
        <button
          onClick={handleClearFilters}
          className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
        >
          Clear Filters
        </button>
        <button
          onClick={handleApplyFilters}
          className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700"
        >
          Apply Filters
        </button>
      </div>
    </div>
  )
}
