import { useEffect, useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useAuthStore } from '../store/authStore'
import { Card, CardHeader, CardTitle, CardContent } from '../components/ui/Card'
import { Button } from '../components/ui/Button'
import { 
  ArrowLeftIcon,
  TrophyIcon,
  UserGroupIcon
} from '@heroicons/react/24/outline'

interface GameDetails {
  id: number
  home_team: {
    id: number
    name: string
  }
  away_team: {
    id: number
    name: string
  }
  competition: {
    id: number
    name: string
  }
  game_date: string
  home_team_score?: number
  away_team_score?: number
  quarter?: number
}

interface PlayerStats {
  id: number
  username: string
  first_name: string
  last_name: string
  jersey_number?: number
  position?: string
  points: number
  rebounds: number
  assists: number
  steals: number
  blocks: number
  turnovers: number
  field_goals_made: number
  field_goals_attempted: number
  three_pointers_made: number
  three_pointers_attempted: number
  free_throws_made: number
  free_throws_attempted: number
  minutes_played: number
}

interface TeamStats {
  team: {
    id: number
    name: string
  }
  points: number
  rebounds: number
  assists: number
  steals: number
  blocks: number
  turnovers: number
  field_goals_made: number
  field_goals_attempted: number
  three_pointers_made: number
  three_pointers_attempted: number
  free_throws_made: number
  free_throws_attempted: number
  total_possessions: number
  offensive_possessions: number
  defensive_possessions: number
  avg_offensive_possession_time: number
}


