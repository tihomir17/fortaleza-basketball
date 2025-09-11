import { act, waitFor } from '@testing-library/react'
import { renderHook } from '@testing-library/react'
import '@testing-library/jest-dom'
import { useAuthStore } from '../authStore'

jest.mock('../../utils/monitoring', () => ({
  errorTracker: { captureError: jest.fn(), setUser: jest.fn(), setContext: jest.fn(), addBreadcrumb: jest.fn() },
  behaviorTracker: { trackAction: jest.fn(), trackPageView: jest.fn(), trackFormSubmission: jest.fn(), trackApiCall: jest.fn() },
}))

jest.mock('../../services/api', () => ({
  authApi: {
    login: jest.fn().mockResolvedValue({ access: 'token', refresh: 'refresh' }),
    me: jest.fn().mockResolvedValue({ id: 1, username: 'test', role: 'coach' }),
    logout: jest.fn().mockResolvedValue({}),
    refreshToken: jest.fn().mockResolvedValue({ access: 'new-token' }),
  },
}))

const { authApi } = jest.requireMock('../../services/api')

describe('authStore', () => {
  beforeEach(() => {
    ;(window.localStorage.clear as jest.Mock).mockClear?.()
    window.localStorage.clear()
    // Reset relevant auth state between tests without overwriting actions
    useAuthStore.setState({
      user: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,
    })
  })

  it('logs in successfully', async () => {
    const { result } = renderHook(() => useAuthStore())

    await act(async () => {
      await result.current.login({ username: 'testuser', password: 'password' })
    })

    await waitFor(() => expect(result.current.isAuthenticated).toBe(true))
    expect(result.current.token).toBe('token')
    expect(result.current.user?.username).toBe('test')
  })

  it('handles login failure', async () => {
    ;(authApi.login as jest.Mock).mockRejectedValueOnce(new Error('Invalid credentials'))

    const { result } = renderHook(() => useAuthStore())

    await act(async () => {
      await expect(result.current.login({ username: 'testuser', password: 'wrongpassword' })).rejects.toThrow()
    })

    expect(result.current.isAuthenticated).toBe(false)
  })

  it('refreshes token', async () => {
    const { result } = renderHook(() => useAuthStore())

    await act(async () => {
      await result.current.refreshToken()
    })

    await waitFor(() => expect(result.current.token).toBe('new-token'))
  })

  it('logs out', async () => {
    const { result } = renderHook(() => useAuthStore())

    await act(async () => {
      await result.current.login({ username: 'testuser', password: 'password' })
      result.current.logout()
    })

    await waitFor(() => expect(result.current.isAuthenticated).toBe(false))
    expect(result.current.token).toBeNull()
  })
})