import '@testing-library/jest-dom'

// Polyfill for TextEncoder/TextDecoder (needed for React Router)
// TextEncoder and TextDecoder are available in modern Node.js environments

// Mock environment variables for Vite
Object.defineProperty(globalThis, 'import', {
  value: {
    meta: {
      env: {
        VITE_API_BASE_URL: 'http://localhost:8000/api',
        VITE_ADMIN_API_BASE_URL: 'http://localhost:8000',
        VITE_USE_MOCKS: 'false',
        VITE_NODE_ENV: 'test',
      }
    }
  }
})

// Mock localStorage (working in-memory version)
const storage: Record<string, string> = {}
const localStorageMock = {
  getItem: jest.fn((key: string) => (key in storage ? storage[key] : null)),
  setItem: jest.fn((key: string, value: string) => { storage[key] = String(value) }),
  removeItem: jest.fn((key: string) => { delete storage[key] }),
  clear: jest.fn(() => { for (const k of Object.keys(storage)) delete storage[k] }),
}
Object.defineProperty(window, 'localStorage', {
  value: localStorageMock,
})

// Mock window.matchMedia
if (typeof window !== 'undefined') {
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: jest.fn().mockImplementation(query => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: jest.fn(), // deprecated
      removeListener: jest.fn(), // deprecated
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
      dispatchEvent: jest.fn(),
    })),
  });
}

// Mock IntersectionObserver
(globalThis as any).IntersectionObserver = jest.fn().mockImplementation(() => ({
  disconnect: jest.fn(),
  observe: jest.fn(),
  unobserve: jest.fn(),
  takeRecords: jest.fn(() => []),
  root: null,
  rootMargin: '0px',
  thresholds: []
}))

// Mock ResizeObserver
(globalThis as any).ResizeObserver = jest.fn().mockImplementation(() => ({
  disconnect: jest.fn(),
  observe: jest.fn(),
  unobserve: jest.fn()
}))

// Mock fetch
(globalThis as any).fetch = jest.fn()

// Mock console methods to reduce noise in tests
const originalError = console.error
const originalWarn = console.warn

beforeAll(() => {
  console.error = (...args: any[]) => {
    if (
      typeof args[0] === 'string' &&
      (args[0].includes('Warning:') || args[0].includes('Error:'))
    ) {
      return
    }
    originalError.call(console, ...args)
  }
  
  console.warn = (...args: any[]) => {
    if (
      typeof args[0] === 'string' &&
      args[0].includes('Warning:')
    ) {
      return
    }
    originalWarn.call(console, ...args)
  }
})

afterAll(() => {
  console.error = originalError
  console.warn = originalWarn
})