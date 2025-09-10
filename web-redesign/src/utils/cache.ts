interface CacheEntry<T> {
  data: T
  timestamp: number
  ttl: number
  key: string
}

interface CacheOptions {
  ttl?: number // Time to live in milliseconds
  maxSize?: number // Maximum number of entries
  storage?: 'memory' | 'localStorage' | 'sessionStorage'
}

export class CacheManager<T = any> {
  private cache: Map<string, CacheEntry<T>> = new Map()
  private options: Required<CacheOptions>

  constructor(options: CacheOptions = {}) {
    this.options = {
      ttl: options.ttl || 5 * 60 * 1000, // 5 minutes default
      maxSize: options.maxSize || 100,
      storage: options.storage || 'memory',
    }
  }

  set(key: string, data: T, ttl?: number): void {
    const entry: CacheEntry<T> = {
      data,
      timestamp: Date.now(),
      ttl: ttl || this.options.ttl,
      key,
    }

    // Remove oldest entries if cache is full
    if (this.cache.size >= this.options.maxSize) {
      const oldestKey = this.cache.keys().next().value
      if (oldestKey) this.cache.delete(oldestKey)
    }

    this.cache.set(key, entry)

    // Persist to storage if configured
    if (this.options.storage !== 'memory') {
      this.persistToStorage(key, entry)
    }
  }

  get(key: string): T | null {
    const entry = this.cache.get(key)

    if (!entry) {
      // Try to load from storage
      if (this.options.storage !== 'memory') {
        const storedEntry = this.loadFromStorage(key)
        if (storedEntry) {
          this.cache.set(key, storedEntry)
          return this.isValid(storedEntry) ? storedEntry.data : null
        }
      }
      return null
    }

    if (!this.isValid(entry)) {
      this.cache.delete(key)
      return null
    }

    return entry.data
  }

  has(key: string): boolean {
    return this.get(key) !== null
  }

  delete(key: string): void {
    this.cache.delete(key)
    
    if (this.options.storage !== 'memory') {
      this.removeFromStorage(key)
    }
  }

  clear(): void {
    this.cache.clear()
    
    if (this.options.storage !== 'memory') {
      this.clearStorage()
    }
  }

  size(): number {
    return this.cache.size
  }

  keys(): string[] {
    return Array.from(this.cache.keys())
  }

  private isValid(entry: CacheEntry<T>): boolean {
    return Date.now() - entry.timestamp < entry.ttl
  }

  private persistToStorage(key: string, entry: CacheEntry<T>): void {
    try {
      const storage = this.getStorage()
      const cacheKey = `cache_${key}`
      storage.setItem(cacheKey, JSON.stringify(entry))
    } catch (error) {
      console.warn('Failed to persist cache entry:', error)
    }
  }

  private loadFromStorage(key: string): CacheEntry<T> | null {
    try {
      const storage = this.getStorage()
      const cacheKey = `cache_${key}`
      const stored = storage.getItem(cacheKey)
      
      if (stored) {
        return JSON.parse(stored)
      }
    } catch (error) {
      console.warn('Failed to load cache entry from storage:', error)
    }
    
    return null
  }

  private removeFromStorage(key: string): void {
    try {
      const storage = this.getStorage()
      const cacheKey = `cache_${key}`
      storage.removeItem(cacheKey)
    } catch (error) {
      console.warn('Failed to remove cache entry from storage:', error)
    }
  }

  private clearStorage(): void {
    try {
      const storage = this.getStorage()
      const keys = Object.keys(storage).filter(key => key.startsWith('cache_'))
      keys.forEach(key => storage.removeItem(key))
    } catch (error) {
      console.warn('Failed to clear cache storage:', error)
    }
  }

  private getStorage(): Storage {
    if (this.options.storage === 'localStorage') {
      return localStorage
    } else if (this.options.storage === 'sessionStorage') {
      return sessionStorage
    }
    throw new Error('Invalid storage type')
  }
}

// Global cache instances
export const apiCache = new CacheManager({
  ttl: 5 * 60 * 1000, // 5 minutes
  maxSize: 100,
  storage: 'memory',
})

export const userCache = new CacheManager({
  ttl: 10 * 60 * 1000, // 10 minutes
  maxSize: 50,
  storage: 'localStorage',
})

export const gameCache = new CacheManager({
  ttl: 2 * 60 * 1000, // 2 minutes
  maxSize: 200,
  storage: 'memory',
})

// Cache key generators
export const cacheKeys = {
  games: (params?: any) => `games_${JSON.stringify(params || {})}`,
  game: (id: string) => `game_${id}`,
  teams: (params?: any) => `teams_${JSON.stringify(params || {})}`,
  team: (id: string) => `team_${id}`,
  players: (params?: any) => `players_${JSON.stringify(params || {})}`,
  player: (id: string) => `player_${id}`,
  users: (params?: any) => `users_${JSON.stringify(params || {})}`,
  user: (id: string) => `user_${id}`,
  analytics: (type: string, params?: any) => `analytics_${type}_${JSON.stringify(params || {})}`,
}

// Cache utilities
export function createCacheKey(prefix: string, params?: any): string {
  return `${prefix}_${JSON.stringify(params || {})}`
}

export function invalidateCachePattern(pattern: string): void {
  const keys = apiCache.keys().filter(key => key.includes(pattern))
  keys.forEach(key => apiCache.delete(key))
}

export function invalidateRelatedCache(type: string, id?: string): void {
  // Invalidate related cache entries when data changes
  const patterns = [type]
  if (id) {
    patterns.push(`${type}_${id}`)
  }
  
  patterns.forEach(pattern => {
    invalidateCachePattern(pattern)
  })
}

// Cache middleware for API calls
export function withCache<T>(
  cacheKey: string,
  apiCall: () => Promise<T>,
  options?: { ttl?: number; cache?: CacheManager<T> }
): Promise<T> {
  const cache = options?.cache || apiCache
  const ttl = options?.ttl

  // Check cache first
  const cached = cache.get(cacheKey)
  if (cached) {
    return Promise.resolve(cached)
  }

  // Make API call and cache result
  return apiCall().then(data => {
    cache.set(cacheKey, data, ttl)
    return data
  })
}

// Cache invalidation strategies
export const cacheStrategies = {
  // Invalidate on create/update/delete
  invalidateOnMutation: (type: string, id?: string) => {
    invalidateRelatedCache(type, id)
  },

  // Invalidate all cache
  invalidateAll: () => {
    apiCache.clear()
    gameCache.clear()
  },

  // Invalidate by pattern
  invalidateByPattern: (pattern: string) => {
    invalidateCachePattern(pattern)
  },

  // Invalidate expired entries
  invalidateExpired: () => {
    // This is handled automatically by the cache manager
    // but can be called manually if needed
    apiCache.keys().forEach(key => {
      const entry = apiCache.get(key)
      if (!entry) {
        apiCache.delete(key)
      }
    })
  },
}

// Cache statistics
export function getCacheStats() {
  return {
    apiCache: {
      size: apiCache.size(),
      keys: apiCache.keys(),
    },
    gameCache: {
      size: gameCache.size(),
      keys: gameCache.keys(),
    },
    userCache: {
      size: userCache.size(),
      keys: userCache.keys(),
    },
  }
}