export default function GameDetails() {
  const { gameId } = useParams<{ gameId: string }>()
  const navigate = useNavigate()
  const { isAuthenticated } = useAuthStore()
  
  const [game, setGame] = useState<GameDetails | null>(null)
  const [homeTeamStats, setHomeTeamStats] = useState<TeamStats | null>(null)
  const [awayTeamStats, setAwayTeamStats] = useState<TeamStats | null>(null)
  const [homePlayerStats, setHomePlayerStats] = useState<PlayerStats[]>([])
  const [awayPlayerStats, setAwayPlayerStats] = useState<PlayerStats[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Redirect to login if not authenticated
  useEffect(() => {
    if (!isAuthenticated) {
      navigate('/login')
    }
  }, [isAuthenticated, navigate])

  useEffect(() => {
    if (gameId && isAuthenticated) {
      fetchGameDetails()
    }
  }, [gameId, isAuthenticated])

  const fetchGameDetails = async () => {
    try {
      setLoading(true)
      setError(null)

      // Fetch game basic info
      const gameResponse = await fetch(`/api/games/${gameId}/`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`,
          'Content-Type': 'application/json'
        }
      })
      
      if (!gameResponse.ok) {
        throw new Error('Failed to fetch game details')
      }
      
      const gameData = await gameResponse.json()
      setGame(gameData)

      // Fetch team stats for both teams
      const [homeStatsResponse, awayStatsResponse] = await Promise.all([
        fetch(`/api/games/${gameId}/post-game-report/?team_id=${gameData.home_team.id}`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
            'Content-Type': 'application/json'
          }
        }),
        fetch(`/api/games/${gameId}/post-game-report/?team_id=${gameData.away_team.id}`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
            'Content-Type': 'application/json'
          }
        })
      ])

      if (homeStatsResponse.ok) {
        const homeStats = await homeStatsResponse.json()
        setHomeTeamStats(homeStats)
      }

      if (awayStatsResponse.ok) {
        const awayStats = await awayStatsResponse.json()
        setAwayTeamStats(awayStats)
      }

      // Fetch player stats for both teams
      const [homePlayerResponse, awayPlayerResponse] = await Promise.all([
        fetch(`/api/games/${gameId}/player-stats/?team_id=${gameData.home_team.id}`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
            'Content-Type': 'application/json'
          }
        }),
        fetch(`/api/games/${gameId}/player-stats/?team_id=${gameData.away_team.id}`, {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
            'Content-Type': 'application/json'
          }
        })
      ])

      if (homePlayerResponse.ok) {
        const homePlayers = await homePlayerResponse.json()
        setHomePlayerStats(homePlayers.players || [])
      }

      if (awayPlayerResponse.ok) {
        const awayPlayers = await awayPlayerResponse.json()
        setAwayPlayerStats(awayPlayers.players || [])
      }

    } catch (err: any) {
      setError(err.message || 'Failed to load game details')
    } finally {
      setLoading(false)
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit'
    })
  }

  const calculateFieldGoalPercentage = (made: number, attempted: number) => {
    return attempted > 0 ? ((made / attempted) * 100).toFixed(1) : '0.0'
  }

  const calculateThreePointPercentage = (made: number, attempted: number) => {
    return attempted > 0 ? ((made / attempted) * 100).toFixed(1) : '0.0'
  }

  const calculateFreeThrowPercentage = (made: number, attempted: number) => {
    return attempted > 0 ? ((made / attempted) * 100).toFixed(1) : '0.0'
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="animate-pulse">
            <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-1/4 mb-6"></div>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <div className="h-64 bg-gray-200 dark:bg-gray-700 rounded"></div>
              <div className="h-64 bg-gray-200 dark:bg-gray-700 rounded"></div>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center">
            <div className="text-red-600 dark:text-red-400 text-lg font-medium mb-4">
              Error loading game details
            </div>
            <div className="text-gray-600 dark:text-gray-400 mb-6">{error}</div>
            <Button onClick={() => navigate('/calendar')}>
              <ArrowLeftIcon className="w-4 h-4 mr-2" />
              Back to Calendar
            </Button>
          </div>
        </div>
      </div>
    )
  }

  if (!game) {
    return (
      <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center">
            <div className="text-gray-600 dark:text-gray-400 text-lg font-medium mb-4">
              Game not found
            </div>
            <Button onClick={() => navigate('/calendar')}>
              <ArrowLeftIcon className="w-4 h-4 mr-2" />
              Back to Calendar
            </Button>
          </div>
        </div>
      </div>
    )
  }

  const isGameFinished = game.home_team_score !== null && game.away_team_score !== null
  const homeTeamWon = isGameFinished && (game.home_team_score || 0) > (game.away_team_score || 0)

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <Button 
            variant="outline" 
            onClick={() => navigate('/calendar')}
            className="mb-4"
          >
            <ArrowLeftIcon className="w-4 h-4 mr-2" />
            Back to Calendar
          </Button>
          
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                {game.home_team.name} vs {game.away_team.name}
              </h1>
              <p className="text-gray-600 dark:text-gray-400 mt-2">
                {game.competition.name} • {formatDate(game.game_date)}
              </p>
            </div>
            
            {isGameFinished && (
              <div className="text-right">
                <div className="text-4xl font-bold text-gray-900 dark:text-white">
                  {game.home_team_score} - {game.away_team_score}
                </div>
                <div className="text-lg text-gray-600 dark:text-gray-400">
                  {homeTeamWon ? game.home_team.name : game.away_team.name} Wins
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Team Stats Comparison */}
        {homeTeamStats && awayTeamStats && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            {/* Home Team Stats */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <UserGroupIcon className="w-5 h-5" />
                  {game.home_team.name} Stats
                  {isGameFinished && homeTeamWon && (
                    <TrophyIcon className="w-5 h-5 text-yellow-500" />
                  )}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-3">
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Points:</span>
                      <span className="font-medium">{homeTeamStats.points}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Rebounds:</span>
                      <span className="font-medium">{homeTeamStats.rebounds}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Assists:</span>
                      <span className="font-medium">{homeTeamStats.assists}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Steals:</span>
                      <span className="font-medium">{homeTeamStats.steals}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Blocks:</span>
                      <span className="font-medium">{homeTeamStats.blocks}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Turnovers:</span>
                      <span className="font-medium">{homeTeamStats.turnovers}</span>
                    </div>
                  </div>
                  <div className="space-y-3">
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">FG%:</span>
                      <span className="font-medium">
                        {calculateFieldGoalPercentage(homeTeamStats.field_goals_made, homeTeamStats.field_goals_attempted)}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">3P%:</span>
                      <span className="font-medium">
                        {calculateThreePointPercentage(homeTeamStats.three_pointers_made, homeTeamStats.three_pointers_attempted)}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">FT%:</span>
                      <span className="font-medium">
                        {calculateFreeThrowPercentage(homeTeamStats.free_throws_made, homeTeamStats.free_throws_attempted)}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Possessions:</span>
                      <span className="font-medium">{homeTeamStats.total_possessions}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Avg Poss Time:</span>
                      <span className="font-medium">
                        {homeTeamStats.avg_offensive_possession_time?.toFixed(1)}s
                      </span>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>

            {/* Away Team Stats */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <UserGroupIcon className="w-5 h-5" />
                  {game.away_team.name} Stats
                  {isGameFinished && !homeTeamWon && (
                    <TrophyIcon className="w-5 h-5 text-yellow-500" />
                  )}
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-3">
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Points:</span>
                      <span className="font-medium">{awayTeamStats.points}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Rebounds:</span>
                      <span className="font-medium">{awayTeamStats.rebounds}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Assists:</span>
                      <span className="font-medium">{awayTeamStats.assists}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Steals:</span>
                      <span className="font-medium">{awayTeamStats.steals}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Blocks:</span>
                      <span className="font-medium">{awayTeamStats.blocks}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Turnovers:</span>
                      <span className="font-medium">{awayTeamStats.turnovers}</span>
                    </div>
                  </div>
                  <div className="space-y-3">
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">FG%:</span>
                      <span className="font-medium">
                        {calculateFieldGoalPercentage(awayTeamStats.field_goals_made, awayTeamStats.field_goals_attempted)}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">3P%:</span>
                      <span className="font-medium">
                        {calculateThreePointPercentage(awayTeamStats.three_pointers_made, awayTeamStats.three_pointers_attempted)}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">FT%:</span>
                      <span className="font-medium">
                        {calculateFreeThrowPercentage(awayTeamStats.free_throws_made, awayTeamStats.free_throws_attempted)}%
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Possessions:</span>
                      <span className="font-medium">{awayTeamStats.total_possessions}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-600 dark:text-gray-400">Avg Poss Time:</span>
                      <span className="font-medium">
                        {awayTeamStats.avg_offensive_possession_time?.toFixed(1)}s
                      </span>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Player Stats */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Home Team Players */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <UserGroupIcon className="w-5 h-5" />
                {game.home_team.name} Players
              </CardTitle>
            </CardHeader>
            <CardContent>
              {homePlayerStats.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-gray-200 dark:border-gray-700">
                        <th className="text-left py-2">Player</th>
                        <th className="text-center py-2">PTS</th>
                        <th className="text-center py-2">REB</th>
                        <th className="text-center py-2">AST</th>
                        <th className="text-center py-2">STL</th>
                        <th className="text-center py-2">BLK</th>
                        <th className="text-center py-2">TO</th>
                        <th className="text-center py-2">FG%</th>
                        <th className="text-center py-2">3P%</th>
                        <th className="text-center py-2">FT%</th>
                        <th className="text-center py-2">MIN</th>
                      </tr>
                    </thead>
                    <tbody>
                      {homePlayerStats.map((player) => (
                        <tr key={player.id} className="border-b border-gray-100 dark:border-gray-800">
                          <td className="py-2">
                            <div>
                              <div className="font-medium">
                                {player.jersey_number && `#${player.jersey_number} `}
                                {player.first_name} {player.last_name}
                              </div>
                              <div className="text-xs text-gray-500 dark:text-gray-400">
                                {player.position}
                              </div>
                            </div>
                          </td>
                          <td className="text-center py-2 font-medium">{player.points}</td>
                          <td className="text-center py-2">{player.rebounds}</td>
                          <td className="text-center py-2">{player.assists}</td>
                          <td className="text-center py-2">{player.steals}</td>
                          <td className="text-center py-2">{player.blocks}</td>
                          <td className="text-center py-2">{player.turnovers}</td>
                          <td className="text-center py-2">
                            {calculateFieldGoalPercentage(player.field_goals_made, player.field_goals_attempted)}%
                          </td>
                          <td className="text-center py-2">
                            {calculateThreePointPercentage(player.three_pointers_made, player.three_pointers_attempted)}%
                          </td>
                          <td className="text-center py-2">
                            {calculateFreeThrowPercentage(player.free_throws_made, player.free_throws_attempted)}%
                          </td>
                          <td className="text-center py-2">{player.minutes_played}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="text-center text-gray-500 dark:text-gray-400 py-8">
                  No player statistics available
                </div>
              )}
            </CardContent>
          </Card>

          {/* Away Team Players */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <UserGroupIcon className="w-5 h-5" />
                {game.away_team.name} Players
              </CardTitle>
            </CardHeader>
            <CardContent>
              {awayPlayerStats.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b border-gray-200 dark:border-gray-700">
                        <th className="text-left py-2">Player</th>
                        <th className="text-center py-2">PTS</th>
                        <th className="text-center py-2">REB</th>
                        <th className="text-center py-2">AST</th>
                        <th className="text-center py-2">STL</th>
                        <th className="text-center py-2">BLK</th>
                        <th className="text-center py-2">TO</th>
                        <th className="text-center py-2">FG%</th>
                        <th className="text-center py-2">3P%</th>
                        <th className="text-center py-2">FT%</th>
                        <th className="text-center py-2">MIN</th>
                      </tr>
                    </thead>
                    <tbody>
                      {awayPlayerStats.map((player) => (
                        <tr key={player.id} className="border-b border-gray-100 dark:border-gray-800">
                          <td className="py-2">
                            <div>
                              <div className="font-medium">
                                {player.jersey_number && `#${player.jersey_number} `}
                                {player.first_name} {player.last_name}
                              </div>
                              <div className="text-xs text-gray-500 dark:text-gray-400">
                                {player.position}
                              </div>
                            </div>
                          </td>
                          <td className="text-center py-2 font-medium">{player.points}</td>
                          <td className="text-center py-2">{player.rebounds}</td>
                          <td className="text-center py-2">{player.assists}</td>
                          <td className="text-center py-2">{player.steals}</td>
                          <td className="text-center py-2">{player.blocks}</td>
                          <td className="text-center py-2">{player.turnovers}</td>
                          <td className="text-center py-2">
                            {calculateFieldGoalPercentage(player.field_goals_made, player.field_goals_attempted)}%
                          </td>
                          <td className="text-center py-2">
                            {calculateThreePointPercentage(player.three_pointers_made, player.three_pointers_attempted)}%
                          </td>
                          <td className="text-center py-2">
                            {calculateFreeThrowPercentage(player.free_throws_made, player.free_throws_attempted)}%
                          </td>
                          <td className="text-center py-2">{player.minutes_played}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="text-center text-gray-500 dark:text-gray-400 py-8">
                  No player statistics available
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
