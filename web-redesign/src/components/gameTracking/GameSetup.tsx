import { useState, useEffect, useCallback, useMemo } from 'react'
import { useForm } from 'react-hook-form'
import {
  CheckCircleIcon,
  ExclamationTriangleIcon,
  UserGroupIcon,
  TrophyIcon,
  PlayIcon,
  ClockIcon
} from '@heroicons/react/24/outline'
import { useGameTrackingStore } from '../../store/gameTrackingStore'
import { useTeamsStore } from '../../store/teamsStore'

interface GameSetupProps {
  gameId: number
  onSetupComplete: () => void
}

interface SetupFormData {
  homeTeamId: number
  awayTeamId: number
  gameDate: string
  gameTime: string
  location: string
  competition: string
  notes: string
  gameRoster: {
    home: number[]
    away: number[]
  }
  startingFive: {
    home: number[]
    away: number[]
  }
}

interface SetupStep {
  id: string
  title: string
  description: string
  completed: boolean
  required: boolean
}

export function GameSetup({ gameId, onSetupComplete }: GameSetupProps) {
  const { teams, teamMembers, fetchTeamMembers, currentTeam } = useTeamsStore()
  const { selectGame, currentGame } = useGameTrackingStore()
  const [currentStep, setCurrentStep] = useState(0)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)
  const [isGameCompleted, setIsGameCompleted] = useState(false)

  const {
    register,
    handleSubmit,
    watch,
    setValue,
    getValues,
    formState: { errors }
  } = useForm<SetupFormData>({
    defaultValues: {
      homeTeamId: 0,
      awayTeamId: 0,
      gameDate: new Date().toISOString().split('T')[0],
      gameTime: '19:00',
      location: '',
      competition: '',
      notes: '',
      gameRoster: {
        home: [],
        away: []
      },
      startingFive: {
        home: [],
        away: []
      }
    }
  })

  // Check if game is completed (has final scores)
  useEffect(() => {
    if (currentGame) {
      const completed = currentGame.home_team_score !== undefined && currentGame.away_team_score !== undefined
      setIsGameCompleted(completed)
      console.log('🎮 Game completion status:', { completed, scores: { home: currentGame.home_team_score, away: currentGame.away_team_score } })
    }
  }, [currentGame])

  // Pre-populate form with current game data when available
  useEffect(() => {
    if (currentGame) {
      console.log('🎮 Pre-populating form with game data:', currentGame)
      setValue('homeTeamId', currentGame.home_team.id)
      setValue('awayTeamId', currentGame.away_team.id)
      setValue('gameDate', new Date(currentGame.game_date).toISOString().split('T')[0])
      setValue('gameTime', new Date(currentGame.game_date).toTimeString().slice(0, 5))
      setValue('competition', currentGame.competition?.name || '')
      
      // For completed games, try to auto-populate rosters
      if (isGameCompleted) {
        console.log('🎮 Game is completed, attempting auto-population')
        setTimeout(() => {
          autoPopulateForCompletedGame()
        }, 500)
      }
    }
  }, [currentGame, isGameCompleted, setValue])

  // Auto-populate a specific team
  const autoPopulateTeam = useCallback((teamType: 'home' | 'away', teamId: number) => {
    console.log('🎮 Auto-populating team:', { teamType, teamId })

    // Get players from the current game data first, then fall back to team members
    let teamPlayers: any[] = []
    
    if (teamType === 'home' && currentGame?.home_team?.players) {
      teamPlayers = currentGame.home_team.players.filter((player: any) => player.role === 'PLAYER')
    } else if (teamType === 'away' && currentGame?.away_team?.players) {
      teamPlayers = currentGame.away_team.players.filter((player: any) => player.role === 'PLAYER')
    } else {
      // Fallback to team members from store
      teamPlayers = teamMembers.filter((member: any) => 
        member.role === 'PLAYER' && member.team === teamId
      )
    }

    console.log('🎮 Team players found:', { teamType, count: teamPlayers.length, players: teamPlayers })

    if (teamPlayers.length === 0) {
      console.log('🎮 No players found for team:', teamType)
      return
    }

    // Try to load saved default roster from localStorage
    const savedGameRoster = localStorage.getItem(`defaultGameRoster_${teamId}`)
    const savedStartingFive = localStorage.getItem(`defaultStartingFive_${teamId}`)
    
    let gameRoster: number[] = []
    let startingFive: number[] = []
    
    if (savedGameRoster && savedStartingFive) {
      // Use saved default roster
      const defaultGameRoster = JSON.parse(savedGameRoster)
      const defaultStartingFive = JSON.parse(savedStartingFive)
      
      // Filter to only include players that are available in the current game
      gameRoster = defaultGameRoster.filter((playerId: number) => 
        teamPlayers.some(player => player.id === playerId)
      )
      startingFive = defaultStartingFive.filter((playerId: number) => 
        teamPlayers.some(player => player.id === playerId) && gameRoster.includes(playerId)
      )
      
      console.log('🎮 Using saved default roster:', { 
        teamType, 
        savedGameRoster: defaultGameRoster.length, 
        savedStartingFive: defaultStartingFive.length,
        filteredGameRoster: gameRoster.length,
        filteredStartingFive: startingFive.length
      })
    } else {
      // Fallback to auto-selecting first 12 players for game roster
      gameRoster = teamPlayers.slice(0, 12).map(player => player.id)
      startingFive = teamPlayers.slice(0, 5).map(player => player.id)
      
      console.log('🎮 Using fallback auto-selection:', { teamType, gameRoster: gameRoster.length, startingFive: startingFive.length })
    }

    setValue(`gameRoster.${teamType}`, gameRoster)
    setValue(`startingFive.${teamType}`, startingFive)

    console.log('🎮 Auto-populated:', { teamType, gameRoster: gameRoster.length, startingFive: startingFive.length })

    // Force form re-render
    setTimeout(() => {
      const currentValues = getValues()
      console.log('🎮 Form values after auto-population:', {
        teamType,
        gameRoster: currentValues.gameRoster[teamType].length,
        startingFive: currentValues.startingFive[teamType].length
      })
    }, 100)
  }, [currentGame, teamMembers, setValue, getValues])

  // Auto-populate for completed games
  const autoPopulateForCompletedGame = useCallback(() => {
    if (!currentGame || !currentTeam) return

    console.log('🎮 Auto-populating for completed game:', {
      currentTeamId: currentTeam.id,
      homeTeamId: currentGame.home_team.id,
      awayTeamId: currentGame.away_team.id
    })

    // Auto-populate home team if it's the user's team
    if (currentGame.home_team.id === currentTeam.id) {
      autoPopulateTeam('home', currentGame.home_team.id)
    }

    // Auto-populate away team if it's the user's team
    if (currentGame.away_team.id === currentTeam.id) {
      autoPopulateTeam('away', currentGame.away_team.id)
    }

    // Force step completion update after auto-population
    setTimeout(() => {
      const currentValues = getValues()
      console.log('🎮 Forcing step completion update after auto-population:', {
        gameRoster: {
          home: currentValues.gameRoster.home.length,
          away: currentValues.gameRoster.away.length
        },
        startingFive: {
          home: currentValues.startingFive.home.length,
          away: currentValues.startingFive.away.length
        }
      })
      
      // Trigger a re-render by updating the setup steps
      setSetupSteps(prev => [...prev])
    }, 200)
  }, [currentGame, currentTeam, autoPopulateTeam, getValues])

  // Create a combined list of teams that includes both user's teams and game participants
  const availableTeams = useMemo(() => {
    const userTeams = teams || []
    const gameTeams = currentGame ? [currentGame.home_team, currentGame.away_team] : []
    
    // Combine and deduplicate teams
    const allTeams = [...userTeams, ...gameTeams]
    const uniqueTeams = allTeams.filter((team, index, self) => 
      index === self.findIndex(t => t.id === team.id)
    )
    
    return uniqueTeams
  }, [teams, currentGame])

  // Get team players for roster selection
  const homeTeamPlayers = useMemo(() => {
    if (currentGame?.home_team?.players) {
      return currentGame.home_team.players.filter((player: any) => player.role === 'PLAYER')
    }
    return teamMembers.filter((member: any) => 
      member.role === 'PLAYER' && member.team === watch('homeTeamId')
    )
  }, [currentGame, teamMembers, watch('homeTeamId')])

  const awayTeamPlayers = useMemo(() => {
    if (currentGame?.away_team?.players) {
      return currentGame.away_team.players.filter((player: any) => player.role === 'PLAYER')
    }
    return teamMembers.filter((member: any) => 
      member.role === 'PLAYER' && member.team === watch('awayTeamId')
    )
  }, [currentGame, teamMembers, watch('awayTeamId')])

  const [setupSteps, setSetupSteps] = useState<SetupStep[]>([
    {
      id: 'basic-info',
      title: 'Basic Game Information',
      description: 'Set up teams, date, time, and location',
      completed: false,
      required: true
    },
    {
      id: 'game-roster',
      title: 'Game Roster',
      description: 'Select 12 players for each team from the full roster',
      completed: false,
      required: true
    },
    {
      id: 'starting-five',
      title: 'Starting Lineups',
      description: 'Select the starting five players from the game roster',
      completed: false,
      required: true
    },
    {
      id: 'review',
      title: 'Review & Start',
      description: 'Review all settings and begin game tracking',
      completed: false,
      required: true
    }
  ])

  // Load team members when teams are selected
  useEffect(() => {
    const loadTeamMembers = async () => {
      const homeTeamId = watch('homeTeamId')
      const awayTeamId = watch('awayTeamId')
      
      if (homeTeamId && homeTeamId > 0) {
        await fetchTeamMembers(homeTeamId)
      }
      if (awayTeamId && awayTeamId > 0) {
        await fetchTeamMembers(awayTeamId)
      }
    }
    
    loadTeamMembers()
  }, [watch('homeTeamId'), watch('awayTeamId'), fetchTeamMembers])

  // Watch form values for step completion
  const watchedHomeTeamId = watch('homeTeamId')
  const watchedAwayTeamId = watch('awayTeamId')
  const watchedHomeGameRoster = watch('gameRoster.home')
  const watchedAwayGameRoster = watch('gameRoster.away')
  const watchedHomeStartingFive = watch('startingFive.home')
  const watchedAwayStartingFive = watch('startingFive.away')

  // Update step completion status
  useEffect(() => {
    const homeTeamSelected = watchedHomeTeamId > 0
    const awayTeamSelected = watchedAwayTeamId > 0
    const basicInfoComplete = homeTeamSelected && awayTeamSelected

    const gameRosterComplete = watchedHomeGameRoster.length === 12 && watchedAwayGameRoster.length === 12
    const startingFiveComplete = watchedHomeStartingFive.length === 5 && watchedAwayStartingFive.length === 5

    console.log('🎮 Step completion check:', {
      basicInfoComplete,
      gameRosterComplete,
      startingFiveComplete,
      homeGameRoster: watchedHomeGameRoster.length,
      awayGameRoster: watchedAwayGameRoster.length,
      homeStartingFive: watchedHomeStartingFive.length,
      awayStartingFive: watchedAwayStartingFive.length
    })

    setSetupSteps((prev: SetupStep[]) => prev.map((step: SetupStep) => {
      if (step.id === 'basic-info') {
        return { ...step, completed: basicInfoComplete }
      }
      if (step.id === 'game-roster') {
        return { ...step, completed: gameRosterComplete }
      }
      if (step.id === 'starting-five') {
        return { ...step, completed: startingFiveComplete }
      }
      if (step.id === 'review') {
        // Review step is complete when all other required steps are complete
        return { ...step, completed: basicInfoComplete && gameRosterComplete && startingFiveComplete }
      }
      return step
    }))
  }, [watchedHomeTeamId, watchedAwayTeamId, watchedHomeGameRoster, watchedAwayGameRoster, watchedHomeStartingFive, watchedAwayStartingFive])

  const handleGameRosterChange = (team: 'home' | 'away', playerId: number, checked: boolean) => {
    const currentGameRoster = getValues('gameRoster')
    const teamGameRoster = currentGameRoster[team]

    if (checked) {
      if (teamGameRoster.length < 12) {
        const newRoster = [...teamGameRoster, playerId]
        setValue(`gameRoster.${team}`, newRoster)
      }
    } else {
      const newGameRoster = teamGameRoster.filter(id => id !== playerId)
      setValue(`gameRoster.${team}`, newGameRoster)
      
      // Remove from starting five if they were selected
      const currentStartingFive = getValues('startingFive')
      const teamStartingFive = currentStartingFive[team]
      if (teamStartingFive.includes(playerId)) {
        setValue(`startingFive.${team}`, teamStartingFive.filter(id => id !== playerId))
      }
    }
  }

  const handleStartingFiveChange = (team: 'home' | 'away', playerId: number, checked: boolean) => {
    const currentStartingFive = getValues('startingFive')
    const teamStartingFive = currentStartingFive[team]
    const currentGameRoster = getValues('gameRoster')
    const teamGameRoster = currentGameRoster[team]

    // Only allow selection if player is in game roster
    if (!teamGameRoster.includes(playerId)) {
      return
    }

    if (checked) {
      if (teamStartingFive.length < 5) {
        setValue(`startingFive.${team}`, [...teamStartingFive, playerId])
      }
    } else {
      setValue(`startingFive.${team}`, teamStartingFive.filter(id => id !== playerId))
    }
  }

  const onSubmit = async () => {
    setIsSubmitting(true)
    setSubmitError(null)

    try {
      // Here you would typically save the game setup to the backend
      // For now, we'll just complete the setup and start tracking
      
      // Load the game data
      await selectGame(gameId)
      
      // Complete setup
      onSetupComplete()
    } catch (error: any) {
      setSubmitError(error.message || 'Failed to complete game setup')
    } finally {
      setIsSubmitting(false)
    }
  }

  const nextStep = () => {
    if (currentStep < setupSteps.length - 1) {
      setCurrentStep(currentStep + 1)
    }
  }

  const prevStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1)
    }
  }

  const canProceedToNext = useMemo(() => {
    const currentStepData = setupSteps[currentStep]
    const canProceed = currentStepData.completed || !currentStepData.required
    
    console.log('🎮 canProceedToNext check:', {
      currentStep,
      stepId: currentStepData.id,
      completed: currentStepData.completed,
      required: currentStepData.required,
      canProceed,
      allSteps: setupSteps.map(step => ({ id: step.id, completed: step.completed }))
    })
    
    return canProceed
  }, [setupSteps, currentStep])

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2 flex items-center">
          <PlayIcon className="h-8 w-8 mr-3 text-blue-600" />
          Game Setup
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          {isGameCompleted ? (
            <span className="flex items-center">
              <ClockIcon className="h-5 w-5 mr-2 text-green-600" />
              This game is completed. Setting up for analysis and tracking.
            </span>
          ) : (
            'Configure your game settings before starting possession tracking'
          )}
        </p>
      </div>

      {/* Progress Steps */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          {setupSteps.map((step, index) => (
            <div key={step.id} className="flex items-center">
              <div className={`flex items-center justify-center w-10 h-10 rounded-full border-2 ${
                step.completed 
                  ? 'bg-green-600 border-green-600 text-white' 
                  : index === currentStep 
                    ? 'bg-blue-600 border-blue-600 text-white' 
                    : 'bg-gray-100 border-gray-300 text-gray-500'
              }`}>
                {step.completed ? (
                  <CheckCircleIcon className="h-6 w-6" />
                ) : (
                  <span className="text-sm font-semibold">{index + 1}</span>
                )}
              </div>
              <div className="ml-3">
                <p className={`text-sm font-medium ${
                  index === currentStep ? 'text-blue-600' : 'text-gray-500'
                }`}>
                  {step.title}
                </p>
                <p className="text-xs text-gray-400">{step.description}</p>
              </div>
              {index < setupSteps.length - 1 && (
                <div className={`flex-1 h-0.5 mx-4 ${
                  step.completed ? 'bg-green-600' : 'bg-gray-300'
                }`} />
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Error Message */}
      {submitError && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6 flex items-center">
          <ExclamationTriangleIcon className="h-5 w-5 text-red-600 mr-2" />
          <p className="text-red-800">{submitError}</p>
        </div>
      )}

      {/* Form Content */}
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
        {/* Step 1: Basic Game Information */}
        {currentStep === 0 && (
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
              <TrophyIcon className="h-5 w-5 mr-2" />
              Basic Game Information
            </h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Home Team</label>
                <select
                  {...register('homeTeamId', { required: 'Home team is required' })}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select home team</option>
                  {availableTeams.map(team => (
                    <option key={team.id} value={team.id}>{team.name}</option>
                  ))}
                </select>
                {errors.homeTeamId && <p className="text-red-600 text-sm mt-1">{errors.homeTeamId.message}</p>}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Away Team</label>
                <select
                  {...register('awayTeamId', { required: 'Away team is required' })}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select away team</option>
                  {availableTeams.map(team => (
                    <option key={team.id} value={team.id}>{team.name}</option>
                  ))}
                </select>
                {errors.awayTeamId && <p className="text-red-600 text-sm mt-1">{errors.awayTeamId.message}</p>}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Game Date</label>
                <input
                  type="date"
                  {...register('gameDate', { required: 'Game date is required' })}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                />
                {errors.gameDate && <p className="text-red-600 text-sm mt-1">{errors.gameDate.message}</p>}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Game Time</label>
                <input
                  type="time"
                  {...register('gameTime', { required: 'Game time is required' })}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                />
                {errors.gameTime && <p className="text-red-600 text-sm mt-1">{errors.gameTime.message}</p>}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Location</label>
                <input
                  type="text"
                  {...register('location')}
                  placeholder="Arena, gym, or venue name"
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Competition</label>
                <input
                  type="text"
                  {...register('competition')}
                  placeholder="League, tournament, or season"
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            </div>

            <div className="mt-4">
              <label className="block text-sm font-medium text-gray-700 mb-1">Notes</label>
              <textarea
                {...register('notes')}
                rows={3}
                placeholder="Additional notes about the game..."
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>
        )}

        {/* Step 2: Starting Lineups */}
        {currentStep === 1 && (
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
              <UserGroupIcon className="h-5 w-5 mr-2" />
              Game Roster Selection
            </h2>
            <p className="text-gray-600 mb-6">
              Select 12 players for each team from the full roster. These players will be available for the game.
            </p>
            
            {/* Auto-population notification for completed games */}
            {isGameCompleted && currentTeam && (watchedHomeTeamId === currentTeam.id || watchedAwayTeamId === currentTeam.id) && (
              <div className="bg-green-50 border border-green-200 rounded-md p-4 mb-6">
                <div className="flex">
                  <div className="flex-shrink-0">
                    <CheckCircleIcon className="h-5 w-5 text-green-400" />
                  </div>
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-green-800">
                      Auto-populated for {currentTeam.name}
                    </h3>
                    <div className="mt-2 text-sm text-green-700">
                      <p>Your team's default roster has been automatically selected for this completed game. You can modify the selections below if needed.</p>
                    </div>
                  </div>
                </div>
              </div>
            )}
            
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Home Team Game Roster */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-3">
                  Home Team Game Roster ({watch('gameRoster.home').length}/12)
                </h3>
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {homeTeamPlayers.map((player: any) => (
                    <label key={player.id} className="flex items-center p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={watch('gameRoster.home').includes(player.id)}
                        onChange={(e) => handleGameRosterChange('home', player.id, e.target.checked)}
                        className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        disabled={!watch('gameRoster.home').includes(player.id) && watch('gameRoster.home').length >= 12}
                      />
                      <div className="ml-3 flex-1">
                        <div className="flex items-center justify-between">
                          <span className="text-sm font-medium text-gray-900">
                            #{player.jersey_number} {player.first_name} {player.last_name}
                          </span>
                          <span className="text-xs text-gray-500">{player.position}</span>
                        </div>
                      </div>
                    </label>
                  ))}
                </div>
              </div>

              {/* Away Team Game Roster */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-3">
                  Away Team Game Roster ({watch('gameRoster.away').length}/12)
                </h3>
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {awayTeamPlayers.map((player: any) => (
                    <label key={player.id} className="flex items-center p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={watch('gameRoster.away').includes(player.id)}
                        onChange={(e) => handleGameRosterChange('away', player.id, e.target.checked)}
                        className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        disabled={!watch('gameRoster.away').includes(player.id) && watch('gameRoster.away').length >= 12}
                      />
                      <div className="ml-3 flex-1">
                        <div className="flex items-center justify-between">
                          <span className="text-sm font-medium text-gray-900">
                            #{player.jersey_number} {player.first_name} {player.last_name}
                          </span>
                          <span className="text-xs text-gray-500">{player.position}</span>
                        </div>
                      </div>
                    </label>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {currentStep === 2 && (
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
              <UserGroupIcon className="h-5 w-5 mr-2" />
              Starting Lineups
            </h2>
            <p className="text-gray-600 mb-6">
              Select the starting five players for each team from the game roster.
            </p>
            
            {/* Auto-population notification for completed games */}
            {isGameCompleted && currentTeam && (watchedHomeTeamId === currentTeam.id || watchedAwayTeamId === currentTeam.id) && (
              <div className="bg-green-50 border border-green-200 rounded-md p-4 mb-6">
                <div className="flex">
                  <div className="flex-shrink-0">
                    <CheckCircleIcon className="h-5 w-5 text-green-400" />
                  </div>
                  <div className="ml-3">
                    <h3 className="text-sm font-medium text-green-800">
                      Starting lineup auto-selected
                    </h3>
                    <div className="mt-2 text-sm text-green-700">
                      <p>Your team's default starting five has been automatically selected for this completed game. You can modify the selections below if needed.</p>
                    </div>
                  </div>
                </div>
              </div>
            )}
            
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Home Team Starting Five */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-3">
                  Home Team Starting Five ({watch('startingFive.home').length}/5)
                </h3>
                <div className="space-y-2">
                  {homeTeamPlayers
                    .filter((player: any) => watch('gameRoster.home').includes(player.id))
                    .map((player: any) => (
                    <label key={player.id} className="flex items-center p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={watch('startingFive.home').includes(player.id)}
                        onChange={(e) => handleStartingFiveChange('home', player.id, e.target.checked)}
                        className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        disabled={!watch('startingFive.home').includes(player.id) && watch('startingFive.home').length >= 5}
                      />
                      <div className="ml-3 flex-1">
                        <div className="flex items-center justify-between">
                          <span className="text-sm font-medium text-gray-900">
                            #{player.jersey_number} {player.first_name} {player.last_name}
                          </span>
                          <span className="text-xs text-gray-500">{player.position}</span>
                        </div>
                      </div>
                    </label>
                  ))}
                </div>
              </div>

              {/* Away Team Starting Five */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-3">
                  Away Team Starting Five ({watch('startingFive.away').length}/5)
                </h3>
                <div className="space-y-2">
                  {awayTeamPlayers
                    .filter((player: any) => watch('gameRoster.away').includes(player.id))
                    .map((player: any) => (
                    <label key={player.id} className="flex items-center p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={watch('startingFive.away').includes(player.id)}
                        onChange={(e) => handleStartingFiveChange('away', player.id, e.target.checked)}
                        className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                        disabled={!watch('startingFive.away').includes(player.id) && watch('startingFive.away').length >= 5}
                      />
                      <div className="ml-3 flex-1">
                        <div className="flex items-center justify-between">
                          <span className="text-sm font-medium text-gray-900">
                            #{player.jersey_number} {player.first_name} {player.last_name}
                          </span>
                          <span className="text-xs text-gray-500">{player.position}</span>
                        </div>
                      </div>
                    </label>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Step 4: Review & Start */}
        {currentStep === 3 && (
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center">
              <CheckCircleIcon className="h-5 w-5 mr-2" />
              Review & Start Game
            </h2>
            
            <div className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-4 bg-gray-50 rounded-lg">
                  <h3 className="font-medium text-gray-900 mb-2">Game Details</h3>
                  <div className="space-y-1 text-sm text-gray-600">
                    <p><strong>Date:</strong> {watch('gameDate')}</p>
                    <p><strong>Time:</strong> {watch('gameTime')}</p>
                    <p><strong>Location:</strong> {watch('location') || 'Not specified'}</p>
                    <p><strong>Competition:</strong> {watch('competition') || 'Not specified'}</p>
                    {isGameCompleted && currentGame && (
                      <p><strong>Final Score:</strong> {currentGame.home_team_score} - {currentGame.away_team_score}</p>
                    )}
                  </div>
                </div>
                
                <div className="p-4 bg-gray-50 rounded-lg">
                  <h3 className="font-medium text-gray-900 mb-2">Teams</h3>
                  <div className="space-y-1 text-sm text-gray-600">
                    <p><strong>Home:</strong> {availableTeams.find(t => t.id === watch('homeTeamId'))?.name}</p>
                    <p><strong>Away:</strong> {availableTeams.find(t => t.id === watch('awayTeamId'))?.name}</p>
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-4 bg-gray-50 rounded-lg">
                  <h3 className="font-medium text-gray-900 mb-2">Game Roster</h3>
                  <div className="space-y-1 text-sm text-gray-600">
                    <p><strong>Home Team:</strong> {watch('gameRoster.home').length}/12 players selected</p>
                    <p><strong>Away Team:</strong> {watch('gameRoster.away').length}/12 players selected</p>
                  </div>
                </div>
                
                <div className="p-4 bg-gray-50 rounded-lg">
                  <h3 className="font-medium text-gray-900 mb-2">Starting Lineups</h3>
                  <div className="space-y-1 text-sm text-gray-600">
                    <p><strong>Home Team:</strong> {watch('startingFive.home').length}/5 players selected</p>
                    <p><strong>Away Team:</strong> {watch('startingFive.away').length}/5 players selected</p>
                  </div>
                </div>
              </div>

              {watch('notes') && (
                <div className="p-4 bg-gray-50 rounded-lg">
                  <h3 className="font-medium text-gray-900 mb-2">Notes</h3>
                  <p className="text-sm text-gray-600">{watch('notes')}</p>
                </div>
              )}

              <div className={`p-4 rounded-lg ${isGameCompleted ? 'bg-green-50' : 'bg-blue-50'}`}>
                <h3 className={`font-medium mb-2 ${isGameCompleted ? 'text-green-900' : 'text-blue-900'}`}>
                  {isGameCompleted ? 'Ready for Analysis' : 'Ready to Start'}
                </h3>
                <p className={`text-sm ${isGameCompleted ? 'text-green-700' : 'text-blue-700'}`}>
                  {isGameCompleted 
                    ? 'All setup steps are complete. Click "Start Game Tracking" to begin analyzing this completed game and its possessions.'
                    : 'All setup steps are complete. Click "Start Game Tracking" to begin recording possessions and statistics.'
                  }
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Navigation Buttons */}
        <div className="flex justify-between pt-6">
          <button
            type="button"
            onClick={prevStep}
            disabled={currentStep === 0}
            className="px-4 py-2 text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 transition-colors disabled:bg-gray-50 disabled:text-gray-400 disabled:cursor-not-allowed"
          >
            Previous
          </button>
          
          <div className="flex space-x-3">
            {currentStep < setupSteps.length - 1 ? (
              <button
                type="button"
                onClick={nextStep}
                disabled={!canProceedToNext}
                className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                Next
              </button>
            ) : (
              <button
                type="submit"
                disabled={isSubmitting || !canProceedToNext}
                className="px-6 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center"
              >
                {isSubmitting ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Starting...
                  </>
                ) : (
                  <>
                    <PlayIcon className="h-4 w-4 mr-2" />
                    Start Game Tracking
                  </>
                )}
              </button>
            )}
          </div>
        </div>
      </form>
    </div>
  )
}
