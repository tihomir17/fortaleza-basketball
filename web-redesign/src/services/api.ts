import axios from 'axios'
import type { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios'
// import type { ApiResponse, ApiError, ApiRequestConfig } from '../types/api'
import { retryNetworkOperation, retryAuthOperation } from '../utils/retry'
// import { handleApiError, isRetryableError } from '../utils/errorHandler'

// API Configuration
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api'
const API_TIMEOUT = 30000 // 30 seconds

// Create axios instance
const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
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
      
      // Clear stored token
      localStorage.removeItem('auth_token')
      
      // Redirect to login page
      window.location.href = '/login'
      
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

// Authentication API with special retry logic
export const authApi = {
  login: (credentials: { email: string; password: string }) =>
    retryAuthOperation(() =>
      api.post<{ user: unknown; token: string }>('/auth/login', credentials)
    ),
    
  logout: () =>
    api.post('/auth/logout'),
    
  me: () =>
    retryAuthOperation(() =>
      api.get<unknown>('/auth/me')
    ),
    
  refreshToken: () =>
    retryAuthOperation(() => 
      api.post<{ token: string }>('/auth/refresh')
    ),
    
  forgotPassword: (email: string) =>
    api.post('/auth/forgot-password', { email }),
    
  resetPassword: (token: string, password: string) =>
    api.post('/auth/reset-password', { token, password }),
    
  register: (userData: unknown) =>
    api.post<{ user: unknown; token: string }>('/auth/register', userData),
    
  updateProfile: (userData: unknown) =>
    api.put<{ user: unknown }>('/auth/profile', userData),
    
  changePassword: (passwords: unknown) =>
    api.post('/auth/change-password', passwords),
    
  verifyEmail: (token: string) =>
    api.post('/auth/verify-email', { token }),
    
  resendVerification: () =>
    api.post('/auth/resend-verification'),
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