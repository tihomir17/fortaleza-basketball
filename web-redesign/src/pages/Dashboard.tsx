import { useEffect } from 'react'
import {
  CalendarDaysIcon,
  TrophyIcon,
  UserGroupIcon,
  ChartBarIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline'
import { useDashboardStore } from '../store/dashboardStore'
import { DashboardLoading } from '../components/ui/LoadingStates'
import { DashboardBreadcrumb } from '../components/ui/Breadcrumb'
import { notify } from '../store/notificationsStore'

export function Dashboard() {
  const { data, isLoading, error, fetchDashboardData, clearError } = useDashboardStore()

  useEffect(() => {
    fetchDashboardData()
    
    // Demo notifications
    const timer1 = setTimeout(() => {
      notify.success('Welcome!', 'Dashboard loaded successfully')
    }, 1000)
    
    const timer2 = setTimeout(() => {
      notify.info('New Game', 'Upcoming game against Lakers tomorrow at 7 PM', {
        label: 'View Details',
        onClick: () => console.log('View game details')
      })
    }, 3000)
    
    const timer3 = setTimeout(() => {
      notify.warning('Player Update', 'John Smith is listed as questionable for next game')
    }, 5000)

    return () => {
      clearTimeout(timer1)
      clearTimeout(timer2)
      clearTimeout(timer3)
    }
  }, [fetchDashboardData])

  if (isLoading && !data) {
    return <DashboardLoading />
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-6">
        <div className="flex items-center">
          <ExclamationTriangleIcon className="w-6 h-6 text-red-600 mr-3" />
          <div>
            <h3 className="text-lg font-medium text-red-800">Error loading dashboard</h3>
            <p className="text-red-600 mt-1">{error}</p>
            <button
              onClick={() => {
                clearError()
                fetchDashboardData()
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

  const stats = data?.quickStats || {
    totalGames: 0,
    wins: 0,
    losses: 0,
    winPercentage: 0,
    upcomingGames: 0,
    activePlayers: 0
  }

  return (
    <div className="max-w-7xl xl:max-w-8xl 2xl:max-w-9xl mx-auto animate-fade-in px-4 sm:px-6 lg:px-8">
      {/* Breadcrumb */}
      <div className="mb-6 animate-fade-in-down">
        <DashboardBreadcrumb />
      </div>

      {/* Page Header */}
      <div className="mb-8 animate-fade-in-down">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Dashboard</h1>
        <p className="text-gray-600 dark:text-gray-400 mb-2">Welcome back! Here's what's happening with your team.</p>
        {data?.lastUpdated && (
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Last updated: {new Date(data.lastUpdated).toLocaleString()}
          </p>
        )}
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-4 2xl:grid-cols-6 gap-4 sm:gap-6 mb-8">
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 hover:shadow-md transition-all duration-300 hover:-translate-y-1 animate-fade-in-up animate-stagger-1">
          <div className="flex items-center">
            <div className="p-3 bg-blue-50 dark:bg-blue-900/50 rounded-xl">
              <CalendarDaysIcon className="w-6 h-6 text-blue-600 dark:text-blue-400" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Upcoming Games</p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.upcomingGames}</p>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 hover:shadow-md transition-all duration-300 hover:-translate-y-1 animate-fade-in-up animate-stagger-2">
          <div className="flex items-center">
            <div className="p-3 bg-green-50 dark:bg-green-900/50 rounded-xl">
              <TrophyIcon className="w-6 h-6 text-green-600 dark:text-green-400" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Wins This Season</p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.wins}</p>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 hover:shadow-md transition-all duration-300 hover:-translate-y-1 animate-fade-in-up animate-stagger-3">
          <div className="flex items-center">
            <div className="p-3 bg-yellow-50 dark:bg-yellow-900/50 rounded-xl">
              <UserGroupIcon className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Active Players</p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.activePlayers}</p>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 hover:shadow-md transition-all duration-300 hover:-translate-y-1 animate-fade-in-up animate-stagger-4">
          <div className="flex items-center">
            <div className="p-3 bg-purple-50 dark:bg-purple-900/50 rounded-xl">
              <ChartBarIcon className="w-6 h-6 text-purple-600 dark:text-purple-400" />
            </div>
            <div className="ml-4">
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Win Percentage</p>
              <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.winPercentage.toFixed(1)}%</p>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Games and Activity - Two Column Layout for Large Screens */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6 lg:gap-8">
        {/* Recent Games */}
        {data?.recentGames && data.recentGames.length > 0 && (
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 animate-fade-in-up animate-stagger-2">
            <div className="px-6 py-5 border-b border-gray-100 dark:border-gray-700">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Recent Games</h3>
            </div>
            <div className="p-6">
              <div className="space-y-3">
                {data.recentGames.slice(0, 5).map((game) => (
                  <div key={game.id} className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors">
                    <div className="flex items-center space-x-4">
                      <div className={`w-3 h-3 rounded-full ${game.result === 'W' ? 'bg-green-500' : 'bg-red-500'}`}></div>
                      <div>
                        <p className="text-sm font-medium text-gray-900 dark:text-white">
                          {game.home_team_name} vs {game.away_team_name}
                        </p>
                        <p className="text-xs text-gray-500 dark:text-gray-400">{new Date(game.date).toLocaleDateString()}</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-semibold text-gray-900 dark:text-white">
                        {game.home_score} - {game.away_score}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">{game.result === 'W' ? 'Win' : 'Loss'}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Recent Activity */}
        {data?.recentActivity && data.recentActivity.length > 0 && (
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 animate-fade-in-up animate-stagger-3">
            <div className="px-6 py-5 border-b border-gray-100 dark:border-gray-700">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Recent Activity</h3>
            </div>
            <div className="p-6">
              <div className="space-y-4">
                {data.recentActivity.slice(0, 5).map((activity) => (
                  <div key={activity.id} className="flex items-center space-x-4 p-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                    <div className={`w-3 h-3 rounded-full ${
                      activity.type === 'GAME' ? 'bg-green-500' :
                      activity.type === 'PLAYER' ? 'bg-blue-500' :
                      activity.type === 'TEAM' ? 'bg-yellow-500' :
                      'bg-purple-500'
                    }`}></div>
                    <div className="flex-1">
                      <p className="text-sm text-gray-900 dark:text-white">{activity.message}</p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {new Date(activity.timestamp).toLocaleString()}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
