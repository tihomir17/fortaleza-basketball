import { useMemo } from 'react'
import { UserGroupIcon, TrophyIcon } from '@heroicons/react/24/outline'
import type { Possession } from '../../services/gameTracking'

interface LiveStatsProps {
  possessions: Possession[]
  homeTeamId: number
  awayTeamId: number
  homeTeamName: string
  awayTeamName: string
}

interface TeamStats {
  teamId: number
  teamName: string
  points: number
  fieldGoalsMade: number
  fieldGoalsAttempted: number
  threePointersMade: number
  threePointersAttempted: number
  freeThrowsMade: number
  freeThrowsAttempted: number
  rebounds: number
  assists: number
  steals: number
  blocks: number
  turnovers: number
  fouls: number
  offensiveRebounds: number
  defensiveRebounds: number
  fastBreakPoints: number
  pointsInPaint: number
  secondChancePoints: number
}

interface PlayerStats {
  playerId: number
  playerName: string
  jerseyNumber: number
  position: string
  teamId: number
  points: number
  fieldGoalsMade: number
  fieldGoalsAttempted: number
  threePointersMade: number
  threePointersAttempted: number
  freeThrowsMade: number
  freeThrowsAttempted: number
  rebounds: number
  assists: number
  steals: number
  blocks: number
  turnovers: number
  fouls: number
  minutesPlayed: number
}

