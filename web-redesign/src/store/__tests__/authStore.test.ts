import { renderHook, act } from '@testing-library/react'
import { useAuthStore } from '../authStore'

describe('AuthStore', () => {
  beforeEach(() => {
    // Reset store state before each test
    useAuthStore.getState().logout()
  })

  it('should have initial state', () => {
    const { result } = renderHook(() => useAuthStore())
    
    expect(result.current.isAuthenticated).toBe(false)
    expect(result.current.user).toBeNull()
    expect(result.current.isLoading).toBe(false)
  })

  it('should login user', async () => {
    const { result } = renderHook(() => useAuthStore())
    
    const mockUser = {
      id: '1',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      role: 'admin'
    }

    await act(async () => {
      await result.current.login({ username: 'testuser', password: 'password' })
    })

    expect(result.current.isAuthenticated).toBe(true)
    expect(result.current.user).toEqual(mockUser)
  })

  it('should logout user', () => {
    const { result } = renderHook(() => useAuthStore())
    
    act(() => {
      result.current.logout()
    })

    expect(result.current.isAuthenticated).toBe(false)
    expect(result.current.user).toBeNull()
  })

  it('should handle login error', async () => {
    const { result } = renderHook(() => useAuthStore())
    
    await act(async () => {
      await result.current.login({ username: 'invaliduser', password: 'wrongpassword' })
    })

    expect(result.current.isAuthenticated).toBe(false)
    expect(result.current.user).toBeNull()
  })
})
