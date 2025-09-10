import { useState, useEffect } from 'react'
import { MagnifyingGlassIcon, FunnelIcon, XMarkIcon } from '@heroicons/react/24/outline'

export interface FilterOption {
  value: string
  label: string
  count?: number
}

export interface SearchFilterProps {
  searchValue: string
  onSearchChange: (value: string) => void
  filters?: {
    [key: string]: {
      label: string
      options: FilterOption[]
      value: string
      onChange: (value: string) => void
    }
  }
  placeholder?: string
  className?: string
}

export function SearchFilter({
  searchValue,
  onSearchChange,
  filters = {},
  placeholder = "Search...",
  className = ""
}: SearchFilterProps) {
  const [showFilters, setShowFilters] = useState(false)
  const [hasActiveFilters, setHasActiveFilters] = useState(false)

  useEffect(() => {
    const activeFilters = Object.values(filters).some(filter => filter.value !== '')
    setHasActiveFilters(activeFilters)
  }, [filters])

  const clearAllFilters = () => {
    Object.values(filters).forEach(filter => {
      filter.onChange('')
    })
  }

  const getActiveFilterCount = () => {
    return Object.values(filters).filter(filter => filter.value !== '').length
  }

  return (
    <div className={`space-y-4 ${className}`}>
      {/* Search Bar */}
      <div className="relative">
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <MagnifyingGlassIcon className="h-5 w-5 text-gray-400" />
        </div>
        <input
          type="text"
          value={searchValue}
          onChange={(e) => onSearchChange(e.target.value)}
          className="block w-full pl-10 pr-12 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:ring-2 focus:ring-fortaleza-blue focus:border-transparent"
          placeholder={placeholder}
        />
        {searchValue && (
          <button
            onClick={() => onSearchChange('')}
            className="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            <XMarkIcon className="h-5 w-5" />
          </button>
        )}
      </div>

      {/* Filter Toggle */}
      {Object.keys(filters).length > 0 && (
        <div className="flex items-center justify-between">
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`flex items-center space-x-2 px-3 py-2 rounded-lg border transition-colors ${
              hasActiveFilters
                ? 'bg-fortaleza-blue text-white border-fortaleza-blue'
                : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
            }`}
          >
            <FunnelIcon className="h-4 w-4" />
            <span>Filters</span>
            {hasActiveFilters && (
              <span className="bg-white text-fortaleza-blue text-xs rounded-full px-2 py-1">
                {getActiveFilterCount()}
              </span>
            )}
          </button>

          {hasActiveFilters && (
            <button
              onClick={clearAllFilters}
              className="text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
            >
              Clear all
            </button>
          )}
        </div>
      )}

      {/* Filter Options */}
      {showFilters && Object.keys(filters).length > 0 && (
        <div className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4 space-y-4">
          {Object.entries(filters).map(([key, filter]) => (
            <div key={key}>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                {filter.label}
              </label>
              <select
                value={filter.value}
                onChange={(e) => filter.onChange(e.target.value)}
                className="block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-fortaleza-blue focus:border-transparent"
              >
                <option value="">All {filter.label}</option>
                {filter.options.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                    {option.count !== undefined && ` (${option.count})`}
                  </option>
                ))}
              </select>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

// Specialized search components for different data types
export function GameSearchFilter({
  searchValue,
  onSearchChange,
  statusFilter,
  onStatusChange,
  teamFilter,
  onTeamChange,
  dateFilter,
  onDateChange,
  teams = [],
  className = ""
}: {
  searchValue: string
  onSearchChange: (value: string) => void
  statusFilter: string
  onStatusChange: (value: string) => void
  teamFilter: string
  onTeamChange: (value: string) => void
  dateFilter: string
  onDateChange: (value: string) => void
  teams?: Array<{ id: string; name: string }>
  className?: string
}) {
  const statusOptions = [
    { value: 'SCHEDULED', label: 'Scheduled' },
    { value: 'IN_PROGRESS', label: 'In Progress' },
    { value: 'COMPLETED', label: 'Completed' },
    { value: 'CANCELLED', label: 'Cancelled' },
  ]

  const dateOptions = [
    { value: 'today', label: 'Today' },
    { value: 'tomorrow', label: 'Tomorrow' },
    { value: 'this_week', label: 'This Week' },
    { value: 'this_month', label: 'This Month' },
    { value: 'upcoming', label: 'Upcoming' },
    { value: 'past', label: 'Past Games' },
  ]

  const teamOptions = teams.map(team => ({
    value: team.id,
    label: team.name
  }))

  return (
    <SearchFilter
      searchValue={searchValue}
      onSearchChange={onSearchChange}
      filters={{
        status: {
          label: 'Status',
          options: statusOptions,
          value: statusFilter,
          onChange: onStatusChange
        },
        team: {
          label: 'Team',
          options: teamOptions,
          value: teamFilter,
          onChange: onTeamChange
        },
        date: {
          label: 'Date',
          options: dateOptions,
          value: dateFilter,
          onChange: onDateChange
        }
      }}
      placeholder="Search games by team name, location, or opponent..."
      className={className}
    />
  )
}

export function PlayerSearchFilter({
  searchValue,
  onSearchChange,
  positionFilter,
  onPositionChange,
  teamFilter,
  onTeamChange,
  statusFilter,
  onStatusChange,
  teams = [],
  className = ""
}: {
  searchValue: string
  onSearchChange: (value: string) => void
  positionFilter: string
  onPositionChange: (value: string) => void
  teamFilter: string
  onTeamChange: (value: string) => void
  statusFilter: string
  onStatusChange: (value: string) => void
  teams?: Array<{ id: string; name: string }>
  className?: string
}) {
  const positionOptions = [
    { value: 'PG', label: 'Point Guard' },
    { value: 'SG', label: 'Shooting Guard' },
    { value: 'SF', label: 'Small Forward' },
    { value: 'PF', label: 'Power Forward' },
    { value: 'C', label: 'Center' },
  ]

  const statusOptions = [
    { value: 'ACTIVE', label: 'Active' },
    { value: 'INJURED', label: 'Injured' },
    { value: 'SUSPENDED', label: 'Suspended' },
    { value: 'INACTIVE', label: 'Inactive' },
  ]

  const teamOptions = teams.map(team => ({
    value: team.id,
    label: team.name
  }))

  return (
    <SearchFilter
      searchValue={searchValue}
      onSearchChange={onSearchChange}
      filters={{
        position: {
          label: 'Position',
          options: positionOptions,
          value: positionFilter,
          onChange: onPositionChange
        },
        team: {
          label: 'Team',
          options: teamOptions,
          value: teamFilter,
          onChange: onTeamChange
        },
        status: {
          label: 'Status',
          options: statusOptions,
          value: statusFilter,
          onChange: onStatusChange
        }
      }}
      placeholder="Search players by name, number, or position..."
      className={className}
    />
  )
}
