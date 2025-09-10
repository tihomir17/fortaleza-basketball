import type { ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { useAuthStore } from '../../store/authStore'
import { behaviorTracker } from '../../utils/monitoring'

interface ProtectedRouteProps {
  children: ReactNode
  requiredPermissions?: string[]
  requiredRole?: string
  fallback?: ReactNode
}

export function ProtectedRoute({
  children,
  requiredPermissions = [],
  requiredRole,
  fallback,
}: ProtectedRouteProps) {
  const { isAuthenticated, user, hasPermission, hasRole } = useAuthStore()
  const location = useLocation()

  // Track route access attempts
  behaviorTracker.trackAction('route-access-attempt', {
    path: location.pathname,
    isAuthenticated,
    requiredPermissions,
    requiredRole,
  })

  // Check authentication
  if (!isAuthenticated || !user) {
    behaviorTracker.trackAction('route-access-denied', {
      reason: 'not-authenticated',
      path: location.pathname,
    })
    
    return <Navigate to="/login" state={{ from: location }} replace />
  }

  // Check role requirement
  if (requiredRole && !hasRole(requiredRole)) {
    behaviorTracker.trackAction('route-access-denied', {
      reason: 'insufficient-role',
      path: location.pathname,
      userRole: user.role,
      requiredRole,
    })
    
    return fallback || <Navigate to="/unauthorized" replace />
  }

  // Check permission requirements
  if (requiredPermissions.length > 0) {
    const hasAllPermissions = requiredPermissions.every(permission => 
      hasPermission(permission)
    )

    if (!hasAllPermissions) {
      behaviorTracker.trackAction('route-access-denied', {
        reason: 'insufficient-permissions',
        path: location.pathname,
        userRole: user.role,
        requiredPermissions,
      })
      
      return fallback || <Navigate to="/unauthorized" replace />
    }
  }

  // Track successful route access
  behaviorTracker.trackAction('route-access-granted', {
    path: location.pathname,
    userRole: user.role,
  })

  return <>{children}</>
}

// Higher-order component for protecting routes
export function withAuth<T extends object>(
  Component: React.ComponentType<T>,
  options?: {
    requiredPermissions?: string[]
    requiredRole?: string
    fallback?: ReactNode
  }
) {
  return function AuthenticatedComponent(props: T) {
    return (
      <ProtectedRoute
        requiredPermissions={options?.requiredPermissions}
        requiredRole={options?.requiredRole}
        fallback={options?.fallback}
      >
        <Component {...props} />
      </ProtectedRoute>
    )
  }
}

// Hook for checking permissions in components
export function usePermissions() {
  const { user, hasPermission, hasRole } = useAuthStore()

  return {
    user,
    hasPermission,
    hasRole,
    isAuthenticated: !!user,
    canAccess: (permissions: string[], role?: string) => {
      if (role && !hasRole(role)) return false
      return permissions.every(permission => hasPermission(permission))
    },
  }
}
