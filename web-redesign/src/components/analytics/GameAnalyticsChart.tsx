import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'
import type { GameAnalytics } from '../../services/analytics'

interface GameAnalyticsChartProps {
  games: GameAnalytics[]
}

export function GameAnalyticsChart({ games }: GameAnalyticsChartProps) {
  // Prepare data for the chart
  const chartData = games.map((game, index) => ({
    game: index + 1,
    date: new Date(game.game_date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
    points: game.home_score + game.away_score,
    offensive_efficiency: game.offensive_efficiency,
    defensive_efficiency: game.defensive_efficiency,
    pace: game.pace,
    outcome: game.outcome,
    opponent: game.outcome === 'W' ? game.away_team : game.home_team
  }))

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const data = chartData[label - 1]
      return (
        <div className="bg-white p-3 border border-gray-200 rounded shadow-lg">
          <p className="font-medium">{`Game ${label} - ${data?.date}`}</p>
          <p className="text-sm text-gray-500 mb-2">vs {data?.opponent}</p>
          {payload.map((entry: any, index: number) => (
            <p key={index} style={{ color: entry.color }}>
              {`${entry.dataKey.replace('_', ' ')}: ${entry.value.toFixed(1)}`}
            </p>
          ))}
          <p className={`text-sm font-medium ${
            data?.outcome === 'W' ? 'text-green-600' : 'text-red-600'
          }`}>
            Result: {data?.outcome === 'W' ? 'Win' : 'Loss'}
          </p>
        </div>
      )
    }
    return null
  }

  return (
    <div className="h-80">
      <ResponsiveContainer width="100%" height="100%">
        <LineChart data={chartData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
          <XAxis 
            dataKey="game" 
            stroke="#6b7280"
            fontSize={12}
            tickLine={false}
            axisLine={false}
          />
          <YAxis 
            stroke="#6b7280"
            fontSize={12}
            tickLine={false}
            axisLine={false}
          />
          <Tooltip content={<CustomTooltip />} />
          <Legend />
          <Line 
            type="monotone" 
            dataKey="offensive_efficiency" 
            stroke="#3b82f6" 
            strokeWidth={2}
            dot={{ fill: '#3b82f6', strokeWidth: 2, r: 4 }}
            name="Offensive Efficiency"
          />
          <Line 
            type="monotone" 
            dataKey="defensive_efficiency" 
            stroke="#ef4444" 
            strokeWidth={2}
            dot={{ fill: '#ef4444', strokeWidth: 2, r: 4 }}
            name="Defensive Efficiency"
          />
          <Line 
            type="monotone" 
            dataKey="pace" 
            stroke="#f59e0b" 
            strokeWidth={2}
            dot={{ fill: '#f59e0b', strokeWidth: 2, r: 4 }}
            name="Pace"
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}
