import axios from 'axios'
import type { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios'
// import type { ApiResponse, ApiError, ApiRequestConfig } from '../types/api'
import { retryNetworkOperation, retryAuthOperation } from '../utils/retry'
// import { handleApiError, isRetryableError } from '../utils/errorHandler'

// API Configuration
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api'
const ADMIN_API_BASE_URL = import.meta.env.VITE_ADMIN_API_BASE_URL || 'http://localhost:8000'
const API_TIMEOUT = 30000 // 30 seconds

// Create axios instance
const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  timeout: API_TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Create admin axios instance for admin endpoints
const adminApiClient: AxiosInstance = axios.create({
  baseURL: ADMIN_API_BASE_URL,
  timeout: API_TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor to add auth token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Admin API request interceptor to add auth token
adminApiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor for error handling
apiClient.interceptors.response.use(
  (response: AxiosResponse) => {
    return response
  },
  async (error) => {
    const originalRequest = error.config

    // Handle 401 errors (unauthorized)
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true
      
      // Try to refresh token first
      const refreshToken = localStorage.getItem('refresh_token')
      if (refreshToken) {
        try {
          console.log('Attempting to refresh token...')
          const refreshResponse = await fetch(`${API_BASE_URL}/auth/login/refresh/`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ refresh: refreshToken }),
          })
          
          if (refreshResponse.ok) {
            const tokenData = await refreshResponse.json()
            localStorage.setItem('auth_token', tokenData.access)
            
            // Retry original request with new token
            originalRequest.headers.Authorization = `Bearer ${tokenData.access}`
            return apiClient(originalRequest)
          }
        } catch (refreshError) {
          console.warn('Token refresh failed:', refreshError)
        }
      }
      
      // If refresh fails or no refresh token, clear tokens and redirect
      localStorage.removeItem('auth_token')
      localStorage.removeItem('refresh_token')
      
      // In development, don't hard-redirect; allow pages to render with mocks/bypass
      if (import.meta.env.PROD) {
        // Redirect to login page in production
        window.location.href = '/login'
      } else {
        console.warn('401 Unauthorized in development - bypassing redirect to /login')
      }
      
      return Promise.reject(error)
    }

    // Handle network errors
    if (!error.response) {
      error.message = 'Network error. Please check your connection.'
    }

    return Promise.reject(error)
  }
)

// Admin API response interceptor for error handling
adminApiClient.interceptors.response.use(
  (response: AxiosResponse) => {
    return response
  },
  async (error) => {
    const originalRequest = error.config

    // Handle 401 errors (unauthorized)
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true
      
      // Try to refresh token first
      const refreshToken = localStorage.getItem('refresh_token')
      if (refreshToken) {
        try {
          console.log('Attempting to refresh token for admin API...')
          const refreshResponse = await fetch(`${ADMIN_API_BASE_URL}/api/auth/login/refresh/`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ refresh: refreshToken }),
          })
          
          if (refreshResponse.ok) {
            const tokenData = await refreshResponse.json()
            localStorage.setItem('auth_token', tokenData.access)
            
            // Retry original request with new token
            originalRequest.headers.Authorization = `Bearer ${tokenData.access}`
            return adminApiClient(originalRequest)
          }
        } catch (refreshError) {
          console.warn('Token refresh failed for admin API:', refreshError)
        }
      }
      
      // If refresh fails or no refresh token, clear tokens and redirect
      localStorage.removeItem('auth_token')
      localStorage.removeItem('refresh_token')
      
      // In development, don't hard-redirect; allow pages to render with mocks/bypass
      if (import.meta.env.PROD) {
        // Redirect to login page in production
        window.location.href = '/login'
      } else {
        console.warn('401 Unauthorized in development - bypassing redirect to /login')
      }
      
      return Promise.reject(error)
    }

    // Handle network errors
    if (!error.response) {
      error.message = 'Network error. Please check your connection.'
    }

    return Promise.reject(error)
  }
)

