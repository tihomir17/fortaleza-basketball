import { useState, useEffect, useCallback, useRef } from 'react'
import { apiCache } from '../utils/cache'

interface UseCacheOptions<T> {
  ttl?: number
  enabled?: boolean
  onSuccess?: (data: T) => void
  onError?: (error: unknown) => void
  refetchOnMount?: boolean
  refetchOnWindowFocus?: boolean
}

export function useCache<T = any>(
  key: string,
  fetcher: () => Promise<T>,
  options: UseCacheOptions<T> = {}
) {
  const {
    ttl,
    enabled = true,
    onSuccess,
    onError,
    refetchOnMount = false,
    refetchOnWindowFocus = false,
  } = options

  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isStale, setIsStale] = useState(false)
  
  const fetcherRef = useRef(fetcher)
  const mountedRef = useRef(true)

  // Update fetcher ref when it changes
  useEffect(() => {
    fetcherRef.current = fetcher
  }, [fetcher])

  // Check if data is stale
  const checkStaleness = useCallback(() => {
    const cached = apiCache.get(key)
    if (cached) {
      setIsStale(false)
    } else {
      setIsStale(true)
    }
  }, [key])

  // Fetch data
  const fetchData = useCallback(async (force = false) => {
    if (!enabled) return

    // Check cache first
    if (!force) {
      const cached = apiCache.get(key)
      if (cached) {
        setData(cached)
        setIsStale(false)
        onSuccess?.(cached)
        return
      }
    }

    setLoading(true)
    setError(null)

    try {
      const result = await fetcherRef.current()
      
      if (mountedRef.current) {
        setData(result)
        setIsStale(false)
        
        // Cache the result
        apiCache.set(key, result, ttl)
        
        onSuccess?.(result)
      }
    } catch (err: unknown) {
      if (mountedRef.current) {
        setError((err as any)?.message || 'An error occurred')
        onError?.(err)
      }
    } finally {
      if (mountedRef.current) {
        setLoading(false)
      }
    }
  }, [key, enabled, ttl, onSuccess, onError])

  // Refetch function
  const refetch = useCallback(() => {
    return fetchData(true)
  }, [fetchData])

  // Invalidate cache
  const invalidate = useCallback(() => {
    apiCache.delete(key)
    setIsStale(true)
  }, [key])

  // Update data in cache
  const updateData = useCallback((newData: T) => {
    setData(newData)
    apiCache.set(key, newData, ttl)
    setIsStale(false)
  }, [key, ttl])

  // Initial fetch
  useEffect(() => {
    if (enabled) {
      fetchData(refetchOnMount)
    }
  }, [enabled, fetchData, refetchOnMount])

  // Refetch on window focus
  useEffect(() => {
    if (!refetchOnWindowFocus || !enabled) return

    const handleFocus = () => {
      if (isStale) {
        fetchData(true)
      }
    }

    window.addEventListener('focus', handleFocus)
    return () => window.removeEventListener('focus', handleFocus)
  }, [refetchOnWindowFocus, enabled, isStale, fetchData])

  // Check staleness periodically
  useEffect(() => {
    if (!enabled) return

    const interval = setInterval(checkStaleness, 30000) // Check every 30 seconds
    return () => clearInterval(interval)
  }, [enabled, checkStaleness])

  // Cleanup
  useEffect(() => {
    return () => {
      mountedRef.current = false
    }
  }, [])

  return {
    data,
    loading,
    error,
    isStale,
    refetch,
    invalidate,
    updateData,
  }
}

// Hook for cached API calls
export function useCachedApi<T = any>(
  apiCall: () => Promise<T>,
  cacheKey: string,
  options: UseCacheOptions<T> = {}
) {
  return useCache(cacheKey, apiCall, options)
}

// Hook for paginated cached data
export function useCachedPaginatedApi<T = any>(
  apiCall: (page: number, limit: number, params?: unknown) => Promise<{ data: T[]; pagination: unknown }>,
  baseKey: string,
  params?: unknown,
  options: UseCacheOptions<{ data: T[]; pagination: unknown }> = {}
) {
  const [page, setPage] = useState(1)
  const [limit] = useState(10)
  const [allData, setAllData] = useState<T[]>([])
  const [pagination, setPagination] = useState<unknown>(null)

  const cacheKey = `${baseKey}_${JSON.stringify({ page, limit, ...(params as Record<string, unknown>) })}`

  const { data, loading, error, refetch, invalidate } = useCache(
    cacheKey,
    () => apiCall(page, limit, params),
    options
  )

  // Update aggregated data when new data arrives
  useEffect(() => {
    if (data) {
      if (page === 1) {
        setAllData(data.data)
      } else {
        setAllData(prev => [...prev, ...data.data])
      }
      setPagination(data.pagination)
    }
  }, [data, page])

  const loadMore = useCallback(() => {
    if ((pagination as any)?.hasNext && !loading) {
      setPage(prev => prev + 1)
    }
  }, [pagination, loading])

  const refresh = useCallback(() => {
    setPage(1)
    setAllData([])
    invalidate()
    refetch()
  }, [invalidate, refetch])

  const updateParams = useCallback((_newParams: unknown) => { // eslint-disable-line @typescript-eslint/no-unused-vars
    setPage(1)
    setAllData([])
    invalidate()
  }, [invalidate])

  return {
    data: allData,
    loading,
    error,
    pagination,
    loadMore,
    refresh,
    updateParams,
    hasMore: (pagination as any)?.hasNext || false,
  }
}

// Hook for real-time cached data
export function useCachedRealtimeApi<T = any>(
  apiCall: () => Promise<T>,
  cacheKey: string,
  interval: number = 30000,
  options: UseCacheOptions<T> = {}
) {
  const { data, loading, error, refetch, invalidate } = useCache(
    cacheKey,
    apiCall,
    { ...options, refetchOnWindowFocus: true }
  )

  // Set up interval for real-time updates
  useEffect(() => {
    const intervalId = setInterval(() => {
      refetch()
    }, interval)

    return () => clearInterval(intervalId)
  }, [refetch, interval])

  return {
    data,
    loading,
    error,
    refetch,
    invalidate,
  }
}

// Hook for optimistic updates with cache
export function useCachedOptimisticApi<T = any>(
  apiCall: (data: T) => Promise<T>,
  cacheKey: string,
  initialData: T[] = []
) {
  const [data, setData] = useState<T[]>(initialData)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const execute = useCallback(async (newData: T) => {
    // Optimistically update the UI
    setData(prev => [...prev, newData])
    setLoading(true)
    setError(null)

    try {
      const result = await apiCall(newData)
      
      // Update with server response and cache
      setData(prev => prev.map(item => 
        item === newData ? result : item
      ))
      
      // Update cache
      apiCache.set(cacheKey, result)
      
      return result
    } catch (error: unknown) {
      // Revert optimistic update on error
      setData(prev => prev.filter(item => item !== newData))
      setError((error as any)?.message || 'An error occurred')
      throw error
    } finally {
      setLoading(false)
    }
  }, [apiCall, cacheKey])

  return { data, loading, error, execute }
}
