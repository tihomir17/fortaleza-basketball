import { useAuthStore } from '../store/authStore'
import { Login } from '../pages/Login'

interface ProtectedRouteProps {
  children: React.ReactNode
}

export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const { isAuthenticated } = useAuthStore()

  // Check authentication - show login if not authenticated
  if (!isAuthenticated) {
    return <Login />
  }

  return <>{children}</>
}
