import { useState, useEffect } from 'react'
import { 
  BookOpenIcon, 
  PlusIcon, 
  PencilIcon, 
  TrashIcon,
  DocumentDuplicateIcon,
  MagnifyingGlassIcon,
  FunnelIcon,
  Squares2X2Icon,
  ListBulletIcon
} from '@heroicons/react/24/outline'
import { DndContext, DragOverlay, closestCenter } from '@dnd-kit/core'
import type { DragEndEvent, DragStartEvent } from '@dnd-kit/core'
import { SortableContext, verticalListSortingStrategy, arrayMove } from '@dnd-kit/sortable'
import { useSortable } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { apiWithFallback } from '../services/apiWithFallback'
import { notify } from '../store/notificationsStore'
import type { Play, PlayFilters } from '../services/playbook'
import { testPlaysApi } from '../utils/testApi'

// Helper function to transform backend play data to frontend format
const transformPlayData = (backendPlay: any): Play => {
  // Debug: Log the raw backend data for the first few plays
  if (Math.random() < 0.1) { // Only log 10% of the time to avoid spam
    console.log('🔍 Raw backend play data:', {
      id: backendPlay.id,
      name: backendPlay.name,
      is_favorite: backendPlay.is_favorite,
      is_favorite_type: typeof backendPlay.is_favorite
    })
  }
  
  return {
    ...backendPlay,
    // Ensure all required fields have default values
    tags: backendPlay.tags || [],
    steps: backendPlay.steps || [],
    success_rate: backendPlay.success_rate || 0,
    last_used: backendPlay.last_used || new Date().toISOString().split('T')[0],
    is_favorite: Boolean(backendPlay.is_favorite),
    difficulty: backendPlay.difficulty || 'Beginner',
    duration: backendPlay.duration || 12,
    players: backendPlay.players || 5,
  }
}

// Helper function to load plays from API
const loadPlays = async (filters: PlayFilters = {}): Promise<Play[]> => {
  try {
    const response = await apiWithFallback.getPlays(filters)
    console.log('🔍 Raw API response:', response)
    
    let playsData: any[] = []
    
    // Handle different response formats
    if (Array.isArray(response)) {
      // Direct array response
      playsData = response
    } else if (response && typeof response === 'object' && 'data' in response && Array.isArray((response as any).data)) {
      // Wrapped in data property
      playsData = (response as any).data
    } else if (response && typeof response === 'object' && 'results' in response && Array.isArray((response as any).results)) {
      // Paginated response
      playsData = (response as any).results
    } else {
      console.warn('Unexpected response format:', response)
      return []
    }
    
    // Transform backend data to frontend format
    return playsData.map(transformPlayData)
  } catch (error) {
    console.error('Failed to load plays:', error)
    notify.error('Error Loading Plays', 'Failed to load plays from the database')
    return []
  }
}

