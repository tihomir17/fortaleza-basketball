import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import '@testing-library/jest-dom'
import { BrowserRouter } from 'react-router-dom'
import Dashboard from '../Dashboard'
import { useDashboardStore } from '../../store/dashboardStore'
import { useAuthStore } from '../../store/authStore'

// Mock the dashboard store
jest.mock('../../store/dashboardStore')
const mockUseDashboardStore = useDashboardStore as jest.MockedFunction<typeof useDashboardStore>

// Mock the auth store
jest.mock('../../store/authStore')
const mockUseAuthStore = useAuthStore as jest.MockedFunction<typeof useAuthStore>

// Mock the dashboard service
jest.mock('../../services/dashboard', () => ({
  dashboardService: {
    getDashboardData: jest.fn(),
    getQuickStats: jest.fn(),
    getUpcomingGames: jest.fn(),
    getRecentGames: jest.fn(),
    getTopPerformers: jest.fn(),
    getRecentActivity: jest.fn(),
  }
}))

// Mock the notifications store
jest.mock('../../store/notificationsStore', () => ({
  notify: {
    success: jest.fn(),
    info: jest.fn(),
    warning: jest.fn(),
    error: jest.fn(),
  }
}))

const mockDashboardData = {
  quickStats: {
    totalGames: 25,
    wins: 18,
    losses: 7,
    winPercentage: 72,
    upcomingGames: 3,
    activePlayers: 12
  },
  upcomingGames: [
    {
      id: 1,
      home_team_name: 'Lakers',
      away_team_name: 'Warriors',
      date: '2024-01-15',
      time: '19:30',
      venue: 'Staples Center'
    },
    {
      id: 2,
      home_team_name: 'Celtics',
      away_team_name: 'Heat',
      date: '2024-01-18',
      time: '20:00',
      venue: 'TD Garden'
    }
  ],
  recentGames: [
    {
      id: 3,
      home_team_name: 'Lakers',
      away_team_name: 'Clippers',
      home_score: 112,
      away_score: 108,
      date: '2024-01-10',
      result: 'W' as const
    },
    {
      id: 4,
      home_team_name: 'Warriors',
      away_team_name: 'Lakers',
      home_score: 98,
      away_score: 105,
      date: '2024-01-08',
      result: 'L' as const
    }
  ],
  topPerformers: [
    {
      player_name: 'LeBron James',
      jersey_number: 23,
      position: 'SF',
      points_per_game: 25.4,
      rebounds_per_game: 7.8,
      assists_per_game: 6.9
    },
    {
      player_name: 'Anthony Davis',
      jersey_number: 3,
      position: 'PF',
      points_per_game: 22.1,
      rebounds_per_game: 9.2,
      assists_per_game: 3.1
    }
  ],
  recentActivity: [
    {
      id: 1,
      type: 'GAME' as const,
      message: 'Game against Warriors scheduled',
      timestamp: '2024-01-12T10:00:00Z'
    },
    {
      id: 2,
      type: 'SCOUTING' as const,
      message: 'New scouting report: Warriors Analysis',
      timestamp: '2024-01-11T15:30:00Z'
    }
  ],
  analyticsData: {
    performanceTrend: [
      { month: 'Jan', points: 85, rebounds: 42, assists: 18 },
      { month: 'Feb', points: 92, rebounds: 38, assists: 22 },
      { month: 'Mar', points: 78, rebounds: 45, assists: 19 }
    ],
    teamStats: {
      totalPossessions: 1250,
      offensiveEfficiency: 112.5,
      defensiveEfficiency: 108.3,
      pace: 98.7
    }
  },
  lastUpdated: '2024-01-12T12:00:00Z'
}

const renderDashboard = () => {
  return render(
    <BrowserRouter>
      <Dashboard />
    </BrowserRouter>
  )
}

