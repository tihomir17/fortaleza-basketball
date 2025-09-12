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
  const { teams, teamMembers } = useTeamsStore()
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
  const homeTeamPlayers = teamMembers.filter((member: any) => 
    member.role === 'PLAYER' && member.team === watchedHomeTeamId
  )
  const awayTeamPlayers = teamMembers.filter((member: any) => 
    member.role === 'PLAYER' && member.team === watchedAwayTeamId
  )

  const [setupSteps, setSetupSteps] = useState<SetupStep[]>([
    {
      id: 'basic-info',
      title: 'Basic Game Information',
      description: 'Set up teams, date, time, and location',
      completed: false,
      required: true
    },
    {
      id: 'starting-five',
      title: 'Starting Lineups',
      description: 'Select the starting five players for each team',
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

  // Update step completion status
  useEffect(() => {
    const homeTeamSelected = watchedHomeTeamId > 0
    const awayTeamSelected = watchedAwayTeamId > 0
    const basicInfoComplete = homeTeamSelected && awayTeamSelected

    const homeStartingFive = watch('startingFive.home')
    const awayStartingFive = watch('startingFive.away')
    const startingFiveComplete = homeStartingFive.length === 5 && awayStartingFive.length === 5

    setSetupSteps((prev: SetupStep[]) => prev.map((step: SetupStep) => {
      if (step.id === 'basic-info') {
        return { ...step, completed: basicInfoComplete }
      }
      if (step.id === 'starting-five') {
        return { ...step, completed: startingFiveComplete }
      }
      return step
    }))
  }, [watchedHomeTeamId, watchedAwayTeamId, watch])

  const handleStartingFiveChange = (team: 'home' | 'away', playerId: number, checked: boolean) => {
    const currentStartingFive = watch('startingFive')
    const teamStartingFive = currentStartingFive[team]

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

  const canProceedToNext = () => {
    const currentStepData = setupSteps[currentStep]
    return currentStepData.completed || !currentStepData.required
  }

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
              Starting Lineups
            </h2>
            
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Home Team Starting Five */}
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-3">
                  Home Team Starting Five ({watch('startingFive.home').length}/5)
                </h3>
                <div className="space-y-2">
                  {homeTeamPlayers.map((player: any) => (
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
                  {awayTeamPlayers.map((player: any) => (
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

        {/* Step 3: Review & Start */}
        {currentStep === 2 && (
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
                    <p><strong>Home:</strong> {teams.find(t => t.id === watch('homeTeamId'))?.name}</p>
                    <p><strong>Away:</strong> {teams.find(t => t.id === watch('awayTeamId'))?.name}</p>
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
                disabled={!canProceedToNext()}
                className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                Next
              </button>
            ) : (
              <button
                type="submit"
                disabled={isSubmitting || !canProceedToNext()}
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
