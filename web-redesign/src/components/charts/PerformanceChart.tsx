import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  AreaChart,
  Area
} from 'recharts'

interface PerformanceChartProps {
  data: any[]
  type: 'line' | 'bar' | 'pie' | 'area'
  title?: string
  height?: number
  className?: string
}

const COLORS = ['#1e3a8a', '#f59e0b', '#10b981', '#ef4444', '#8b5cf6', '#06b6d4']

export function PerformanceChart({ 
  data, 
  type, 
  title, 
  height = 300, 
  className = '' 
}: PerformanceChartProps) {
  const renderChart = () => {
    switch (type) {
      case 'line':
        return (
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Line 
              type="monotone" 
              dataKey="value" 
              stroke="#1e3a8a" 
              strokeWidth={2}
              dot={{ fill: '#1e3a8a', strokeWidth: 2, r: 4 }}
            />
          </LineChart>
        )
      
      case 'bar':
        return (
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="value" fill="#1e3a8a" />
          </BarChart>
        )
      
      case 'pie':
        return (
          <PieChart>
            <Pie
              data={data}
              cx="50%"
              cy="50%"
              labelLine={false}
              label={(entry: any) => `${entry.name} ${(entry.percent * 100).toFixed(0)}%`}
              outerRadius={80}
              fill="#8884d8"
              dataKey="value"
            >
              {data.map((_entry, index) => (
                <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
              ))}
            </Pie>
            <Tooltip />
          </PieChart>
        )
      
      case 'area':
        return (
          <AreaChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Area 
              type="monotone" 
              dataKey="value" 
              stroke="#1e3a8a" 
              fill="#1e3a8a" 
              fillOpacity={0.3}
            />
          </AreaChart>
        )
      
      default:
        return <div>Unsupported chart type</div>
    }
  }

  return (
    <div className={`bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-100 dark:border-gray-700 p-6 ${className}`}>
      {title && (
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          {title}
        </h3>
      )}
      <ResponsiveContainer width="100%" height={height}>
        {renderChart()}
      </ResponsiveContainer>
    </div>
  )
}

// Specialized chart components
export function PlayerStatsChart({ playerData }: { playerData: any[] }) {
  return (
    <PerformanceChart
      data={playerData}
      type="line"
      title="Player Performance Over Time"
      height={400}
    />
  )
}

export function TeamComparisonChart({ teamData }: { teamData: any[] }) {
  return (
    <PerformanceChart
      data={teamData}
      type="bar"
      title="Team Performance Comparison"
      height={350}
    />
  )
}

export function GameDistributionChart({ gameData }: { gameData: any[] }) {
  return (
    <PerformanceChart
      data={gameData}
      type="pie"
      title="Game Results Distribution"
      height={300}
    />
  )
}

export function SeasonTrendsChart({ trendData }: { trendData: any[] }) {
  return (
    <PerformanceChart
      data={trendData}
      type="area"
      title="Season Trends"
      height={400}
    />
  )
}

// Multi-line chart for comparing multiple metrics
interface MultiLineChartProps {
  data: any[]
  title?: string
  height?: number
  className?: string
}

export function MultiLineChart({ 
  data, 
  title, 
  height = 400, 
  className = '' 
}: MultiLineChartProps) {
  return (
    <div className={`bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-100 dark:border-gray-700 p-6 ${className}`}>
      {title && (
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          {title}
        </h3>
      )}
      <ResponsiveContainer width="100%" height={height}>
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" />
          <XAxis dataKey="name" />
          <YAxis />
          <Tooltip />
          <Legend />
          <Line 
            type="monotone" 
            dataKey="points" 
            stroke="#1e3a8a" 
            strokeWidth={2}
            name="Points"
          />
          <Line 
            type="monotone" 
            dataKey="assists" 
            stroke="#f59e0b" 
            strokeWidth={2}
            name="Assists"
          />
          <Line 
            type="monotone" 
            dataKey="rebounds" 
            stroke="#10b981" 
            strokeWidth={2}
            name="Rebounds"
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  )
}

// Dashboard stats chart
export function DashboardStatsChart({ statsData }: { statsData: any[] }) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <PerformanceChart
        data={statsData}
        type="line"
        title="Performance Trends"
        height={300}
      />
      <PerformanceChart
        data={statsData}
        type="bar"
        title="Monthly Comparison"
        height={300}
      />
    </div>
  )
}
