import { useCallback } from 'react'
import { usePaginatedApi, useApi } from './useApi'
import { gamesApi } from '../services/api'

export function useGames(params?: { search?: string; status?: string }) {
  return usePaginatedApi(
    (page, limit, searchParams) => gamesApi.getGames({ 
      page, 
      limit, 
      ...(searchParams as Record<string, unknown>) 
    }),
    params
  )
}

export function useGame(id: string) {
  return useApi(() => gamesApi.getGame(id))
}

export function useCreateGame() {
  const { execute, loading, error } = useApi(() => Promise.resolve(), { immediate: false })
  
  const createGame = useCallback(async (_gameData: unknown) => {
    return execute()
  }, [execute])
  
  return { createGame, loading, error }
}

export function useUpdateGame() {
  const { execute, loading, error } = useApi(() => Promise.resolve(), { immediate: false })
  
  const updateGame = useCallback(async (_id: string, _gameData: unknown) => {
    return execute()
  }, [execute])
  
  return { updateGame, loading, error }
}

export function useDeleteGame() {
  const { execute, loading, error } = useApi(() => Promise.resolve(), { immediate: false })
  
  const deleteGame = useCallback(async (_id: string) => {
    return execute()
  }, [execute])
  
  return { deleteGame, loading, error }
}

export function useUpcomingGames() {
  return useApi(() => gamesApi.getUpcomingGames())
}

export function useRecentGames() {
  return useApi(() => gamesApi.getRecentGames())
}