// Generic API methods with retry logic
export const api = {
  get: <T = unknown>(url: string, config?: AxiosRequestConfig): Promise<T> =>
    retryNetworkOperation(() => 
      apiClient.get(url, config).then(response => response.data)
    ),
    
  post: <T = unknown>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> =>
    retryNetworkOperation(() => 
      apiClient.post(url, data, config).then(response => response.data)
    ),
    
  put: <T = unknown>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> =>
    retryNetworkOperation(() => 
      apiClient.put(url, data, config).then(response => response.data)
    ),
    
  patch: <T = unknown>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> =>
    retryNetworkOperation(() => 
      apiClient.patch(url, data, config).then(response => response.data)
    ),
    
  delete: <T = unknown>(url: string, config?: AxiosRequestConfig): Promise<T> =>
    retryNetworkOperation(() => 
      apiClient.delete(url, config).then(response => response.data)
    ),
}

// Admin API methods for admin endpoints (without /api prefix)
export const adminApi = {
  get: <T = unknown>(url: string, config?: AxiosRequestConfig): Promise<T> =>
    retryNetworkOperation(() => 
      adminApiClient.get(url, config).then(response => response.data)
    ),
    
  post: <T = unknown>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> =>
    retryNetworkOperation(() => 
      adminApiClient.post(url, data, config).then(response => response.data)
    ),
    
  put: <T = unknown>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> =>
    retryNetworkOperation(() => 
      adminApiClient.put(url, data, config).then(response => response.data)
    ),
    
  patch: <T = unknown>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> =>
    retryNetworkOperation(() => 
      adminApiClient.patch(url, data, config).then(response => response.data)
    ),
    
  delete: <T = unknown>(url: string, config?: AxiosRequestConfig): Promise<T> =>
    retryNetworkOperation(() => 
      adminApiClient.delete(url, config).then(response => response.data)
    ),
}

// Authentication API for Django backend
export const authApi = {
  login: (credentials: { username: string; password: string }) => {
    console.log('Using real backend authentication')
    console.log('API Base URL:', API_BASE_URL)
    console.log('Login endpoint:', `${API_BASE_URL}/auth/login/`)
    return api.post<{ access: string; refresh: string }>('/auth/login/', credentials)
  },
  
  logout: () => {
    // Django doesn't have a logout endpoint, just clear tokens
    return Promise.resolve({})
  },
  
  me: () => {
    console.log('Fetching user info from /auth/me/')
    const token = localStorage.getItem('auth_token')
    console.log('Token for /auth/me/ call:', token ? 'Present' : 'Missing')
    return api.get<{
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
    }>('/auth/me/', {
      headers: {
        Authorization: `Bearer ${token}`
      }
    })
  },
  
  refreshToken: () => {
    if (import.meta.env.VITE_USE_MOCKS === 'true') {
      return Promise.resolve({ access: 'mock-access-token' })
    }
    return retryAuthOperation(() => 
      api.post<{ access: string }>('/auth/login/refresh/')
    )
  },
  
  forgotPassword: (email: string) => {
    if (import.meta.env.VITE_USE_MOCKS === 'true') {
      return Promise.resolve({ message: 'Password reset email sent' })
    }
    return api.post('/auth/forgot-password', { email })
  },
  
  resetPassword: (token: string, password: string) => {
    if (import.meta.env.VITE_USE_MOCKS === 'true') {
      return Promise.resolve({ message: 'Password reset successful' })
    }
    return api.post('/auth/reset-password', { token, password })
  },
  
  register: (userData: {
    username: string
    email: string
    password: string
    first_name: string
    last_name: string
    role?: string
  }) => {
    if (import.meta.env.VITE_USE_MOCKS === 'true') {
      return Promise.resolve({
        access: 'mock-access-token',
        refresh: 'mock-refresh-token'
      })
    }
    return api.post<{ access: string; refresh: string }>('/auth/register/', userData)
  },
  
  updateProfile: (userData: unknown) => {
    if (import.meta.env.VITE_USE_MOCKS === 'true') {
      return Promise.resolve({ user: userData })
    }
    return api.put<{ user: unknown }>('/auth/profile', userData)
  },
  
  changePassword: (passwords: unknown) => {
    if (import.meta.env.VITE_USE_MOCKS === 'true') {
      return Promise.resolve({ message: 'Password changed successfully' })
    }
    return api.post('/auth/change-password', passwords)
  },
  
  verifyEmail: (token: string) => {
    if (import.meta.env.VITE_USE_MOCKS === 'true') {
      return Promise.resolve({ message: 'Email verified successfully' })
    }
    return api.post('/auth/verify-email', { token })
  },
  
  resendVerification: () => {
    if (import.meta.env.VITE_USE_MOCKS === 'true') {
      return Promise.resolve({ message: 'Verification email sent' })
    }
    return api.post('/auth/resend-verification')
  },
}

