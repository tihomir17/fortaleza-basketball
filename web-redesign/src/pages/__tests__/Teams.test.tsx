import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import Teams from '../Teams'
import { useTeamsStore } from '../../store/teamsStore'

// Mock the teams store
jest.mock('../../store/teamsStore')
const mockUseTeamsStore = useTeamsStore as jest.MockedFunction<typeof useTeamsStore>

// Mock the notification system
jest.mock('../../hooks/useNotification', () => ({
  useNotification: () => ({
    success: jest.fn(),
    error: jest.fn(),
    info: jest.fn(),
    warning: jest.fn(),
  }),
}))

const mockTeams = [
  {
    id: 1,
    name: 'Test Team 1',
    description: 'A test team',
    competition: 1,
    coaches: [1, 2],
    players: [3, 4, 5],
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z',
  },
  {
    id: 2,
    name: 'Test Team 2',
    description: 'Another test team',
    competition: 2,
    coaches: [1],
    players: [6, 7, 8, 9],
    created_at: '2024-01-02T00:00:00Z',
    updated_at: '2024-01-02T00:00:00Z',
  },
]

const mockStore = {
  teams: mockTeams,
  loading: false,
  error: null,
  fetchTeams: jest.fn(),
  createTeam: jest.fn(),
  updateTeam: jest.fn(),
  deleteTeam: jest.fn(),
}

const renderTeams = () => {
  return render(
    <BrowserRouter>
      <Teams />
    </BrowserRouter>
  )
}

describe('Teams Component', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockUseTeamsStore.mockReturnValue(mockStore)
  })

  it('renders teams list', () => {
    renderTeams()
    
    expect(screen.getByText('Test Team 1')).toBeInTheDocument()
    expect(screen.getByText('Test Team 2')).toBeInTheDocument()
    expect(screen.getByText('A test team')).toBeInTheDocument()
    expect(screen.getByText('Another test team')).toBeInTheDocument()
  })

  it('shows create team button', () => {
    renderTeams()
    
    expect(screen.getByText('Create Team')).toBeInTheDocument()
  })

  it('opens create team modal when button is clicked', () => {
    renderTeams()
    
    const createButton = screen.getByText('Create Team')
    fireEvent.click(createButton)
    
    expect(screen.getByText('Create New Team')).toBeInTheDocument()
  })

  it('filters teams by search term', () => {
    renderTeams()
    
    const searchInput = screen.getByPlaceholderText('Search teams...')
    fireEvent.change(searchInput, { target: { value: 'Test Team 1' } })
    
    expect(screen.getByText('Test Team 1')).toBeInTheDocument()
    expect(screen.queryByText('Test Team 2')).not.toBeInTheDocument()
  })

  it('shows edit and delete buttons for each team', () => {
    renderTeams()
    
    const editButtons = screen.getAllByLabelText(/edit team/i)
    const deleteButtons = screen.getAllByLabelText(/delete team/i)
    
    expect(editButtons).toHaveLength(2)
    expect(deleteButtons).toHaveLength(2)
  })

  it('opens edit modal when edit button is clicked', () => {
    renderTeams()
    
    const editButtons = screen.getAllByLabelText(/edit team/i)
    fireEvent.click(editButtons[0])
    
    expect(screen.getByText('Edit Team')).toBeInTheDocument()
    expect(screen.getByDisplayValue('Test Team 1')).toBeInTheDocument()
  })

  it('shows delete confirmation when delete button is clicked', () => {
    renderTeams()
    
    const deleteButtons = screen.getAllByLabelText(/delete team/i)
    fireEvent.click(deleteButtons[0])
    
    expect(screen.getByText('Delete Team')).toBeInTheDocument()
    expect(screen.getByText('Are you sure you want to delete "Test Team 1"?')).toBeInTheDocument()
  })

  it('calls deleteTeam when confirmed', async () => {
    mockStore.deleteTeam.mockResolvedValue(undefined)
    
    renderTeams()
    
    const deleteButtons = screen.getAllByLabelText(/delete team/i)
    fireEvent.click(deleteButtons[0])
    
    const confirmButton = screen.getByText('Delete')
    fireEvent.click(confirmButton)
    
    await waitFor(() => {
      expect(mockStore.deleteTeam).toHaveBeenCalledWith(1)
    })
  })

  it('shows loading state', () => {
    mockUseTeamsStore.mockReturnValue({
      ...mockStore,
      loading: true,
    })
    
    renderTeams()
    
    expect(screen.getByText(/loading/i)).toBeInTheDocument()
  })

  it('shows error state', () => {
    mockUseTeamsStore.mockReturnValue({
      ...mockStore,
      error: 'Failed to load teams',
    })
    
    renderTeams()
    
    expect(screen.getByText('Failed to load teams')).toBeInTheDocument()
  })

  it('shows empty state when no teams', () => {
    mockUseTeamsStore.mockReturnValue({
      ...mockStore,
      teams: [],
    })
    
    renderTeams()
    
    expect(screen.getByText('No teams found')).toBeInTheDocument()
    expect(screen.getByText('Create your first team to get started')).toBeInTheDocument()
  })
})
