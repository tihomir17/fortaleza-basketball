import { create } from 'zustand'

export interface User {
  id: string
  email: string
  firstName: string
  lastName: string
  role: 'admin' | 'coach' | 'player' | 'viewer'
  status: 'active' | 'inactive' | 'pending'
  avatar?: string
  phone?: string
  teamId?: string
  teamName?: string
  permissions: string[]
  lastLogin?: Date
  createdAt: Date
  updatedAt: Date
}

export interface CreateUserData {
  email: string
  firstName: string
  lastName: string
  role: 'admin' | 'coach' | 'player' | 'viewer'
  phone?: string
  teamId?: string
  password?: string
}

export interface UpdateUserData {
  firstName?: string
  lastName?: string
  role?: 'admin' | 'coach' | 'player' | 'viewer'
  status?: 'active' | 'inactive' | 'pending'
  phone?: string
  teamId?: string
  permissions?: string[]
}

interface UserManagementState {
  users: User[]
  isLoading: boolean
  error: string | null
  selectedUser: User | null

  // Actions
  fetchUsers: () => Promise<void>
  createUser: (userData: CreateUserData) => Promise<User>
  updateUser: (id: string, userData: UpdateUserData) => Promise<User>
  deleteUser: (id: string) => Promise<void>
  resetPassword: (id: string) => Promise<void>
  toggleUserStatus: (id: string) => Promise<void>
  setSelectedUser: (user: User | null) => void
  clearError: () => void
}

// Mock data for development
const mockUsers: User[] = [
  {
    id: '1',
    email: 'admin@fortaleza.com',
    firstName: 'Admin',
    lastName: 'User',
    role: 'admin',
    status: 'active',
    permissions: ['all'],
    lastLogin: new Date('2024-01-15'),
    createdAt: new Date('2024-01-01'),
    updatedAt: new Date('2024-01-15')
  },
  {
    id: '2',
    email: 'coach@fortaleza.com',
    firstName: 'John',
    lastName: 'Coach',
    role: 'coach',
    status: 'active',
    phone: '+1-555-0123',
    teamId: 'team1',
    teamName: 'Fortaleza Basketball',
    permissions: ['games:read', 'games:write', 'players:read', 'players:write', 'analytics:read'],
    lastLogin: new Date('2024-01-14'),
    createdAt: new Date('2024-01-02'),
    updatedAt: new Date('2024-01-14')
  },
  {
    id: '3',
    email: 'player1@fortaleza.com',
    firstName: 'Carlos',
    lastName: 'Santos',
    role: 'player',
    status: 'active',
    phone: '+1-555-0124',
    teamId: 'team1',
    teamName: 'Fortaleza Basketball',
    permissions: ['games:read', 'players:read'],
    lastLogin: new Date('2024-01-13'),
    createdAt: new Date('2024-01-03'),
    updatedAt: new Date('2024-01-13')
  },
  {
    id: '4',
    email: 'viewer@fortaleza.com',
    firstName: 'Jane',
    lastName: 'Viewer',
    role: 'viewer',
    status: 'active',
    permissions: ['games:read', 'players:read', 'analytics:read'],
    lastLogin: new Date('2024-01-12'),
    createdAt: new Date('2024-01-04'),
    updatedAt: new Date('2024-01-12')
  },
  {
    id: '5',
    email: 'pending@fortaleza.com',
    firstName: 'Pending',
    lastName: 'User',
    role: 'player',
    status: 'pending',
    phone: '+1-555-0125',
    teamId: 'team1',
    teamName: 'Fortaleza Basketball',
    permissions: [],
    createdAt: new Date('2024-01-10'),
    updatedAt: new Date('2024-01-10')
  }
]

