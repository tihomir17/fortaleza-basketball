import { useState, useEffect } from 'react'
import {
  PlayIcon,
  PauseIcon,
  StopIcon,
  ClockIcon,
  ChartBarIcon,
  UserGroupIcon,
  TrophyIcon,
  SignalIcon
} from '@heroicons/react/24/outline'
import { LiveTrackingLoading } from '../components/ui/LoadingStates'

interface GameState {
  isLive: boolean
  isPaused: boolean
  currentQuarter: number
  timeRemaining: string
  homeScore: number
  awayScore: number
  homeTeam: string
  awayTeam: string
  possession: 'home' | 'away'
}

interface Play {
  id: number
  time: string
  quarter: number
  team: 'home' | 'away'
  player: string
  action: string
  points?: number
  description: string
  timestamp: number
}

interface PlayerStats {
  id: number
  name: string
  jersey: number
  position: string
  team: 'home' | 'away'
  points: number
  rebounds: number
  assists: number
  steals: number
  blocks: number
  turnovers: number
  fouls: number
  fieldGoalsMade: number
  fieldGoalsAttempted: number
  threePointersMade: number
  threePointersAttempted: number
  freeThrowsMade: number
  freeThrowsAttempted: number
  minutesPlayed: number
}

interface TeamStats {
  team: 'home' | 'away'
  points: number
  fieldGoalPercentage: number
  threePointPercentage: number
  freeThrowPercentage: number
  rebounds: number
  assists: number
  steals: number
  blocks: number
  turnovers: number
  fouls: number
  fastBreakPoints: number
  pointsInPaint: number
  secondChancePoints: number
}

