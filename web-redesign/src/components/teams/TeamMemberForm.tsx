import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { XMarkIcon, UserIcon, CogIcon, UserGroupIcon, PlusIcon } from '@heroicons/react/24/outline'
import type { TeamMember, TeamMemberCreate, TeamMemberUpdate } from '../../services/teams'

interface ExistingUser {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  role: 'PLAYER' | 'COACH' | 'STAFF'
  coach_type?: string
  staff_type?: string
  jersey_number?: number | null
}

interface TeamMemberFormProps {
  isOpen: boolean
  onClose: () => void
  onSubmit: (data: TeamMemberCreate | TeamMemberUpdate) => Promise<void>
  onSubmitExisting: (userId: number, role: string) => Promise<void>
  member?: TeamMember | null
  teamId: number
  availableJerseyNumbers: number[]
  existingUsers?: ExistingUser[]
  isLoading?: boolean
}

interface FormData {
  username: string
  email: string
  first_name: string
  last_name: string
  role: 'PLAYER' | 'COACH' | 'STAFF'
  coach_type?: string
  staff_type?: string
  jersey_number?: number
  position?: string
  password?: string
  is_active: boolean
}

export function TeamMemberForm({ 
  isOpen, 
  onClose, 
  onSubmit,
  onSubmitExisting,
  member, 
  teamId: _teamId, 
  availableJerseyNumbers,
  existingUsers = [],
  isLoading = false 
}: TeamMemberFormProps) {
  const [selectedRole, setSelectedRole] = useState<'PLAYER' | 'COACH' | 'STAFF'>('PLAYER')
  const [formMode, setFormMode] = useState<'create' | 'select'>('create')
  const [selectedExistingUser, setSelectedExistingUser] = useState<ExistingUser | null>(null)
  const [errorMessage, setErrorMessage] = useState<string>('')
  
  const { register, handleSubmit, reset, watch, setValue, formState: { errors } } = useForm<FormData>({
    defaultValues: {
      username: '',
      email: '',
      first_name: '',
      last_name: '',
      role: 'PLAYER',
      coach_type: 'ASSISTANT_COACH',
      staff_type: 'PHYSIO',
      jersey_number: undefined,
      position: '',
      password: '',
      is_active: true
    }
  })

  const watchedRole = watch('role')
  const watchedFirstName = watch('first_name')
  const watchedLastName = watch('last_name')

  // Auto-generate username from first and last name
  useEffect(() => {
    if (!member && watchedFirstName && watchedLastName) {
      const timestamp = Date.now().toString().slice(-4) // Last 4 digits of timestamp
      const generatedUsername = `${watchedFirstName.toLowerCase()}.${watchedLastName.toLowerCase()}.${timestamp}`
      setValue('username', generatedUsername)
    }
  }, [watchedFirstName, watchedLastName, member, setValue])

  // Clear error message when form mode changes
  useEffect(() => {
    setErrorMessage('')
  }, [formMode, selectedRole])

  const handleFormSubmit = async (data: FormData) => {
    try {
      setErrorMessage('')
      if (formMode === 'create') {
        await onSubmit(data)
      } else if (formMode === 'select' && selectedExistingUser) {
        await onSubmitExisting(selectedExistingUser.id, selectedRole.toLowerCase())
      }
    } catch (error: any) {
      console.error('Form submission error:', error)
      
      // Handle specific error cases
      if (error?.response?.data?.error?.includes('already exists')) {
        setErrorMessage('A user with this email or username already exists. Please choose a different email/username or select an existing user.')
      } else if (error?.response?.data?.error) {
        setErrorMessage(error.response.data.error)
      } else if (error?.message) {
        setErrorMessage(error.message)
      } else {
        setErrorMessage('Failed to create team member. Please try again.')
      }
    }
  }

  useEffect(() => {
    if (member) {
      reset({
        username: member.username,
        email: member.email,
        first_name: member.first_name,
        last_name: member.last_name,
        role: member.role,
        coach_type: member.coach_type || 'ASSISTANT_COACH',
        staff_type: member.staff_type || 'PHYSIO',
        jersey_number: member.jersey_number || undefined,
        position: member.position || '',
        password: '',
        is_active: member.is_active
      })
      setSelectedRole(member.role)
    } else {
      reset({
        username: '',
        email: '',
        first_name: '',
        last_name: '',
        role: 'PLAYER',
        coach_type: 'ASSISTANT_COACH',
        staff_type: 'PHYSIO',
        jersey_number: undefined,
        position: '',
        password: '',
        is_active: true
      })
      setSelectedRole('PLAYER')
    }
  }, [member, reset])

  useEffect(() => {
    setSelectedRole(watchedRole)
  }, [watchedRole])


  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-medium text-gray-900">
            {member ? 'Edit Team Member' : 'Add Team Member'}
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <XMarkIcon className="h-6 w-6" />
          </button>
        </div>

        {/* Error Message */}
        {errorMessage && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-md">
            <p className="text-sm text-red-600">{errorMessage}</p>
          </div>
        )}

        {/* Mode Selection */}
        {!member && (
          <div className="mb-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">Add Member</label>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => setFormMode('create')}
                className={`p-2 text-sm font-medium rounded-md border ${
                  formMode === 'create'
                    ? 'bg-blue-50 border-blue-500 text-blue-700'
                    : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50'
                }`}
              >
                <PlusIcon className="h-4 w-4 inline mr-1" />
                Create New
              </button>
              <button
                type="button"
                onClick={() => setFormMode('select')}
                className={`p-2 text-sm font-medium rounded-md border ${
                  formMode === 'select'
                    ? 'bg-blue-50 border-blue-500 text-blue-700'
                    : 'bg-white border-gray-300 text-gray-700 hover:bg-gray-50'
                }`}
              >
                <UserIcon className="h-4 w-4 inline mr-1" />
                Select Existing
              </button>
            </div>
          </div>
        )}

        <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
          {/* Role Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Role</label>
            <div className="grid grid-cols-3 gap-2">
              {[
                { value: 'PLAYER', label: 'Player', icon: UserIcon },
                { value: 'COACH', label: 'Coach', icon: CogIcon },
                { value: 'STAFF', label: 'Staff', icon: UserGroupIcon }
              ].map(({ value, label, icon: Icon }) => (
                <button
                  key={value}
                  type="button"
                  onClick={() => {
                    setValue('role', value as 'PLAYER' | 'COACH' | 'STAFF')
                    setSelectedRole(value as 'PLAYER' | 'COACH' | 'STAFF')
                  }}
                  className={`p-3 border rounded-lg text-center transition-colors ${
                    selectedRole === value
                      ? 'border-blue-500 bg-blue-50 text-blue-700'
                      : 'border-gray-300 hover:border-gray-400'
                  }`}
                >
                  <Icon className="h-5 w-5 mx-auto mb-1" />
                  <span className="text-xs font-medium">{label}</span>
                </button>
              ))}
            </div>
            <input type="hidden" {...register('role')} />
          </div>

          {/* Existing User Selection */}
          {!member && formMode === 'select' && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Select Existing User
              </label>
              <select
                value={selectedExistingUser?.id || ''}
                onChange={(e) => {
                  const userId = parseInt(e.target.value)
                  const user = existingUsers.find(u => u.id === userId)
                  setSelectedExistingUser(user || null)
                }}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                required={formMode === 'select'}
              >
                <option value="">Choose a user...</option>
                {existingUsers
                  .filter(user => user.role === selectedRole)
                  .map(user => (
                    <option key={user.id} value={user.id}>
                      {user.first_name} {user.last_name} ({user.email})
                    </option>
                  ))}
              </select>
              {existingUsers.filter(user => user.role === selectedRole).length === 0 && (
                <p className="mt-1 text-sm text-gray-500">
                  No existing {selectedRole.toLowerCase()}s found. Switch to "Create New" to add a new member.
                </p>
              )}
            </div>
          )}

          {/* Basic Information - Only show for create mode or when editing */}
          {((!member && formMode === 'create') || member) && (
            <>
              <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">First Name</label>
              <input
                type="text"
                {...register('first_name', { required: 'First name is required' })}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              />
              {errors.first_name && (
                <p className="mt-1 text-sm text-red-600">{errors.first_name.message}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">Last Name</label>
              <input
                type="text"
                {...register('last_name', { required: 'Last name is required' })}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              />
              {errors.last_name && (
                <p className="mt-1 text-sm text-red-600">{errors.last_name.message}</p>
              )}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Username</label>
            <input
              type="text"
              {...register('username', { required: 'Username is required' })}
              className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
            />
            {errors.username && (
              <p className="mt-1 text-sm text-red-600">{errors.username.message}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700">Email</label>
            <input
              type="email"
              {...register('email', { 
                required: 'Email is required',
                pattern: {
                  value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
                  message: 'Invalid email address'
                }
              })}
              className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
            />
            {errors.email && (
              <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>
            )}
          </div>

          {/* Role-specific fields */}
          {selectedRole === 'PLAYER' && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">Jersey Number</label>
                <select
                  {...register('jersey_number', { required: 'Jersey number is required' })}
                  className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select jersey number</option>
                  {availableJerseyNumbers.map(num => (
                    <option key={num} value={num}>#{num}</option>
                  ))}
                </select>
                {errors.jersey_number && (
                  <p className="mt-1 text-sm text-red-600">{errors.jersey_number.message}</p>
                )}
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700">Position</label>
                <select
                  {...register('position')}
                  className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Select position</option>
                  <option value="PG">PG - Point Guard</option>
                  <option value="SG">SG - Shooting Guard</option>
                  <option value="SF">SF - Small Forward</option>
                  <option value="PF">PF - Power Forward</option>
                  <option value="C">C - Center</option>
                </select>
                {errors.position && (
                  <p className="mt-1 text-sm text-red-600">{errors.position.message}</p>
                )}
              </div>
            </div>
          )}

          {selectedRole === 'COACH' && (
            <div>
              <label className="block text-sm font-medium text-gray-700">Coach Type</label>
              <select
                {...register('coach_type')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="HEAD_COACH">Head Coach</option>
                <option value="ASSISTANT_COACH">Assistant Coach</option>
              </select>
            </div>
          )}

          {selectedRole === 'STAFF' && (
            <div>
              <label className="block text-sm font-medium text-gray-700">Staff Type</label>
              <select
                {...register('staff_type')}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="PHYSIO">Physiotherapist</option>
                <option value="STRENGTH_CONDITIONING">Strength & Conditioning</option>
                <option value="EQUIPMENT_MANAGER">Equipment Manager</option>
                <option value="ANALYST">Analyst</option>
              </select>
            </div>
          )}

          {/* Password field for new members */}
          {!member && (
            <div>
              <label className="block text-sm font-medium text-gray-700">Password</label>
              <input
                type="password"
                {...register('password', { 
                  required: !member ? 'Password is required' : false,
                  minLength: {
                    value: 8,
                    message: 'Password must be at least 8 characters'
                  }
                })}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                placeholder="Leave empty for default password"
              />
              {errors.password && (
                <p className="mt-1 text-sm text-red-600">{errors.password.message}</p>
              )}
            </div>
          )}

          {/* Status toggle for existing members */}
          {member && (
            <div className="flex items-center">
              <input
                type="checkbox"
                {...register('is_active')}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label className="ml-2 block text-sm text-gray-900">Active</label>
            </div>
          )}
            </>
          )}

          {/* Form Actions */}
          <div className="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isLoading}
              className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50"
            >
              {isLoading ? 'Saving...' : (member ? 'Update' : 'Add')}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
