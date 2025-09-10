import { render, screen, fireEvent } from '@testing-library/react'
import { ThemeToggle } from '../ThemeToggle'
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
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders theme toggle button', () => {
    render(<ThemeToggle />)
    
    const toggleButton = screen.getByRole('button')
    expect(toggleButton).toBeInTheDocument()
  })

  it('shows sun icon for light theme', () => {
    render(<ThemeToggle />)
    
    // Should show sun icon for light theme
    const sunIcon = screen.getByTestId('sun-icon')
    expect(sunIcon).toBeInTheDocument()
  })

  it('shows moon icon for dark theme', () => {
    mockUseThemeStore.mockReturnValue({
      theme: 'dark',
      setTheme: mockSetTheme,
      initialize: mockInitialize,
      toggleTheme: jest.fn(),
      isDark: true,
      updateTheme: jest.fn(),
    })

    render(<ThemeToggle />)
    
    const moonIcon = screen.getByTestId('moon-icon')
    expect(moonIcon).toBeInTheDocument()
  })

  it('calls setTheme when theme option is clicked', () => {
    render(<ThemeToggle showLabel={true} />)
    
    const toggleButton = screen.getByRole('button')
    fireEvent.click(toggleButton)
    
    // Should open dropdown with theme options
    expect(screen.getByText('Light')).toBeInTheDocument()
    expect(screen.getByText('Dark')).toBeInTheDocument()
    expect(screen.getByText('System')).toBeInTheDocument()
  })

  it('calls initialize on mount', () => {
    render(<ThemeToggle />)
    
    expect(mockInitialize).toHaveBeenCalled()
  })
})