export const useUserManagementStore = create<UserManagementState>((set, get) => ({
  users: [],
  isLoading: false,
  error: null,
  selectedUser: null,

  fetchUsers: async () => {
    set({ isLoading: true, error: null })
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))
      set({ users: mockUsers, isLoading: false })
    } catch {
      set({ error: 'Failed to fetch users', isLoading: false })
    }
  },

  createUser: async (userData: CreateUserData) => {
    set({ isLoading: true, error: null })
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      const newUser: User = {
        id: Math.random().toString(36).substr(2, 9),
        ...userData,
        status: 'pending',
        permissions: getDefaultPermissions(userData.role),
        createdAt: new Date(),
        updatedAt: new Date()
      }

      set(state => ({
        users: [...state.users, newUser],
        isLoading: false
      }))

      return newUser
    } catch {
      set({ error: 'Failed to create user', isLoading: false })
      throw new Error('Operation failed')
    }
  },

  updateUser: async (id: string, userData: UpdateUserData) => {
    set({ isLoading: true, error: null })
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      set(state => ({
        users: state.users.map(user =>
          user.id === id
            ? { ...user, ...userData, updatedAt: new Date() }
            : user
        ),
        isLoading: false
      }))

      const updatedUser = get().users.find(user => user.id === id)
      if (updatedUser) {
        return updatedUser
      }
      throw new Error('User not found')
    } catch {
      set({ error: 'Failed to update user', isLoading: false })
      throw new Error('Operation failed')
    }
  },

  deleteUser: async (id: string) => {
    set({ isLoading: true, error: null })
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      set(state => ({
        users: state.users.filter(user => user.id !== id),
        isLoading: false
      }))
    } catch {
      set({ error: 'Failed to delete user', isLoading: false })
      throw new Error('Operation failed')
    }
  },

  resetPassword: async (_id: string) => {
    set({ isLoading: true, error: null })
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))
      set({ isLoading: false })
    } catch {
      set({ error: 'Failed to reset password', isLoading: false })
      throw new Error('Operation failed')
    }
  },

  toggleUserStatus: async (id: string) => {
    set({ isLoading: true, error: null })
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000))
      
      set(state => ({
        users: state.users.map(user =>
          user.id === id
            ? { 
                ...user, 
                status: user.status === 'active' ? 'inactive' : 'active',
                updatedAt: new Date()
              }
            : user
        ),
        isLoading: false
      }))
    } catch {
      set({ error: 'Failed to toggle user status', isLoading: false })
      throw new Error('Operation failed')
    }
  },

  setSelectedUser: (user: User | null) => {
    set({ selectedUser: user })
  },

  clearError: () => {
    set({ error: null })
  }
}))

// Helper function to get default permissions based on role
const getDefaultPermissions = (role: string): string[] => {
  switch (role) {
    case 'admin':
      return ['all']
    case 'coach':
      return ['games:read', 'games:write', 'players:read', 'players:write', 'analytics:read', 'teams:read']
    case 'player':
      return ['games:read', 'players:read']
    case 'viewer':
      return ['games:read', 'players:read', 'analytics:read']
    default:
      return []
  }
}

// Permission checking utilities
export const hasPermission = (user: User, permission: string): boolean => {
  if (user.permissions.includes('all')) return true
  return user.permissions.includes(permission)
}

export const hasAnyPermission = (user: User, permissions: string[]): boolean => {
  if (user.permissions.includes('all')) return true
  return permissions.some(permission => user.permissions.includes(permission))
}

export const hasAllPermissions = (user: User, permissions: string[]): boolean => {
  if (user.permissions.includes('all')) return true
  return permissions.every(permission => user.permissions.includes(permission))
}

// Role hierarchy checking
export const canManageUser = (currentUser: User, targetUser: User): boolean => {
  if (currentUser.role === 'admin') return true
  if (currentUser.role === 'coach' && targetUser.role === 'player') return true
  return false
}

// Available roles and their descriptions
export const ROLE_DESCRIPTIONS = {
  admin: 'Full system access and user management',
  coach: 'Team management, game planning, and player oversight',
  player: 'View own stats and team information',
  viewer: 'Read-only access to games and analytics'
}

// Available permissions
export const AVAILABLE_PERMISSIONS = [
  { key: 'games:read', label: 'View Games', description: 'Read access to games and schedules' },
  { key: 'games:write', label: 'Manage Games', description: 'Create, edit, and delete games' },
  { key: 'players:read', label: 'View Players', description: 'Read access to player information' },
  { key: 'players:write', label: 'Manage Players', description: 'Create, edit, and delete players' },
  { key: 'teams:read', label: 'View Teams', description: 'Read access to team information' },
  { key: 'teams:write', label: 'Manage Teams', description: 'Create, edit, and delete teams' },
  { key: 'analytics:read', label: 'View Analytics', description: 'Read access to analytics and reports' },
  { key: 'analytics:write', label: 'Manage Analytics', description: 'Create and edit analytics reports' },
  { key: 'users:read', label: 'View Users', description: 'Read access to user information' },
  { key: 'users:write', label: 'Manage Users', description: 'Create, edit, and delete users' },
  { key: 'settings:read', label: 'View Settings', description: 'Read access to system settings' },
  { key: 'settings:write', label: 'Manage Settings', description: 'Modify system settings' }
]
