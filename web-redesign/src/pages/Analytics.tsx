import { useEffect, useState } from 'react'
import { useAnalyticsStore } from '../store/analyticsStore'
import { useTeamsStore } from '../store/teamsStore'
import { 
  ChartBarIcon, 
  DocumentArrowDownIcon, 
  FunnelIcon,
  TrophyIcon,
  ArrowTrendingUpIcon,
  CalendarIcon
} from '@heroicons/react/24/outline'
import type { AnalyticsFilters } from '../services/analytics'
import { AnalyticsFiltersPanel } from '../components/analytics/AnalyticsFiltersPanel'
import { TeamStatsOverview } from '../components/analytics/TeamStatsOverview'
import { PlayerStatsTable } from '../components/analytics/PlayerStatsTable'
import { GameAnalyticsChart } from '../components/analytics/GameAnalyticsChart'
import { PerformanceTrendsChart } from '../components/analytics/PerformanceTrendsChart'
import { EfficiencyChart } from '../components/analytics/EfficiencyChart'

export default function Analytics() {
  const { 
    analytics, 
    isLoading, 
    error, 
    filters,
    fetchAnalytics, 
    exportPDF, 
    setFilters, 
    clearError 
  } = useAnalyticsStore()
  
  const { teams, fetchTeams } = useTeamsStore()
  const [showFilters, setShowFilters] = useState(false)

  useEffect(() => {
    fetchTeams()
    fetchAnalytics()
  }, [fetchTeams, fetchAnalytics])

  const handleFiltersChange = (newFilters: AnalyticsFilters) => {
    setFilters(newFilters)
    fetchAnalytics(newFilters)
  }

  const handleExportPDF = () => {
    exportPDF(filters)
  }

  if (error) {
    return (
      <div className="p-6">
        <div className="bg-red-50 border border-red-200 rounded-md p-4">
          <div className="flex">
            <div className="ml-3">
              <h3 className="text-sm font-medium text-red-800">Error loading analytics</h3>
              <div className="mt-2 text-sm text-red-700">{error}</div>
              <div className="mt-4">
                <button
                  onClick={() => {
                    clearError()
                    fetchAnalytics()
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
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 flex items-center">
              <ChartBarIcon className="h-8 w-8 mr-3 text-blue-600" />
              Analytics Dashboard
            </h1>
            <p className="mt-1 text-sm text-gray-500">
              Comprehensive team and player performance analytics
            </p>
          </div>
          
          <div className="flex space-x-3">
            <button
              onClick={() => setShowFilters(!showFilters)}
              className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
            >
              <FunnelIcon className="h-4 w-4 mr-2" />
              Filters
            </button>
            
            <button
              onClick={handleExportPDF}
              disabled={isLoading}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
            >
              <DocumentArrowDownIcon className="h-4 w-4 mr-2" />
              Export PDF
            </button>
          </div>
        </div>
      </div>

      {/* Filters Panel */}
      {showFilters && (
        <div className="mb-6">
          <AnalyticsFiltersPanel
            teams={teams}
            filters={filters}
            onFiltersChange={handleFiltersChange}
            onClose={() => setShowFilters(false)}
          />
        </div>
      )}

      {/* Loading State */}
      {isLoading && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <span className="ml-2 text-gray-600">Loading analytics...</span>
        </div>
      )}

      {/* Analytics Content */}
      {analytics && !isLoading && (
        <div className="space-y-6">
          {/* Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <TrophyIcon className="h-6 w-6 text-yellow-600" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">Win Rate</dt>
                      <dd className="text-lg font-medium text-gray-900">
                        {analytics.summary.win_percentage.toFixed(1)}%
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <ArrowTrendingUpIcon className="h-6 w-6 text-green-600" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">Avg Points For</dt>
                      <dd className="text-lg font-medium text-gray-900">
                        {analytics.summary.average_points_for.toFixed(1)}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <ChartBarIcon className="h-6 w-6 text-blue-600" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">Net Efficiency</dt>
                      <dd className="text-lg font-medium text-gray-900">
                        {analytics.summary.average_net_efficiency.toFixed(1)}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-white overflow-hidden shadow rounded-lg">
              <div className="p-5">
                <div className="flex items-center">
                  <div className="flex-shrink-0">
                    <CalendarIcon className="h-6 w-6 text-purple-600" />
                  </div>
                  <div className="ml-5 w-0 flex-1">
                    <dl>
                      <dt className="text-sm font-medium text-gray-500 truncate">Games Played</dt>
                      <dd className="text-lg font-medium text-gray-900">
                        {analytics.summary.total_games}
                      </dd>
                    </dl>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Charts Row */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="bg-white shadow rounded-lg p-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Performance Trends</h3>
              <PerformanceTrendsChart trends={analytics.trends} />
            </div>

            <div className="bg-white shadow rounded-lg p-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Efficiency Metrics</h3>
              <EfficiencyChart teamStats={analytics.team_stats} />
            </div>
          </div>

          {/* Game Analytics Chart */}
          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Game-by-Game Analytics</h3>
            <GameAnalyticsChart games={analytics.game_analytics} />
          </div>

          {/* Team Stats Overview */}
          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Team Statistics</h3>
            <TeamStatsOverview teamStats={analytics.team_stats} />
          </div>

          {/* Player Stats Table */}
          <div className="bg-white shadow rounded-lg p-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Player Statistics</h3>
            <PlayerStatsTable players={analytics.player_stats} />
          </div>
        </div>
      )}

      {/* Empty State */}
      {!analytics && !isLoading && !error && (
        <div className="text-center py-12">
          <ChartBarIcon className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">No analytics data</h3>
          <p className="mt-1 text-sm text-gray-500">
            No analytics data available. Try adjusting your filters or check back later.
          </p>
        </div>
      )}
    </div>
  )
}