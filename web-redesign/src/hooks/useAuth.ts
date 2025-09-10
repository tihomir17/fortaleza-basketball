import { useCallback, useEffect } from 'react'
import { useApi } from './useApi'
import { authApi } from '../services/api'
import { useAuthStore } from '../store/authStore'

export function useAuth() {
  const { user, isAuthenticated, login: storeLogin, logout: storeLogout, setLoading, setError } = useAuthStore()

  const { loading: loginLoading, error: loginError } = useApi(
    () => Promise.resolve(),
    { immediate: false }
  )

  const { execute: logoutApi, loading: logoutLoading } = useApi(
    () => authApi.logout(),
    { immediate: false }
  )

  const { execute: meApi, loading: meLoading } = useApi(
    () => authApi.me(),
    { immediate: false }
  )

  const login = useCallback(async (credentials: { email: string; password: string }) => {
    try {
      setLoading(true)
      setError(null)
      
      const response = await authApi.login(credentials)
      
      // Store token
      localStorage.setItem('auth_token', response.token)
      
      // Update store
      storeLogin(response as any)
      
      return response
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || error.message || 'Login failed'
      setError(errorMessage)
      throw error
    } finally {
      setLoading(false)
    }
  }, [storeLogin, setLoading, setError])

  const logout = useCallback(async () => {
    try {
      setLoading(true)
      
      // Call logout API
      await logoutApi()
    } catch {
      // Continue with logout even if API call fails
      console.error('Logout API error')
    } finally {
      // Clear local storage
      localStorage.removeItem('auth_token')
      
      // Update store
      storeLogout()
      setLoading(false)
    }
  }, [logoutApi, storeLogout, setLoading])

  const checkAuth = useCallback(async () => {
    const token = localStorage.getItem('auth_token')
    
    if (!token) {
      return false
    }

    try {
      setLoading(true)
      const user = await meApi()
      storeLogin(user as any)
      return true
    } catch {
      // Token is invalid, clear it
      localStorage.removeItem('auth_token')
      storeLogout()
      return false
    } finally {
      setLoading(false)
    }
  }, [meApi, storeLogin, storeLogout, setLoading])

  const refreshToken = useCallback(async () => {
    try {
      const response = await authApi.refreshToken()
      localStorage.setItem('auth_token', response.token)
      return response.token
    } catch {
      // Refresh failed, logout user
      await logout()
      throw new Error('Authentication failed')
    }
  }, [logout])

  const forgotPassword = useCallback(async (email: string) => {
    try {
      await authApi.forgotPassword(email)
      return true
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to send reset email'
      setError(errorMessage)
      throw error
    }
  }, [setError])

  const resetPassword = useCallback(async (token: string, password: string) => {
    try {
      await authApi.resetPassword(token, password)
      return true
    } catch (error: any) {
      const errorMessage = error.response?.data?.message || error.message || 'Failed to reset password'
      setError(errorMessage)
      throw error
    }
  }, [setError])

  // Check authentication on mount
  useEffect(() => {
    checkAuth()
  }, [checkAuth])

  return {
    user,
    isAuthenticated,
    loading: loginLoading || logoutLoading || meLoading,
    error: loginError,
    login,
    logout,
    checkAuth,
    refreshToken,
    forgotPassword,
    resetPassword,
  }
}
