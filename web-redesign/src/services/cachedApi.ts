import { api } from './api'
import { withCache, cacheKeys, cacheStrategies } from '../utils/cache'

// Cached API methods
export const cachedApi = {
  // Games
  getGames: (params?: { page?: number; limit?: number; search?: string; status?: string }) =>
    withCache(
      cacheKeys.games(params),
      () => api.get('/games', { params }),
      { ttl: 2 * 60 * 1000 } // 2 minutes
    ),

  getGame: (id: string) =>
    withCache(
      cacheKeys.game(id),
      () => api.get(`/games/${id}`),
      { ttl: 5 * 60 * 1000 } // 5 minutes
    ),

  createGame: (gameData: any) =>
    api.post('/games', gameData).then(result => {
      cacheStrategies.invalidateOnMutation('games')
      return result
    }),

  updateGame: (id: string, gameData: any) =>
    api.put(`/games/${id}`, gameData).then(result => {
      cacheStrategies.invalidateOnMutation('games', id)
      return result
    }),

  deleteGame: (id: string) =>
    api.delete(`/games/${id}`).then(result => {
      cacheStrategies.invalidateOnMutation('games', id)
      return result
    }),

  // Teams
  getTeams: (params?: { page?: number; limit?: number; search?: string }) =>
    withCache(
      cacheKeys.teams(params),
      () => api.get('/teams', { params }),
      { ttl: 5 * 60 * 1000 } // 5 minutes
    ),

  getTeam: (id: string) =>
    withCache(
      cacheKeys.team(id),
      () => api.get(`/teams/${id}`),
      { ttl: 10 * 60 * 1000 } // 10 minutes
    ),

  createTeam: (teamData: any) =>
    api.post('/teams', teamData).then(result => {
      cacheStrategies.invalidateOnMutation('teams')
      return result
    }),

  updateTeam: (id: string, teamData: any) =>
    api.put(`/teams/${id}`, teamData).then(result => {
      cacheStrategies.invalidateOnMutation('teams', id)
      return result
    }),

  deleteTeam: (id: string) =>
    api.delete(`/teams/${id}`).then(result => {
      cacheStrategies.invalidateOnMutation('teams', id)
      return result
    }),

  // Players
  getPlayers: (params?: { page?: number; limit?: number; search?: string; team_id?: string }) =>
    withCache(
      cacheKeys.players(params),
      () => api.get('/players', { params }),
      { ttl: 3 * 60 * 1000 } // 3 minutes
    ),

  getPlayer: (id: string) =>
    withCache(
      cacheKeys.player(id),
      () => api.get(`/players/${id}`),
      { ttl: 5 * 60 * 1000 } // 5 minutes
    ),

  createPlayer: (playerData: any) =>
    api.post('/players', playerData).then(result => {
      cacheStrategies.invalidateOnMutation('players')
      return result
    }),

  updatePlayer: (id: string, playerData: any) =>
    api.put(`/players/${id}`, playerData).then(result => {
      cacheStrategies.invalidateOnMutation('players', id)
      return result
    }),

  deletePlayer: (id: string) =>
    api.delete(`/players/${id}`).then(result => {
      cacheStrategies.invalidateOnMutation('players', id)
      return result
    }),

  // Users
  getUsers: (params?: { page?: number; limit?: number; search?: string; role?: string; status?: string }) =>
    withCache(
      cacheKeys.users(params),
      () => api.get('/users', { params }),
      { ttl: 2 * 60 * 1000 } // 2 minutes
    ),

  getUser: (id: string) =>
    withCache(
      cacheKeys.user(id),
      () => api.get(`/users/${id}`),
      { ttl: 5 * 60 * 1000 } // 5 minutes
    ),

  createUser: (userData: any) =>
    api.post('/users', userData).then(result => {
      cacheStrategies.invalidateOnMutation('users')
      return result
    }),

  updateUser: (id: string, userData: any) =>
    api.put(`/users/${id}`, userData).then(result => {
      cacheStrategies.invalidateOnMutation('users', id)
      return result
    }),

  deleteUser: (id: string) =>
    api.delete(`/users/${id}`).then(result => {
      cacheStrategies.invalidateOnMutation('users', id)
      return result
    }),

  // Analytics
  getDashboardStats: () =>
    withCache(
      cacheKeys.analytics('dashboard'),
      () => api.get('/analytics/dashboard'),
      { ttl: 1 * 60 * 1000 } // 1 minute
    ),

  getGameStats: (gameId: string) =>
    withCache(
      cacheKeys.analytics('game', { gameId }),
      () => api.get(`/analytics/games/${gameId}`),
      { ttl: 2 * 60 * 1000 } // 2 minutes
    ),

  getPlayerStats: (playerId: string) =>
    withCache(
      cacheKeys.analytics('player', { playerId }),
      () => api.get(`/analytics/players/${playerId}`),
      { ttl: 3 * 60 * 1000 } // 3 minutes
    ),

  getTeamStats: (teamId: string) =>
    withCache(
      cacheKeys.analytics('team', { teamId }),
      () => api.get(`/analytics/teams/${teamId}`),
      { ttl: 5 * 60 * 1000 } // 5 minutes
    ),

  getTrends: (params?: { period?: string; metric?: string }) =>
    withCache(
      cacheKeys.analytics('trends', params),
      () => api.get('/analytics/trends', { params }),
      { ttl: 5 * 60 * 1000 } // 5 minutes
    ),
}

// Cache management utilities
export const cacheManager = {
  // Clear all caches
  clearAll: () => {
    cacheStrategies.invalidateAll()
  },

  // Clear specific cache
  clearGames: () => {
    cacheStrategies.invalidateByPattern('games')
  },

  clearTeams: () => {
    cacheStrategies.invalidateByPattern('teams')
  },

  clearPlayers: () => {
    cacheStrategies.invalidateByPattern('players')
  },

  clearUsers: () => {
    cacheStrategies.invalidateByPattern('users')
  },

  clearAnalytics: () => {
    cacheStrategies.invalidateByPattern('analytics')
  },

  // Preload critical data
  preloadCriticalData: async () => {
    try {
      await Promise.all([
        cachedApi.getDashboardStats(),
        cachedApi.getGames({ limit: 10 }),
        cachedApi.getTeams({ limit: 10 }),
      ])
    } catch (error) {
      console.warn('Failed to preload critical data:', error)
    }
  },

  // Warm up cache with user-specific data
  warmUpUserCache: async (userId: string) => {
    try {
      await Promise.all([
        cachedApi.getUser(userId),
        cachedApi.getDashboardStats(),
      ])
    } catch (error) {
      console.warn('Failed to warm up user cache:', error)
    }
  },
}

export default cachedApi
