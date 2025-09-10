import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts'

interface PerformanceTrendsChartProps {
  trends: {
    recent_form: ('W' | 'L')[]
    points_trend: number[]
    efficiency_trend: number[]
    pace_trend: number[]
  }
}

export function PerformanceTrendsChart({ trends }: PerformanceTrendsChartProps) {
  // Create data array for the chart
  const chartData = trends.points_trend.map((points, index) => ({
    game: index + 1,
    points: points,
    efficiency: trends.efficiency_trend[index] || 0,
    pace: trends.pace_trend[index] || 0,
    result: trends.recent_form[index] || 'W'
  }))

  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-white p-3 border border-gray-200 rounded shadow-lg">
          <p className="font-medium">{`Game ${label}`}</p>
          {payload.map((entry: any, index: number) => (
            <p key={index} style={{ color: entry.color }}>
              {`${entry.dataKey}: ${entry.value.toFixed(1)}`}
            </p>
          ))}
          <p className="text-sm text-gray-500">
            Result: {chartData[label - 1]?.result || 'N/A'}
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
            dataKey="points" 
            stroke="#3b82f6" 
            strokeWidth={2}
            dot={{ fill: '#3b82f6', strokeWidth: 2, r: 4 }}
            name="Points"
          />
          <Line 
            type="monotone" 
            dataKey="efficiency" 
            stroke="#10b981" 
            strokeWidth={2}
            dot={{ fill: '#10b981', strokeWidth: 2, r: 4 }}
            name="Efficiency"
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
