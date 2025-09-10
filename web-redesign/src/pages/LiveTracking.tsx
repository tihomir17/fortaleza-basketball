import { useState, useEffect } from 'react'
import {
  PlayIcon,
  PauseIcon,
  StopIcon,
  ClockIcon,
  ChartBarIcon
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
      description: 'Jump shot from 15 feet'
    },
    {
      id: 2,
      time: '11:30',
      quarter: 1,
      team: 'away',
      player: 'Mike Johnson',
      action: '3PT_MADE',
      points: 3,
      description: 'Three-pointer from corner'
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
      description: `${points}-point shot`
    }
    setPlays(prev => [newPlay, ...prev])
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
    <div>
      {/* Page Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Live Game Tracking</h1>
        <p className="mt-2 text-gray-600">Track your game in real-time with live statistics.</p>
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

      {/* Live Plays */}
      <div className="bg-white rounded-lg shadow">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">Live Plays</h3>
        </div>
        <div className="p-6">
          {plays.length > 0 ? (
            <div className="space-y-4">
              {plays.map((play) => (
                <div key={play.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                  <div className="flex items-center space-x-4">
                    <div className={`w-3 h-3 rounded-full ${
                      play.team === 'home' ? 'bg-fortaleza-blue' : 'bg-fortaleza-gold'
                    }`}></div>
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        Q{play.quarter} {play.time} - {play.player}
                      </p>
                      <p className="text-xs text-gray-500">{play.description}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-semibold text-gray-900">
                      +{play.points} pts
                    </p>
                    <p className="text-xs text-gray-500">
                      {play.team === 'home' ? gameState.homeTeam : gameState.awayTeam}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8">
              <ChartBarIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">No plays yet</h3>
              <p className="text-gray-500">Start the game and add plays to see them here.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
