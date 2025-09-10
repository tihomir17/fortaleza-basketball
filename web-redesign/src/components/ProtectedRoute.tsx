// import { useEffect } from 'react'
import { useAuthStore } from '../store/authStore'
import { Login } from '../pages/Login'

interface ProtectedRouteProps {
  children: React.ReactNode
}

export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const { isAuthenticated } = useAuthStore()

  // For development, bypass authentication
  // TODO: Remove this in production
  const isDevelopment = import.meta.env.DEV
  
  // In development mode, always allow access
  if (isDevelopment) {
    return <>{children}</>
  }
  
  // In production, check authentication
  if (!isAuthenticated) {
    return <Login />
  }

  return <>{children}</>
}
