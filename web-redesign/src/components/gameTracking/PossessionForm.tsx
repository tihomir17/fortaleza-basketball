import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import {
  XMarkIcon,
  UserGroupIcon,
  ChartBarIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon
} from '@heroicons/react/24/outline'
import { useGameTrackingStore } from '../../store/gameTrackingStore'
import { useTeamsStore } from '../../store/teamsStore'

interface PossessionFormProps {
  isOpen: boolean
  onClose: () => void
  gameId: number
  currentQuarter: number
  currentTime: string
}

interface FormData {
  // Basic fields
  quarter: number
  start_time_in_game: string
  duration_seconds: number
  outcome: string
  points_scored: number
  
  // Team and opponent
  team_id: number
  opponent_id?: number
  
  // Offensive analysis
  offensive_set?: string
  pnr_type?: string
  pnr_result?: string
  
  // Sequence analysis
  has_paint_touch: boolean
  has_kick_out: boolean
  has_extra_pass: boolean
  number_of_passes: number
  
  // Offensive rebounds
  is_offensive_rebound: boolean
  offensive_rebound_count: number
  offensive_rebound_players: number[]
  
  // Defensive analysis
  defensive_set?: string
  defensive_pnr?: string
  
  // Box out analysis
  box_out_count: number
  offensive_rebounds_allowed: number
  
  // Shooting analysis
  shoot_time?: number
  shoot_quality?: string
  time_range?: string
  
  // Context
  after_timeout: boolean
  
  // Player attributions
  scorer_id?: number
  assisted_by_id?: number
  blocked_by_id?: number
  stolen_by_id?: number
  fouled_by_id?: number
  
  // Players on court
  players_on_court: number[]
  defensive_players_on_court: number[]
  
  // Special scenarios
  is_buzzer_beater: boolean
  is_technical_foul: boolean
  technical_foul_player_id?: number
  is_coach_challenge: boolean
  
  // Additional metadata
  notes: string
}

const OUTCOME_OPTIONS = [
  { value: 'MADE_2PTS', label: 'Made 2-Point Shot' },
  { value: 'MISSED_2PTS', label: 'Missed 2-Point Shot' },
  { value: 'MADE_3PTS', label: 'Made 3-Point Shot' },
  { value: 'MISSED_3PTS', label: 'Missed 3-Point Shot' },
  { value: 'MADE_FTS', label: 'Made Free Throw' },
  { value: 'MISSED_FTS', label: 'Missed Free Throw' },
  { value: 'TURNOVER', label: 'Turnover' },
  { value: 'FOUL', label: 'Foul' },
  { value: 'REBOUND', label: 'Rebound' },
  { value: 'STEAL', label: 'Steal' },
  { value: 'BLOCK', label: 'Block' },
  { value: 'TECHNICAL_FOUL', label: 'Technical Foul' },
  { value: 'COACH_CHALLENGE', label: 'Coach Challenge' }
]

const OFFENSIVE_SET_OPTIONS = [
  { value: 'PICK_AND_ROLL', label: 'Pick and Roll' },
  { value: 'PICK_AND_POP', label: 'Pick and Pop' },
  { value: 'HANDOFF', label: 'Handoff' },
  { value: 'BACKDOOR', label: 'Backdoor' },
  { value: 'FLARE', label: 'Flare' },
  { value: 'DOWN_SCREEN', label: 'Down Screen' },
  { value: 'UP_SCREEN', label: 'Up Screen' },
  { value: 'CROSS_SCREEN', label: 'Cross Screen' },
  { value: 'POST_UP', label: 'Post Up' },
  { value: 'ISOLATION', label: 'Isolation' },
  { value: 'TRANSITION', label: 'Transition' },
  { value: 'OFFENSIVE_REBOUND', label: 'Offensive Rebound' },
  { value: 'FASTBREAK', label: 'Fast Break' },
  { value: 'OTHER', label: 'Other' }
]

const DEFENSIVE_SET_OPTIONS = [
  { value: 'MAN_TO_MAN', label: 'Man to Man' },
  { value: 'ZONE_2_3', label: '2-3 Zone' },
  { value: 'ZONE_3_2', label: '3-2 Zone' },
  { value: 'ZONE_1_3_1', label: '1-3-1 Zone' },
  { value: 'PRESS', label: 'Press' },
  { value: 'TRAP', label: 'Trap' },
  { value: 'SWITCH', label: 'Switch' },
  { value: 'ICE', label: 'Ice' },
  { value: 'GO_OVER', label: 'Go Over' },
  { value: 'GO_UNDER', label: 'Go Under' },
  { value: 'HEDGE', label: 'Hedge' },
  { value: 'FLAT', label: 'Flat' },
  { value: 'WEAK', label: 'Weak' },
  { value: 'OTHER', label: 'Other' }
]

// const SHOOT_QUALITY_OPTIONS = [
//   { value: 'EXCELLENT', label: 'Excellent' },
//   { value: 'GOOD', label: 'Good' },
//   { value: 'AVERAGE', label: 'Average' },
//   { value: 'POOR', label: 'Poor' },
//   { value: 'CONTESTED', label: 'Contested' },
//   { value: 'OPEN', label: 'Open' }
// ]

