import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { authApi } from '../services/api'
import { errorTracker, behaviorTracker } from '../utils/monitoring'

interface User {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  role: string
  coach_type: string
  staff_type: string
  jersey_number: number | null
  is_active: boolean
  date_joined: string
}

interface AuthState {
  user: User | null
  token: string | null
  isAuthenticated: boolean
  isLoading: boolean
  error: string | null
  lastActivity: number
  sessionTimeout: number
}

interface AuthActions {
  login: (credentials: { username: string; password: string }) => Promise<void>
  logout: () => void
  register: (userData: RegisterData) => Promise<void>
  refreshToken: () => Promise<void>
  updateProfile: (userData: Partial<User>) => Promise<void>
  changePassword: (passwords: { current: string; new: string }) => Promise<void>
  forgotPassword: (email: string) => Promise<void>
  resetPassword: (token: string, password: string) => Promise<void>
  verifyEmail: (token: string) => Promise<void>
  resendVerification: () => Promise<void>
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  clearError: () => void
  updateLastActivity: () => void
  checkSession: () => boolean
  hasPermission: (permission: string) => boolean
  hasRole: (role: string) => boolean
}

interface RegisterData {
  username: string
  email: string
  password: string
  first_name: string
  last_name: string
  role?: string
}

type AuthStore = AuthState & AuthActions

const SESSION_TIMEOUT = 30 * 60 * 1000 // 30 minutes
// const INACTIVITY_TIMEOUT = 15 * 60 * 1000 // 15 minutes