// Games API
export const gamesApi = {
  getGames: (params?: { page?: number; limit?: number; search?: string; status?: string }) =>
    api.get<{ data: unknown[]; pagination: unknown }>('/games', { params }),
    
  getGame: (id: string) =>
    api.get<unknown>(`/games/${id}`),
    
  createGame: (gameData: unknown) =>
    api.post<unknown>('/games', gameData),
    
  updateGame: (id: string, gameData: unknown) =>
    api.put<unknown>(`/games/${id}`, gameData),
    
  deleteGame: (id: string) =>
    api.delete(`/games/${id}`),
    
  getUpcomingGames: () =>
    api.get<unknown[]>('/games/upcoming'),
    
  getRecentGames: () =>
    api.get<unknown[]>('/games/recent'),
}

// Teams API
export const teamsApi = {
  getTeams: (params?: { page?: number; limit?: number; search?: string }) =>
    api.get<{ data: unknown[]; pagination: unknown }>('/teams', { params }),
    
  getTeam: (id: string) =>
    api.get<unknown>(`/teams/${id}`),
    
  createTeam: (teamData: unknown) =>
    api.post<unknown>('/teams', teamData),
    
  updateTeam: (id: string, teamData: unknown) =>
    api.put<unknown>(`/teams/${id}`, teamData),
    
  deleteTeam: (id: string) =>
    api.delete(`/teams/${id}`),
    
  getTeamPlayers: (id: string) =>
    api.get<unknown[]>(`/teams/${id}/players`),
    
  addPlayerToTeam: (teamId: string, playerId: string) =>
    api.post(`/teams/${teamId}/players`, { player_id: playerId }),
    
  removePlayerFromTeam: (teamId: string, playerId: string) =>
    api.delete(`/teams/${teamId}/players/${playerId}`),
}

// Players API
export const playersApi = {
  getPlayers: (params?: { page?: number; limit?: number; search?: string; team_id?: string }) =>
    api.get<{ data: unknown[]; pagination: unknown }>('/players', { params }),
    
  getPlayer: (id: string) =>
    api.get<unknown>(`/players/${id}`),
    
  createPlayer: (playerData: unknown) =>
    api.post<unknown>('/players', playerData),
    
  updatePlayer: (id: string, playerData: unknown) =>
    api.put<unknown>(`/players/${id}`, playerData),
    
  deletePlayer: (id: string) =>
    api.delete(`/players/${id}`),
    
  getPlayerStats: (id: string) =>
    api.get<unknown>(`/players/${id}/stats`),
}

// Users API
export const usersApi = {
  getUsers: (params?: { page?: number; limit?: number; search?: string; role?: string; status?: string }) =>
    api.get<{ data: unknown[]; pagination: unknown }>('/users', { params }),
    
  getUser: (id: string) =>
    api.get<unknown>(`/users/${id}`),
    
  createUser: (userData: unknown) =>
    api.post<unknown>('/users', userData),
    
  updateUser: (id: string, userData: unknown) =>
    api.put<unknown>(`/users/${id}`, userData),
    
  deleteUser: (id: string) =>
    api.delete(`/users/${id}`),
    
  resetUserPassword: (id: string) =>
    api.post(`/users/${id}/reset-password`),
    
  toggleUserStatus: (id: string) =>
    api.patch(`/users/${id}/toggle-status`),
}

