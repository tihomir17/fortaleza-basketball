import { useEffect, useState } from 'react'
import {
  // PlusIcon,
  PencilIcon,
  TrashIcon,
  EyeIcon,
  KeyIcon,
  UserPlusIcon,
  UserMinusIcon,
  MagnifyingGlassIcon,
  // FunnelIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline'
import { useUserManagementStore } from '../store/userManagementStore'
import { ExportButton } from '../components/ui/ExportButton'
import { notify } from '../store/notificationsStore'

export function UserManagement() {
  const {
    users,
    isLoading,
    error,
    // selectedUser,
    fetchUsers,
    // createUser,
    // updateUser,
    deleteUser,
    resetPassword,
    toggleUserStatus,
    setSelectedUser,
    clearError
  } = useUserManagementStore()

  // const [showCreateModal, setShowCreateModal] = useState(false)
  // const [showEditModal, setShowEditModal] = useState(false)
  // const [showViewModal, setShowViewModal] = useState(false)
  const [searchValue, setSearchValue] = useState('')
  const [roleFilter, setRoleFilter] = useState('')
  const [statusFilter, setStatusFilter] = useState('')

  useEffect(() => {
    fetchUsers()
  }, [fetchUsers])

  // const handleCreateUser = async (userData: CreateUserData) => {
  //   try {
  //     await createUser(userData)
  //     setShowCreateModal(false)
  //     notify.success('User Created', 'User has been created successfully')
  //   } catch {
  //     notify.error('Creation Failed', 'Failed to create user')
  //   }
  // }

  // const handleUpdateUser = async (id: string, userData: UpdateUserData) => {
  //   try {
  //     await updateUser(id, userData)
  //     setShowEditModal(false)
  //     setSelectedUser(null)
  //     notify.success('User Updated', 'User has been updated successfully')
  //   } catch {
  //     notify.error('Update Failed', 'Failed to update user')
  //   }
  // }

  const handleDeleteUser = async (id: string) => {
    if (window.confirm('Are you sure you want to delete this user?')) {
      try {
        await deleteUser(id)
        notify.success('User Deleted', 'User has been deleted successfully')
      } catch {
        notify.error('Deletion Failed', 'Failed to delete user')
      }
    }
  }

  const handleResetPassword = async (id: string) => {
    if (window.confirm('Are you sure you want to reset this user\'s password?')) {
      try {
        await resetPassword(id)
        notify.success('Password Reset', 'Password reset email has been sent')
      } catch {
        notify.error('Reset Failed', 'Failed to reset password')
      }
    }
  }

  const handleToggleStatus = async (id: string) => {
    try {
      await toggleUserStatus(id)
      const user = users.find(u => u.id === id)
      notify.success(
        'Status Updated', 
        `User status changed to ${user?.status === 'active' ? 'inactive' : 'active'}`
      )
    } catch {
      notify.error('Status Update Failed', 'Failed to update user status')
    }
  }

  const getFilteredUsers = () => {
    return users.filter(user => {
      const matchesSearch = !searchValue || 
        user.firstName.toLowerCase().includes(searchValue.toLowerCase()) ||
        user.lastName.toLowerCase().includes(searchValue.toLowerCase()) ||
        user.email.toLowerCase().includes(searchValue.toLowerCase())

      const matchesRole = !roleFilter || user.role === roleFilter
      const matchesStatus = !statusFilter || user.status === statusFilter

      return matchesSearch && matchesRole && matchesStatus
    })
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400'
      case 'inactive':
        return 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400'
      case 'pending':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400'
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400'
    }
  }

  const getRoleColor = (role: string) => {
    switch (role) {
      case 'admin':
        return 'bg-purple-100 text-purple-800 dark:bg-purple-900/20 dark:text-purple-400'
      case 'coach':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400'
      case 'player':
        return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400'
      case 'viewer':
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400'
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400'
    }
  }

  if (isLoading && users.length === 0) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-fortaleza-blue"></div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-6">
        <div className="flex items-center">
          <ExclamationTriangleIcon className="w-6 h-6 text-red-600 dark:text-red-400 mr-3" />
          <div>
            <h3 className="text-lg font-medium text-red-800 dark:text-red-200">Error</h3>
            <p className="text-red-600 dark:text-red-400">{error}</p>
            <button
              onClick={clearError}
              className="mt-2 text-sm text-red-600 dark:text-red-400 hover:text-red-800 dark:hover:text-red-200"
            >
              Try again
            </button>
          </div>
        </div>
      </div>
    )
  }

  const filteredUsers = getFilteredUsers()

  return (
    <div>
      {/* Page Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">User Management</h1>
          <p className="mt-2 text-gray-600 dark:text-gray-400">Manage system users and their permissions.</p>
        </div>
        <div className="flex items-center space-x-3">
          <ExportButton
            data={filteredUsers}
            dataType="custom"
            title="Users Export"
            size="md"
            variant="outline"
          />
          <button
            onClick={() => {/* setShowCreateModal(true) */}}
            className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center"
          >
            <UserPlusIcon className="w-5 h-5 mr-2" />
            Add User
          </button>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="mb-6 space-y-4">
        {/* Search Bar */}
        <div className="relative">
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <MagnifyingGlassIcon className="h-5 w-5 text-gray-400" />
          </div>
          <input
            type="text"
            value={searchValue}
            onChange={(e) => setSearchValue(e.target.value)}
            className="block w-full pl-10 pr-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:ring-2 focus:ring-fortaleza-blue focus:border-transparent"
            placeholder="Search users by name or email..."
          />
        </div>

        {/* Filters */}
        <div className="flex flex-wrap gap-4">
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-fortaleza-blue focus:border-transparent"
          >
            <option value="">All Roles</option>
            <option value="admin">Admin</option>
            <option value="coach">Coach</option>
            <option value="player">Player</option>
            <option value="viewer">Viewer</option>
          </select>

          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-fortaleza-blue focus:border-transparent"
          >
            <option value="">All Status</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
            <option value="pending">Pending</option>
          </select>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead className="bg-gray-50 dark:bg-gray-700">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  User
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Role
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Team
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Last Login
                </th>
                <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
              {filteredUsers.map((user) => (
                <tr key={user.id} className="hover:bg-gray-50 dark:hover:bg-gray-700">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="flex-shrink-0 h-10 w-10">
                        <div className="h-10 w-10 rounded-full bg-fortaleza-blue flex items-center justify-center">
                          <span className="text-sm font-medium text-white">
                            {user.firstName[0]}{user.lastName[0]}
                          </span>
                        </div>
                      </div>
                      <div className="ml-4">
                        <div className="text-sm font-medium text-gray-900 dark:text-white">
                          {user.firstName} {user.lastName}
                        </div>
                        <div className="text-sm text-gray-500 dark:text-gray-400">
                          {user.email}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getRoleColor(user.role)}`}>
                      {user.role.charAt(0).toUpperCase() + user.role.slice(1)}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(user.status)}`}>
                      {user.status.charAt(0).toUpperCase() + user.status.slice(1)}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    {user.teamName || 'No Team'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                    {user.lastLogin ? new Date(user.lastLogin).toLocaleDateString() : 'Never'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <div className="flex items-center justify-end space-x-2">
                      <button
                        onClick={() => {
                          setSelectedUser(user)
                          {/* setShowViewModal(true) */}
                        }}
                        className="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
                        title="View User"
                      >
                        <EyeIcon className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => {
                          setSelectedUser(user)
                          {/* setShowEditModal(true) */}
                        }}
                        className="text-blue-600 dark:text-blue-400 hover:text-blue-900 dark:hover:text-blue-300"
                        title="Edit User"
                      >
                        <PencilIcon className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleResetPassword(user.id)}
                        className="text-yellow-600 dark:text-yellow-400 hover:text-yellow-900 dark:hover:text-yellow-300"
                        title="Reset Password"
                      >
                        <KeyIcon className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => handleToggleStatus(user.id)}
                        className={`${user.status === 'active' ? 'text-red-600 dark:text-red-400 hover:text-red-900 dark:hover:text-red-300' : 'text-green-600 dark:text-green-400 hover:text-green-900 dark:hover:text-green-300'}`}
                        title={user.status === 'active' ? 'Deactivate User' : 'Activate User'}
                      >
                        {user.status === 'active' ? <UserMinusIcon className="w-4 h-4" /> : <UserPlusIcon className="w-4 h-4" />}
                      </button>
                      <button
                        onClick={() => handleDeleteUser(user.id)}
                        className="text-red-600 dark:text-red-400 hover:text-red-900 dark:hover:text-red-300"
                        title="Delete User"
                      >
                        <TrashIcon className="w-4 h-4" />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {filteredUsers.length === 0 && (
          <div className="text-center py-12">
            <UserPlusIcon className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No users found</h3>
            <p className="text-gray-600 dark:text-gray-400 mb-4">
              {searchValue || roleFilter || statusFilter
                ? 'Try adjusting your search or filter criteria.'
                : 'Get started by creating your first user.'
              }
            </p>
            {!searchValue && !roleFilter && !statusFilter && (
              <button
                onClick={() => {/* setShowCreateModal(true) */}}
                className="bg-fortaleza-blue text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors flex items-center mx-auto"
              >
                <UserPlusIcon className="w-5 h-5 mr-2" />
                Add User
              </button>
            )}
          </div>
        )}
      </div>

      {/* Modals would go here - CreateUserModal, EditUserModal, ViewUserModal */}
      {/* For now, we'll just show the basic structure */}
    </div>
  )
}
