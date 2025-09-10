import { useState, useEffect, useCallback } from 'react'
import { api } from '../services/api'

interface UseApiState<T> {
  data: T | null
  loading: boolean
  error: string | null
}

interface UseApiOptions {
  immediate?: boolean
  onSuccess?: (data: unknown) => void
  onError?: (error: unknown) => void
}

export function useApi<T = any>(
  apiCall: () => Promise<T>,
  options: UseApiOptions = {}
) {
  const { immediate = true, onSuccess, onError } = options
  const [state, setState] = useState<UseApiState<T>>({
    data: null,
    loading: false,
    error: null,
  })

  const execute = useCallback(async () => {
    setState(prev => ({ ...prev, loading: true, error: null }))
    
    try {
      const data = await apiCall()
      setState({ data, loading: false, error: null })
      onSuccess?.(data)
      return data
    } catch (error: unknown) {
      const errorMessage = (error as any)?.response?.data?.message || (error as any)?.message || 'An error occurred'
      setState({ data: null, loading: false, error: errorMessage })
      onError?.(error)
      throw error
    }
  }, [apiCall, onSuccess, onError])

  useEffect(() => {
    if (immediate) {
      execute()
    }
  }, [immediate, execute])

  return {
    ...state,
    execute,
    refetch: execute,
  }
}

// Specific hooks for common API patterns
export function useGet<T = any>(url: string, options?: UseApiOptions) {
  return useApi<T>(() => api.get<T>(url), options)
}

export function usePost<T = any>(url: string, data?: unknown, options?: UseApiOptions) {
  return useApi<T>(() => api.post<T>(url, data), { ...options, immediate: false })
}

export function usePut<T = any>(url: string, data?: unknown, options?: UseApiOptions) {
  return useApi<T>(() => api.put<T>(url, data), { ...options, immediate: false })
}

export function useDelete<T = any>(url: string, options?: UseApiOptions) {
  return useApi<T>(() => api.delete<T>(url), { ...options, immediate: false })
}

// Hook for paginated data
export function usePaginatedApi<T = any>(
  apiCall: (page: number, limit: number, params?: unknown) => Promise<{ data: T[]; pagination: unknown }>,
  initialParams?: unknown
) {
  const [page, setPage] = useState(1)
  const [limit] = useState(10)
  const [params, setParams] = useState(initialParams)
  const [allData, setAllData] = useState<T[]>([])
  const [pagination, setPagination] = useState<unknown>(null)

  const { data, loading, error, execute } = useApi(
    () => apiCall(page, limit, params),
    { immediate: true }
  )

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
    execute()
  }, [execute])

  const updateParams = useCallback((newParams: unknown) => {
    setParams(newParams)
    setPage(1)
    setAllData([])
  }, [])

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

// Hook for real-time data updates
export function useRealtimeApi<T = any>(
  apiCall: () => Promise<T>,
  interval: number = 30000 // 30 seconds
) {
  const { data, loading, error, execute } = useApi(apiCall, { immediate: true })

  useEffect(() => {
    const intervalId = setInterval(execute, interval)
    return () => clearInterval(intervalId)
  }, [execute, interval])

  return { data, loading, error, refetch: execute }
}

// Hook for optimistic updates
export function useOptimisticApi<T = any>(
  apiCall: (data: T) => Promise<T>,
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
      // Update with server response
      setData(prev => prev.map(item => 
        item === newData ? result : item
      ))
      return result
    } catch (error: unknown) {
      // Revert optimistic update on error
      setData(prev => prev.filter(item => item !== newData))
      setError((error as any)?.response?.data?.message || (error as any)?.message || 'An error occurred')
      throw error
    } finally {
      setLoading(false)
    }
  }, [apiCall])

  return { data, loading, error, execute }
}