export const useAuthStore = create<AuthStore>()(
  persist(
    (set, get) => ({
      // Initial state
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,
      lastActivity: Date.now(),
      sessionTimeout: SESSION_TIMEOUT,

      // Actions
      login: async (credentials) => {
        set({ isLoading: true, error: null })
        
        try {
          console.log('Attempting login with credentials:', credentials)
          const response = await authApi.login(credentials)
          console.log('Login response:', response)
          
          // Store token immediately before making /auth/me/ call
          localStorage.setItem('auth_token', response.access)
          localStorage.setItem('refresh_token', response.refresh)
          
          // Get user info from /auth/me/ endpoint with explicit token
          console.log('Fetching user info...')
          const userResponse = await authApi.me()
          console.log('User response:', userResponse)
          
          set({
            user: userResponse as User,
            token: response.access,
            isAuthenticated: true,
            isLoading: false,
            lastActivity: Date.now(),
          })

          // Token already stored above
          
          // Track successful login
          behaviorTracker.trackAction('user-login', {
            userId: (userResponse as any)?.id,
            role: (userResponse as any)?.role,
          })
          
          // Set up session monitoring
          get().updateLastActivity()
          
        } catch (error: unknown) {
          const errorMessage = (error as any)?.response?.data?.message || (error as any)?.message || 'Login failed'
          
          set({
            error: errorMessage,
            isLoading: false,
          })

          // Track failed login
          behaviorTracker.trackAction('user-login-failed', {
            username: credentials.username,
            error: errorMessage,
          })

          errorTracker.captureError(error as Error, { context: 'login' })
          throw error
        }
      },

      logout: () => {
        const { user } = get()
        
        // Track logout
        if (user) {
          behaviorTracker.trackAction('user-logout', {
            userId: user.id,
          })
        }

        // Clear tokens from localStorage
        localStorage.removeItem('auth_token')
        localStorage.removeItem('refresh_token')
        
        // Reset state
        set({
          user: null,
          token: null,
          isAuthenticated: false,
          error: null,
          lastActivity: 0,
        })

        // Call logout API (fire and forget)
        authApi.logout().catch(() => {
          // Ignore errors on logout
        })
      },

      register: async (userData) => {
        set({ isLoading: true, error: null })
        
        try {
          const response = await authApi.register(userData)
          
          // Get user info from /auth/me/ endpoint
          const userResponse = await authApi.me()
          
          set({
            user: userResponse as User,
            token: response.access,
            isAuthenticated: true,
            isLoading: false,
            lastActivity: Date.now(),
          })

          // Store tokens in localStorage
          localStorage.setItem('auth_token', response.access)
          localStorage.setItem('refresh_token', response.refresh)
          
          // Track successful registration
          behaviorTracker.trackAction('user-register', {
            userId: (userResponse as any)?.id,
            role: (userResponse as any)?.role,
          })
          
        } catch (error: unknown) {
          const errorMessage = (error as any)?.response?.data?.message || (error as any)?.message || 'Registration failed'
          
          set({
            error: errorMessage,
            isLoading: false,
          })

          errorTracker.captureError(error as Error, { context: 'register' })
          throw error
        }
      },

      refreshToken: async () => {
        try {
          const response = await authApi.refreshToken()
          
          set({
            token: response.access,
            lastActivity: Date.now(),
          })

          // Update token in localStorage
          localStorage.setItem('auth_token', response.access)
          
        } catch (error: unknown) {
          // If refresh fails, logout user
          get().logout()
          throw error
        }
      },

      updateProfile: async (userData) => {
        set({ isLoading: true, error: null })
        
        try {
          const response = await authApi.updateProfile(userData)
          
          set({
            user: { ...get().user, ...(response as any).user },
            isLoading: false,
          })

          // Track profile update
          behaviorTracker.trackAction('user-profile-update', {
            userId: (response as any).user?.id,
            fields: Object.keys(userData),
          })
          
        } catch (error: unknown) {
          const errorMessage = (error as any)?.response?.data?.message || (error as any)?.message || 'Profile update failed'
          
          set({
            error: errorMessage,
            isLoading: false,
          })

          errorTracker.captureError(error as Error, { context: 'updateProfile' })
          throw error
        }
      },

      changePassword: async (passwords) => {
        set({ isLoading: true, error: null })
        
        try {
          await authApi.changePassword(passwords)
          
          set({ isLoading: false })

          // Track password change
          behaviorTracker.trackAction('user-password-change', {
            userId: get().user?.id,
          })
          
        } catch (error: unknown) {
          const errorMessage = (error as any)?.response?.data?.message || (error as any)?.message || 'Password change failed'
          
          set({
            error: errorMessage,
            isLoading: false,
          })

          errorTracker.captureError(error as Error, { context: 'changePassword' })
          throw error
        }
      },

      forgotPassword: async (email) => {
        set({ isLoading: true, error: null })
        
        try {
          await authApi.forgotPassword(email)
          
          set({ isLoading: false })

          // Track forgot password request
          behaviorTracker.trackAction('user-forgot-password', { email })
          
        } catch (error: unknown) {
          const errorMessage = (error as any)?.response?.data?.message || (error as any)?.message || 'Password reset failed'
          
          set({
            error: errorMessage,
            isLoading: false,
          })

          errorTracker.captureError(error as Error, { context: 'forgotPassword' })
          throw error
        }
      },

      resetPassword: async (token, password) => {
        set({ isLoading: true, error: null })
        
        try {
          await authApi.resetPassword(token, password)
          
          set({ isLoading: false })

          // Track password reset
          behaviorTracker.trackAction('user-password-reset')
          
        } catch (error: unknown) {
          const errorMessage = (error as any)?.response?.data?.message || (error as any)?.message || 'Password reset failed'
          
          set({
            error: errorMessage,
            isLoading: false,
          })

          errorTracker.captureError(error as Error, { context: 'resetPassword' })
          throw error
        }
      },

      verifyEmail: async (token) => {
        set({ isLoading: true, error: null })
        
        try {
          await authApi.verifyEmail(token)
          
          set({ isLoading: false })

          // Track email verification
          behaviorTracker.trackAction('user-email-verify')
          
        } catch (error: unknown) {
          const errorMessage = (error as any)?.response?.data?.message || (error as any)?.message || 'Email verification failed'
          
          set({
            error: errorMessage,
            isLoading: false,
          })

          errorTracker.captureError(error as Error, { context: 'verifyEmail' })
          throw error
        }
      },

      resendVerification: async () => {
        set({ isLoading: true, error: null })
        
        try {
          await authApi.resendVerification()
          
          set({ isLoading: false })

          // Track verification resend
          behaviorTracker.trackAction('user-verification-resend')
          
        } catch (error: unknown) {
          const errorMessage = (error as any)?.response?.data?.message || (error as any)?.message || 'Failed to resend verification'
          
          set({
            error: errorMessage,
            isLoading: false,
          })

          errorTracker.captureError(error as Error, { context: 'resendVerification' })
          throw error
        }
      },

      setLoading: (loading) => set({ isLoading: loading }),
      setError: (error) => set({ error }),
      clearError: () => set({ error: null }),

      updateLastActivity: () => {
        set({ lastActivity: Date.now() })
      },

      checkSession: () => {
        const { lastActivity, sessionTimeout, isAuthenticated } = get()
        
        if (!isAuthenticated) {
          return false
        }

        const now = Date.now()
        const timeSinceLastActivity = now - lastActivity

        if (timeSinceLastActivity > sessionTimeout) {
          get().logout()
          return false
        }

        return true
      },

      hasPermission: (_permission) => {
        // For now, return true for all permissions since Django backend doesn't have permissions field
        return true
      },

      hasRole: (role) => {
        const { user } = get()
        return user?.role === role
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
        lastActivity: state.lastActivity,
      }),
    }
  )
)

// Session monitoring
let sessionCheckInterval: NodeJS.Timeout | null = null

export const startSessionMonitoring = () => {
  if (sessionCheckInterval) {
    clearInterval(sessionCheckInterval)
  }

  sessionCheckInterval = setInterval(() => {
    const { checkSession } = useAuthStore.getState()
    checkSession()
  }, 60000) // Check every minute
}

export const stopSessionMonitoring = () => {
  if (sessionCheckInterval) {
    clearInterval(sessionCheckInterval)
    sessionCheckInterval = null
  }
}

// Activity tracking
export const trackUserActivity = () => {
  const { updateLastActivity } = useAuthStore.getState()
  updateLastActivity()
}

// Set up global activity tracking
if (typeof window !== 'undefined') {
  const events = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart']
  
  events.forEach(event => {
    document.addEventListener(event, trackUserActivity, true)
  })
}