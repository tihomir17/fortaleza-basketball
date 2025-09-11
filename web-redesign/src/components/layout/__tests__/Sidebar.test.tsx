import { render, screen, fireEvent } from '@testing-library/react'
import '@testing-library/jest-dom'
import { BrowserRouter } from 'react-router-dom'
import Sidebar from '../Sidebar'
import { useAuthStore } from '../../../store/authStore'

// Mock the auth store
jest.mock('../../../store/authStore')
const mockUseAuthStore = useAuthStore as jest.MockedFunction<typeof useAuthStore>

// Mock the density store
jest.mock('../../../store/densityStore', () => ({
  useDensityStore: () => ({
    density: 'comfortable'
  })
}))

const renderSidebar = () => {
  return render(
    <BrowserRouter>
      <Sidebar />
    </BrowserRouter>
  )
}

describe('Sidebar Component', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    
    mockUseAuthStore.mockReturnValue({
      user: {
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
        first_name: 'Test',
        last_name: 'User',
        role: 'COACH'
      },
      isAuthenticated: true,
      login: jest.fn(),
      logout: jest.fn(),
      register: jest.fn(),
      refreshToken: jest.fn(),
      clearError: jest.fn(),
      error: null,
      isLoading: false
    } as any)
  })

  it('renders sidebar with all navigation items', () => {
    renderSidebar()

    // Check for main navigation items
    expect(screen.getByText('Dashboard')).toBeInTheDocument()
    expect(screen.getByText('Teams')).toBeInTheDocument()
    expect(screen.getByText('Games')).toBeInTheDocument()
    expect(screen.getByText('Calendar')).toBeInTheDocument()
    expect(screen.getByText('Playbook')).toBeInTheDocument()
    expect(screen.getByText('Live Tracking')).toBeInTheDocument()
  })

  it('renders coach-specific navigation items', () => {
    renderSidebar()

    // Coach-specific items
    expect(screen.getByText('Team Analytics Reports')).toBeInTheDocument()
    expect(screen.getByText('Opponent Scouting')).toBeInTheDocument()
    expect(screen.getByText('Player Analytics Reports')).toBeInTheDocument()
    expect(screen.getByText('Game Preparation')).toBeInTheDocument()
    expect(screen.getByText('Post Game Scouting')).toBeInTheDocument()
  })

  it('renders navigation items with icons and text', () => {
    renderSidebar()

    // Check that items have both icons and text
    const dashboardItem = screen.getByText('Dashboard').closest('a')
    expect(dashboardItem).toBeInTheDocument()
    expect(dashboardItem).toHaveClass('flex', 'flex-col', 'items-center')

    const teamsItem = screen.getByText('Teams').closest('a')
    expect(teamsItem).toBeInTheDocument()
    expect(teamsItem).toHaveClass('flex', 'flex-col', 'items-center')
  })

  it('has correct href attributes for navigation', () => {
    renderSidebar()

    // Check main navigation links
    expect(screen.getByText('Dashboard').closest('a')).toHaveAttribute('href', '/')
    expect(screen.getByText('Teams').closest('a')).toHaveAttribute('href', '/teams')
    expect(screen.getByText('Games').closest('a')).toHaveAttribute('href', '/games')
    expect(screen.getByText('Calendar').closest('a')).toHaveAttribute('href', '/calendar')
    expect(screen.getByText('Playbook').closest('a')).toHaveAttribute('href', '/playbook')
    expect(screen.getByText('Live Tracking').closest('a')).toHaveAttribute('href', '/live')
  })

  it('has correct href attributes for coach-specific navigation', () => {
    renderSidebar()

    // Check coach-specific links
    expect(screen.getByText('Team Analytics Reports').closest('a')).toHaveAttribute('href', '/scouting-reports')
    expect(screen.getByText('Opponent Scouting').closest('a')).toHaveAttribute('href', '/opponent-scouting')
    expect(screen.getByText('Player Analytics Reports').closest('a')).toHaveAttribute('href', '/coach-self-scouting')
    expect(screen.getByText('Game Preparation').closest('a')).toHaveAttribute('href', '/individual-game-prep')
    expect(screen.getByText('Post Game Scouting').closest('a')).toHaveAttribute('href', '/individual-post-game')
  })

  it('applies correct styling classes', () => {
    renderSidebar()

    const sidebar = screen.getByRole('complementary')
    expect(sidebar).toHaveClass('fixed', 'bottom-0', 'left-0', 'right-0', 'h-20', 'bg-white', 'dark:bg-gray-900', 'border-t', 'border-gray-200', 'dark:border-gray-700', 'z-50')

    const nav = sidebar.querySelector('nav')
    expect(nav).toHaveClass('h-full', 'px-4', 'py-2')

    const ul = nav?.querySelector('ul')
    expect(ul).toHaveClass('flex', 'justify-around', 'items-center', 'h-full', 'gap-1')
  })

  it('handles player role correctly', () => {
    mockUseAuthStore.mockReturnValue({
      user: {
        id: 2,
        username: 'player',
        email: 'player@example.com',
        first_name: 'Player',
        last_name: 'User',
        role: 'PLAYER'
      },
      isAuthenticated: true,
      login: jest.fn(),
      logout: jest.fn(),
      register: jest.fn(),
      refreshToken: jest.fn(),
      clearError: jest.fn(),
      error: null,
      isLoading: false
    } as any)

    renderSidebar()

    // Player should see basic navigation
    expect(screen.getByText('Dashboard')).toBeInTheDocument()
    expect(screen.getByText('Teams')).toBeInTheDocument()
    expect(screen.getByText('Games')).toBeInTheDocument()
    expect(screen.getByText('Calendar')).toBeInTheDocument()

    // Player should NOT see coach-specific items
    expect(screen.queryByText('Team Analytics Reports')).not.toBeInTheDocument()
    expect(screen.queryByText('Opponent Scouting')).not.toBeInTheDocument()
    expect(screen.queryByText('Player Analytics Reports')).not.toBeInTheDocument()
    expect(screen.queryByText('Game Preparation')).not.toBeInTheDocument()
    expect(screen.queryByText('Post Game Scouting')).not.toBeInTheDocument()
  })

  it('handles admin role correctly', () => {
    mockUseAuthStore.mockReturnValue({
      user: {
        id: 3,
        username: 'admin',
        email: 'admin@example.com',
        first_name: 'Admin',
        last_name: 'User',
        role: 'ADMIN'
      },
      isAuthenticated: true,
      login: jest.fn(),
      logout: jest.fn(),
      register: jest.fn(),
      refreshToken: jest.fn(),
      clearError: jest.fn(),
      error: null,
      isLoading: false
    } as any)

    renderSidebar()

    // Admin should see all navigation items
    expect(screen.getByText('Dashboard')).toBeInTheDocument()
    expect(screen.getByText('Teams')).toBeInTheDocument()
    expect(screen.getByText('Games')).toBeInTheDocument()
    expect(screen.getByText('Calendar')).toBeInTheDocument()
    expect(screen.getByText('Playbook')).toBeInTheDocument()
    expect(screen.getByText('Live Tracking')).toBeInTheDocument()

    // Admin should also see coach-specific items
    expect(screen.getByText('Team Analytics Reports')).toBeInTheDocument()
    expect(screen.getByText('Opponent Scouting')).toBeInTheDocument()
    expect(screen.getByText('Player Analytics Reports')).toBeInTheDocument()
    expect(screen.getByText('Game Preparation')).toBeInTheDocument()
    expect(screen.getByText('Post Game Scouting')).toBeInTheDocument()
  })

  it('handles unauthenticated user correctly', () => {
    mockUseAuthStore.mockReturnValue({
      user: null,
      isAuthenticated: false,
      login: jest.fn(),
      logout: jest.fn(),
      register: jest.fn(),
      refreshToken: jest.fn(),
      clearError: jest.fn(),
      error: null,
      isLoading: false
    } as any)

    renderSidebar()

    // Should still render basic navigation
    expect(screen.getByText('Dashboard')).toBeInTheDocument()
    expect(screen.getByText('Teams')).toBeInTheDocument()
    expect(screen.getByText('Games')).toBeInTheDocument()
    expect(screen.getByText('Calendar')).toBeInTheDocument()
  })

  it('applies hover effects correctly', () => {
    renderSidebar()

    const dashboardLink = screen.getByText('Dashboard').closest('a')
    expect(dashboardLink).toHaveClass('hover:bg-gray-100', 'dark:hover:bg-gray-800', 'transition-all', 'duration-200')
  })

  it('renders with correct icon sizes', () => {
    renderSidebar()

    // Check that icons have correct size classes
    const icons = screen.getAllByRole('img', { hidden: true })
    icons.forEach(icon => {
      expect(icon).toHaveClass('w-7', 'h-7', 'mb-1')
    })
  })

  it('renders text labels with correct styling', () => {
    renderSidebar()

    const textLabels = screen.getAllByText(/Dashboard|Teams|Games|Calendar|Playbook|Live Tracking/)
    textLabels.forEach(label => {
      expect(label).toHaveClass('text-[10px]', 'leading-tight', 'text-center')
    })
  })

  it('handles navigation click events', () => {
    renderSidebar()

    const dashboardLink = screen.getByText('Dashboard').closest('a')
    expect(dashboardLink).toBeInTheDocument()
    
    // The link should be clickable (no error thrown)
    fireEvent.click(dashboardLink!)
    expect(dashboardLink).toHaveAttribute('href', '/')
  })

  it('renders all navigation items in correct order', () => {
    renderSidebar()

    const navItems = screen.getAllByRole('link')
    const itemTexts = navItems.map(item => item.textContent?.trim()).filter(Boolean)

    // Check that items are in the expected order
    expect(itemTexts[0]).toBe('Dashboard')
    expect(itemTexts[1]).toBe('Teams')
    expect(itemTexts[2]).toBe('Games')
    expect(itemTexts[3]).toBe('Calendar')
    expect(itemTexts[4]).toBe('Playbook')
    expect(itemTexts[5]).toBe('Live Tracking')
  })
})