// Sortable Play Card Component
function SortablePlayCard({ play, onEdit, onDelete, onDuplicate, onToggleFavorite }: {
  play: Play
  onEdit: (play: Play) => void
  onDelete: (id: string) => void
  onDuplicate: (play: Play) => void
  onToggleFavorite: (id: string) => void
}) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: play.id })

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  }

  const getCategoryColor = (category: string) => {
    switch (category) {
      case 'Offense': return 'bg-green-100 text-green-800 border-green-200'
      case 'Defense': return 'bg-red-100 text-red-800 border-red-200'
      case 'Special Situations': return 'bg-purple-100 text-purple-800 border-purple-200'
      default: return 'bg-gray-100 text-gray-800 border-gray-200'
    }
  }

  const getDifficultyColor = (difficulty: string) => {
    switch (difficulty) {
      case 'Beginner': return 'bg-blue-100 text-blue-800'
      case 'Intermediate': return 'bg-yellow-100 text-yellow-800'
      case 'Advanced': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  return (
    <div
      ref={setNodeRef}
      style={style}
      {...attributes}
      className="bg-white dark:bg-gray-800 rounded-lg shadow-md border border-gray-200 dark:border-gray-700 p-6 hover:shadow-lg transition-shadow"
    >
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1">
          <div className="flex items-center space-x-2 mb-2">
            <div 
              {...listeners}
              className="cursor-move p-1 hover:bg-gray-100 rounded"
              title="Drag to reorder"
            >
              <svg className="w-4 h-4 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                <path d="M7 2a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM7 8a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM7 14a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 2a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 8a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM13 14a2 2 0 1 0 0 4 2 2 0 0 0 0-4z"/>
              </svg>
            </div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{play.name}</h3>
            {play.is_favorite && (
              <span className="text-yellow-500">⭐</span>
            )}
          </div>
          <p className="text-gray-600 dark:text-gray-400 text-sm mb-3">{play.description}</p>
          
          <div className="flex flex-wrap gap-2 mb-3">
            <span className={`px-2 py-1 rounded-full text-xs font-medium border ${getCategoryColor(play.category?.name || 'Unknown')}`}>
              {play.category?.name || 'Unknown'}
            </span>
            <span className={`px-2 py-1 rounded-full text-xs font-medium ${getDifficultyColor(play.difficulty)}`}>
              {play.difficulty}
            </span>
            <span className="px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
              {play.duration}s
            </span>
            <span className="px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
              {play.players} players
            </span>
          </div>

          <div className="flex items-center justify-between text-sm text-gray-500 dark:text-gray-400">
            <span>Success Rate: {play.success_rate}%</span>
            <span>Last used: {play.last_used}</span>
          </div>
        </div>

        <div className="flex items-center space-x-2 ml-4">
          <button
            onClick={(e) => {
              e.stopPropagation()
              console.log('⭐ Favorite button clicked in UI for play:', play.id)
              onToggleFavorite(play.id)
            }}
            className={`p-2 rounded-lg transition-colors ${
              play.is_favorite 
                ? 'text-yellow-500 hover:bg-yellow-50' 
                : 'text-gray-400 hover:bg-gray-50 hover:text-yellow-500'
            }`}
          >
            ⭐
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation()
              console.log('✏️ Edit button clicked in UI for play:', play.id)
              onEdit(play)
            }}
            className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
          >
            <PencilIcon className="w-4 h-4" />
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation()
              console.log('📋 Duplicate button clicked in UI for play:', play.id)
              onDuplicate(play)
            }}
            className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
          >
            <DocumentDuplicateIcon className="w-4 h-4" />
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation()
              console.log('🗑️ Delete button clicked in UI for play:', play.id)
              onDelete(play.id)
            }}
            className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
          >
            <TrashIcon className="w-4 h-4" />
          </button>
        </div>
      </div>

      <div className="flex flex-wrap gap-1">
        {(play.tags || []).map((tag, index) => (
          <span
            key={index}
            className="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300 text-xs rounded"
          >
            #{tag}
          </span>
        ))}
      </div>
    </div>
  )
}

