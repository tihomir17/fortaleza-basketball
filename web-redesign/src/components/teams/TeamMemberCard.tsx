import { useState } from 'react'
import { 
  PencilIcon, 
  TrashIcon, 
  UserIcon, 
  CogIcon, 
  UserGroupIcon,
  CheckCircleIcon,
  XCircleIcon
} from '@heroicons/react/24/outline'
import type { TeamMember } from '../../services/teams'

interface TeamMemberCardProps {
  member: TeamMember
  onEdit: (member: TeamMember) => void
  onDelete: (memberId: number) => void
  onToggleStatus: (memberId: number, isActive: boolean) => void
  isLoading?: boolean
}

export function TeamMemberCard({ 
  member, 
  onEdit, 
  onDelete, 
  onToggleStatus, 
  isLoading = false 
}: TeamMemberCardProps) {
  const [showActions, setShowActions] = useState(false)

  const getRoleIcon = (role: string) => {
    switch (role) {
      case 'PLAYER': return UserIcon
      case 'COACH': return CogIcon
      case 'STAFF': return UserGroupIcon
      default: return UserIcon
    }
  }

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'PLAYER': return 'bg-blue-100 text-blue-800 border-blue-200'
      case 'COACH': return 'bg-green-100 text-green-800 border-green-200'
      case 'STAFF': return 'bg-purple-100 text-purple-800 border-purple-200'
      default: return 'bg-gray-100 text-gray-800 border-gray-200'
    }
  }

  const getCoachTypeColor = (coachType: string) => {
    switch (coachType) {
      case 'HEAD_COACH': return 'bg-red-100 text-red-800'
      case 'ASSISTANT_COACH': return 'bg-orange-100 text-orange-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getStaffTypeColor = (staffType: string) => {
    switch (staffType) {
      case 'PHYSIO': return 'bg-pink-100 text-pink-800'
      case 'STRENGTH_CONDITIONING': return 'bg-indigo-100 text-indigo-800'
      case 'EQUIPMENT_MANAGER': return 'bg-yellow-100 text-yellow-800'
      case 'ANALYST': return 'bg-teal-100 text-teal-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const formatStaffType = (staffType: string) => {
    return staffType.replace('_', ' ').toLowerCase().replace(/\b\w/g, l => l.toUpperCase())
  }

  const formatCoachType = (coachType: string) => {
    return coachType.replace('_', ' ').toLowerCase().replace(/\b\w/g, l => l.toUpperCase())
  }

  const RoleIcon = getRoleIcon(member.role)

  return (
    <div 
      className={`border rounded-lg p-4 transition-all duration-200 ${
        member.is_active 
          ? 'border-gray-200 bg-white hover:border-gray-300' 
          : 'border-gray-200 bg-gray-50 opacity-75'
      }`}
      onMouseEnter={() => setShowActions(true)}
      onMouseLeave={() => setShowActions(false)}
    >
      <div className="flex items-start justify-between">
        <div className="flex items-start space-x-3">
          <div className={`p-2 rounded-lg ${getRoleColor(member.role)}`}>
            <RoleIcon className="h-5 w-5" />
          </div>
          
          <div className="flex-1 min-w-0">
            <div className="flex items-center space-x-2">
              <h3 className="text-sm font-medium text-gray-900 truncate">
                {member.first_name} {member.last_name}
              </h3>
              {!member.is_active && (
                <XCircleIcon className="h-4 w-4 text-red-500" />
              )}
              {member.is_active && (
                <CheckCircleIcon className="h-4 w-4 text-green-500" />
              )}
            </div>
            
            <p className="text-xs text-gray-500 truncate">{member.email}</p>
            <p className="text-xs text-gray-400 truncate">@{member.username}</p>
            
            <div className="flex items-center space-x-2 mt-2">
              <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${getRoleColor(member.role)}`}>
                {member.role}
              </span>
              
              {member.role === 'PLAYER' && member.jersey_number && (
                <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                  #{member.jersey_number}
                </span>
              )}
              
              {member.role === 'PLAYER' && member.position && (
                <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-indigo-100 text-indigo-800">
                  {member.position}
                </span>
              )}
              
              {member.role === 'COACH' && member.coach_type && (
                <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${getCoachTypeColor(member.coach_type)}`}>
                  {formatCoachType(member.coach_type)}
                </span>
              )}
              
              {member.role === 'STAFF' && member.staff_type && (
                <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${getStaffTypeColor(member.staff_type)}`}>
                  {formatStaffType(member.staff_type)}
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className={`flex items-center space-x-1 transition-opacity duration-200 ${
          showActions ? 'opacity-100' : 'opacity-0'
        }`}>
          <button
            onClick={() => onEdit(member)}
            disabled={isLoading}
            className="p-1 text-gray-400 hover:text-blue-600 transition-colors"
            title="Edit member"
          >
            <PencilIcon className="h-4 w-4" />
          </button>
          
          <button
            onClick={() => onToggleStatus(member.id, !member.is_active)}
            disabled={isLoading}
            className={`p-1 transition-colors ${
              member.is_active 
                ? 'text-gray-400 hover:text-orange-600' 
                : 'text-gray-400 hover:text-green-600'
            }`}
            title={member.is_active ? 'Deactivate member' : 'Activate member'}
          >
            {member.is_active ? (
              <XCircleIcon className="h-4 w-4" />
            ) : (
              <CheckCircleIcon className="h-4 w-4" />
            )}
          </button>
          
          <button
            onClick={() => onDelete(member.id)}
            disabled={isLoading}
            className="p-1 text-gray-400 hover:text-red-600 transition-colors"
            title="Delete member"
          >
            <TrashIcon className="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>
  )
}
