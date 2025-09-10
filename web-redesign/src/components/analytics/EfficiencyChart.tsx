import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import type { TeamStats } from '../../services/analytics'

interface EfficiencyChartProps {
  teamStats: TeamStats
}

export function EfficiencyChart({ teamStats }: EfficiencyChartProps) {
  const data = [
    {
      name: 'Offensive',
      efficiency: teamStats.offensive_efficiency,
      color: '#3b82f6'
    },
    {
      name: 'Defensive',
      efficiency: teamStats.defensive_efficiency,
      color: '#ef4444'
    },
    {
      name: 'Net',
      efficiency: teamStats.net_efficiency,
      color: '#10b981'
    }
  ]

  const CustomTooltip = ({ active, payload }: any) => {
    if (active && payload && payload.length) {
      return (
        <div className="bg-white p-3 border border-gray-200 rounded shadow-lg">
          <p className="font-medium">{payload[0].payload.name} Efficiency</p>
          <p style={{ color: payload[0].color }}>
            {payload[0].value.toFixed(1)}
          </p>
        </div>
      )
    }
    return null
  }

  return (
    <div className="h-80">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={data} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
          <XAxis 
            dataKey="name" 
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
          <Bar 
            dataKey="efficiency" 
            fill="#3b82f6"
            radius={[4, 4, 0, 0]}
          />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}
