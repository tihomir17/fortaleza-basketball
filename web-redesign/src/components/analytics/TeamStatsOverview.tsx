import type { TeamStats } from '../../services/analytics'

interface TeamStatsOverviewProps {
  teamStats: TeamStats
}

export function TeamStatsOverview({ teamStats }: TeamStatsOverviewProps) {
  const stats = [
    {
      label: 'Games Played',
      value: teamStats.games_played,
      format: 'number'
    },
    {
      label: 'Wins',
      value: teamStats.wins,
      format: 'number'
    },
    {
      label: 'Losses',
      value: teamStats.losses,
      format: 'number'
    },
    {
      label: 'Win Percentage',
      value: teamStats.win_percentage,
      format: 'percentage'
    },
    {
      label: 'Points For',
      value: teamStats.points_for,
      format: 'number'
    },
    {
      label: 'Points Against',
      value: teamStats.points_against,
      format: 'number'
    },
    {
      label: 'Point Differential',
      value: teamStats.point_differential,
      format: 'number'
    },
    {
      label: 'Pace',
      value: teamStats.pace,
      format: 'decimal'
    },
    {
      label: 'Offensive Efficiency',
      value: teamStats.offensive_efficiency,
      format: 'decimal'
    },
    {
      label: 'Defensive Efficiency',
      value: teamStats.defensive_efficiency,
      format: 'decimal'
    },
    {
      label: 'Net Efficiency',
      value: teamStats.net_efficiency,
      format: 'decimal'
    },
    {
      label: 'Field Goal %',
      value: teamStats.field_goal_percentage,
      format: 'percentage'
    },
    {
      label: '3-Point %',
      value: teamStats.three_point_percentage,
      format: 'percentage'
    },
    {
      label: 'Free Throw %',
      value: teamStats.free_throw_percentage,
      format: 'percentage'
    },
    {
      label: 'Rebounds',
      value: teamStats.rebounds,
      format: 'number'
    },
    {
      label: 'Assists',
      value: teamStats.assists,
      format: 'number'
    },
    {
      label: 'Turnovers',
      value: teamStats.turnovers,
      format: 'number'
    },
    {
      label: 'Steals',
      value: teamStats.steals,
      format: 'number'
    },
    {
      label: 'Blocks',
      value: teamStats.blocks,
      format: 'number'
    }
  ]

  const formatValue = (value: number, format: string) => {
    switch (format) {
      case 'percentage':
        return `${value.toFixed(1)}%`
      case 'decimal':
        return value.toFixed(1)
      case 'number':
      default:
        return value.toLocaleString()
    }
  }

  const getValueColor = (label: string, value: number) => {
    // Color coding for key metrics
    if (label.includes('Win Percentage') || label.includes('Efficiency') || label.includes('%')) {
      if (value > 50) return 'text-green-600'
      if (value < 40) return 'text-red-600'
      return 'text-gray-900'
    }
    
    if (label.includes('Differential')) {
      if (value > 0) return 'text-green-600'
      if (value < 0) return 'text-red-600'
      return 'text-gray-900'
    }
    
    return 'text-gray-900'
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
      {stats.map((stat) => (
        <div key={stat.label} className="bg-gray-50 rounded-lg p-4">
          <dt className="text-sm font-medium text-gray-500 truncate">
            {stat.label}
          </dt>
          <dd className={`mt-1 text-lg font-semibold ${getValueColor(stat.label, stat.value)}`}>
            {formatValue(stat.value, stat.format)}
          </dd>
        </div>
      ))}
    </div>
  )
}
