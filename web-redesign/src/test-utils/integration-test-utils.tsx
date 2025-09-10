import type { ReactElement } from 'react'
import { render } from '@testing-library/react'
import type { RenderOptions } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
// import { ThemeProvider } from '../components/ui/ThemeProvider'

// Mock stores for testing
const mockAuthStore = {
  isAuthenticated: true,
  user: {
    id: '1',
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
    role: 'admin'
  },
  login: jest.fn(),
  logout: jest.fn(),
  isLoading: false,
  error: null
}

const mockThemeStore = {
  theme: 'light',
  setTheme: jest.fn(),
  toggleTheme: jest.fn(),
  isDark: false,
  initialize: jest.fn()
}

// Mock the stores
jest.mock('../store/authStore', () => ({
  useAuthStore: () => mockAuthStore
}))

jest.mock('../store/themeStore', () => ({
  useThemeStore: () => mockThemeStore
}))

// Custom render function with providers
const AllTheProviders = ({ children }: { children: React.ReactNode }) => {
  return (
    <BrowserRouter>
      {children}
    </BrowserRouter>
  )
}

const customRender = (
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) => render(ui, { wrapper: AllTheProviders, ...options })

// Test data factories
export const createMockGame = (overrides = {}) => ({
  id: 1,
  home_team: 1,
  away_team: 2,
  home_team_name: 'Fortaleza',
  away_team_name: 'Lakers',
  date: '2024-01-15',
  time: '19:00',
  venue: 'Home Arena',
  status: 'SCHEDULED' as const,
  home_score: 0,
  away_score: 0,
  season: 1,
  competition: 1,
  ...overrides
})

export const createMockPlayer = (overrides = {}) => ({
  id: '1',
  name: 'John Doe',
  position: 'PG',
  jersey_number: 1,
  team_id: '1',
  team_name: 'Fortaleza',
  ...overrides
})

export const createMockTeam = (overrides = {}) => ({
  id: '1',
  name: 'Fortaleza',
  city: 'Fortaleza',
  state: 'CE',
  league: 'Professional',
  division: 'A',
  coach: 'Coach Smith',
  ...overrides
})

export const createMockUser = (overrides = {}) => ({
  id: '1',
  email: 'user@example.com',
  firstName: 'John',
  lastName: 'Doe',
  role: 'player' as const,
  status: 'active' as const,
  permissions: ['games:read', 'players:read'],
  createdAt: new Date('2024-01-01'),
  updatedAt: new Date('2024-01-01'),
  ...overrides
})

// Helper functions for common test scenarios
export const fillForm = async (formData: Record<string, string>) => {
  const { fireEvent } = await import('@testing-library/react')
  
  for (const [fieldName, value] of Object.entries(formData)) {
    const input = document.querySelector(`[name="${fieldName}"]`) as HTMLInputElement
    if (input) {
      fireEvent.change(input, { target: { value } })
    }
  }
}

export const clickButton = async (buttonText: string) => {
  const { fireEvent, getByText } = await import('@testing-library/react')
  
  const button = (getByText as any)(buttonText, { exact: false })
  fireEvent.click(button)
}

export const waitForLoadingToFinish = async () => {
  const { waitFor } = await import('@testing-library/react')
  
  await waitFor(() => {
    const loadingElements = document.querySelectorAll('[data-testid*="loading"], .animate-spin')
    expect(loadingElements.length).toBe(0)
  })
}

export const mockApiResponse = (data: any, delay = 0) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        ok: true,
        json: () => Promise.resolve(data),
        status: 200
      })
    }, delay)
  })
}

export const mockApiError = (status = 500, message = 'Internal Server Error') => {
  return Promise.reject({
    ok: false,
    status,
    json: () => Promise.resolve({ message }),
  })
}

// Navigation helpers
export const navigateToPage = async (path: string) => {
  const { fireEvent, getByText } = await import('@testing-library/react')
  
  // Find and click navigation link
  const link = (getByText as any)(path.split('/').pop() || path, { exact: false })
  fireEvent.click(link)
}

// Assertion helpers
export const expectElementToBeVisible = (selector: string) => {
  const element = document.querySelector(selector)
  expect(element).toBeInTheDocument()
  expect(element).toBeVisible()
}

export const expectElementToHaveText = (selector: string, text: string) => {
  const element = document.querySelector(selector)
  expect(element).toHaveTextContent(text)
}

export const expectFormToHaveValues = (formData: Record<string, string>) => {
  for (const [fieldName, value] of Object.entries(formData)) {
    const input = document.querySelector(`[name="${fieldName}"]`) as HTMLInputElement
    expect(input).toHaveValue(value)
  }
}

// Re-export everything from React Testing Library
export * from '@testing-library/react'
export { customRender as render }
