import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Playbook } from '../Playbook'
import { apiWithFallback } from '../../services/apiWithFallback'

// Mock the API
jest.mock('../../services/apiWithFallback')
const mockApiWithFallback = apiWithFallback as jest.Mocked<typeof apiWithFallback>

// Mock the notification system
jest.mock('../../hooks/useNotification', () => ({
  useNotification: () => ({
    success: jest.fn(),
    error: jest.fn(),
    info: jest.fn(),
    warning: jest.fn(),
  }),
}))

const mockPlays = [
  {
    id: '1',
    name: 'Test Play 1',
    description: 'A test play',
    play_type: 'OFFENSIVE' as const,
    team: 1,
    category: { id: 1, name: 'Offense' },
    subcategory: 'Fast Break',
    action_type: 'NORMAL',
    diagram_url: '',
    video_url: '',
    tags: ['test', 'offense'],
    difficulty: 'Beginner' as const,
    duration: 12,
    players: 5,
    success_rate: 75.5,
    last_used: '2024-01-01',
    is_favorite: false,
    created_by: 1,
    created_by_name: 'Test User',
    steps: [],
  },
  {
    id: '2',
    name: 'Test Play 2',
    description: 'Another test play',
    play_type: 'DEFENSIVE' as const,
    team: 1,
    category: { id: 2, name: 'Defense' },
    subcategory: 'Zone',
    action_type: 'NORMAL',
    diagram_url: '',
    video_url: '',
    tags: ['test', 'defense'],
    difficulty: 'Intermediate' as const,
    duration: 15,
    players: 5,
    success_rate: 60.0,
    last_used: '2024-01-02',
    is_favorite: true,
    created_by: 1,
    created_by_name: 'Test User',
    steps: [],
  },
]

const renderPlaybook = () => {
  return render(
    <BrowserRouter>
      <Playbook />
    </BrowserRouter>
  )
}

describe('Playbook Component', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockApiWithFallback.getPlays.mockResolvedValue({ data: mockPlays })
  })

  it('renders playbook with plays', async () => {
    renderPlaybook()
    
    await waitFor(() => {
      expect(screen.getByText('Test Play 1')).toBeInTheDocument()
      expect(screen.getByText('Test Play 2')).toBeInTheDocument()
    })
  })

  it('filters plays by search term', async () => {
    renderPlaybook()
    
    await waitFor(() => {
      expect(screen.getByText('Test Play 1')).toBeInTheDocument()
    })
    
    const searchInput = screen.getByPlaceholderText('Search plays...')
    fireEvent.change(searchInput, { target: { value: 'Test Play 1' } })
    
    await waitFor(() => {
      expect(screen.getByText('Test Play 1')).toBeInTheDocument()
      expect(screen.queryByText('Test Play 2')).not.toBeInTheDocument()
    })
  })

  it('filters plays by difficulty', async () => {
    renderPlaybook()
    
    await waitFor(() => {
      expect(screen.getByText('Test Play 1')).toBeInTheDocument()
    })
    
    const difficultyFilter = screen.getByDisplayValue('All Difficulties')
    fireEvent.change(difficultyFilter, { target: { value: 'Beginner' } })
    
    await waitFor(() => {
      expect(screen.getByText('Test Play 1')).toBeInTheDocument()
      expect(screen.queryByText('Test Play 2')).not.toBeInTheDocument()
    })
  })

  it('toggles favorites filter', async () => {
    renderPlaybook()
    
    await waitFor(() => {
      expect(screen.getByText('Test Play 1')).toBeInTheDocument()
    })
    
    const favoritesToggle = screen.getByText('Favorites Only')
    fireEvent.click(favoritesToggle)
    
    await waitFor(() => {
      expect(screen.queryByText('Test Play 1')).not.toBeInTheDocument()
      expect(screen.getByText('Test Play 2')).toBeInTheDocument()
    })
  })

  it('opens edit modal when edit button is clicked', async () => {
    mockApiWithFallback.updatePlay.mockResolvedValue({ data: mockPlays[0] })
    
    renderPlaybook()
    
    await waitFor(() => {
      expect(screen.getByText('Test Play 1')).toBeInTheDocument()
    })
    
    const editButtons = screen.getAllByLabelText(/edit/i)
    fireEvent.click(editButtons[0])
    
    await waitFor(() => {
      expect(screen.getByText('Edit Play: Test Play 1')).toBeInTheDocument()
    })
  })

  it('toggles favorite status', async () => {
    mockApiWithFallback.toggleFavorite.mockResolvedValue({ data: { ...mockPlays[0], is_favorite: true } })
    
    renderPlaybook()
    
    await waitFor(() => {
      expect(screen.getByText('Test Play 1')).toBeInTheDocument()
    })
    
    const favoriteButtons = screen.getAllByLabelText(/favorite/i)
    fireEvent.click(favoriteButtons[0])
    
    await waitFor(() => {
      expect(mockApiWithFallback.toggleFavorite).toHaveBeenCalledWith('1')
    })
  })

  it('deletes play when delete button is clicked', async () => {
    mockApiWithFallback.deletePlay.mockResolvedValue({ success: true })
    
    renderPlaybook()
    
    await waitFor(() => {
      expect(screen.getByText('Test Play 1')).toBeInTheDocument()
    })
    
    const deleteButtons = screen.getAllByLabelText(/delete/i)
    fireEvent.click(deleteButtons[0])
    
    // Confirm deletion in the confirmation dialog
    const confirmButton = screen.getByText('Delete')
    fireEvent.click(confirmButton)
    
    await waitFor(() => {
      expect(mockApiWithFallback.deletePlay).toHaveBeenCalledWith('1')
    })
  })

  it('duplicates play when duplicate button is clicked', async () => {
    mockApiWithFallback.duplicatePlay.mockResolvedValue({ data: { ...mockPlays[0], name: 'Test Play 1 (Copy)' } })
    
    renderPlaybook()
    
    await waitFor(() => {
      expect(screen.getByText('Test Play 1')).toBeInTheDocument()
    })
    
    const duplicateButtons = screen.getAllByLabelText(/duplicate/i)
    fireEvent.click(duplicateButtons[0])
    
    await waitFor(() => {
      expect(mockApiWithFallback.duplicatePlay).toHaveBeenCalledWith('1', undefined)
    })
  })

  it('handles API errors gracefully', async () => {
    mockApiWithFallback.getPlays.mockRejectedValue(new Error('API Error'))
    
    renderPlaybook()
    
    await waitFor(() => {
      expect(screen.getByText(/error loading plays/i)).toBeInTheDocument()
    })
  })
})