// Playbook API - Using existing backend endpoints
export const playbookApi = {
  getPlays: (params?: { category?: string; difficulty?: string; search?: string; tags?: string; is_favorite?: boolean }) =>
    api.get<{ results: unknown[]; count: number }>('/plays/', { params }),
    
  getPlay: (id: string) =>
    api.get<unknown>(`/plays/${id}/`),
    
  createPlay: (playData: unknown) =>
    api.post<unknown>('/plays/', playData),
    
  updatePlay: (id: string, playData: unknown) =>
    api.put<unknown>(`/plays/${id}/`, playData),
    
  deletePlay: (id: string) =>
    api.delete(`/plays/${id}/`),
    
  duplicatePlay: (id: string, newName?: string) =>
    api.post<unknown>(`/plays/${id}/duplicate/`, { name: newName }),
    
  toggleFavorite: (id: string) =>
    api.patch<unknown>(`/plays/${id}/favorite/`),
    
  updatePlayOrder: (playIds: string[]) =>
    api.patch('/plays/order/', { play_ids: playIds }),
    
  getCategories: () =>
    api.get<{ results: string[] }>('/play-categories/'),
    
  getDifficulties: () =>
    api.get<{ difficulties: string[] }>('/plays/difficulties/'),
    
  getTags: () =>
    api.get<{ tags: string[] }>('/plays/tags/'),
    
  getPlayStats: () =>
    api.get<unknown>('/plays/stats/')
}

// Analytics API
export const analyticsApi = {
  getDashboardStats: () =>
    api.get<unknown>('/analytics/dashboard'),
    
  getGameStats: (gameId: string) =>
    api.get<unknown>(`/analytics/games/${gameId}`),
    
  getPlayerStats: (playerId: string) =>
    api.get<unknown>(`/analytics/players/${playerId}`),
    
  getTeamStats: (teamId: string) =>
    api.get<unknown>(`/analytics/teams/${teamId}`),
    
  getTrends: (params?: { period?: string; metric?: string }) =>
    api.get<unknown>('/analytics/trends', { params }),
}

// Events API
export const eventsApi = {
  getEvents: (params?: { page?: number; limit?: number; search?: string; game_id?: string }) =>
    api.get<{ data: unknown[]; pagination: unknown }>('/events', { params }),
    
  getEvent: (id: string) =>
    api.get<unknown>(`/events/${id}`),
    
  createEvent: (eventData: unknown) =>
    api.post<unknown>('/events', eventData),
    
  updateEvent: (id: string, eventData: unknown) =>
    api.put<unknown>(`/events/${id}`, eventData),
    
  deleteEvent: (id: string) =>
    api.delete(`/events/${id}`),
}

// Possessions API
export const possessionsApi = {
  getPossessions: (params?: { page?: number; limit?: number; search?: string; game_id?: string }) =>
    api.get<{ data: unknown[]; pagination: unknown }>('/possessions', { params }),
    
  getPossession: (id: string) =>
    api.get<unknown>(`/possessions/${id}`),
    
  createPossession: (possessionData: unknown) =>
    api.post<unknown>('/possessions', possessionData),
    
  updatePossession: (id: string, possessionData: unknown) =>
    api.put<unknown>(`/possessions/${id}`, possessionData),
    
  deletePossession: (id: string) =>
    api.delete(`/possessions/${id}`),
}

// File upload API
export const uploadApi = {
  uploadFile: (file: File, endpoint: string) => {
    const formData = new FormData()
    formData.append('file', file)
    
    return api.post<unknown>(`/upload/${endpoint}`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    })
  },
  
  uploadImage: (file: File) => uploadApi.uploadFile(file, 'image'),
  uploadDocument: (file: File) => uploadApi.uploadFile(file, 'document'),
}

// Export API
export const exportApi = {
  exportGames: (format: 'excel' | 'csv' | 'pdf', params?: unknown) =>
    api.get(`/export/games.${format}`, { 
      params,
      responseType: 'blob'
    }),
    
  exportPlayers: (format: 'excel' | 'csv' | 'pdf', params?: unknown) =>
    api.get(`/export/players.${format}`, { 
      params,
      responseType: 'blob'
    }),
    
  exportTeams: (format: 'excel' | 'csv' | 'pdf', params?: unknown) =>
    api.get(`/export/teams.${format}`, { 
      params,
      responseType: 'blob'
    }),
    
  exportUsers: (format: 'excel' | 'csv' | 'pdf', params?: unknown) =>
    api.get(`/export/users.${format}`, { 
      params,
      responseType: 'blob'
    }),
}

export default api