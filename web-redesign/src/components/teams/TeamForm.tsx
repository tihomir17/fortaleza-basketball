import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { XMarkIcon } from '@heroicons/react/24/outline'
import type { Team, TeamCreate } from '../../services/teams'

interface TeamFormProps {
  isOpen: boolean
  onClose: () => void
  onSubmit: (data: TeamCreate) => Promise<void>
  team?: Team | null
  isLoading?: boolean
}

interface FormData {
  name: string
  competition: number
}

export function TeamForm({ 
  isOpen, 
  onClose, 
  onSubmit,
  team,
  isLoading = false 
}: TeamFormProps) {
  const [errorMessage, setErrorMessage] = useState<string>('')
  
  const { register, handleSubmit, reset, formState: { errors } } = useForm<FormData>({
    defaultValues: {
      name: '',
      competition: 1 // Default competition ID
    }
  })

  // Reset form when team changes or modal opens/closes
  useEffect(() => {
    if (isOpen) {
      if (team) {
        reset({
          name: team.name,
          competition: team.competition || 1
        })
      } else {
        reset({
          name: '',
          competition: 1
        })
      }
      setErrorMessage('')
    }
  }, [isOpen, team, reset])

  const handleFormSubmit = async (data: FormData) => {
    try {
      setErrorMessage('')
      await onSubmit(data)
    } catch (error: any) {
      console.error('Form submission error:', error)
      
      if (error?.response?.data?.error) {
        setErrorMessage(error.response.data.error)
      } else if (error?.message) {
        setErrorMessage(error.message)
      } else {
        setErrorMessage('Failed to save team. Please try again.')
      }
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-md w-full">
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-bold text-gray-900 dark:text-white">
              {team ? 'Edit Team' : 'Create New Team'}
            </h2>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
            >
              <XMarkIcon className="w-6 h-6" />
            </button>
          </div>

          <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
            {/* Team Name */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Team Name *
              </label>
              <input
                type="text"
                {...register('name', { 
                  required: 'Team name is required',
                  minLength: { value: 2, message: 'Team name must be at least 2 characters' },
                  maxLength: { value: 100, message: 'Team name must be less than 100 characters' }
                })}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                placeholder="Enter team name"
              />
              {errors.name && (
                <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                  {errors.name.message}
                </p>
              )}
            </div>

            {/* Competition */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Competition *
              </label>
              <select
                {...register('competition', { 
                  required: 'Competition is required',
                  valueAsNumber: true
                })}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
              >
                <option value={1}>Fortaleza Basketball League</option>
                <option value={2}>Regional Championship</option>
                <option value={3}>National Tournament</option>
              </select>
              {errors.competition && (
                <p className="mt-1 text-sm text-red-600 dark:text-red-400">
                  {errors.competition.message}
                </p>
              )}
            </div>

            {/* Error Message */}
            {errorMessage && (
              <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-3">
                <p className="text-sm text-red-600 dark:text-red-400">
                  {errorMessage}
                </p>
              </div>
            )}

            {/* Action Buttons */}
            <div className="flex items-center justify-end space-x-3 pt-4">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                disabled={isLoading}
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                disabled={isLoading}
              >
                {isLoading ? (
                  <div className="flex items-center space-x-2">
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                    <span>{team ? 'Updating...' : 'Creating...'}</span>
                  </div>
                ) : (
                  team ? 'Update Team' : 'Create Team'
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}
