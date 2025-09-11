import { renderHook, act } from '@testing-library/react'
import { useAuthStore } from '../authStore'

// Mock localStorage
const mockLocalStorage = {
  getItem: jest.fn(),
  setItem: jest.fn(),
  removeItem: jest.fn(),
  clear: jest.fn(),
}

Object.defineProperty(window, 'localStorage', {
  value: mockLocalStorage,
})

// Mock fetch
global.fetch = jest.fn()

describe('AuthStore', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    // Reset store state
    useAuthStore.getState().logout()
  })

  it('initializes with default state', () => {
    const { result } = renderHook(() => useAuthStore())
    
    expect(result.current.isAuthenticated).toBe(false)
    expect(result.current.user).toBeNull()
    expect(result.current.token).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('sets loading state during login', async () => {
    const { result } = renderHook(() => useAuthStore())
    
    const mockResponse = {
      ok: true,
      json: async () => ({
        access: 'mock-access-token',
        refresh: 'mock-refresh-token',
        user: {
          id: 1,
          username: 'testuser',
          email: 'test@example.com',
          first_name: 'Test',
          last_name: 'User',
        },
      }),
    }
    
    ;(global.fetch as jest.Mock).mockResolvedValueOnce(mockResponse)
    
    await act(async () => {
      result.current.login('testuser', 'password')
    })
    
    expect(result.current.isAuthenticated).toBe(true)
    expect(result.current.user).toEqual({
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      first_name: 'Test',
      last_name: 'User',
    })
    expect(result.current.token).toBe('mock-access-token')
  })

  it('handles login failure', async () => {
    const { result } = renderHook(() => useAuthStore())
    
    const mockResponse = {
      ok: false,
      status: 401,
      json: async () => ({ error: 'Invalid credentials' }),
    }
    
    ;(global.fetch as jest.Mock).mockResolvedValueOnce(mockResponse)
    
    await act(async () => {
      try {
        await result.current.login('testuser', 'wrongpassword')
      } catch (error) {
        // Expected to throw
      }
    })
    
    expect(result.current.isAuthenticated).toBe(false)
    expect(result.current.user).toBeNull()
    expect(result.current.token).toBeNull()
  })

  it('logs out user', () => {
    const { result } = renderHook(() => useAuthStore())
    
    // First set some state
    act(() => {
      result.current.setUser({
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        first_name: 'Test',
        last_name: 'User',
      })
      result.current.setToken('mock-token')
    })
    
    expect(result.current.isAuthenticated).toBe(true)
    
    // Then logout
    act(() => {
      result.current.logout()
    })
    
    expect(result.current.isAuthenticated).toBe(false)
    expect(result.current.user).toBeNull()
    expect(result.current.token).toBeNull()
    expect(mockLocalStorage.removeItem).toHaveBeenCalledWith('auth_token')
  })

  it('loads user from token', async () => {
    const { result } = renderHook(() => useAuthStore())
    
    const mockUserResponse = {
      ok: true,
      json: async () => ({
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        first_name: 'Test',
        last_name: 'User',
      }),
    }
    
    mockLocalStorage.getItem.mockReturnValue('mock-token')
    ;(global.fetch as jest.Mock).mockResolvedValueOnce(mockUserResponse)
    
    await act(async () => {
      await result.current.loadUserFromToken()
    })
    
    expect(result.current.isAuthenticated).toBe(true)
    expect(result.current.user).toEqual({
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      first_name: 'Test',
      last_name: 'User',
    })
    expect(result.current.token).toBe('mock-token')
  })

  it('handles token refresh', async () => {
    const { result } = renderHook(() => useAuthStore())
    
    const mockRefreshResponse = {
      ok: true,
      json: async () => ({
        access: 'new-access-token',
        refresh: 'new-refresh-token',
      }),
    }
    
    mockLocalStorage.getItem.mockReturnValue('old-refresh-token')
    ;(global.fetch as jest.Mock).mockResolvedValueOnce(mockRefreshResponse)
    
    await act(async () => {
      await result.current.refreshToken()
    })
    
    expect(result.current.token).toBe('new-access-token')
    expect(mockLocalStorage.setItem).toHaveBeenCalledWith('auth_token', 'new-access-token')
  })
})