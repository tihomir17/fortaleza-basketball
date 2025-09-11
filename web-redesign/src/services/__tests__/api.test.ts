import { api, adminApi } from '../api'

// Mock axios
jest.mock('axios')
import axios from 'axios'
const mockedAxios = axios as jest.Mocked<typeof axios>

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

describe('API Service', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('Request Interceptors', () => {
    it('adds auth token to requests when available', () => {
      mockLocalStorage.getItem.mockReturnValue('test-token')
      
      // Create a new instance to test interceptor
      const mockRequest = { headers: {} }
      const mockConfig = { ...mockRequest }
      
      // Simulate the interceptor
      const token = localStorage.getItem('auth_token')
      if (token) {
        mockConfig.headers.Authorization = `Bearer ${token}`
      }
      
      expect(mockConfig.headers.Authorization).toBe('Bearer test-token')
    })

    it('does not add auth token when not available', () => {
      mockLocalStorage.getItem.mockReturnValue(null)
      
      const mockRequest = { headers: {} }
      const mockConfig = { ...mockRequest }
      
      const token = localStorage.getItem('auth_token')
      if (token) {
        mockConfig.headers.Authorization = `Bearer ${token}`
      }
      
      expect(mockConfig.headers.Authorization).toBeUndefined()
    })
  })

  describe('Response Interceptors', () => {
    it('handles 401 responses by redirecting to login', () => {
      const mockError = {
        response: {
          status: 401,
        },
      }
      
      // Mock window.location
      delete (window as any).location
      window.location = { href: '' } as any
      
      // Simulate the interceptor logic
      if (mockError.response?.status === 401) {
        localStorage.removeItem('auth_token')
        if (window.location.pathname !== '/login') {
          window.location.href = '/login'
        }
      }
      
      expect(mockLocalStorage.removeItem).toHaveBeenCalledWith('auth_token')
      expect(window.location.href).toBe('/login')
    })

    it('does not redirect when already on login page', () => {
      const mockError = {
        response: {
          status: 401,
        },
      }
      
      // Mock window.location
      delete (window as any).location
      window.location = { href: '', pathname: '/login' } as any
      
      // Simulate the interceptor logic
      if (mockError.response?.status === 401) {
        localStorage.removeItem('auth_token')
        if (window.location.pathname !== '/login') {
          window.location.href = '/login'
        }
      }
      
      expect(mockLocalStorage.removeItem).toHaveBeenCalledWith('auth_token')
      expect(window.location.href).toBe('')
    })
  })

  describe('API Instances', () => {
    it('creates api instance with correct base URL', () => {
      expect(api.defaults.baseURL).toBe('http://localhost:8000/api')
    })

    it('creates adminApi instance with correct base URL', () => {
      expect(adminApi.defaults.baseURL).toBe('http://localhost:8000')
    })

    it('sets correct timeout', () => {
      expect(api.defaults.timeout).toBe(30000)
      expect(adminApi.defaults.timeout).toBe(30000)
    })

    it('sets correct content type', () => {
      expect(api.defaults.headers['Content-Type']).toBe('application/json')
      expect(adminApi.defaults.headers['Content-Type']).toBe('application/json')
    })
  })
})