// Edit Play Modal Component
function EditPlayModal({ play, onClose, onSave }: {
  play: Play
  onClose: () => void
  onSave: (updatedPlay: Partial<Play>) => void
}) {
  const [formData, setFormData] = useState({
    name: play.name,
    description: play.description || '',
    play_type: play.play_type,
    difficulty: play.difficulty,
    duration: play.duration,
    players: play.players,
    success_rate: play.success_rate,
    tags: play.tags.join(', '),
    subcategory: play.subcategory || '',
    diagram_url: play.diagram_url || '',
    video_url: play.video_url || '',
  })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    const updatedPlay = {
      name: formData.name,
      description: formData.description,
      play_type: formData.play_type,
      difficulty: formData.difficulty,
      duration: Number(formData.duration),
      players: Number(formData.players),
      success_rate: Number(formData.success_rate),
      tags: formData.tags.split(',').map(tag => tag.trim()).filter(tag => tag),
      subcategory: formData.subcategory,
      diagram_url: formData.diagram_url,
      video_url: formData.video_url,
    }
    onSave(updatedPlay)
  }

  const handleChange = (field: string, value: any) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
              Edit Play: {play.name}
            </h2>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Basic Information */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Play Name *
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => handleChange('name', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Play Type *
                </label>
                <select
                  value={formData.play_type}
                  onChange={(e) => handleChange('play_type', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                  required
                >
                  <option value="OFFENSIVE">Offensive</option>
                  <option value="DEFENSIVE">Defensive</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Description
              </label>
              <textarea
                value={formData.description}
                onChange={(e) => handleChange('description', e.target.value)}
                rows={3}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                placeholder="Describe the play..."
              />
            </div>

            {/* Play Details */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Difficulty *
                </label>
                <select
                  value={formData.difficulty}
                  onChange={(e) => handleChange('difficulty', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                  required
                >
                  <option value="Beginner">Beginner</option>
                  <option value="Intermediate">Intermediate</option>
                  <option value="Advanced">Advanced</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Duration (seconds)
                </label>
                <input
                  type="number"
                  value={formData.duration}
                  onChange={(e) => handleChange('duration', parseInt(e.target.value) || 0)}
                  min="1"
                  max="24"
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Number of Players
                </label>
                <input
                  type="number"
                  value={formData.players}
                  onChange={(e) => handleChange('players', parseInt(e.target.value) || 0)}
                  min="1"
                  max="10"
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Success Rate (%)
                </label>
                <input
                  type="number"
                  value={formData.success_rate}
                  onChange={(e) => handleChange('success_rate', parseFloat(e.target.value) || 0)}
                  min="0"
                  max="100"
                  step="0.1"
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Subcategory
                </label>
                <input
                  type="text"
                  value={formData.subcategory}
                  onChange={(e) => handleChange('subcategory', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                  placeholder="e.g., Pick and Roll, Zone Defense"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Tags (comma-separated)
              </label>
              <input
                type="text"
                value={formData.tags}
                onChange={(e) => handleChange('tags', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                placeholder="e.g., pick, roll, screen, ball-handler"
              />
            </div>

            {/* Media URLs */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Diagram URL
                </label>
                <input
                  type="url"
                  value={formData.diagram_url}
                  onChange={(e) => handleChange('diagram_url', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                  placeholder="https://example.com/diagram.png"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Video URL
                </label>
                <input
                  type="url"
                  value={formData.video_url}
                  onChange={(e) => handleChange('video_url', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                  placeholder="https://youtube.com/watch?v=..."
                />
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex items-center justify-end space-x-4 pt-6 border-t border-gray-200 dark:border-gray-700">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-gray-700 dark:text-gray-300 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                Save Changes
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  )
}

export function Playbook() {
  const [plays, setPlays] = useState<Play[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCategory, setSelectedCategory] = useState<string>('')
  const [selectedDifficulty, setSelectedDifficulty] = useState<string>('')
  const [showFavoritesOnly, setShowFavoritesOnly] = useState<boolean>(false)
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [showFilters, setShowFilters] = useState(false)
  const [activeId, setActiveId] = useState<string | null>(null)
  const [editingPlay, setEditingPlay] = useState<Play | null>(null)
  const [showEditModal, setShowEditModal] = useState(false)

  // Load plays on component mount
  useEffect(() => {
    const fetchPlays = async () => {
      setLoading(true)
      setError(null)
      try {
        console.log('🎯 Loading plays from database...')
        
        // Test the API first
        try {
          await testPlaysApi()
        } catch (testError) {
          console.warn('⚠️ API test failed, continuing with normal flow:', testError)
        }
        
        const playsData = await loadPlays()
        console.log('✅ Plays loaded successfully:', playsData.length, 'plays')
        setPlays(playsData)
      } catch (err) {
        setError('Failed to load plays')
        console.error('❌ Error loading plays:', err)
      } finally {
        setLoading(false)
      }
    }

    fetchPlays()
  }, [])

  // Load plays when filters change
  useEffect(() => {
    const fetchFilteredPlays = async () => {
      const filters: PlayFilters = {}
      if (selectedCategory) filters.category = selectedCategory
      if (selectedDifficulty) filters.difficulty = selectedDifficulty
      if (searchTerm) filters.search = searchTerm

      try {
        const playsData = await loadPlays(filters)
        setPlays(playsData)
      } catch (err) {
        console.error('Error loading filtered plays:', err)
      }
    }

    if (!loading) {
      fetchFilteredPlays()
    }
  }, [selectedCategory, selectedDifficulty, searchTerm, loading])

  // Filter plays based on search and filters
  const filteredPlays = plays.filter(play => {
    const matchesSearch = play.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (play.description && play.description.toLowerCase().includes(searchTerm.toLowerCase())) ||
                         play.tags.some(tag => tag.toLowerCase().includes(searchTerm.toLowerCase()))
    
    const matchesCategory = !selectedCategory || play.category?.name === selectedCategory
    const matchesDifficulty = !selectedDifficulty || play.difficulty === selectedDifficulty
    const matchesFavorites = !showFavoritesOnly || play.is_favorite
    
    return matchesSearch && matchesCategory && matchesDifficulty && matchesFavorites
  })

  // Drag and drop handlers
  const handleDragStart = (event: DragStartEvent) => {
    setActiveId(event.active.id as string)
  }

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event
    
    if (over && active.id !== over.id) {
      setPlays((items) => {
        const oldIndex = items.findIndex(item => item.id === active.id)
        const newIndex = items.findIndex(item => item.id === over.id)
        return arrayMove(items, oldIndex, newIndex)
      })
    }
    
    setActiveId(null)
  }

  // Play management functions
  const handleEditPlay = (play: Play) => {
    console.log('Edit play:', play)
    setEditingPlay(play)
    setShowEditModal(true)
  }

  const handleDeletePlay = async (id: string) => {
    console.log('🗑️ Delete button clicked for play:', id)
    if (confirm('Are you sure you want to delete this play?')) {
      try {
        console.log('🗑️ Attempting to delete play:', id)
        await apiWithFallback.deletePlay(id)
        setPlays(plays.filter(play => play.id !== id))
        notify.success('Play Deleted', 'Play has been successfully deleted')
        console.log('✅ Play deleted successfully')
      } catch (error) {
        console.error('❌ Failed to delete play:', error)
        notify.error('Delete Failed', 'Failed to delete the play')
      }
    }
  }

  const handleDuplicatePlay = async (play: Play) => {
    console.log('📋 Duplicate button clicked for play:', play.id, play.name)
    try {
      console.log('📋 Attempting to duplicate play:', play.id)
      const newPlay = await apiWithFallback.duplicatePlay(play.id, `${play.name} (Copy)`) as Play
      setPlays([...plays, newPlay])
      notify.success('Play Duplicated', `"${play.name}" has been duplicated`)
      console.log('✅ Play duplicated successfully:', newPlay)
    } catch (error) {
      console.error('❌ Failed to duplicate play:', error)
      notify.error('Duplicate Failed', 'Failed to duplicate the play')
    }
  }

  const handleToggleFavorite = async (id: string) => {
    console.log('⭐ Favorite button clicked for play:', id)
    try {
      console.log('⭐ Attempting to toggle favorite for play:', id)
      const updatedPlay = await apiWithFallback.toggleFavorite(id) as Play
      setPlays(plays.map(play => 
        play.id === id ? updatedPlay : play
      ))
      const play = plays.find(p => p.id === id)
      notify.success('Favorite Updated', `"${play?.name}" favorite status updated`)
      console.log('✅ Favorite toggled successfully:', updatedPlay)
    } catch (error) {
      console.error('❌ Failed to toggle favorite:', error)
      notify.error('Update Failed', 'Failed to update favorite status')
    }
  }

  const handleAddNewPlay = () => {
    // TODO: Open add new play modal
    console.log('Add new play')
  }

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 animate-fade-in">
      {/* Header */}
      <div className="mb-8">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2 flex items-center">
              <BookOpenIcon className="h-8 w-8 mr-3 text-blue-600" />
              Playbook Manager
            </h1>
            <p className="text-gray-600 dark:text-gray-400">
              Create, organize, and manage your basketball plays with drag-and-drop functionality
            </p>
          </div>
          
          <div className="flex items-center space-x-3 mt-4 sm:mt-0">
            <button
              onClick={handleAddNewPlay}
              className="flex items-center space-x-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              <PlusIcon className="w-4 h-4" />
              <span>New Play</span>
            </button>
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="mb-6">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between space-y-4 sm:space-y-0 sm:space-x-4">
          {/* Search */}
          <div className="relative flex-1">
            <MagnifyingGlassIcon className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
            <input
              type="text"
              placeholder="Search plays..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
            />
          </div>

          {/* Filters Toggle */}
          <button
            onClick={() => setShowFilters(!showFilters)}
            className="flex items-center space-x-2 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          >
            <FunnelIcon className="w-4 h-4" />
            <span>Filters</span>
          </button>

          {/* Quick Favorites Toggle */}
          <button
            onClick={() => setShowFavoritesOnly(!showFavoritesOnly)}
            className={`flex items-center space-x-2 px-3 py-2 rounded-lg transition-colors ${
              showFavoritesOnly 
                ? 'bg-yellow-100 text-yellow-700 border border-yellow-300' 
                : 'border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
            }`}
          >
            <span className="text-lg">⭐</span>
            <span className="text-sm font-medium">
              {showFavoritesOnly ? 'All Plays' : 'Favorites'}
            </span>
          </button>

          {/* View Mode Toggle */}
          <div className="flex items-center space-x-2">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 rounded-lg transition-colors ${
                viewMode === 'grid' 
                  ? 'bg-blue-100 text-blue-600' 
                  : 'text-gray-400 hover:bg-gray-100'
              }`}
            >
              <Squares2X2Icon className="w-4 h-4" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 rounded-lg transition-colors ${
                viewMode === 'list' 
                  ? 'bg-blue-100 text-blue-600' 
                  : 'text-gray-400 hover:bg-gray-100'
              }`}
            >
              <ListBulletIcon className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Filters Panel */}
        {showFilters && (
          <div className="mt-4 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Category
                </label>
                <select
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                >
                  <option value="">All Categories</option>
                  <option value="Offense">Offense</option>
                  <option value="Defense">Defense</option>
                  <option value="Special Situations">Special Situations</option>
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Difficulty
                </label>
                <select
                  value={selectedDifficulty}
                  onChange={(e) => setSelectedDifficulty(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white"
                >
                  <option value="">All Difficulties</option>
                  <option value="Beginner">Beginner</option>
                  <option value="Intermediate">Intermediate</option>
                  <option value="Advanced">Advanced</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Favorites
                </label>
                <div className="flex items-center space-x-2">
                  <input
                    type="checkbox"
                    id="favorites-only"
                    checked={showFavoritesOnly}
                    onChange={(e) => setShowFavoritesOnly(e.target.checked)}
                    className="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
                  />
                  <label htmlFor="favorites-only" className="text-sm text-gray-700 dark:text-gray-300">
                    Show favorites only
                  </label>
                </div>
              </div>

              <div className="flex items-end">
                <button
                  onClick={() => {
                    setSelectedCategory('')
                    setSelectedDifficulty('')
                    setShowFavoritesOnly(false)
                    setSearchTerm('')
                  }}
                  className="w-full px-4 py-2 bg-gray-200 dark:bg-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-500 transition-colors"
                >
                  Clear Filters
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4 mb-6">
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow">
          <div className="text-2xl font-bold text-gray-900 dark:text-white">{plays.length}</div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Total Plays</div>
        </div>
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow">
          <div className="text-2xl font-bold text-gray-900 dark:text-white">
            {plays.filter(p => p.is_favorite).length}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Favorites</div>
        </div>
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow">
          <div className="text-2xl font-bold text-gray-900 dark:text-white">
            {Math.round(plays.reduce((acc, play) => acc + play.success_rate, 0) / plays.length)}%
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Avg Success Rate</div>
        </div>
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow">
          <div className="text-2xl font-bold text-gray-900 dark:text-white">
            {Math.round(plays.reduce((acc, play) => acc + play.duration, 0) / plays.length)}s
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Avg Duration</div>
        </div>
      </div>

      {/* Loading State */}
      {loading && (
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600 dark:text-gray-400">Loading plays...</p>
        </div>
      )}

      {/* Error State */}
      {error && (
        <div className="text-center py-12">
          <div className="text-red-500 text-lg font-medium mb-2">Error Loading Plays</div>
          <p className="text-gray-600 dark:text-gray-400 mb-4">{error}</p>
          <button
            onClick={() => window.location.reload()}
            className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Retry
          </button>
        </div>
      )}

      {/* Plays Grid/List */}
      {!loading && !error && (
        <DndContext
          collisionDetection={closestCenter}
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
        >
        <SortableContext items={filteredPlays.map(play => play.id)} strategy={verticalListSortingStrategy}>
          <div className={`${
            viewMode === 'grid' 
              ? 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6' 
              : 'space-y-4'
          }`}>
            {filteredPlays.map((play) => (
              <SortablePlayCard
                key={play.id}
                play={play}
                onEdit={handleEditPlay}
                onDelete={handleDeletePlay}
                onDuplicate={handleDuplicatePlay}
                onToggleFavorite={handleToggleFavorite}
              />
            ))}
          </div>
        </SortableContext>
        
        <DragOverlay>
          {activeId ? (
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 p-6 opacity-90">
              <div className="text-lg font-semibold text-gray-900 dark:text-white">
                {plays.find(play => play.id === activeId)?.name}
              </div>
            </div>
          ) : null}
        </DragOverlay>
        </DndContext>
      )}

      {/* Empty State */}
      {!loading && !error && filteredPlays.length === 0 ? (
        <div className="text-center py-12">
          <BookOpenIcon className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900 dark:text-white">No plays found</h3>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {searchTerm || selectedCategory || selectedDifficulty
              ? 'Try adjusting your search or filters.'
              : 'Get started by creating your first play.'
            }
          </p>
          <div className="mt-6">
            <button
              onClick={handleAddNewPlay}
              className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
            >
              <PlusIcon className="w-4 h-4 mr-2" />
              Create Play
            </button>
          </div>
        </div>
      ) : null}

      {/* Edit Play Modal */}
      {showEditModal && editingPlay && (
        <EditPlayModal
          play={editingPlay}
          onClose={() => {
            setShowEditModal(false)
            setEditingPlay(null)
          }}
          onSave={async (updatedPlay) => {
            try {
              console.log('💾 Saving play:', updatedPlay)
              const savedPlay = await apiWithFallback.updatePlay(editingPlay.id, updatedPlay) as Play
              setPlays(plays.map(play => 
                play.id === editingPlay.id ? savedPlay : play
              ))
              setShowEditModal(false)
              setEditingPlay(null)
              notify.success('Play Updated', `"${updatedPlay.name}" has been updated successfully`)
            } catch (error) {
              console.error('❌ Failed to update play:', error)
              notify.error('Update Failed', 'Failed to update the play')
            }
          }}
        />
      )}
    </div>
  )
}


