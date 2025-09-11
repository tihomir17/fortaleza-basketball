import { adminApi, api } from './api'

// Playbook Types
export interface PlayStep {
  id: string
  order: number
  title: string
  description: string
  diagram?: string
  duration: number
}

export interface Play {
  id: string
  name: string
  description?: string
  play_type: 'OFFENSIVE' | 'DEFENSIVE'
  team: number
  parent?: number
  category?: {
    id: number
    name: string
    description?: string
  }
  subcategory?: string
  action_type: string
  diagram_url?: string
  video_url?: string
  tags: string[]
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced'
  duration: number
  players: number
  success_rate: number
  last_used?: string
  is_favorite: boolean
  created_by?: number
  created_by_name?: string
  steps: PlayStep[]
}

export interface PlayCreate {
  name: string
  description: string
  category: 'Offense' | 'Defense' | 'Special Situations'
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced'
  duration: number
  players: number
  tags: string[]
  steps: Omit<PlayStep, 'id'>[]
  successRate?: number
}

export interface PlayUpdate extends Partial<PlayCreate> {
  id: string
}

export interface PlayFilters {
  category?: string
  difficulty?: string
  search?: string
  tags?: string[]
  isFavorite?: boolean
}

// Mock data for fallback - simplified for now
export const mockPlays: Play[] = []

// Playbook API - Using existing backend endpoints
export const playbookApi = {
  // Get all plays with optional filtering (excluding Control category)
  getPlays: (filters?: PlayFilters) => {
    const params = new URLSearchParams()
    if (filters?.category) params.append('category', filters.category)
    if (filters?.difficulty) params.append('difficulty', filters.difficulty)
    if (filters?.search) params.append('search', filters.search)
    if (filters?.tags?.length) params.append('tags', filters.tags.join(','))
    if (filters?.isFavorite !== undefined) params.append('is_favorite', filters.isFavorite.toString())
    
    // Always exclude Control category plays
    params.append('exclude_category', 'Control')
    
    return api.get<{ results: Play[]; count: number }>(`/plays/?${params.toString()}`)
  },

  // Get a single play by ID
  getPlay: (id: string) =>
    api.get<Play>(`/plays/${id}/`),

  // Create a new play
  createPlay: (playData: PlayCreate) =>
    api.post<Play>('/plays/', playData),

  // Update an existing play
  updatePlay: (id: string, playData: Partial<PlayCreate>) =>
    api.put<Play>(`/plays/${id}/`, playData),

  // Delete a play
  deletePlay: (id: string) =>
    api.delete(`/plays/${id}/`),

  // Duplicate a play
  duplicatePlay: (id: string, newName?: string) =>
    api.post<Play>(`/plays/${id}/duplicate/`, { name: newName }),

  // Toggle favorite status
  toggleFavorite: (id: string) =>
    api.patch<Play>(`/plays/${id}/favorite/`),

  // Update play order (for drag and drop)
  updatePlayOrder: (playIds: string[]) =>
    api.patch('/plays/order/', { play_ids: playIds }),

  // Get play categories (excluding Control category)
  getCategories: () =>
    api.get<{ results: string[] }>('/play-categories/?exclude=Control'),

  // Get play difficulties
  getDifficulties: () =>
    api.get<{ difficulties: string[] }>('/plays/difficulties/'),

  // Get play tags
  getTags: () =>
    api.get<{ tags: string[] }>('/plays/tags/'),

  // Get play statistics
  getPlayStats: () =>
    adminApi.get<{
      totalPlays: number
      categoryCounts: Record<string, number>
      difficultyCounts: Record<string, number>
      averageSuccessRate: number
      mostUsedPlays: Play[]
    }>('/admin/plays/playdefinition/stats/')
}

// Cached playbook API
export const cachedPlaybookApi = {
  getPlays: (filters?: PlayFilters) => {
    const cacheKey = `playbook_plays_${JSON.stringify(filters || {})}`
    const cached = localStorage.getItem(cacheKey)
    if (cached) {
      try {
        const data = JSON.parse(cached)
        const cacheTime = data.timestamp
        const now = Date.now()
        // Cache for 5 minutes
        if (now - cacheTime < 5 * 60 * 1000) {
          return Promise.resolve(data.data)
        }
      } catch (error) {
        console.warn('Failed to parse cached playbook data:', error)
      }
    }
    
    return playbookApi.getPlays(filters).then((response: any) => {
      const cacheData = {
        data: response,
        timestamp: Date.now()
      }
      localStorage.setItem(cacheKey, JSON.stringify(cacheData))
      return response
    })
  },

  getPlay: (id: string) => {
    const cacheKey = `playbook_play_${id}`
    const cached = localStorage.getItem(cacheKey)
    if (cached) {
      try {
        const data = JSON.parse(cached)
        const cacheTime = data.timestamp
        const now = Date.now()
        // Cache for 10 minutes
        if (now - cacheTime < 10 * 60 * 1000) {
          return Promise.resolve(data.data)
        }
      } catch (error) {
        console.warn('Failed to parse cached play data:', error)
      }
    }
    
    return playbookApi.getPlay(id).then((response: any) => {
      const cacheData = {
        data: response,
        timestamp: Date.now()
      }
      localStorage.setItem(cacheKey, JSON.stringify(cacheData))
      return response
    })
  },

  // Invalidate cache methods
  invalidatePlaysCache: () => {
    const keys = Object.keys(localStorage)
    keys.forEach(key => {
      if (key.startsWith('playbook_plays_') || key.startsWith('playbook_play_')) {
        localStorage.removeItem(key)
      }
    })
  },

  invalidatePlayCache: (id: string) => {
    localStorage.removeItem(`playbook_play_${id}`)
  }
}

export default playbookApi
