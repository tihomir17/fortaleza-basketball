import { useState } from 'react'
import type { PlayerStats } from '../../services/analytics'

interface PlayerStatsTableProps {
  players: PlayerStats[]
}

export function PlayerStatsTable({ players }: PlayerStatsTableProps) {
  const [sortField, setSortField] = useState<keyof PlayerStats>('points_per_game')
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc')

  const handleSort = (field: keyof PlayerStats) => {
    if (sortField === field) {
      setSortDirection(sortDirection === 'asc' ? 'desc' : 'asc')
    } else {
      setSortField(field)
      setSortDirection('desc')
    }
  }

  const sortedPlayers = [...players].sort((a, b) => {
    const aValue = a[sortField] as number
    const bValue = b[sortField] as number
    
    if (sortDirection === 'asc' ) {
      return aValue - bValue
    } else {
      return bValue - aValue
    }
  })

  const formatValue = (value: number, type: 'percentage' | 'decimal' | 'number' = 'number') => {
    switch (type) {
      case 'percentage':
        return `${value.toFixed(1)}%`
      case 'decimal':
        return value.toFixed(1)
      case 'number':
      default:
        return value.toLocaleString()
    }
  }

  const getSortIcon = (field: keyof PlayerStats) => {
    if (sortField !== field) {
      return <span className="text-gray-400">↕</span>
    }
    return sortDirection === 'asc' ? <span className="text-blue-600">↑</span> : <span className="text-blue-600">↓</span>
  }

  const columns = [
    { key: 'jersey_number', label: '#', width: 'w-16' },
    { key: 'first_name', label: 'Player', width: 'w-32' },
    { key: 'games_played', label: 'GP', width: 'w-16' },
    { key: 'points_per_game', label: 'PPG', width: 'w-16' },
    { key: 'assists_per_game', label: 'APG', width: 'w-16' },
    { key: 'rebounds_per_game', label: 'RPG', width: 'w-16' },
    { key: 'field_goal_percentage', label: 'FG%', width: 'w-16' },
    { key: 'three_point_percentage', label: '3P%', width: 'w-16' },
    { key: 'free_throw_percentage', label: 'FT%', width: 'w-16' },
    { key: 'efficiency_rating', label: 'EFF', width: 'w-16' },
    { key: 'plus_minus', label: '+/-', width: 'w-16' }
  ]

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            {columns.map((column) => (
              <th
                key={column.key}
                className={`px-3 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider ${column.width} cursor-pointer hover:bg-gray-100`}
                onClick={() => handleSort(column.key as keyof PlayerStats)}
              >
                <div className="flex items-center space-x-1">
                  <span>{column.label}</span>
                  {getSortIcon(column.key as keyof PlayerStats)}
                </div>
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {sortedPlayers.map((player) => (
            <tr key={player.id} className="hover:bg-gray-50">
              <td className="px-3 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                {player.jersey_number || '-'}
              </td>
              <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                <div>
                  <div className="font-medium">{player.first_name} {player.last_name}</div>
                  <div className="text-gray-500 text-xs">{player.username}</div>
                </div>
              </td>
              <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                {formatValue(player.games_played)}
              </td>
              <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                {formatValue(player.points_per_game, 'decimal')}
              </td>
              <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                {formatValue(player.assists_per_game, 'decimal')}
              </td>
              <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                {formatValue(player.rebounds_per_game, 'decimal')}
              </td>
              <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                {formatValue(player.field_goal_percentage, 'percentage')}
              </td>
              <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                {formatValue(player.three_point_percentage, 'percentage')}
              </td>
              <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                {formatValue(player.free_throw_percentage, 'percentage')}
              </td>
              <td className="px-3 py-4 whitespace-nowrap text-sm text-gray-900">
                {formatValue(player.efficiency_rating, 'decimal')}
              </td>
              <td className={`px-3 py-4 whitespace-nowrap text-sm ${
                player.plus_minus > 0 ? 'text-green-600' : 
                player.plus_minus < 0 ? 'text-red-600' : 'text-gray-900'
              }`}>
                {player.plus_minus > 0 ? '+' : ''}{formatValue(player.plus_minus, 'decimal')}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      
      {players.length === 0 && (
        <div className="text-center py-8 text-gray-500">
          No player statistics available
        </div>
      )}
    </div>
  )
}
