import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import {
  PlayIcon,
  StopIcon,
  ClockIcon,
  ChartBarIcon,
  UserGroupIcon,
  TrophyIcon,
  PlusIcon,
  ChevronDownIcon
} from '@heroicons/react/24/outline'
import { GameTrackingLoading } from '../components/ui/LoadingStates'
import { useGameTrackingStore } from '../store/gameTrackingStore'
import { useAuthStore } from '../store/authStore'
import { useTeamsStore } from '../store/teamsStore'
import { PossessionForm } from '../components/gameTracking/PossessionForm'
import { LiveStats } from '../components/gameTracking/LiveStats'
import { GameSetup } from '../components/gameTracking/GameSetup'
import { PossessionHistory } from '../components/gameTracking/PossessionHistory'

interface GameState {
  isTracking: boolean
  currentQuarter: number
  timeRemaining: string
  homeScore: number
  awayScore: number
  homeTeam: string
  awayTeam: string
  possession: 'home' | 'away'
  gameId?: number
}


// Interfaces removed - now using real data from LiveStats component

export function GameTracking() {
  const { gameId } = useParams<{ gameId?: string }>()
  const navigate = useNavigate()
  
  // Store hooks
  const { user } = useAuthStore()
  const { teams } = useTeamsStore()
  const {
    currentGame,
    possessions,
    availableGames,
    isLoadingPossessions,
    isLoadingGames,
    possessionsError,
    gamesError,
    hasMorePossessions,
    setSelectedGameId,
    fetchAvailableGames,
    selectGame,
    loadMorePossessions,
    refreshPossessions,
    clearGameData
  } = useGameTrackingStore()

  const [gameState, setGameState] = useState<GameState>({
    isTracking: false,
    currentQuarter: 1,
    timeRemaining: '12:00',
    homeScore: 0,
    awayScore: 0,
    homeTeam: 'Fortaleza',
    awayTeam: 'Thunder',
    possession: 'home'
  })
  const [isLoading, setIsLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<'possessions' | 'stats' | 'players' | 'add-possession'>('possessions')
  const [showAddPossessionForm, setShowAddPossessionForm] = useState(false)
  const [showGameSelector, setShowGameSelector] = useState(false)
  const [showGameSetup, setShowGameSetup] = useState(false)

  // Mock data removed - now using real data from LiveStats component

  // Initialize component based on URL parameters
  useEffect(() => {
    const initializeGameTracking = async () => {
      setIsLoading(true)
      
      try {
        // Scenario 1: Game ID provided in URL (from calendar click)
        if (gameId) {
          const gameIdNum = parseInt(gameId)
          
          if (isNaN(gameIdNum)) {
            console.error('Invalid game ID:', gameId)
            return
          }
          
          await selectGame(gameIdNum)
          setSelectedGameId(gameIdNum)
        } 
        // Scenario 2: No game ID - show game selector for coach
        else if (user?.role === 'COACH' && teams.length > 0) {
          // Get the first team the coach is associated with
          const coachTeam = teams[0]
          await fetchAvailableGames(coachTeam.id)
          setShowGameSelector(true)
        }
        // Scenario 3: No game ID and not a coach - redirect or show error
        else {
          console.warn('No game selected and user is not a coach')
        }
      } catch (error) {
        console.error('Failed to initialize game tracking:', error)
        // If we have a gameId but selection failed, show error
        if (gameId) {
          console.error('Failed to load game with ID:', gameId)
        }
      } finally {
        setIsLoading(false)
      }
    }

    initializeGameTracking()
    
    // Cleanup on unmount
    return () => {
      clearGameData()
    }
  }, [gameId, user?.role, teams, selectGame, fetchAvailableGames, clearGameData])

  // Update game state when current game changes
  useEffect(() => {
    if (currentGame) {
      setGameState(prev => ({
        ...prev,
        homeTeam: currentGame.home_team.name,
        awayTeam: currentGame.away_team.name,
        homeScore: currentGame.home_team_score || 0,
        awayScore: currentGame.away_team_score || 0,
        currentQuarter: currentGame.quarter || 1
      }))
      
      // Show game setup if no possessions exist yet
      if (possessions.length === 0) {
        setShowGameSetup(true)
      }
    }
  }, [currentGame, possessions.length])


  const [, setTime] = useState(0)

  useEffect(() => {
    let interval: ReturnType<typeof setInterval>
    if (gameState.isTracking) {
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
  }, [gameState.isTracking])

  // Handle game selection
  const handleGameSelect = async (selectedGameId: number) => {
    setShowGameSelector(false)
    await selectGame(selectedGameId)
    // Update URL to include game ID
    navigate(`/game-tracking/${selectedGameId}`, { replace: true })
  }

  if (isLoading) {
    return <GameTrackingLoading />
  }

  // Show game setup if needed
  if (showGameSetup && currentGame) {
    return (
      <GameSetup
        gameId={currentGame.id}
        onSetupComplete={() => setShowGameSetup(false)}
      />
    )
  }

  // Show game selector if no game is selected and user is a coach
  if (showGameSelector && !currentGame) {
    return (
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 animate-fade-in">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2 flex items-center">
            <ChartBarIcon className="h-8 w-8 mr-3 text-blue-600" />
            Select Game to Track
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            Choose a game to start tracking possessions and statistics
          </p>
        </div>

        {isLoadingGames ? (
          <div className="bg-white rounded-lg shadow p-6">
            <div className="animate-pulse">
              <div className="h-4 bg-gray-200 rounded w-1/4 mb-4"></div>
              <div className="space-y-3">
                {Array.from({ length: 5 }).map((_, i) => (
                  <div key={i} className="h-16 bg-gray-200 rounded"></div>
                ))}
              </div>
            </div>
          </div>
        ) : gamesError ? (
          <div className="bg-red-50 border border-red-200 rounded-lg p-6">
            <p className="text-red-600">Error loading games: {gamesError}</p>
          </div>
        ) : availableGames.length === 0 ? (
          <div className="bg-gray-50 border border-gray-200 rounded-lg p-6 text-center">
            <p className="text-gray-600">No games available for your teams.</p>
          </div>
        ) : (
          <div className="bg-white rounded-lg shadow">
            <div className="p-6 border-b border-gray-200">
              <h2 className="text-lg font-semibold text-gray-900">Available Games</h2>
            </div>
            <div className="divide-y divide-gray-200">
              {availableGames.map((game) => (
                <div
                  key={game.id}
                  onClick={() => handleGameSelect(game.id)}
                  className="p-6 hover:bg-gray-50 cursor-pointer transition-colors"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex-1">
                      <div className="flex items-center space-x-4">
                        <div className="text-center">
                          <div className="text-sm font-medium text-gray-900">{game.home_team.name}</div>
                          <div className="text-2xl font-bold text-blue-600">{game.home_team_score || 0}</div>
                        </div>
                        <div className="text-gray-400">vs</div>
                        <div className="text-center">
                          <div className="text-sm font-medium text-gray-900">{game.away_team.name}</div>
                          <div className="text-2xl font-bold text-yellow-600">{game.away_team_score || 0}</div>
                        </div>
                      </div>
                      <div className="mt-2 text-sm text-gray-500">
                        {game.competition.name} • {new Date(game.game_date).toLocaleDateString()}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm text-gray-500">Q{game.quarter || 1}</div>
                      <div className="text-xs text-gray-400">
                        {new Date(game.game_date).toLocaleTimeString()}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    )
  }

  // Show error if no game is selected and user is not a coach
  if (!currentGame && !showGameSelector && !isLoading) {
    return (
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 animate-fade-in">
        <div className="text-center py-12">
          <ChartBarIcon className="h-16 w-16 text-gray-400 mx-auto mb-4" />
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">No Game Selected</h1>
          <p className="text-gray-600 dark:text-gray-400 mb-6">
            Please select a game from the calendar or contact your coach to access game tracking.
          </p>
          
          {/* Debug information */}
          <div className="mb-4 p-4 bg-yellow-50 border border-yellow-200 rounded-lg text-left">
            <h3 className="font-semibold text-yellow-800 mb-2">Debug Information:</h3>
            <p className="text-yellow-800 text-sm">Game ID from URL: {gameId || 'None'}</p>
            <p className="text-yellow-800 text-sm">Current Game: {currentGame ? 'Loaded' : 'Not loaded'}</p>
            <p className="text-yellow-800 text-sm">Show Game Selector: {showGameSelector ? 'Yes' : 'No'}</p>
            <p className="text-yellow-800 text-sm">Is Loading: {isLoading ? 'Yes' : 'No'}</p>
            <p className="text-yellow-800 text-sm">User Role: {user?.role || 'Unknown'}</p>
            <p className="text-yellow-800 text-sm">Teams Count: {teams.length}</p>
            <p className="text-yellow-800 text-sm">Possessions Error: {possessionsError || 'None'}</p>
            <p className="text-yellow-800 text-sm">Auth Token: {localStorage.getItem('auth_token') ? 'Present' : 'Missing'}</p>
            <p className="text-yellow-800 text-sm">User ID: {user?.id || 'Unknown'}</p>
          </div>
          
          <button
            onClick={() => navigate('/calendar')}
            className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
          >
            Go to Calendar
          </button>
        </div>
      </div>
    )
  }

  const startTracking = () => {
    setGameState(prev => ({ ...prev, isTracking: true }))
  }

  const stopTracking = () => {
    setGameState(prev => ({ 
      ...prev, 
      isTracking: false,
      timeRemaining: '12:00'
    }))
    setTime(0)
  }

  const addPossession = async (possessionData: any) => {
    if (!currentGame) return

    const newPossessionData = {
      game_id: currentGame.id,
      team_id: possessionData.team === 'home' ? currentGame.home_team.id : currentGame.away_team.id,
      quarter: gameState.currentQuarter,
      start_time_in_game: gameState.timeRemaining,
      duration_seconds: possessionData.duration_seconds || 0,
      outcome: possessionData.outcome || 'MADE_2PTS',
      points_scored: possessionData.points || 0,
      offensive_set: possessionData.offensive_set,
      defensive_set: possessionData.defensive_set
    }

    // Use the store's createPossession method
    const newPossession = await useGameTrackingStore.getState().createPossession(newPossessionData)

    if (newPossession) {
      // Update scores if points were scored
      if (newPossession.points_scored > 0) {
        setGameState(prev => ({
          ...prev,
          homeScore: possessionData.team === 'home' ? prev.homeScore + newPossession.points_scored : prev.homeScore,
          awayScore: possessionData.team === 'away' ? prev.awayScore + newPossession.points_scored : prev.awayScore
        }))
      }
    }
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
              <ChartBarIcon className="h-8 w-8 mr-3 text-blue-600" />
              Game Tracking
            </h1>
            <p className="text-gray-600 dark:text-gray-400">
              Track possessions and statistics throughout your game with detailed analytics
            </p>
          </div>
          
          <div className="flex items-center space-x-4 mt-4 sm:mt-0">
            {/* Tracking Status */}
            <div className="flex items-center space-x-2">
              <div className={`w-2 h-2 rounded-full ${gameState.isTracking ? 'bg-green-500' : 'bg-gray-400'}`} />
              <span className="text-sm text-gray-600 dark:text-gray-400">
                {gameState.isTracking ? 'Tracking Active' : 'Not Tracking'}
              </span>
            </div>
            
            {/* Add Possession Button */}
            <button
              onClick={() => setShowAddPossessionForm(true)}
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center"
            >
              <PlusIcon className="w-4 h-4 mr-2" />
              Add Possession
            </button>
          </div>
        </div>
      </div>

      {/* Game Controls */}
      <div className="bg-white rounded-lg shadow p-6 mb-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-gray-900">Game Controls</h2>
          <div className="flex items-center space-x-3">
            {!gameState.isTracking ? (
              <button
                onClick={startTracking}
                className="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors flex items-center"
              >
                <PlayIcon className="w-5 h-5 mr-2" />
                Start Tracking
              </button>
            ) : (
              <button
                onClick={stopTracking}
                className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors flex items-center"
              >
                <StopIcon className="w-5 h-5 mr-2" />
                Stop Tracking
              </button>
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
                onClick={() => addPossession({ team: 'home', outcome: 'MADE_FTS', points: 1, player: 'Player', description: 'Free throw made' })}
                className="bg-blue-100 text-blue-800 px-3 py-1 rounded-lg hover:bg-blue-200 transition-colors"
              >
                +1 FT
              </button>
              <button
                onClick={() => addPossession({ team: 'home', outcome: 'MADE_2PTS', points: 2, player: 'Player', description: '2-point shot made' })}
                className="bg-green-100 text-green-800 px-3 py-1 rounded-lg hover:bg-green-200 transition-colors"
              >
                +2 PT
              </button>
              <button
                onClick={() => addPossession({ team: 'home', outcome: 'MADE_3PTS', points: 3, player: 'Player', description: '3-point shot made' })}
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
                onClick={() => addPossession({ team: 'away', outcome: 'MADE_FTS', points: 1, player: 'Player', description: 'Free throw made' })}
                className="bg-blue-100 text-blue-800 px-3 py-1 rounded-lg hover:bg-blue-200 transition-colors"
              >
                +1 FT
              </button>
              <button
                onClick={() => addPossession({ team: 'away', outcome: 'MADE_2PTS', points: 2, player: 'Player', description: '2-point shot made' })}
                className="bg-green-100 text-green-800 px-3 py-1 rounded-lg hover:bg-green-200 transition-colors"
              >
                +2 PT
              </button>
              <button
                onClick={() => addPossession({ team: 'away', outcome: 'MADE_3PTS', points: 3, player: 'Player', description: '3-point shot made' })}
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
              onClick={() => setActiveTab('possessions')}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'possessions'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <ChartBarIcon className="h-4 w-4 inline mr-2" />
              Possessions ({possessions.length})
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
            <button
              onClick={() => setActiveTab('add-possession')}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                activeTab === 'add-possession'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <PlusIcon className="h-4 w-4 inline mr-2" />
              Add Possession
            </button>
          </nav>
        </div>

        <div className="p-6">
          {/* Possessions Tab */}
          {activeTab === 'possessions' && currentGame && (
            <div>
              {possessionsError ? (
                <div className="bg-red-50 border border-red-200 rounded-lg p-6">
                  <p className="text-red-600">Error loading possessions: {possessionsError}</p>
                  <button
                    onClick={refreshPossessions}
                    className="mt-2 bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors"
                  >
                    Retry
                  </button>
                </div>
              ) : possessions.length > 0 ? (
                <div>
                  <PossessionHistory
                    possessions={possessions}
                    homeTeamId={currentGame.home_team.id}
                    awayTeamId={currentGame.away_team.id}
                    homeTeamName={currentGame.home_team.name}
                    awayTeamName={currentGame.away_team.name}
                  />
                  
                  {/* Load More Button */}
                  {hasMorePossessions && (
                    <div className="mt-6 text-center">
                      <button
                        onClick={loadMorePossessions}
                        disabled={isLoadingPossessions}
                        className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center mx-auto"
                      >
                        {isLoadingPossessions ? (
                          <>
                            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                            Loading...
                          </>
                        ) : (
                          <>
                            <ChevronDownIcon className="w-4 h-4 mr-2" />
                            Load More Possessions
                          </>
                        )}
                      </button>
                    </div>
                  )}
                </div>
              ) : isLoadingPossessions ? (
                <div className="text-center py-8">
                  <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
                  <p className="text-gray-500 dark:text-gray-400">Loading possessions...</p>
                </div>
              ) : (
                <div className="text-center py-8">
                  <ChartBarIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No possessions yet</h3>
                  <p className="text-gray-500 dark:text-gray-400">Start tracking and add possessions to see them here.</p>
                </div>
              )}
            </div>
          )}

          {/* Team Stats Tab */}
          {activeTab === 'stats' && currentGame && (
            <LiveStats
              possessions={possessions}
              homeTeamId={currentGame.home_team.id}
              awayTeamId={currentGame.away_team.id}
              homeTeamName={currentGame.home_team.name}
              awayTeamName={currentGame.away_team.name}
            />
          )}

          {/* Player Stats Tab */}
          {activeTab === 'players' && currentGame && (
            <LiveStats
              possessions={possessions}
              homeTeamId={currentGame.home_team.id}
              awayTeamId={currentGame.away_team.id}
              homeTeamName={currentGame.home_team.name}
              awayTeamName={currentGame.away_team.name}
            />
          )}

          {/* Add Possession Tab */}
          {activeTab === 'add-possession' && (
            <div>
              <div className="text-center py-8">
                <PlusIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">Add New Possession</h3>
                <p className="text-gray-500 dark:text-gray-400 mb-6">Create a detailed possession entry with all relevant information.</p>
                <button
                  onClick={() => setShowAddPossessionForm(true)}
                  className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors flex items-center mx-auto"
                >
                  <PlusIcon className="w-5 h-5 mr-2" />
                  Add Possession
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Possession Form Modal */}
      {currentGame && (
        <PossessionForm
          isOpen={showAddPossessionForm}
          onClose={() => setShowAddPossessionForm(false)}
          gameId={currentGame.id}
          currentQuarter={gameState.currentQuarter}
          currentTime={gameState.timeRemaining}
        />
      )}
    </div>
  )
}