export function LiveTracking() {
  const [gameState, setGameState] = useState<GameState>({
    isLive: false,
    isPaused: false,
    currentQuarter: 1,
    timeRemaining: '12:00',
    homeScore: 0,
    awayScore: 0,
    homeTeam: 'Fortaleza',
    awayTeam: 'Thunder',
    possession: 'home'
  })
  const [isLoading, setIsLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<'plays' | 'stats' | 'players'>('plays')
  const [isConnected] = useState(true)
  const [autoSave, setAutoSave] = useState(true)

  // Mock player stats
  const [playerStats, setPlayerStats] = useState<PlayerStats[]>([
    // Home team players
    { id: 1, name: 'João Silva', jersey: 10, position: 'PG', team: 'home', points: 12, rebounds: 3, assists: 5, steals: 2, blocks: 0, turnovers: 1, fouls: 2, fieldGoalsMade: 5, fieldGoalsAttempted: 8, threePointersMade: 2, threePointersAttempted: 4, freeThrowsMade: 0, freeThrowsAttempted: 0, minutesPlayed: 15 },
    { id: 2, name: 'Carlos Santos', jersey: 23, position: 'SG', team: 'home', points: 8, rebounds: 2, assists: 3, steals: 1, blocks: 0, turnovers: 2, fouls: 1, fieldGoalsMade: 3, fieldGoalsAttempted: 7, threePointersMade: 2, threePointersAttempted: 5, freeThrowsMade: 0, freeThrowsAttempted: 0, minutesPlayed: 12 },
    { id: 3, name: 'Pedro Costa', jersey: 7, position: 'SF', team: 'home', points: 15, rebounds: 6, assists: 2, steals: 0, blocks: 1, turnovers: 1, fouls: 3, fieldGoalsMade: 6, fieldGoalsAttempted: 10, threePointersMade: 1, threePointersAttempted: 3, freeThrowsMade: 2, freeThrowsAttempted: 2, minutesPlayed: 18 },
    { id: 4, name: 'Miguel Oliveira', jersey: 33, position: 'PF', team: 'home', points: 6, rebounds: 8, assists: 1, steals: 0, blocks: 2, turnovers: 0, fouls: 2, fieldGoalsMade: 3, fieldGoalsAttempted: 6, threePointersMade: 0, threePointersAttempted: 1, freeThrowsMade: 0, freeThrowsAttempted: 0, minutesPlayed: 16 },
    { id: 5, name: 'André Ferreira', jersey: 21, position: 'C', team: 'home', points: 10, rebounds: 12, assists: 1, steals: 1, blocks: 3, turnovers: 2, fouls: 1, fieldGoalsMade: 5, fieldGoalsAttempted: 8, threePointersMade: 0, threePointersAttempted: 0, freeThrowsMade: 0, freeThrowsAttempted: 0, minutesPlayed: 20 },
    // Away team players
    { id: 6, name: 'Mike Johnson', jersey: 3, position: 'PG', team: 'away', points: 18, rebounds: 2, assists: 7, steals: 3, blocks: 0, turnovers: 1, fouls: 1, fieldGoalsMade: 7, fieldGoalsAttempted: 12, threePointersMade: 4, threePointersAttempted: 8, freeThrowsMade: 0, freeThrowsAttempted: 0, minutesPlayed: 19 },
    { id: 7, name: 'David Wilson', jersey: 15, position: 'SG', team: 'away', points: 14, rebounds: 4, assists: 2, steals: 1, blocks: 0, turnovers: 2, fouls: 2, fieldGoalsMade: 5, fieldGoalsAttempted: 9, threePointersMade: 2, threePointersAttempted: 4, freeThrowsMade: 2, freeThrowsAttempted: 2, minutesPlayed: 17 },
    { id: 8, name: 'Chris Brown', jersey: 8, position: 'SF', team: 'away', points: 9, rebounds: 5, assists: 4, steals: 0, blocks: 1, turnovers: 1, fouls: 3, fieldGoalsMade: 4, fieldGoalsAttempted: 8, threePointersMade: 1, threePointersAttempted: 3, freeThrowsMade: 0, freeThrowsAttempted: 0, minutesPlayed: 16 },
    { id: 9, name: 'Alex Davis', jersey: 42, position: 'PF', team: 'away', points: 7, rebounds: 9, assists: 1, steals: 0, blocks: 2, turnovers: 0, fouls: 2, fieldGoalsMade: 3, fieldGoalsAttempted: 7, threePointersMade: 1, threePointersAttempted: 2, freeThrowsMade: 0, freeThrowsAttempted: 0, minutesPlayed: 18 },
    { id: 10, name: 'Ryan Miller', jersey: 55, position: 'C', team: 'away', points: 11, rebounds: 11, assists: 2, steals: 1, blocks: 4, turnovers: 1, fouls: 1, fieldGoalsMade: 5, fieldGoalsAttempted: 9, threePointersMade: 0, threePointersAttempted: 0, freeThrowsMade: 1, freeThrowsAttempted: 2, minutesPlayed: 22 }
  ])

  // Mock team stats
  const [teamStats, setTeamStats] = useState<TeamStats[]>([
    {
      team: 'home',
      points: 51,
      fieldGoalPercentage: 48.2,
      threePointPercentage: 35.7,
      freeThrowPercentage: 100.0,
      rebounds: 31,
      assists: 12,
      steals: 4,
      blocks: 6,
      turnovers: 6,
      fouls: 9,
      fastBreakPoints: 8,
      pointsInPaint: 24,
      secondChancePoints: 6
    },
    {
      team: 'away',
      points: 59,
      fieldGoalPercentage: 44.4,
      threePointPercentage: 47.1,
      freeThrowPercentage: 100.0,
      rebounds: 31,
      assists: 16,
      steals: 5,
      blocks: 7,
      turnovers: 5,
      fouls: 9,
      fastBreakPoints: 12,
      pointsInPaint: 18,
      secondChancePoints: 4
    }
  ])

  useEffect(() => {
    // Simulate loading
    const timer = setTimeout(() => {
      setIsLoading(false)
    }, 1000)
    return () => clearTimeout(timer)
  }, [])

  const [plays, setPlays] = useState<Play[]>([
    {
      id: 1,
      time: '11:45',
      quarter: 1,
      team: 'home',
      player: 'João Silva',
      action: '2PT_MADE',
      points: 2,
      description: 'Jump shot from 15 feet',
      timestamp: Date.now() - 300000
    },
    {
      id: 2,
      time: '11:30',
      quarter: 1,
      team: 'away',
      player: 'Mike Johnson',
      action: '3PT_MADE',
      points: 3,
      description: 'Three-pointer from corner',
      timestamp: Date.now() - 600000
    },
    {
      id: 3,
      time: '11:15',
      quarter: 1,
      team: 'home',
      player: 'Pedro Costa',
      action: 'REBOUND',
      points: 0,
      description: 'Defensive rebound',
      timestamp: Date.now() - 900000
    },
    {
      id: 4,
      time: '11:00',
      quarter: 1,
      team: 'away',
      player: 'David Wilson',
      action: 'STEAL',
      points: 0,
      description: 'Steal and fast break',
      timestamp: Date.now() - 1200000
    }
  ])

  const [, setTime] = useState(0)

  useEffect(() => {
    let interval: NodeJS.Timeout
    if (gameState.isLive && !gameState.isPaused) {
      interval = setInterval(() => {
        setTime(prev => {
          const newTime = prev + 1
          const minutes = Math.floor(newTime / 60)
          const seconds = newTime % 60
          const timeString = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
          
          setGameState(prev => ({
            ...prev,
            timeRemaining: timeString
          }))
          
          return newTime
        })
      }, 1000)
    }
    return () => clearInterval(interval)
  }, [gameState.isLive, gameState.isPaused])

  if (isLoading) {
    return <LiveTrackingLoading />
  }

  const startGame = () => {
    setGameState(prev => ({ ...prev, isLive: true, isPaused: false }))
  }

  const pauseGame = () => {
    setGameState(prev => ({ ...prev, isPaused: !prev.isPaused }))
  }

  const stopGame = () => {
    setGameState(prev => ({ 
      ...prev, 
      isLive: false, 
      isPaused: false,
      timeRemaining: '12:00'
    }))
    setTime(0)
  }

  const addScore = (team: 'home' | 'away', points: number) => {
    setGameState(prev => ({
      ...prev,
      homeScore: team === 'home' ? prev.homeScore + points : prev.homeScore,
      awayScore: team === 'away' ? prev.awayScore + points : prev.awayScore
    }))

    // Add play to history
    const newPlay: Play = {
      id: Date.now(),
      time: gameState.timeRemaining,
      quarter: gameState.currentQuarter,
      team,
      player: team === 'home' ? 'João Silva' : 'Mike Johnson',
      action: points === 2 ? '2PT_MADE' : points === 3 ? '3PT_MADE' : 'FT_MADE',
      points,
      description: `${points}-point shot`,
      timestamp: Date.now()
    }
    setPlays(prev => [newPlay, ...prev])

    // Update player stats
    setPlayerStats(prev => prev.map(player => 
      player.team === team && player.name === (team === 'home' ? 'João Silva' : 'Mike Johnson')
        ? { ...player, points: player.points + points }
        : player
    ))

    // Update team stats
    setTeamStats(prev => prev.map(teamStat => 
      teamStat.team === team
        ? { ...teamStat, points: teamStat.points + points }
        : teamStat
    ))
  }

  const nextQuarter = () => {
    if (gameState.currentQuarter < 4) {
      setGameState(prev => ({
        ...prev,
        currentQuarter: prev.currentQuarter + 1,
        timeRemaining: '12:00'
      }))
      setTime(0)
    }
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 animate-fade-in">
      {/* Page Header */}
      <div className="mb-8">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2 flex items-center">
              <SignalIcon className="h-8 w-8 mr-3 text-green-600" />
              Live Game Tracking
            </h1>
            <p className="text-gray-600 dark:text-gray-400">
              Track your game in real-time with live statistics and player performance
            </p>
          </div>
          
          <div className="flex items-center space-x-4 mt-4 sm:mt-0">
            {/* Connection Status */}
            <div className="flex items-center space-x-2">
              <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`} />
              <span className="text-sm text-gray-600 dark:text-gray-400">
                {isConnected ? 'Connected' : 'Disconnected'}
              </span>
            </div>
            
            {/* Auto Save Toggle */}
            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="autoSave"
                checked={autoSave}
                onChange={(e) => setAutoSave(e.target.checked)}
                className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <label htmlFor="autoSave" className="text-sm text-gray-600 dark:text-gray-400">
                Auto Save
              </label>
            </div>
          </div>
        </div>
      </div>

      {/* Game Controls */}
      <div className="bg-white rounded-lg shadow p-6 mb-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-gray-900">Game Controls</h2>
          <div className="flex items-center space-x-3">
            {!gameState.isLive ? (
              <button
                onClick={startGame}
                className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors flex items-center"
              >
                <PlayIcon className="w-5 h-5 mr-2" />
                Start Game
              </button>
            ) : (
              <>
                <button
                  onClick={pauseGame}
                  className={`px-4 py-2 rounded-lg transition-colors flex items-center ${
                    gameState.isPaused 
                      ? 'bg-green-600 text-white hover:bg-green-700' 
                      : 'bg-yellow-600 text-white hover:bg-yellow-700'
                  }`}
                >
                  {gameState.isPaused ? (
                    <>
                      <PlayIcon className="w-5 h-5 mr-2" />
                      Resume
                    </>
                  ) : (
                    <>
                      <PauseIcon className="w-5 h-5 mr-2" />
                      Pause
                    </>
                  )}
                </button>
                <button
                  onClick={stopGame}
                  className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors flex items-center"
                >
                  <StopIcon className="w-5 h-5 mr-2" />
                  Stop Game
                </button>
              </>
            )}
          </div>
        </div>

        {/* Game Status */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="text-center">
            <div className="text-2xl font-bold text-gray-900 mb-2">
              Q{gameState.currentQuarter}
            </div>
            <div className="text-sm text-gray-600">Quarter</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-gray-900 mb-2 flex items-center justify-center">
              <ClockIcon className="w-6 h-6 mr-2" />
              {gameState.timeRemaining}
            </div>
            <div className="text-sm text-gray-600">Time Remaining</div>
          </div>
          <div className="text-center">
            <div className="text-2xl font-bold text-gray-900 mb-2">
              {gameState.possession === 'home' ? '🏠' : '✈️'}
            </div>
            <div className="text-sm text-gray-600">Possession</div>
          </div>
        </div>
      </div>

      {/* Scoreboard */}
      <div className="bg-white rounded-lg shadow p-6 mb-8">
        <h2 className="text-xl font-semibold text-gray-900 mb-6">Scoreboard</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Home Team */}
          <div className="text-center">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">{gameState.homeTeam}</h3>
            <div className="text-6xl font-bold text-fortaleza-blue mb-4">
              {gameState.homeScore}
            </div>
            <div className="flex justify-center space-x-2">
              <button
                onClick={() => addScore('home', 1)}
                className="bg-blue-100 text-blue-800 px-3 py-1 rounded-lg hover:bg-blue-200 transition-colors"
              >
                +1 FT
              </button>
              <button
                onClick={() => addScore('home', 2)}
                className="bg-green-100 text-green-800 px-3 py-1 rounded-lg hover:bg-green-200 transition-colors"
              >
                +2 PT
              </button>
              <button
                onClick={() => addScore('home', 3)}
                className="bg-purple-100 text-purple-800 px-3 py-1 rounded-lg hover:bg-purple-200 transition-colors"
              >
                +3 PT
              </button>
            </div>
          </div>

          {/* Away Team */}
          <div className="text-center">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">{gameState.awayTeam}</h3>
            <div className="text-6xl font-bold text-fortaleza-gold mb-4">
              {gameState.awayScore}
            </div>
            <div className="flex justify-center space-x-2">
              <button
                onClick={() => addScore('away', 1)}
                className="bg-blue-100 text-blue-800 px-3 py-1 rounded-lg hover:bg-blue-200 transition-colors"
              >
                +1 FT
              </button>
              <button
                onClick={() => addScore('away', 2)}
                className="bg-green-100 text-green-800 px-3 py-1 rounded-lg hover:bg-green-200 transition-colors"
              >
                +2 PT
              </button>
              <button
                onClick={() => addScore('away', 3)}
                className="bg-purple-100 text-purple-800 px-3 py-1 rounded-lg hover:bg-purple-200 transition-colors"
              >
                +3 PT
              </button>
            </div>
          </div>
        </div>

        {/* Quarter Controls */}
        <div className="mt-6 text-center">
          <button
            onClick={nextQuarter}
            disabled={gameState.currentQuarter >= 4}
            className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            Next Quarter
          </button>
        </div>
      </div>

      {/* Enhanced Tabs Section */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow">
        <div className="border-b border-gray-200 dark:border-gray-700">
          <nav className="-mb-px flex space-x-8 px-6">
            <button
              onClick={() => setActiveTab('plays')}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'plays'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <ChartBarIcon className="h-4 w-4 inline mr-2" />
              Live Plays ({plays.length})
            </button>
            <button
              onClick={() => setActiveTab('stats')}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'stats'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <TrophyIcon className="h-4 w-4 inline mr-2" />
              Team Stats
            </button>
            <button
              onClick={() => setActiveTab('players')}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'players'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <UserGroupIcon className="h-4 w-4 inline mr-2" />
              Player Stats
            </button>
          </nav>
        </div>

        <div className="p-6">
          {/* Live Plays Tab */}
          {activeTab === 'plays' && (
            <div>
              {plays.length > 0 ? (
                <div className="space-y-4">
                  {plays.map((play) => (
                    <div key={play.id} className="flex items-center justify-between p-4 bg-gray-50 dark:bg-gray-700 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-600 transition-colors">
                      <div className="flex items-center space-x-4">
                        <div className={`w-3 h-3 rounded-full ${
                          play.team === 'home' ? 'bg-blue-600' : 'bg-yellow-600'
                        }`}></div>
                        <div>
                          <p className="text-sm font-medium text-gray-900 dark:text-white">
                            Q{play.quarter} {play.time} - {play.player}
                          </p>
                          <p className="text-xs text-gray-500 dark:text-gray-400">{play.description}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        {play.points && play.points > 0 && (
                          <p className="text-sm font-semibold text-gray-900 dark:text-white">
                            +{play.points} pts
                          </p>
                        )}
                        <p className="text-xs text-gray-500 dark:text-gray-400">
                          {play.team === 'home' ? gameState.homeTeam : gameState.awayTeam}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-center py-8">
                  <ChartBarIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No plays yet</h3>
                  <p className="text-gray-500 dark:text-gray-400">Start the game and add plays to see them here.</p>
                </div>
              )}
            </div>
          )}

          {/* Team Stats Tab */}
          {activeTab === 'stats' && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {teamStats.map((team) => (
                  <div key={team.team} className="bg-gray-50 dark:bg-gray-700 rounded-lg p-6">
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
                      {team.team === 'home' ? gameState.homeTeam : gameState.awayTeam}
                    </h3>
                    
                    <div className="grid grid-cols-2 gap-4">
                      <div className="text-center">
                        <div className="text-2xl font-bold text-gray-900 dark:text-white">{team.points}</div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">Points</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-gray-900 dark:text-white">{team.fieldGoalPercentage.toFixed(1)}%</div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">FG%</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-gray-900 dark:text-white">{team.threePointPercentage.toFixed(1)}%</div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">3PT%</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-gray-900 dark:text-white">{team.rebounds}</div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">Rebounds</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-gray-900 dark:text-white">{team.assists}</div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">Assists</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-gray-900 dark:text-white">{team.steals}</div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">Steals</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-gray-900 dark:text-white">{team.blocks}</div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">Blocks</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-gray-900 dark:text-white">{team.turnovers}</div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">Turnovers</div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Player Stats Tab */}
          {activeTab === 'players' && (
            <div className="space-y-6">
              <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                {/* Home Team Players */}
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">{gameState.homeTeam}</h3>
                  <div className="space-y-3">
                    {playerStats.filter(p => p.team === 'home').map((player) => (
                      <div key={player.id} className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center space-x-3">
                            <div className="w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center text-sm font-bold">
                              {player.jersey}
                            </div>
                            <div>
                              <p className="font-medium text-gray-900 dark:text-white">{player.name}</p>
                              <p className="text-sm text-gray-500 dark:text-gray-400">{player.position}</p>
                            </div>
                          </div>
                          <div className="text-right">
                            <p className="text-lg font-bold text-gray-900 dark:text-white">{player.points}</p>
                            <p className="text-xs text-gray-500 dark:text-gray-400">PTS</p>
                          </div>
                        </div>
                        <div className="grid grid-cols-4 gap-2 text-center text-sm">
                          <div>
                            <div className="font-medium text-gray-900 dark:text-white">{player.rebounds}</div>
                            <div className="text-xs text-gray-500 dark:text-gray-400">REB</div>
                          </div>
                          <div>
                            <div className="font-medium text-gray-900 dark:text-white">{player.assists}</div>
                            <div className="text-xs text-gray-500 dark:text-gray-400">AST</div>
                          </div>
                          <div>
                            <div className="font-medium text-gray-900 dark:text-white">{player.steals}</div>
                            <div className="text-xs text-gray-500 dark:text-gray-400">STL</div>
                          </div>
                          <div>
                            <div className="font-medium text-gray-900 dark:text-white">{player.blocks}</div>
                            <div className="text-xs text-gray-500 dark:text-gray-400">BLK</div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Away Team Players */}
                <div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">{gameState.awayTeam}</h3>
                  <div className="space-y-3">
                    {playerStats.filter(p => p.team === 'away').map((player) => (
                      <div key={player.id} className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center space-x-3">
                            <div className="w-8 h-8 bg-yellow-600 text-white rounded-full flex items-center justify-center text-sm font-bold">
                              {player.jersey}
                            </div>
                            <div>
                              <p className="font-medium text-gray-900 dark:text-white">{player.name}</p>
                              <p className="text-sm text-gray-500 dark:text-gray-400">{player.position}</p>
                            </div>
                          </div>
                          <div className="text-right">
                            <p className="text-lg font-bold text-gray-900 dark:text-white">{player.points}</p>
                            <p className="text-xs text-gray-500 dark:text-gray-400">PTS</p>
                          </div>
                        </div>
                        <div className="grid grid-cols-4 gap-2 text-center text-sm">
                          <div>
                            <div className="font-medium text-gray-900 dark:text-white">{player.rebounds}</div>
                            <div className="text-xs text-gray-500 dark:text-gray-400">REB</div>
                          </div>
                          <div>
                            <div className="font-medium text-gray-900 dark:text-white">{player.assists}</div>
                            <div className="text-xs text-gray-500 dark:text-gray-400">AST</div>
                          </div>
                          <div>
                            <div className="font-medium text-gray-900 dark:text-white">{player.steals}</div>
                            <div className="text-xs text-gray-500 dark:text-gray-400">STL</div>
                          </div>
                          <div>
                            <div className="font-medium text-gray-900 dark:text-white">{player.blocks}</div>
                            <div className="text-xs text-gray-500 dark:text-gray-400">BLK</div>
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
      </div>
    </div>
  )
}
