import { useEffect, useState } from 'react'
import {
  CalendarDaysIcon,
  TrophyIcon,
  UserGroupIcon,
  ChartBarIcon,
  ExclamationTriangleIcon,
  ArrowUpIcon,
  ClockIcon,
  FireIcon,
  ArrowTrendingUpIcon
} from '@heroicons/react/24/outline'
import { useDashboardStore } from '../store/dashboardStore'
import { DashboardLoading } from '../components/ui/LoadingStates'
import { DashboardBreadcrumb } from '../components/ui/Breadcrumb'
import { notify } from '../store/notificationsStore'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell } from 'recharts'

export function Dashboard() {
  const { data, isLoading, error, fetchDashboardData, clearError } = useDashboardStore()
  const [activeTab, setActiveTab] = useState('overview')
  const [autoRefresh, setAutoRefresh] = useState(true)

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

  // Auto-refresh every 30 seconds
  useEffect(() => {
    if (!autoRefresh) return
    
    const interval = setInterval(() => {
      fetchDashboardData()
    }, 30000)

    return () => clearInterval(interval)
  }, [autoRefresh, fetchDashboardData])

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

  // Sample data for charts (replace with real data when available)
  const performanceData = [
    { month: 'Jan', points: 85, rebounds: 42, assists: 18 },
    { month: 'Feb', points: 92, rebounds: 38, assists: 22 },
    { month: 'Mar', points: 78, rebounds: 45, assists: 19 },
    { month: 'Apr', points: 88, rebounds: 41, assists: 25 },
    { month: 'May', points: 95, rebounds: 43, assists: 21 },
    { month: 'Jun', points: 89, rebounds: 39, assists: 23 }
  ]

  const winLossData = [
    { name: 'Wins', value: stats.wins, color: '#10B981' },
    { name: 'Losses', value: stats.losses, color: '#EF4444' }
  ]

  const playerStats = [
    { name: 'John Smith', points: 24.5, rebounds: 8.2, assists: 6.1, efficiency: 18.3 },
    { name: 'Mike Johnson', points: 19.8, rebounds: 6.5, assists: 4.2, efficiency: 15.1 },
    { name: 'David Wilson', points: 16.2, rebounds: 9.1, assists: 2.8, efficiency: 14.7 },
    { name: 'Chris Brown', points: 14.7, rebounds: 5.3, assists: 7.4, efficiency: 13.9 }
  ]

  return (
    <div className="max-w-7xl xl:max-w-8xl 2xl:max-w-9xl mx-auto animate-fade-in px-4 sm:px-6 lg:px-8">
      {/* Breadcrumb */}
      <div className="mb-6 animate-fade-in-down">
        <DashboardBreadcrumb />
      </div>

      {/* Page Header */}
      <div className="mb-8 animate-fade-in-down">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Dashboard</h1>
            <p className="text-gray-600 dark:text-gray-400 mb-2">Welcome back! Here's what's happening with your team.</p>
            {data?.lastUpdated && (
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Last updated: {new Date(data.lastUpdated).toLocaleString()}
              </p>
            )}
          </div>
          
          {/* Dashboard Controls */}
          <div className="flex items-center space-x-4 mt-4 sm:mt-0">
            <div className="flex items-center space-x-2">
              <label className="text-sm text-gray-600 dark:text-gray-400">Auto-refresh</label>
              <button
                onClick={() => setAutoRefresh(!autoRefresh)}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                  autoRefresh ? 'bg-blue-600' : 'bg-gray-200'
                }`}
              >
                <span
                  className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                    autoRefresh ? 'translate-x-6' : 'translate-x-1'
                  }`}
                />
              </button>
            </div>
            
            <button
              onClick={() => fetchDashboardData()}
              className="flex items-center space-x-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              <ClockIcon className="w-4 h-4" />
              <span>Refresh</span>
            </button>
          </div>
        </div>

        {/* Tab Navigation */}
        <div className="mt-6 border-b border-gray-200 dark:border-gray-700">
          <nav className="-mb-px flex space-x-8">
            {[
              { id: 'overview', name: 'Overview', icon: ChartBarIcon },
              { id: 'analytics', name: 'Analytics', icon: ArrowTrendingUpIcon },
              { id: 'players', name: 'Top Players', icon: UserGroupIcon }
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center space-x-2 py-2 px-1 border-b-2 font-medium text-sm transition-colors ${
                  activeTab === tab.id
                    ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                }`}
              >
                <tab.icon className="w-4 h-4" />
                <span>{tab.name}</span>
              </button>
            ))}
          </nav>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-4 2xl:grid-cols-6 gap-4 sm:gap-6 mb-8">
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 hover:shadow-md transition-all duration-300 hover:-translate-y-1 animate-fade-in-up animate-stagger-1 group cursor-pointer">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="p-3 bg-blue-50 dark:bg-blue-900/50 rounded-xl group-hover:scale-110 transition-transform">
                <CalendarDaysIcon className="w-6 h-6 text-blue-600 dark:text-blue-400" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Upcoming Games</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.upcomingGames}</p>
              </div>
            </div>
            <div className="flex items-center text-green-600">
              <ArrowUpIcon className="w-4 h-4" />
              <span className="text-sm font-medium">+2</span>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 hover:shadow-md transition-all duration-300 hover:-translate-y-1 animate-fade-in-up animate-stagger-2 group cursor-pointer">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="p-3 bg-green-50 dark:bg-green-900/50 rounded-xl group-hover:scale-110 transition-transform">
                <TrophyIcon className="w-6 h-6 text-green-600 dark:text-green-400" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Wins This Season</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.wins}</p>
              </div>
            </div>
            <div className="flex items-center text-green-600">
              <ArrowUpIcon className="w-4 h-4" />
              <span className="text-sm font-medium">+12%</span>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 hover:shadow-md transition-all duration-300 hover:-translate-y-1 animate-fade-in-up animate-stagger-3 group cursor-pointer">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="p-3 bg-yellow-50 dark:bg-yellow-900/50 rounded-xl group-hover:scale-110 transition-transform">
                <UserGroupIcon className="w-6 h-6 text-yellow-600 dark:text-yellow-400" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Active Players</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.activePlayers || 12}</p>
              </div>
            </div>
            <div className="flex items-center text-green-600">
              <ArrowUpIcon className="w-4 h-4" />
              <span className="text-sm font-medium">+1</span>
            </div>
          </div>
        </div>

        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6 hover:shadow-md transition-all duration-300 hover:-translate-y-1 animate-fade-in-up animate-stagger-4 group cursor-pointer">
          <div className="flex items-center justify-between">
            <div className="flex items-center">
              <div className="p-3 bg-purple-50 dark:bg-purple-900/50 rounded-xl group-hover:scale-110 transition-transform">
                <ChartBarIcon className="w-6 h-6 text-purple-600 dark:text-purple-400" />
              </div>
              <div className="ml-4">
                <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Win Percentage</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.winPercentage.toFixed(1)}%</p>
              </div>
            </div>
            <div className="flex items-center text-green-600">
              <ArrowUpIcon className="w-4 h-4" />
              <span className="text-sm font-medium">+5.2%</span>
            </div>
          </div>
        </div>
      </div>

      {/* Tab Content */}
      {activeTab === 'overview' && (
        <div className="space-y-8">
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
      )}

      {activeTab === 'analytics' && (
        <div className="space-y-8">
          {/* Performance Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Team Performance Trend */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Team Performance Trend</h3>
                <div className="flex items-center space-x-2 text-sm text-gray-500">
                  <FireIcon className="w-4 h-4" />
                  <span>Last 6 months</span>
                </div>
              </div>
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={performanceData}>
                  <CartesianGrid strokeDasharray="3 3" className="opacity-30" />
                  <XAxis dataKey="month" />
                  <YAxis />
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: 'rgba(0, 0, 0, 0.8)', 
                      border: 'none', 
                      borderRadius: '8px',
                      color: 'white'
                    }} 
                  />
                  <Line type="monotone" dataKey="points" stroke="#3B82F6" strokeWidth={3} dot={{ fill: '#3B82F6', strokeWidth: 2, r: 4 }} />
                  <Line type="monotone" dataKey="rebounds" stroke="#10B981" strokeWidth={3} dot={{ fill: '#10B981', strokeWidth: 2, r: 4 }} />
                  <Line type="monotone" dataKey="assists" stroke="#F59E0B" strokeWidth={3} dot={{ fill: '#F59E0B', strokeWidth: 2, r: 4 }} />
                </LineChart>
              </ResponsiveContainer>
            </div>

            {/* Win/Loss Distribution */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Season Record</h3>
                <div className="flex items-center space-x-2 text-sm text-gray-500">
                  <TrophyIcon className="w-4 h-4" />
                  <span>2024 Season</span>
                </div>
              </div>
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={winLossData}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={100}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {winLossData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: 'rgba(0, 0, 0, 0.8)', 
                      border: 'none', 
                      borderRadius: '8px',
                      color: 'white'
                    }} 
                  />
                </PieChart>
              </ResponsiveContainer>
              <div className="flex justify-center space-x-6 mt-4">
                {winLossData.map((item) => (
                  <div key={item.name} className="flex items-center space-x-2">
                    <div className="w-3 h-3 rounded-full" style={{ backgroundColor: item.color }}></div>
                    <span className="text-sm text-gray-600 dark:text-gray-400">{item.name}: {item.value}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Monthly Performance */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Monthly Performance Breakdown</h3>
              <div className="flex items-center space-x-2 text-sm text-gray-500">
                <ArrowTrendingUpIcon className="w-4 h-4" />
                <span>Points, Rebounds, Assists</span>
              </div>
            </div>
            <ResponsiveContainer width="100%" height={400}>
              <BarChart data={performanceData}>
                <CartesianGrid strokeDasharray="3 3" className="opacity-30" />
                <XAxis dataKey="month" />
                <YAxis />
                <Tooltip 
                  contentStyle={{ 
                    backgroundColor: 'rgba(0, 0, 0, 0.8)', 
                    border: 'none', 
                    borderRadius: '8px',
                    color: 'white'
                  }} 
                />
                <Bar dataKey="points" fill="#3B82F6" radius={[4, 4, 0, 0]} />
                <Bar dataKey="rebounds" fill="#10B981" radius={[4, 4, 0, 0]} />
                <Bar dataKey="assists" fill="#F59E0B" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {activeTab === 'players' && (
        <div className="space-y-8">
          {/* Top Performers */}
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
            <div className="px-6 py-5 border-b border-gray-100 dark:border-gray-700">
              <div className="flex items-center justify-between">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Top Performers</h3>
                <div className="flex items-center space-x-2 text-sm text-gray-500">
                  <UserGroupIcon className="w-4 h-4" />
                  <span>Season Leaders</span>
                </div>
              </div>
            </div>
            <div className="p-6">
              <div className="space-y-4">
                {playerStats.map((player, index) => (
                  <div key={player.name} className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors">
                    <div className="flex items-center space-x-4">
                      <div className="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full flex items-center justify-center text-white font-bold">
                        {index + 1}
                      </div>
                      <div>
                        <p className="font-medium text-gray-900 dark:text-white">{player.name}</p>
                        <p className="text-sm text-gray-500 dark:text-gray-400">Efficiency: {player.efficiency}</p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-6 text-sm">
                      <div className="text-center">
                        <p className="font-semibold text-gray-900 dark:text-white">{player.points}</p>
                        <p className="text-gray-500 dark:text-gray-400">PTS</p>
                      </div>
                      <div className="text-center">
                        <p className="font-semibold text-gray-900 dark:text-white">{player.rebounds}</p>
                        <p className="text-gray-500 dark:text-gray-400">REB</p>
                      </div>
                      <div className="text-center">
                        <p className="font-semibold text-gray-900 dark:text-white">{player.assists}</p>
                        <p className="text-gray-500 dark:text-gray-400">AST</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