describe('Dashboard Component', () => {
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

    mockUseDashboardStore.mockReturnValue({
      data: mockDashboardData,
      isLoading: false,
      error: null,
      lastUpdated: new Date('2024-01-12T12:00:00Z'),
      fetchDashboardData: jest.fn(),
      refreshDashboard: jest.fn(),
      clearError: jest.fn()
    } as any)
  })

  it('renders dashboard with all main sections', () => {
    renderDashboard()

    expect(screen.getByText('Dashboard')).toBeInTheDocument()
    expect(screen.getByText('Welcome back! Here\'s what\'s happening with your team.')).toBeInTheDocument()
  })

  it('displays quick stats correctly', () => {
    renderDashboard()

    expect(screen.getByText('25')).toBeInTheDocument() // Total Games
    expect(screen.getByText('18')).toBeInTheDocument() // Wins
    expect(screen.getByText('7')).toBeInTheDocument() // Losses
    expect(screen.getByText('72.0%')).toBeInTheDocument() // Win Percentage
    expect(screen.getByText('3')).toBeInTheDocument() // Upcoming Games
    expect(screen.getByText('12')).toBeInTheDocument() // Active Players
  })

  it('displays recent games correctly', () => {
    renderDashboard()

    expect(screen.getByText('Recent Games')).toBeInTheDocument()
    expect(screen.getByText('Lakers vs Clippers')).toBeInTheDocument()
    expect(screen.getByText('112 - 108')).toBeInTheDocument()
    expect(screen.getByText('Warriors vs Lakers')).toBeInTheDocument()
    expect(screen.getByText('98 - 105')).toBeInTheDocument()
  })

  it('displays upcoming games correctly', () => {
    renderDashboard()

    expect(screen.getByText('Upcoming Games')).toBeInTheDocument()
    expect(screen.getByText('Lakers vs Warriors')).toBeInTheDocument()
    expect(screen.getByText('Celtics vs Heat')).toBeInTheDocument()
  })

  it('displays recent activity correctly', () => {
    renderDashboard()

    expect(screen.getByText('Recent Activity')).toBeInTheDocument()
    expect(screen.getByText('Game against Warriors scheduled')).toBeInTheDocument()
    expect(screen.getByText('New scouting report: Warriors Analysis')).toBeInTheDocument()
  })

  it('switches between tabs correctly', () => {
    renderDashboard()

    // Click on Analytics tab
    fireEvent.click(screen.getByText('Analytics'))
    expect(screen.getByText('Team Performance Trend')).toBeInTheDocument()
    expect(screen.getByText('Monthly Performance Breakdown')).toBeInTheDocument()

    // Click on Top Players tab
    fireEvent.click(screen.getByText('Top Players'))
    expect(screen.getByText('Top Performers')).toBeInTheDocument()
    expect(screen.getByText('LeBron James')).toBeInTheDocument()
    expect(screen.getByText('Anthony Davis')).toBeInTheDocument()
  })

  it('displays team statistics in analytics tab', () => {
    renderDashboard()

    fireEvent.click(screen.getByText('Analytics'))

    expect(screen.getByText('Total Possessions')).toBeInTheDocument()
    expect(screen.getByText('1250')).toBeInTheDocument()
    expect(screen.getByText('Offensive Efficiency')).toBeInTheDocument()
    expect(screen.getByText('112.5')).toBeInTheDocument()
    expect(screen.getByText('Defensive Efficiency')).toBeInTheDocument()
    expect(screen.getByText('108.3')).toBeInTheDocument()
    expect(screen.getByText('Pace')).toBeInTheDocument()
    expect(screen.getByText('98.7')).toBeInTheDocument()
  })

  it('displays top performers with correct information', () => {
    renderDashboard()

    fireEvent.click(screen.getByText('Top Players'))

    // Check LeBron James
    expect(screen.getByText('LeBron James')).toBeInTheDocument()
    expect(screen.getByText('#23')).toBeInTheDocument()
    expect(screen.getByText('SF')).toBeInTheDocument()
    expect(screen.getByText('25.4')).toBeInTheDocument() // Points
    expect(screen.getByText('7.8')).toBeInTheDocument() // Rebounds
    expect(screen.getByText('6.9')).toBeInTheDocument() // Assists

    // Check Anthony Davis
    expect(screen.getByText('Anthony Davis')).toBeInTheDocument()
    expect(screen.getByText('#3')).toBeInTheDocument()
    expect(screen.getByText('PF')).toBeInTheDocument()
    expect(screen.getByText('22.1')).toBeInTheDocument() // Points
    expect(screen.getByText('9.2')).toBeInTheDocument() // Rebounds
    expect(screen.getByText('3.1')).toBeInTheDocument() // Assists
  })

  it('shows loading state correctly', () => {
    mockUseDashboardStore.mockReturnValue({
      data: null,
      isLoading: true,
      error: null,
      lastUpdated: null,
      fetchDashboardData: jest.fn(),
      refreshDashboard: jest.fn(),
      clearError: jest.fn()
    } as any)

    renderDashboard()

    expect(screen.getByText('Loading dashboard data...')).toBeInTheDocument()
  })

  it('shows error state correctly', () => {
    mockUseDashboardStore.mockReturnValue({
      data: null,
      isLoading: false,
      error: 'Failed to fetch dashboard data',
      lastUpdated: null,
      fetchDashboardData: jest.fn(),
      refreshDashboard: jest.fn(),
      clearError: jest.fn()
    } as any)

    renderDashboard()

    expect(screen.getByText('Error loading dashboard')).toBeInTheDocument()
    expect(screen.getByText('Failed to fetch dashboard data')).toBeInTheDocument()
  })

  it('calls fetchDashboardData on mount', () => {
    const mockFetchDashboardData = jest.fn()
    mockUseDashboardStore.mockReturnValue({
      data: mockDashboardData,
      isLoading: false,
      error: null,
      lastUpdated: new Date('2024-01-12T12:00:00Z'),
      fetchDashboardData: mockFetchDashboardData,
      refreshDashboard: jest.fn(),
      clearError: jest.fn()
    } as any)

    renderDashboard()

    expect(mockFetchDashboardData).toHaveBeenCalledTimes(1)
  })

  it('handles refresh button click', () => {
    const mockRefreshDashboard = jest.fn()
    mockUseDashboardStore.mockReturnValue({
      data: mockDashboardData,
      isLoading: false,
      error: null,
      lastUpdated: new Date('2024-01-12T12:00:00Z'),
      fetchDashboardData: jest.fn(),
      refreshDashboard: mockRefreshDashboard,
      clearError: jest.fn()
    } as any)

    renderDashboard()

    const refreshButton = screen.getByRole('button', { name: /refresh/i })
    fireEvent.click(refreshButton)

    expect(mockRefreshDashboard).toHaveBeenCalledTimes(1)
  })

  it('displays win/loss indicators correctly', () => {
    renderDashboard()

    // Check for win indicator (green dot)
    const winIndicators = screen.getAllByRole('generic').filter(el => 
      el.className.includes('bg-green-500')
    )
    expect(winIndicators.length).toBeGreaterThan(0)

    // Check for loss indicator (red dot)
    const lossIndicators = screen.getAllByRole('generic').filter(el => 
      el.className.includes('bg-red-500')
    )
    expect(lossIndicators.length).toBeGreaterThan(0)
  })

  it('displays activity type indicators correctly', () => {
    renderDashboard()

    // Check for different activity type indicators
    const gameIndicators = screen.getAllByRole('generic').filter(el => 
      el.className.includes('bg-green-500')
    )
    const scoutingIndicators = screen.getAllByRole('generic').filter(el => 
      el.className.includes('bg-purple-500')
    )

    expect(gameIndicators.length).toBeGreaterThan(0)
    expect(scoutingIndicators.length).toBeGreaterThan(0)
  })

  it('handles empty data gracefully', () => {
    const emptyData = {
      ...mockDashboardData,
      upcomingGames: [],
      recentGames: [],
      topPerformers: [],
      recentActivity: []
    }

    mockUseDashboardStore.mockReturnValue({
      data: emptyData,
      isLoading: false,
      error: null,
      lastUpdated: new Date('2024-01-12T12:00:00Z'),
      fetchDashboardData: jest.fn(),
      refreshDashboard: jest.fn(),
      clearError: jest.fn()
    } as any)

    renderDashboard()

    // Should still render the main dashboard structure
    expect(screen.getByText('Dashboard')).toBeInTheDocument()
    expect(screen.getByText('Welcome back! Here\'s what\'s happening with your team.')).toBeInTheDocument()
  })
})