// const TIME_RANGE_OPTIONS = [
//   { value: 'EARLY_SHOT_CLOCK', label: 'Early Shot Clock (0-7s)' },
//   { value: 'MID_SHOT_CLOCK', label: 'Mid Shot Clock (8-14s)' },
//   { value: 'LATE_SHOT_CLOCK', label: 'Late Shot Clock (15-24s)' },
//   { value: 'SHOT_CLOCK_VIOLATION', label: 'Shot Clock Violation' }
// ]

export function PossessionForm({ isOpen, onClose, gameId, currentQuarter, currentTime }: PossessionFormProps) {
  const { teams, teamMembers } = useTeamsStore()
  const { createPossession } = useGameTrackingStore()
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)
  const [submitSuccess, setSubmitSuccess] = useState(false)

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    formState: { errors }
  } = useForm<FormData>({
    defaultValues: {
      quarter: currentQuarter,
      start_time_in_game: currentTime,
      duration_seconds: 0,
      outcome: '',
      points_scored: 0,
      team_id: 0,
      opponent_id: 0,
      has_paint_touch: false,
      has_kick_out: false,
      has_extra_pass: false,
      number_of_passes: 0,
      is_offensive_rebound: false,
      offensive_rebound_count: 0,
      offensive_rebound_players: [],
      box_out_count: 0,
      offensive_rebounds_allowed: 0,
      after_timeout: false,
      players_on_court: [],
      defensive_players_on_court: [],
      is_buzzer_beater: false,
      is_technical_foul: false,
      is_coach_challenge: false,
      notes: ''
    }
  })

  const watchedOutcome = watch('outcome')

  // Auto-update points based on outcome
  useEffect(() => {
    if (watchedOutcome) {
      switch (watchedOutcome) {
        case 'MADE_2PTS':
          setValue('points_scored', 2)
          break
        case 'MADE_3PTS':
          setValue('points_scored', 3)
          break
        case 'MADE_FTS':
          setValue('points_scored', 1)
          break
        default:
          setValue('points_scored', 0)
          break
      }
    }
  }, [watchedOutcome, setValue])

  // Get team players for selection
  const currentTeamId = watch('team_id')
  const opponentTeamId = watch('opponent_id')
  const teamPlayers = teamMembers.filter((member: any) => member.role === 'PLAYER' && member.team === currentTeamId)
  const opponentPlayers = teamMembers.filter((member: any) => member.role === 'PLAYER' && member.team === opponentTeamId)

  const onSubmit = async (data: FormData) => {
    setIsSubmitting(true)
    setSubmitError(null)
    setSubmitSuccess(false)

    try {
      const possessionData = {
        game_id: gameId,
        ...data
      }

      await createPossession(possessionData)
      
      setSubmitSuccess(true)
      setTimeout(() => {
        reset()
        onClose()
        setSubmitSuccess(false)
      }, 1500)
    } catch (error: any) {
      setSubmitError(error.message || 'Failed to create possession')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleClose = () => {
    reset()
    setSubmitError(null)
    setSubmitSuccess(false)
    onClose()
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-xl font-semibold text-gray-900">Add New Possession</h2>
          <button
            onClick={handleClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-6">
          {/* Success Message */}
          {submitSuccess && (
            <div className="bg-green-50 border border-green-200 rounded-lg p-4 flex items-center">
              <CheckCircleIcon className="h-5 w-5 text-green-600 mr-2" />
              <p className="text-green-800">Possession added successfully!</p>
            </div>
          )}

          {/* Error Message */}
          {submitError && (
            <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-center">
              <ExclamationTriangleIcon className="h-5 w-5 text-red-600 mr-2" />
              <p className="text-red-800">{submitError}</p>
            </div>
          )}

          {/* Basic Information */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Quarter</label>
              <select
                {...register('quarter', { required: 'Quarter is required' })}
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value={1}>Q1</option>
                <option value={2}>Q2</option>
                <option value={3}>Q3</option>
                <option value={4}>Q4</option>
                <option value={5}>OT1</option>
                <option value={6}>OT2</option>
              </select>
              {errors.quarter && <p className="text-red-600 text-sm mt-1">{errors.quarter.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Time</label>
              <input
                type="text"
                {...register('start_time_in_game', { required: 'Time is required' })}
                placeholder="MM:SS"
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
              />
              {errors.start_time_in_game && <p className="text-red-600 text-sm mt-1">{errors.start_time_in_game.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Duration (seconds)</label>
              <input
                type="number"
                {...register('duration_seconds', { min: 0, max: 24 })}
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>

          {/* Teams */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Team</label>
              <select
                {...register('team_id', { required: 'Team is required' })}
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">Select team</option>
                {teams.map(team => (
                  <option key={team.id} value={team.id}>{team.name}</option>
                ))}
              </select>
              {errors.team_id && <p className="text-red-600 text-sm mt-1">{errors.team_id.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Opponent</label>
              <select
                {...register('opponent_id')}
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">Select opponent</option>
                {teams.map(team => (
                  <option key={team.id} value={team.id}>{team.name}</option>
                ))}
              </select>
            </div>
          </div>

          {/* Outcome and Points */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Outcome</label>
              <select
                {...register('outcome', { required: 'Outcome is required' })}
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">Select outcome</option>
                {OUTCOME_OPTIONS.map(option => (
                  <option key={option.value} value={option.value}>{option.label}</option>
                ))}
              </select>
              {errors.outcome && <p className="text-red-600 text-sm mt-1">{errors.outcome.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Points Scored</label>
              <input
                type="number"
                {...register('points_scored', { min: 0, max: 3 })}
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>

          {/* Offensive Analysis */}
          <div className="border-t pt-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
              <ChartBarIcon className="h-5 w-5 mr-2" />
              Offensive Analysis
            </h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Offensive Set</label>
                <select
                  {...register('offensive_set')}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select offensive set</option>
                  {OFFENSIVE_SET_OPTIONS.map(option => (
                    <option key={option.value} value={option.value}>{option.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">PnR Type</label>
                <select
                  {...register('pnr_type')}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select PnR type</option>
                  <option value="BALL_SCREEN">Ball Screen</option>
                  <option value="OFF_BALL_SCREEN">Off Ball Screen</option>
                  <option value="HANDOFF_SCREEN">Handoff Screen</option>
                  <option value="NONE">None</option>
                </select>
              </div>
            </div>

            {/* Sequence Analysis */}
            <div className="mt-4 space-y-3">
              <h4 className="text-md font-medium text-gray-800">Sequence Analysis</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    {...register('has_paint_touch')}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                  />
                  <label className="ml-2 text-sm text-gray-700">Paint Touch</label>
                </div>
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    {...register('has_kick_out')}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                  />
                  <label className="ml-2 text-sm text-gray-700">Kick Out</label>
                </div>
                <div className="flex items-center">
                  <input
                    type="checkbox"
                    {...register('has_extra_pass')}
                    className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                  />
                  <label className="ml-2 text-sm text-gray-700">Extra Pass</label>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Number of Passes</label>
                  <input
                    type="number"
                    {...register('number_of_passes', { min: 0 })}
                    className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Defensive Analysis */}
          <div className="border-t pt-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4">Defensive Analysis</h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Defensive Set</label>
                <select
                  {...register('defensive_set')}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select defensive set</option>
                  {DEFENSIVE_SET_OPTIONS.map(option => (
                    <option key={option.value} value={option.value}>{option.label}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Defensive PnR</label>
                <select
                  {...register('defensive_pnr')}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select defensive PnR</option>
                  <option value="SWITCH">Switch</option>
                  <option value="ICE">Ice</option>
                  <option value="GO_OVER">Go Over</option>
                  <option value="GO_UNDER">Go Under</option>
                  <option value="TRAP">Trap</option>
                  <option value="NONE">None</option>
                </select>
              </div>
            </div>
          </div>

          {/* Player Attributions */}
          <div className="border-t pt-6">
            <h3 className="text-lg font-medium text-gray-900 mb-4 flex items-center">
              <UserGroupIcon className="h-5 w-5 mr-2" />
              Player Attributions
            </h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Scorer</label>
                <select
                  {...register('scorer_id')}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select scorer</option>
                  {teamPlayers.map((player: any) => (
                    <option key={player.id} value={player.id}>
                      #{player.jersey_number} {player.first_name} {player.last_name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Assisted By</label>
                <select
                  {...register('assisted_by_id')}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select assistant</option>
                  {teamPlayers.map((player: any) => (
                    <option key={player.id} value={player.id}>
                      #{player.jersey_number} {player.first_name} {player.last_name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Blocked By</label>
                <select
                  {...register('blocked_by_id')}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select blocker</option>
                  {opponentPlayers.map((player: any) => (
                    <option key={player.id} value={player.id}>
                      #{player.jersey_number} {player.first_name} {player.last_name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Stolen By</label>
                <select
                  {...register('stolen_by_id')}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select stealer</option>
                  {opponentPlayers.map((player: any) => (
                    <option key={player.id} value={player.id}>
                      #{player.jersey_number} {player.first_name} {player.last_name}
                    </option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          {/* Notes */}
          <div className="border-t pt-6">
            <label className="block text-sm font-medium text-gray-700 mb-1">Notes</label>
            <textarea
              {...register('notes')}
              rows={3}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="Additional notes about this possession..."
            />
          </div>

          {/* Submit Buttons */}
          <div className="flex justify-end space-x-3 pt-6 border-t">
            <button
              type="button"
              onClick={handleClose}
              className="px-4 py-2 text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors disabled:bg-gray-400 disabled:cursor-not-allowed flex items-center"
            >
              {isSubmitting ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                  Adding...
                </>
              ) : (
                'Add Possession'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
