import api from './api'

export interface User {
  id: number
  username: string
  email: string
  first_name: string
  last_name: string
  role: string
  staff_type?: string
}

export interface LoginCredentials {
  username: string
  password: string
}

export interface AuthResponse {
  access: string
  refresh: string
  user: User
}

export const authService = {
  async login(credentials: LoginCredentials): Promise<AuthResponse> {
    const response = await api.post('/auth/login/', credentials)
    const { access, refresh, user } = (response as any).data
    
    // Store tokens
    localStorage.setItem('authToken', access)
    localStorage.setItem('refreshToken', refresh)
    localStorage.setItem('user', JSON.stringify(user))
    
    return { access, refresh, user }
  },

  async logout(): Promise<void> {
    try {
      await api.post('/auth/logout/')
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      // Clear local storage regardless of API call success
      localStorage.removeItem('authToken')
      localStorage.removeItem('refreshToken')
      localStorage.removeItem('user')
    }
  },

  async refreshToken(): Promise<string> {
    const refreshToken = localStorage.getItem('refreshToken')
    if (!refreshToken) {
      throw new Error('No refresh token available')
    }

    const response = await api.post('/auth/refresh/', {
      refresh: refreshToken
    })
    
    const { access } = (response as any).data
    localStorage.setItem('authToken', access)
    
    return access
  },

  getCurrentUser(): User | null {
    const userStr = localStorage.getItem('user')
    return userStr ? JSON.parse(userStr) : null
  },

  isAuthenticated(): boolean {
    return !!localStorage.getItem('authToken')
  },

  async changePassword(oldPassword: string, newPassword: string): Promise<void> {
    await api.post('/auth/change-password/', {
      old_password: oldPassword,
      new_password: newPassword
    })
  }
}
