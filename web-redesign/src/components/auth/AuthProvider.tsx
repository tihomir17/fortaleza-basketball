import { useEffect } from 'react'
import type { ReactNode } from 'react'
import { useAuthStore, startSessionMonitoring, stopSessionMonitoring } from '../../store/authStore'
import { errorTracker, behaviorTracker } from '../../utils/monitoring'

interface AuthProviderProps {
  children: ReactNode
}

export function AuthProvider({ children }: AuthProviderProps) {
  const { 
    isAuthenticated, 
    // token, 
    user, 
    checkSession,
    setError,
    clearError 
  } = useAuthStore()

  // Initialize authentication on mount
  useEffect(() => {
    const initializeAuth = async () => {
      try {
        // Check if there's a stored token
        const storedToken = localStorage.getItem('auth_token')
        
        if (storedToken && !isAuthenticated) {
          // Verify token with backend
          const response = await fetch('/api/auth/me', {
            headers: {
              'Authorization': `Bearer ${storedToken}`,
            },
          })

          if (response.ok) {
            const userData = await response.json()
            
            // Update store with user data
            useAuthStore.setState({
              user: userData,
              token: storedToken,
              isAuthenticated: true,
              lastActivity: Date.now(),
            })

            behaviorTracker.trackAction('user-session-restored', {
              userId: userData.id,
            })
          } else {
            // Token is invalid, clear it
            localStorage.removeItem('auth_token')
            behaviorTracker.trackAction('user-session-invalid')
          }
        }
      } catch (error) {
        console.error('Auth initialization error:', error)
        errorTracker.captureError(error as Error, { context: 'auth-initialization' })
      }
    }

    initializeAuth()
  }, [])

  // Set up session monitoring
  useEffect(() => {
    if (isAuthenticated) {
      startSessionMonitoring()
      
      // Set up periodic session checks
      const sessionCheckInterval = setInterval(() => {
        const isValid = checkSession()
        if (!isValid) {
          behaviorTracker.trackAction('user-session-expired')
        }
      }, 60000) // Check every minute

      return () => {
        clearInterval(sessionCheckInterval)
        stopSessionMonitoring()
      }
    } else {
      stopSessionMonitoring()
    }
  }, [isAuthenticated, checkSession])

  // Set up global error handling
  useEffect(() => {
    const handleGlobalError = (event: ErrorEvent) => {
      errorTracker.captureError(event.error, {
        context: 'global-error',
        filename: event.filename,
        lineno: event.lineno,
        colno: event.colno,
      })
    }

    const handleUnhandledRejection = (event: PromiseRejectionEvent) => {
      errorTracker.captureError(new Error(event.reason), {
        context: 'unhandled-promise-rejection',
      })
    }

    window.addEventListener('error', handleGlobalError)
    window.addEventListener('unhandledrejection', handleUnhandledRejection)

    return () => {
      window.removeEventListener('error', handleGlobalError)
      window.removeEventListener('unhandledrejection', handleUnhandledRejection)
    }
  }, [])

  // Set up user context for monitoring
  useEffect(() => {
    if (user) {
      errorTracker.setUser({
        id: user.id,
        email: user.email,
        username: user.firstName + ' ' + user.lastName,
      })
    }
  }, [user])

  // Handle network status changes
  useEffect(() => {
    const handleOnline = () => {
      behaviorTracker.trackAction('network-online')
      clearError()
    }

    const handleOffline = () => {
      behaviorTracker.trackAction('network-offline')
      setError('You are currently offline. Some features may not be available.')
    }

    window.addEventListener('online', handleOnline)
    window.addEventListener('offline', handleOffline)

    return () => {
      window.removeEventListener('online', handleOnline)
      window.removeEventListener('offline', handleOffline)
    }
  }, [clearError, setError])

  // Handle visibility changes (tab focus/blur)
  useEffect(() => {
    const handleVisibilityChange = () => {
      if (document.hidden) {
        behaviorTracker.trackAction('tab-hidden')
      } else {
        behaviorTracker.trackAction('tab-visible')
        // Update last activity when user returns to tab
        if (isAuthenticated) {
          useAuthStore.getState().updateLastActivity()
        }
      }
    }

    document.addEventListener('visibilitychange', handleVisibilityChange)

    return () => {
      document.removeEventListener('visibilitychange', handleVisibilityChange)
    }
  }, [isAuthenticated])

  return <>{children}</>
}

// Hook for authentication status
export function useAuth() {
  const authStore = useAuthStore()
  
  return {
    ...authStore,
    // Additional computed properties
    isAdmin: authStore.hasRole('admin'),
    isCoach: authStore.hasRole('coach'),
    isPlayer: authStore.hasRole('player'),
    isViewer: authStore.hasRole('viewer'),
    canManageUsers: authStore.hasPermission('users:manage'),
    canManageGames: authStore.hasPermission('games:manage'),
    canManageTeams: authStore.hasPermission('teams:manage'),
    canViewAnalytics: authStore.hasPermission('analytics:view'),
  }
}
