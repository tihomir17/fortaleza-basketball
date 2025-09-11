import { render, screen, fireEvent } from '@testing-library/react'
import { ThemeToggle, ThemeDropdown } from '../ThemeToggle'
import { useThemeStore } from '../../../store/themeStore'

// Mock the theme store
jest.mock('../../../store/themeStore', () => ({
  useThemeStore: jest.fn(),
}))

const mockUseThemeStore = useThemeStore as jest.MockedFunction<typeof useThemeStore>

describe('ThemeToggle', () => {
  const mockSetTheme = jest.fn()
  const mockInitialize = jest.fn()

  beforeEach(() => {
    mockUseThemeStore.mockReturnValue({
      theme: 'light',
      setTheme: mockSetTheme,
      initialize: mockInitialize,
      toggleTheme: jest.fn(),
      isDark: false,
      updateTheme: jest.fn(),
    } as any)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders theme toggle button', () => {
    render(<ThemeToggle />)
    const toggleButton = screen.getByRole('button')
    expect(toggleButton).toBeInTheDocument()
  })

  it('renders sun icon for light theme (by title)', () => {
    render(<ThemeToggle />)
    // Button title includes current and next theme; ensures icon rendered
    expect(screen.getByRole('button', { name: /current theme: light/i })).toBeInTheDocument()
  })

  it('renders moon icon for dark theme (by title)', () => {
    mockUseThemeStore.mockReturnValue({
      theme: 'dark',
      setTheme: mockSetTheme,
      initialize: mockInitialize,
      toggleTheme: jest.fn(),
      isDark: true,
      updateTheme: jest.fn(),
    } as any)

    render(<ThemeToggle />)
    expect(screen.getByRole('button', { name: /current theme: dark/i })).toBeInTheDocument()
  })

  it('cycles theme on click', () => {
    render(<ThemeToggle />)
    const toggleButton = screen.getByRole('button')
    fireEvent.click(toggleButton)
    expect(mockSetTheme).toHaveBeenCalled()
  })

  it('shows label when showLabel is true', () => {
    render(<ThemeToggle showLabel />)
    expect(screen.getByText(/light/i)).toBeInTheDocument()
  })
})

// ThemeDropdown specific tests
describe('ThemeDropdown', () => {
  const mockSetTheme = jest.fn()
  const mockInitialize = jest.fn()

  beforeEach(() => {
    mockUseThemeStore.mockReturnValue({
      theme: 'light',
      setTheme: mockSetTheme,
      initialize: mockInitialize,
      toggleTheme: jest.fn(),
      isDark: false,
      updateTheme: jest.fn(),
    } as any)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders options and calls setTheme', () => {
    render(<ThemeDropdown />)
    expect(screen.getByText('Light')).toBeInTheDocument()
    expect(screen.getByText('Dark')).toBeInTheDocument()
    expect(screen.getByText('System')).toBeInTheDocument()

    fireEvent.click(screen.getByText('Dark'))
    expect(mockSetTheme).toHaveBeenCalledWith('dark')
  })
})