export function LiveStats({ possessions, homeTeamId, awayTeamId, homeTeamName, awayTeamName }: LiveStatsProps) {
  // Calculate team statistics
  const teamStats = useMemo((): TeamStats[] => {
    const homeStats: TeamStats = {
      teamId: homeTeamId,
      teamName: homeTeamName,
      points: 0,
      fieldGoalsMade: 0,
      fieldGoalsAttempted: 0,
      threePointersMade: 0,
      threePointersAttempted: 0,
      freeThrowsMade: 0,
      freeThrowsAttempted: 0,
      rebounds: 0,
      assists: 0,
      steals: 0,
      blocks: 0,
      turnovers: 0,
      fouls: 0,
      offensiveRebounds: 0,
      defensiveRebounds: 0,
      fastBreakPoints: 0,
      pointsInPaint: 0,
      secondChancePoints: 0
    }

    const awayStats: TeamStats = {
      teamId: awayTeamId,
      teamName: awayTeamName,
      points: 0,
      fieldGoalsMade: 0,
      fieldGoalsAttempted: 0,
      threePointersMade: 0,
      threePointersAttempted: 0,
      freeThrowsMade: 0,
      freeThrowsAttempted: 0,
      rebounds: 0,
      assists: 0,
      steals: 0,
      blocks: 0,
      turnovers: 0,
      fouls: 0,
      offensiveRebounds: 0,
      defensiveRebounds: 0,
      fastBreakPoints: 0,
      pointsInPaint: 0,
      secondChancePoints: 0
    }

    possessions.forEach(possession => {
      const isHomeTeam = possession.team.team.id === homeTeamId
      const stats = isHomeTeam ? homeStats : awayStats

      // Points
      stats.points += possession.points_scored

      // Field Goals
      if (possession.outcome === 'MADE_2PTS') {
        stats.fieldGoalsMade += 1
        stats.fieldGoalsAttempted += 1
      } else if (possession.outcome === 'MISSED_2PTS') {
        stats.fieldGoalsAttempted += 1
      }

      // Three Pointers
      if (possession.outcome === 'MADE_3PTS') {
        stats.threePointersMade += 1
        stats.threePointersAttempted += 1
        stats.fieldGoalsMade += 1
        stats.fieldGoalsAttempted += 1
      } else if (possession.outcome === 'MISSED_3PTS') {
        stats.threePointersAttempted += 1
        stats.fieldGoalsAttempted += 1
      }

      // Free Throws
      if (possession.outcome === 'MADE_FTS') {
        stats.freeThrowsMade += 1
        stats.freeThrowsAttempted += 1
      } else if (possession.outcome === 'MISSED_FTS') {
        stats.freeThrowsAttempted += 1
      }

      // Other stats
      if (possession.outcome === 'REBOUND') {
        if (possession.is_offensive_rebound) {
          stats.offensiveRebounds += 1
        } else {
          stats.defensiveRebounds += 1
        }
        stats.rebounds += 1
      }

      if (possession.outcome === 'STEAL') {
        stats.steals += 1
      }

      if (possession.outcome === 'BLOCK') {
        stats.blocks += 1
      }

      if (possession.outcome === 'TURNOVER') {
        stats.turnovers += 1
      }

      if (possession.outcome === 'FOUL' || possession.outcome === 'TECHNICAL_FOUL') {
        stats.fouls += 1
      }

      // Assists (if assisted_by is present)
      if (possession.assisted_by) {
        stats.assists += 1
      }

      // Fast break points (if offensive_set is TRANSITION or FASTBREAK)
      if ((possession.offensive_set === 'TRANSITION' || possession.offensive_set === 'FASTBREAK') && possession.points_scored > 0) {
        stats.fastBreakPoints += possession.points_scored
      }

      // Points in paint (if has_paint_touch and points scored)
      if ((possession as any).has_paint_touch && possession.points_scored > 0) {
        stats.pointsInPaint += possession.points_scored
      }

      // Second chance points (if is_offensive_rebound and points scored)
      if (possession.is_offensive_rebound && possession.points_scored > 0) {
        stats.secondChancePoints += possession.points_scored
      }
    })

    return [homeStats, awayStats]
  }, [possessions, homeTeamId, awayTeamId, homeTeamName, awayTeamName])

  // Calculate player statistics
  const playerStats = useMemo((): PlayerStats[] => {
    const playerMap = new Map<number, PlayerStats>()

    possessions.forEach(possession => {
      // Scorer stats
      if (possession.scorer) {
        const playerId = possession.scorer.id
        if (!playerMap.has(playerId)) {
          playerMap.set(playerId, {
            playerId,
            playerName: `${possession.scorer.first_name} ${possession.scorer.last_name}`,
            jerseyNumber: possession.scorer.jersey_number,
            position: possession.scorer.position,
            teamId: possession.team.team.id,
            points: 0,
            fieldGoalsMade: 0,
            fieldGoalsAttempted: 0,
            threePointersMade: 0,
            threePointersAttempted: 0,
            freeThrowsMade: 0,
            freeThrowsAttempted: 0,
            rebounds: 0,
            assists: 0,
            steals: 0,
            blocks: 0,
            turnovers: 0,
            fouls: 0,
            minutesPlayed: 0
          })
        }

        const player = playerMap.get(playerId)!
        player.points += possession.points_scored

        if (possession.outcome === 'MADE_2PTS') {
          player.fieldGoalsMade += 1
          player.fieldGoalsAttempted += 1
        } else if (possession.outcome === 'MISSED_2PTS') {
          player.fieldGoalsAttempted += 1
        }

        if (possession.outcome === 'MADE_3PTS') {
          player.threePointersMade += 1
          player.threePointersAttempted += 1
          player.fieldGoalsMade += 1
          player.fieldGoalsAttempted += 1
        } else if (possession.outcome === 'MISSED_3PTS') {
          player.threePointersAttempted += 1
          player.fieldGoalsAttempted += 1
        }

        if (possession.outcome === 'MADE_FTS') {
          player.freeThrowsMade += 1
          player.freeThrowsAttempted += 1
        } else if (possession.outcome === 'MISSED_FTS') {
          player.freeThrowsAttempted += 1
        }
      }

      // Assistant stats
      if (possession.assisted_by) {
        const playerId = possession.assisted_by.id
        if (!playerMap.has(playerId)) {
          playerMap.set(playerId, {
            playerId,
            playerName: `${possession.assisted_by.first_name} ${possession.assisted_by.last_name}`,
            jerseyNumber: possession.assisted_by.jersey_number,
            position: possession.assisted_by.position,
            teamId: possession.team.team.id,
            points: 0,
            fieldGoalsMade: 0,
            fieldGoalsAttempted: 0,
            threePointersMade: 0,
            threePointersAttempted: 0,
            freeThrowsMade: 0,
            freeThrowsAttempted: 0,
            rebounds: 0,
            assists: 0,
            steals: 0,
            blocks: 0,
            turnovers: 0,
            fouls: 0,
            minutesPlayed: 0
          })
        }
        playerMap.get(playerId)!.assists += 1
      }

      // Other player attributions
      if (possession.blocked_by) {
        const playerId = possession.blocked_by.id
        if (!playerMap.has(playerId)) {
          playerMap.set(playerId, {
            playerId,
            playerName: `${possession.blocked_by.first_name} ${possession.blocked_by.last_name}`,
            jerseyNumber: possession.blocked_by.jersey_number,
            position: possession.blocked_by.position,
            teamId: possession.opponent.team.id,
            points: 0,
            fieldGoalsMade: 0,
            fieldGoalsAttempted: 0,
            threePointersMade: 0,
            threePointersAttempted: 0,
            freeThrowsMade: 0,
            freeThrowsAttempted: 0,
            rebounds: 0,
            assists: 0,
            steals: 0,
            blocks: 0,
            turnovers: 0,
            fouls: 0,
            minutesPlayed: 0
          })
        }
        playerMap.get(playerId)!.blocks += 1
      }

      if (possession.stolen_by) {
        const playerId = possession.stolen_by.id
        if (!playerMap.has(playerId)) {
          playerMap.set(playerId, {
            playerId,
            playerName: `${possession.stolen_by.first_name} ${possession.stolen_by.last_name}`,
            jerseyNumber: possession.stolen_by.jersey_number,
            position: possession.stolen_by.position,
            teamId: possession.opponent.team.id,
            points: 0,
            fieldGoalsMade: 0,
            fieldGoalsAttempted: 0,
            threePointersMade: 0,
            threePointersAttempted: 0,
            freeThrowsMade: 0,
            freeThrowsAttempted: 0,
            rebounds: 0,
            assists: 0,
            steals: 0,
            blocks: 0,
            turnovers: 0,
            fouls: 0,
            minutesPlayed: 0
          })
        }
        playerMap.get(playerId)!.steals += 1
      }
    })

    return Array.from(playerMap.values()).sort((a, b) => b.points - a.points)
  }, [possessions])

  // Calculate shooting percentages
  const calculatePercentage = (made: number, attempted: number): number => {
    return attempted > 0 ? Math.round((made / attempted) * 100) : 0
  }

  return (
    <div className="space-y-6">
      {/* Team Stats */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {teamStats.map((stats) => (
          <div key={stats.teamId} className="bg-white rounded-lg shadow p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
              <TrophyIcon className="h-5 w-5 mr-2" />
              {stats.teamName}
            </h3>
            
            <div className="grid grid-cols-2 gap-4">
              <div className="text-center">
                <div className="text-2xl font-bold text-blue-600">{stats.points}</div>
                <div className="text-sm text-gray-500">Points</div>
              </div>
              <div className="text-center">
                <div className="text-lg font-semibold text-gray-900">
                  {stats.fieldGoalsMade}/{stats.fieldGoalsAttempted}
                </div>
                <div className="text-sm text-gray-500">
                  FG ({calculatePercentage(stats.fieldGoalsMade, stats.fieldGoalsAttempted)}%)
                </div>
              </div>
              <div className="text-center">
                <div className="text-lg font-semibold text-gray-900">
                  {stats.threePointersMade}/{stats.threePointersAttempted}
                </div>
                <div className="text-sm text-gray-500">
                  3PT ({calculatePercentage(stats.threePointersMade, stats.threePointersAttempted)}%)
                </div>
              </div>
              <div className="text-center">
                <div className="text-lg font-semibold text-gray-900">
                  {stats.freeThrowsMade}/{stats.freeThrowsAttempted}
                </div>
                <div className="text-sm text-gray-500">
                  FT ({calculatePercentage(stats.freeThrowsMade, stats.freeThrowsAttempted)}%)
                </div>
              </div>
              <div className="text-center">
                <div className="text-lg font-semibold text-gray-900">{stats.rebounds}</div>
                <div className="text-sm text-gray-500">Rebounds</div>
              </div>
              <div className="text-center">
                <div className="text-lg font-semibold text-gray-900">{stats.assists}</div>
                <div className="text-sm text-gray-500">Assists</div>
              </div>
              <div className="text-center">
                <div className="text-lg font-semibold text-gray-900">{stats.steals}</div>
                <div className="text-sm text-gray-500">Steals</div>
              </div>
              <div className="text-center">
                <div className="text-lg font-semibold text-gray-900">{stats.blocks}</div>
                <div className="text-sm text-gray-500">Blocks</div>
              </div>
              <div className="text-center">
                <div className="text-lg font-semibold text-gray-900">{stats.turnovers}</div>
                <div className="text-sm text-gray-500">Turnovers</div>
              </div>
              <div className="text-center">
                <div className="text-lg font-semibold text-gray-900">{stats.fouls}</div>
                <div className="text-sm text-gray-500">Fouls</div>
              </div>
            </div>

            {/* Advanced Stats */}
            <div className="mt-4 pt-4 border-t border-gray-200">
              <h4 className="text-sm font-medium text-gray-700 mb-2">Advanced Stats</h4>
              <div className="grid grid-cols-3 gap-2 text-sm">
                <div className="text-center">
                  <div className="font-semibold text-gray-900">{stats.fastBreakPoints}</div>
                  <div className="text-gray-500">Fast Break</div>
                </div>
                <div className="text-center">
                  <div className="font-semibold text-gray-900">{stats.pointsInPaint}</div>
                  <div className="text-gray-500">Paint</div>
                </div>
                <div className="text-center">
                  <div className="font-semibold text-gray-900">{stats.secondChancePoints}</div>
                  <div className="text-gray-500">2nd Chance</div>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Top Players */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <UserGroupIcon className="h-5 w-5 mr-2" />
          Top Performers
        </h3>
        
        {playerStats.length > 0 ? (
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Player</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">PTS</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">FG</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">3PT</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">FT</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">REB</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">AST</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">STL</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">BLK</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {playerStats.slice(0, 10).map((player) => (
                  <tr key={player.playerId}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center">
                        <div className="text-sm font-medium text-gray-900">
                          #{player.jerseyNumber} {player.playerName}
                        </div>
                        <div className="ml-2 text-xs text-gray-500">{player.position}</div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm font-semibold text-gray-900">
                      {player.points}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.fieldGoalsMade}/{player.fieldGoalsAttempted}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.threePointersMade}/{player.threePointersAttempted}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.freeThrowsMade}/{player.freeThrowsAttempted}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.rebounds}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.assists}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.steals}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                      {player.blocks}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500">
            No player statistics available yet
          </div>
        )}
      </div>
    </div>
  )
}
