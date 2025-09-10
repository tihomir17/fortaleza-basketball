import { useState } from 'react'
import {
  ChartBarIcon,
  ArrowUpIcon,
  ArrowDownIcon,
  UserGroupIcon,
  TrophyIcon,
  ClockIcon,
  TagIcon
} from '@heroicons/react/24/outline'
import { AnalyticsLoading } from '../components/ui/LoadingStates'
import { ExportButton } from '../components/ui/ExportButton'
import { 
  PerformanceChart, 
  // PlayerStatsChart, 
  // TeamComparisonChart, 
  // GameDistributionChart,
  MultiLineChart 
} from '../components/charts/PerformanceChart'

interface PlayerStats {
  name: string
  jersey: number
  position: string
  gamesPlayed: number
  pointsPerGame: number
  reboundsPerGame: number
  assistsPerGame: number
  fieldGoalPercentage: number
  threePointPercentage: number
  freeThrowPercentage: number
  plusMinus: number
}

interface TeamStats {
  category: string
  value: number
  change: number
  trend: 'up' | 'down'
}

export function Analytics() {
  const [selectedPeriod, setSelectedPeriod] = useState<'season' | 'month' | 'week'>('season')
  const [selectedView, setSelectedView] = useState<'overview' | 'players' | 'games'>('overview')
  const [isLoading, setIsLoading] = useState(true)

  // Simulate loading
  useState(() => {
    const timer = setTimeout(() => {
      setIsLoading(false)
    }, 1000)
    return () => clearTimeout(timer)
  })

  if (isLoading) {
    return <AnalyticsLoading />
  }

  const playerStats: PlayerStats[] = [
    {
      name: "Carlos Santos",
      jersey: 23,
      position: "SF",
      gamesPlayed: 15,
      pointsPerGame: 22.1,
      reboundsPerGame: 8.3,
      assistsPerGame: 3.2,
      fieldGoalPercentage: 48.9,
      threePointPercentage: 35.4,
      freeThrowPercentage: 78.5,
      plusMinus: 12.3
    },
    {
      name: "João Silva",
      jersey: 10,
      position: "PG",
      gamesPlayed: 15,
      pointsPerGame: 18.5,
      reboundsPerGame: 4.2,
      assistsPerGame: 7.8,
      fieldGoalPercentage: 45.2,
      threePointPercentage: 38.7,
      freeThrowPercentage: 82.1,
      plusMinus: 8.7
    },
    {
      name: "Miguel Rodriguez",
      jersey: 5,
      position: "C",
      gamesPlayed: 15,
      pointsPerGame: 15.8,
      reboundsPerGame: 12.4,
      assistsPerGame: 2.1,
      fieldGoalPercentage: 52.3,
      threePointPercentage: 0,
      freeThrowPercentage: 71.2,
      plusMinus: 15.2
    }
  ]

  const teamStats: TeamStats[] = [
    { category: "Points Per Game", value: 95.2, change: 3.2, trend: 'up' },
    { category: "Rebounds Per Game", value: 42.8, change: -1.1, trend: 'down' },
    { category: "Assists Per Game", value: 24.6, change: 2.8, trend: 'up' },
    { category: "Field Goal %", value: 47.8, change: 1.5, trend: 'up' },
    { category: "Three Point %", value: 36.2, change: -0.8, trend: 'down' },
    { category: "Free Throw %", value: 78.9, change: 2.1, trend: 'up' },
    { category: "Turnovers Per Game", value: 12.4, change: -0.9, trend: 'up' },
    { category: "Steals Per Game", value: 8.7, change: 1.2, trend: 'up' }
  ]

  // Chart data
  const performanceData = [
    { name: 'Week 1', points: 85, assists: 18, rebounds: 42 },
    { name: 'Week 2', points: 88, assists: 20, rebounds: 45 },
    { name: 'Week 3', points: 82, assists: 17, rebounds: 40 },
    { name: 'Week 4', points: 90, assists: 22, rebounds: 48 },
    { name: 'Week 5', points: 87, assists: 19, rebounds: 44 },
    { name: 'Week 6', points: 92, assists: 21, rebounds: 46 }
  ]

  const teamComparisonData = [
    { name: 'Fortaleza', value: 85.2 },
    { name: 'Lakers', value: 78.5 },
    { name: 'Warriors', value: 82.1 },
    { name: 'Celtics', value: 79.8 }
  ]

  const gameDistributionData = [
    { name: 'Wins', value: 12 },
    { name: 'Losses', value: 3 },
    { name: 'Overtime', value: 2 }
  ]

  return (
    <div>
      {/* Page Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Analytics</h1>
          <p className="mt-2 text-gray-600 dark:text-gray-400">Comprehensive analytics and performance insights.</p>
        </div>
        <ExportButton
          data={playerStats}
          dataType="analytics"
          title="Analytics Export"
          size="md"
          variant="outline"
        />
      </div>

      {/* Controls */}
      <div className="flex flex-col sm:flex-row gap-4 mb-8">
        <div className="flex space-x-1 bg-gray-100 p-1 rounded-lg">
          {(['overview', 'players', 'games'] as const).map((view) => (
            <button
              key={view}
              onClick={() => setSelectedView(view)}
              className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${
                selectedView === view
                  ? 'bg-white text-fortaleza-blue shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              {view.charAt(0).toUpperCase() + view.slice(1)}
            </button>
          ))}
        </div>
        
        <div className="flex space-x-1 bg-gray-100 p-1 rounded-lg">
          {(['season', 'month', 'week'] as const).map((period) => (
            <button
              key={period}
              onClick={() => setSelectedPeriod(period)}
              className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${
                selectedPeriod === period
                  ? 'bg-white text-fortaleza-blue shadow-sm'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              {period.charAt(0).toUpperCase() + period.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {/* Overview Tab */}
      {selectedView === 'overview' && (
        <div className="space-y-8">
          {/* Key Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center">
                <div className="p-2 bg-green-100 rounded-lg">
                  <TrophyIcon className="w-6 h-6 text-green-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Win Rate</p>
                  <p className="text-2xl font-semibold text-gray-900">80%</p>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center">
                <div className="p-2 bg-blue-100 rounded-lg">
                  <TagIcon className="w-6 h-6 text-blue-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Points/Game</p>
                  <p className="text-2xl font-semibold text-gray-900">95.2</p>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center">
                <div className="p-2 bg-purple-100 rounded-lg">
                  <UserGroupIcon className="w-6 h-6 text-purple-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Team Rating</p>
                  <p className="text-2xl font-semibold text-gray-900">A+</p>
                </div>
              </div>
            </div>

            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center">
                <div className="p-2 bg-yellow-100 rounded-lg">
                  <ClockIcon className="w-6 h-6 text-yellow-600" />
                </div>
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-600">Avg Game Time</p>
                  <p className="text-2xl font-semibold text-gray-900">2h 15m</p>
                </div>
              </div>
            </div>
          </div>

          {/* Team Statistics */}
          <div className="bg-white rounded-lg shadow">
            <div className="px-6 py-4 border-b border-gray-200">
              <h3 className="text-lg font-medium text-gray-900">Team Statistics</h3>
            </div>
            <div className="p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {teamStats.map((stat, index) => (
                  <div key={index} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                    <div>
                      <p className="text-sm font-medium text-gray-900">{stat.category}</p>
                      <p className="text-2xl font-semibold text-gray-900">{stat.value}</p>
                    </div>
                    <div className="flex items-center">
                      {stat.trend === 'up' ? (
                        <ArrowUpIcon className="w-5 h-5 text-green-500 mr-1" />
                      ) : (
                        <ArrowDownIcon className="w-5 h-5 text-red-500 mr-1" />
                      )}
                      <span className={`text-sm font-medium ${
                        stat.trend === 'up' ? 'text-green-600' : 'text-red-600'
                      }`}>
                        {stat.change > 0 ? '+' : ''}{stat.change}%
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Charts Section */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <MultiLineChart 
              data={performanceData}
              title="Performance Trends"
              height={300}
            />
            <PerformanceChart
              data={teamComparisonData}
              type="bar"
              title="Team Comparison"
              height={300}
            />
          </div>

          <PerformanceChart
            data={gameDistributionData}
            type="pie"
            title="Game Results Distribution"
            height={300}
          />
        </div>
      )}

      {/* Players Tab */}
      {selectedView === 'players' && (
        <div className="bg-white rounded-lg shadow">
          <div className="px-6 py-4 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">Player Statistics</h3>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Player
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    GP
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    PPG
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    RPG
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    APG
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    FG%
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    3P%
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    FT%
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    +/-
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {playerStats.map((player, index) => (
                  <tr key={index} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="w-8 h-8 bg-fortaleza-blue rounded-full flex items-center justify-center mr-3">
                          <span className="text-white font-semibold text-sm">{player.jersey}</span>
                        </div>
                        <div>
                          <div className="text-sm font-medium text-gray-900">{player.name}</div>
                          <div className="text-sm text-gray-500">{player.position}</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.gamesPlayed}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.pointsPerGame}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.reboundsPerGame}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.assistsPerGame}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.fieldGoalPercentage}%
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.threePointPercentage}%
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.freeThrowPercentage}%
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      <span className={`font-medium ${
                        player.plusMinus >= 0 ? 'text-green-600' : 'text-red-600'
                      }`}>
                        {player.plusMinus >= 0 ? '+' : ''}{player.plusMinus}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Games Tab */}
      {selectedView === 'games' && (
        <div className="bg-white rounded-lg shadow p-6">
          <div className="text-center py-12">
            <ChartBarIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">Game Analytics</h3>
            <p className="text-gray-600 mb-4">Detailed game-by-game analysis and trends.</p>
            <button className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">
              View Game Reports
            </button>
          </div>
        </div>
      )}
    </div>
  )
}