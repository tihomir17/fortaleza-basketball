import React, { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import {
  CheckCircleIcon,
  ExclamationTriangleIcon,
  UserGroupIcon,
  TrophyIcon,
  PlayIcon
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
  const { teams, teamMembers, fetchTeamMembers } = useTeamsStore()
  const { selectGame, currentGame } = useGameTrackingStore()
  const [currentStep, setCurrentStep] = useState(0)
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    watch,
    setValue,
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

  const watchedHomeTeamId = watch('homeTeamId')
  const watchedAwayTeamId = watch('awayTeamId')

  // Create a combined list of teams that includes both user's teams and game participants
  const availableTeams = React.useMemo(() => {
    const userTeams = teams || []
    const gameTeams = currentGame ? [currentGame.home_team, currentGame.away_team] : []
    
    // Combine and deduplicate teams
    const allTeams = [...userTeams, ...gameTeams]
    const uniqueTeams = allTeams.filter((team, index, self) => 
      index === self.findIndex(t => t.id === team.id)
    )
    
    return uniqueTeams
  }, [teams, currentGame])

  // Get team players for starting five selection
  // Try to get players from current game data first, then fall back to team members
  const homeTeamPlayers = React.useMemo(() => {
    if (currentGame?.home_team?.players) {
      return currentGame.home_team.players.filter((player: any) => player.role === 'PLAYER')
    }
    return teamMembers.filter((member: any) => 
      member.role === 'PLAYER' && member.team === watchedHomeTeamId
    )
  }, [currentGame, teamMembers, watchedHomeTeamId])

  const awayTeamPlayers = React.useMemo(() => {
    if (currentGame?.away_team?.players) {
      return currentGame.away_team.players.filter((player: any) => player.role === 'PLAYER')
    }
    return teamMembers.filter((member: any) => 
      member.role === 'PLAYER' && member.team === watchedAwayTeamId
    )
  }, [currentGame, teamMembers, watchedAwayTeamId])

  // Debug logging (memoized to reduce console spam)
  const debugInfo = React.useMemo(() => ({
    teamMembers: teamMembers.length,
    watchedHomeTeamId,
    watchedAwayTeamId,
    homeTeamPlayers: homeTeamPlayers.length,
    awayTeamPlayers: awayTeamPlayers.length,
    availableTeams: availableTeams.length
  }), [teamMembers.length, watchedHomeTeamId, watchedAwayTeamId, homeTeamPlayers.length, awayTeamPlayers.length, availableTeams.length])
  
  console.log('🔍 GameSetup Debug:', debugInfo)

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

  // Pre-populate form with current game data when available
  useEffect(() => {
    if (currentGame) {
      setValue('homeTeamId', currentGame.home_team.id)
      setValue('awayTeamId', currentGame.away_team.id)
      setValue('gameDate', new Date(currentGame.game_date).toISOString().split('T')[0])
      setValue('gameTime', new Date(currentGame.game_date).toTimeString().slice(0, 5))
      setValue('competition', currentGame.competition?.name || '')
    }
  }, [currentGame, setValue])

  // Load team members when teams are selected (memoized to prevent unnecessary calls)
  const teamIds = React.useMemo(() => [watchedHomeTeamId, watchedAwayTeamId], [watchedHomeTeamId, watchedAwayTeamId])
  
  useEffect(() => {
    const loadTeamMembers = async () => {
      if (watchedHomeTeamId && watchedHomeTeamId > 0) {
        console.log('🔄 Loading team members for home team:', watchedHomeTeamId)
        await fetchTeamMembers(watchedHomeTeamId)
      }
      if (watchedAwayTeamId && watchedAwayTeamId > 0) {
        console.log('🔄 Loading team members for away team:', watchedAwayTeamId)
        await fetchTeamMembers(watchedAwayTeamId)
      }
    }
    
    loadTeamMembers()
  }, [teamIds, fetchTeamMembers])

  // Memoize step completion status to reduce re-renders
  const stepCompletionStatus = React.useMemo(() => {
    const homeTeamSelected = watchedHomeTeamId > 0
    const awayTeamSelected = watchedAwayTeamId > 0
    const basicInfoComplete = homeTeamSelected && awayTeamSelected

    const homeGameRoster = watch('gameRoster.home')
    const awayGameRoster = watch('gameRoster.away')
    const gameRosterComplete = homeGameRoster.length === 12 && awayGameRoster.length === 12

    const homeStartingFive = watch('startingFive.home')
    const awayStartingFive = watch('startingFive.away')
    const startingFiveComplete = homeStartingFive.length === 5 && awayStartingFive.length === 5

    return {
      basicInfoComplete,
      gameRosterComplete,
      startingFiveComplete,
      homeGameRoster: homeGameRoster.length,
      awayGameRoster: awayGameRoster.length,
      homeStartingFive: homeStartingFive.length,
      awayStartingFive: awayStartingFive.length
    }
  }, [watchedHomeTeamId, watchedAwayTeamId, watch])

  // Update step completion status
  useEffect(() => {
    setSetupSteps((prev: SetupStep[]) => prev.map((step: SetupStep) => {
      if (step.id === 'basic-info') {
        return { ...step, completed: stepCompletionStatus.basicInfoComplete }
      }
      if (step.id === 'game-roster') {
        return { ...step, completed: stepCompletionStatus.gameRosterComplete }
      }
      if (step.id === 'starting-five') {
        return { ...step, completed: stepCompletionStatus.startingFiveComplete }
      }
      return step
    }))

    // Debug logging for step completion (only when values change)
    console.log('🔍 Step Completion Debug:', stepCompletionStatus)
  }, [stepCompletionStatus])

  const handleGameRosterChange = (team: 'home' | 'away', playerId: number, checked: boolean) => {
    const currentGameRoster = watch('gameRoster')
    const teamGameRoster = currentGameRoster[team]

    if (checked) {
      if (teamGameRoster.length < 12) {
        setValue(`gameRoster.${team}`, [...teamGameRoster, playerId])
      }
    } else {
      const newGameRoster = teamGameRoster.filter(id => id !== playerId)
      setValue(`gameRoster.${team}`, newGameRoster)
      
      // Remove from starting five if they were selected
      const currentStartingFive = watch('startingFive')
      const teamStartingFive = currentStartingFive[team]
      if (teamStartingFive.includes(playerId)) {
        setValue(`startingFive.${team}`, teamStartingFive.filter(id => id !== playerId))
      }
    }
  }

  const handleStartingFiveChange = (team: 'home' | 'away', playerId: number, checked: boolean) => {
    const currentStartingFive = watch('startingFive')
    const teamStartingFive = currentStartingFive[team]
    const currentGameRoster = watch('gameRoster')
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

  const canProceedToNext = React.useMemo(() => {
    const currentStepData = setupSteps[currentStep]
    const canProceed = currentStepData.completed || !currentStepData.required
    console.log('🔍 canProceedToNext Debug:', {
      currentStep,
      stepId: currentStepData.id,
      completed: currentStepData.completed,
      required: currentStepData.required,
      canProceed
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
          Configure your game settings before starting possession tracking
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

              <div className="p-4 bg-blue-50 rounded-lg">
                <h3 className="font-medium text-blue-900 mb-2">Ready to Start</h3>
                <p className="text-sm text-blue-700">
                  All setup steps are complete. Click "Start Game Tracking" to begin recording possessions and statistics.
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
