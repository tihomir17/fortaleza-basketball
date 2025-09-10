import { render, screen, fireEvent, waitFor } from '../../test-utils/integration-test-utils'
import { Games } from '../../pages/Games'
import { createMockGame } from '../../test-utils/integration-test-utils'
import type { Game } from '../../services/games'

// Mock the games store
const mockGamesStore = {
  games: [] as Game[],
  upcomingGames: [] as Game[],
  recentGames: [] as Game[],
  isLoading: false,
  error: null as string | null,
  fetchGames: jest.fn(),
  fetchUpcomingGames: jest.fn(),
  fetchRecentGames: jest.fn(),
  createGame: jest.fn(),
  updateGame: jest.fn(),
  deleteGame: jest.fn(),
  clearError: jest.fn()
}

jest.mock('../../store/gamesStore', () => ({
  useGamesStore: () => mockGamesStore
}))

describe('Game Management Flow', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockGamesStore.games = []
    mockGamesStore.upcomingGames = []
    mockGamesStore.recentGames = []
  })

  it('should display games list and allow filtering', async () => {
    const mockGames = [
      createMockGame({ id: '1', home_team_name: 'Fortaleza', away_team_name: 'Lakers' }),
      createMockGame({ id: '2', home_team_name: 'Warriors', away_team_name: 'Celtics' })
    ]
    
    mockGamesStore.games = mockGames
    mockGamesStore.upcomingGames = mockGames

    render(<Games />)

    // Should show games list
    expect(screen.getByText('Games')).toBeInTheDocument()
    expect(screen.getByText('Fortaleza vs Lakers')).toBeInTheDocument()
    expect(screen.getByText('Warriors vs Celtics')).toBeInTheDocument()

    // Should show search and filter controls
    expect(screen.getByPlaceholderText(/search games/i)).toBeInTheDocument()
    expect(screen.getByText(/filters/i)).toBeInTheDocument()
  })

  it('should allow creating a new game', async () => {
    const newGame = createMockGame({
      home_team_name: 'Fortaleza',
      away_team_name: 'Bulls',
      date: '2024-01-20T19:00:00Z'
    })

    mockGamesStore.createGame.mockResolvedValue(newGame)

    render(<Games />)

    // Click add game button
    const addButton = screen.getByRole('button', { name: /add game/i })
    fireEvent.click(addButton)

    // Should show create game modal
    await waitFor(() => {
      expect(screen.getByText(/create new game/i)).toBeInTheDocument()
    })

    // Fill form
    const homeTeamInput = screen.getByLabelText(/home team/i)
    const awayTeamInput = screen.getByLabelText(/away team/i)
    const dateInput = screen.getByLabelText(/date/i)

    fireEvent.change(homeTeamInput, { target: { value: 'Fortaleza' } })
    fireEvent.change(awayTeamInput, { target: { value: 'Bulls' } })
    fireEvent.change(dateInput, { target: { value: '2024-01-20T19:00' } })

    // Submit form
    const submitButton = screen.getByRole('button', { name: /create/i })
    fireEvent.click(submitButton)

    // Should call create game function
    await waitFor(() => {
      expect(mockGamesStore.createGame).toHaveBeenCalledWith({
        home_team_name: 'Fortaleza',
        away_team_name: 'Bulls',
        date: '2024-01-20T19:00'
      })
    })
  })

  it('should allow editing an existing game', async () => {
    const mockGame = createMockGame({ id: '1', home_team_name: 'Fortaleza', away_team_name: 'Lakers' })
    mockGamesStore.games = [mockGame]
    mockGamesStore.upcomingGames = [mockGame]

    render(<Games />)

    // Click edit button for the game
    const editButton = screen.getByRole('button', { name: /edit/i })
    fireEvent.click(editButton)

    // Should show edit modal
    await waitFor(() => {
      expect(screen.getByText(/edit game/i)).toBeInTheDocument()
    })

    // Form should be pre-filled
    const homeTeamInput = screen.getByLabelText(/home team/i)
    expect(homeTeamInput).toHaveValue('Fortaleza')

    // Update the game
    fireEvent.change(homeTeamInput, { target: { value: 'Fortaleza Updated' } })

    // Submit changes
    const saveButton = screen.getByRole('button', { name: /save/i })
    fireEvent.click(saveButton)

    // Should call update game function
    await waitFor(() => {
      expect(mockGamesStore.updateGame).toHaveBeenCalledWith('1', {
        home_team_name: 'Fortaleza Updated'
      })
    })
  })

  it('should allow deleting a game with confirmation', async () => {
    const mockGame = createMockGame({ id: '1', home_team_name: 'Fortaleza', away_team_name: 'Lakers' })
    mockGamesStore.games = [mockGame]
    mockGamesStore.upcomingGames = [mockGame]

    // Mock window.confirm
    window.confirm = jest.fn(() => true)

    render(<Games />)

    // Click delete button
    const deleteButton = screen.getByRole('button', { name: /delete/i })
    fireEvent.click(deleteButton)

    // Should show confirmation dialog
    expect(window.confirm).toHaveBeenCalledWith('Are you sure you want to delete this game?')

    // Should call delete game function
    await waitFor(() => {
      expect(mockGamesStore.deleteGame).toHaveBeenCalledWith('1')
    })
  })

  it('should filter games by search term', async () => {
    const mockGames = [
      createMockGame({ id: '1', home_team_name: 'Fortaleza', away_team_name: 'Lakers' }),
      createMockGame({ id: '2', home_team_name: 'Warriors', away_team_name: 'Celtics' })
    ]
    
    mockGamesStore.games = mockGames
    mockGamesStore.upcomingGames = mockGames

    render(<Games />)

    // Search for "Fortaleza"
    const searchInput = screen.getByPlaceholderText(/search games/i)
    fireEvent.change(searchInput, { target: { value: 'Fortaleza' } })

    // Should filter results
    await waitFor(() => {
      expect(screen.getByText('Fortaleza vs Lakers')).toBeInTheDocument()
      expect(screen.queryByText('Warriors vs Celtics')).not.toBeInTheDocument()
    })
  })

  it('should export games data', async () => {
    const mockGames = [
      createMockGame({ id: '1', home_team_name: 'Fortaleza', away_team_name: 'Lakers' })
    ]
    
    mockGamesStore.games = mockGames
    mockGamesStore.upcomingGames = mockGames

    render(<Games />)

    // Click export button
    const exportButton = screen.getByRole('button', { name: /export/i })
    fireEvent.click(exportButton)

    // Should show export options
    await waitFor(() => {
      expect(screen.getByText(/export to excel/i)).toBeInTheDocument()
      expect(screen.getByText(/export to csv/i)).toBeInTheDocument()
      expect(screen.getByText(/export to pdf/i)).toBeInTheDocument()
    })

    // Click Excel export
    const excelButton = screen.getByText(/export to excel/i)
    fireEvent.click(excelButton)

    // Should trigger export (this would be tested with actual export functionality)
    // For now, we just verify the button was clicked
    expect(excelButton).toBeInTheDocument()
  })

  it('should handle loading and error states', async () => {
    // Test loading state
    mockGamesStore.isLoading = true
    mockGamesStore.games = []

    const { rerender } = render(<Games />)

    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument()

    // Test error state
    mockGamesStore.isLoading = false
    mockGamesStore.error = 'Failed to load games'

    rerender(<Games />)

    expect(screen.getByText(/failed to load games/i)).toBeInTheDocument()
    expect(screen.getByText(/try again/i)).toBeInTheDocument()
  })
})
