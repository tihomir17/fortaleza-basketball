import { useState } from 'react'
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

// Types
interface Play {
  id: string
  name: string
  description: string
  category: 'Offense' | 'Defense' | 'Special Situations'
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced'
  duration: number // in minutes
  players: number
  tags: string[]
  steps: PlayStep[]
  successRate: number
  lastUsed: string
  createdBy: string
  isFavorite: boolean
}

interface PlayStep {
  id: string
  order: number
  title: string
  description: string
  diagram?: string
  duration: number
}

// Mock data
const mockPlays: Play[] = [
  {
    id: '1',
    name: 'Pick and Roll',
    description: 'Classic pick and roll play with multiple options',
    category: 'Offense',
    difficulty: 'Intermediate',
    duration: 15,
    players: 5,
    tags: ['pick', 'roll', 'screen', 'ball-handler'],
    steps: [
      { id: '1-1', order: 1, title: 'Setup', description: 'Point guard brings ball up court, center sets up at high post', duration: 2 },
      { id: '1-2', order: 2, title: 'Screen', description: 'Center sets pick on point guard defender', duration: 3 },
      { id: '1-3', order: 3, title: 'Roll', description: 'Center rolls to basket, point guard drives or passes', duration: 5 },
      { id: '1-4', order: 4, title: 'Options', description: 'Multiple scoring options based on defense reaction', duration: 5 }
    ],
    successRate: 78,
    lastUsed: '2024-01-15',
    createdBy: 'Coach Smith',
    isFavorite: true
  },
  {
    id: '2',
    name: 'Zone Defense',
    description: '2-3 zone defense with active hands and communication',
    category: 'Defense',
    difficulty: 'Beginner',
    duration: 20,
    players: 5,
    tags: ['zone', 'defense', 'team', 'communication'],
    steps: [
      { id: '2-1', order: 1, title: 'Setup', description: 'Two guards at top, three bigs in the paint', duration: 3 },
      { id: '2-2', order: 2, title: 'Movement', description: 'Defenders shift based on ball movement', duration: 8 },
      { id: '2-3', order: 3, title: 'Communication', description: 'Constant communication and hand activity', duration: 6 },
      { id: '2-4', order: 4, title: 'Rebound', description: 'Box out and secure defensive rebound', duration: 3 }
    ],
    successRate: 85,
    lastUsed: '2024-01-12',
    createdBy: 'Assistant Coach',
    isFavorite: false
  },
  {
    id: '3',
    name: 'Out of Bounds Play',
    description: 'Sideline out of bounds play for last second shot',
    category: 'Special Situations',
    difficulty: 'Advanced',
    duration: 10,
    players: 5,
    tags: ['out-of-bounds', 'last-second', 'clutch', 'special'],
    steps: [
      { id: '3-1', order: 1, title: 'Setup', description: 'All players in specific positions', duration: 2 },
      { id: '3-2', order: 2, title: 'Execution', description: 'Multiple screens and cuts for open shot', duration: 6 },
      { id: '3-3', order: 3, title: 'Shot', description: 'Best available shot opportunity', duration: 2 }
    ],
    successRate: 65,
    lastUsed: '2024-01-10',
    createdBy: 'Head Coach',
    isFavorite: true
  }
]

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
      {...listeners}
      className="bg-white dark:bg-gray-800 rounded-lg shadow-md border border-gray-200 dark:border-gray-700 p-6 hover:shadow-lg transition-shadow cursor-move"
    >
      <div className="flex items-start justify-between mb-4">
        <div className="flex-1">
          <div className="flex items-center space-x-2 mb-2">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{play.name}</h3>
            {play.isFavorite && (
              <span className="text-yellow-500">⭐</span>
            )}
          </div>
          <p className="text-gray-600 dark:text-gray-400 text-sm mb-3">{play.description}</p>
          
          <div className="flex flex-wrap gap-2 mb-3">
            <span className={`px-2 py-1 rounded-full text-xs font-medium border ${getCategoryColor(play.category)}`}>
              {play.category}
            </span>
            <span className={`px-2 py-1 rounded-full text-xs font-medium ${getDifficultyColor(play.difficulty)}`}>
              {play.difficulty}
            </span>
            <span className="px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
              {play.duration} min
            </span>
            <span className="px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
              {play.players} players
            </span>
          </div>

          <div className="flex items-center justify-between text-sm text-gray-500 dark:text-gray-400">
            <span>Success Rate: {play.successRate}%</span>
            <span>Last used: {play.lastUsed}</span>
          </div>
        </div>

        <div className="flex items-center space-x-2 ml-4">
          <button
            onClick={(e) => {
              e.stopPropagation()
              onToggleFavorite(play.id)
            }}
            className={`p-2 rounded-lg transition-colors ${
              play.isFavorite 
                ? 'text-yellow-500 hover:bg-yellow-50' 
                : 'text-gray-400 hover:bg-gray-50 hover:text-yellow-500'
            }`}
          >
            ⭐
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation()
              onEdit(play)
            }}
            className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
          >
            <PencilIcon className="w-4 h-4" />
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation()
              onDuplicate(play)
            }}
            className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition-colors"
          >
            <DocumentDuplicateIcon className="w-4 h-4" />
          </button>
          <button
            onClick={(e) => {
              e.stopPropagation()
              onDelete(play.id)
            }}
            className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
          >
            <TrashIcon className="w-4 h-4" />
          </button>
        </div>
      </div>

      <div className="flex flex-wrap gap-1">
        {play.tags.map((tag, index) => (
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

export function Playbook() {
  const [plays, setPlays] = useState<Play[]>(mockPlays)
  const [searchTerm, setSearchTerm] = useState('')
  const [selectedCategory, setSelectedCategory] = useState<string>('')
  const [selectedDifficulty, setSelectedDifficulty] = useState<string>('')
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [showFilters, setShowFilters] = useState(false)
  const [activeId, setActiveId] = useState<string | null>(null)

  // Filter plays based on search and filters
  const filteredPlays = plays.filter(play => {
    const matchesSearch = play.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         play.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         play.tags.some(tag => tag.toLowerCase().includes(searchTerm.toLowerCase()))
    
    const matchesCategory = !selectedCategory || play.category === selectedCategory
    const matchesDifficulty = !selectedDifficulty || play.difficulty === selectedDifficulty
    
    return matchesSearch && matchesCategory && matchesDifficulty
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
    // TODO: Open edit modal
    console.log('Edit play:', play)
  }

  const handleDeletePlay = (id: string) => {
    if (confirm('Are you sure you want to delete this play?')) {
      setPlays(plays.filter(play => play.id !== id))
    }
  }

  const handleDuplicatePlay = (play: Play) => {
    const newPlay = {
      ...play,
      id: Date.now().toString(),
      name: `${play.name} (Copy)`,
      createdBy: 'Current User',
      lastUsed: new Date().toISOString().split('T')[0]
    }
    setPlays([...plays, newPlay])
  }

  const handleToggleFavorite = (id: string) => {
    setPlays(plays.map(play => 
      play.id === id ? { ...play, isFavorite: !play.isFavorite } : play
    ))
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

              <div className="flex items-end">
                <button
                  onClick={() => {
                    setSelectedCategory('')
                    setSelectedDifficulty('')
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
            {plays.filter(p => p.isFavorite).length}
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Favorites</div>
        </div>
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow">
          <div className="text-2xl font-bold text-gray-900 dark:text-white">
            {Math.round(plays.reduce((acc, play) => acc + play.successRate, 0) / plays.length)}%
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Avg Success Rate</div>
        </div>
        <div className="bg-white dark:bg-gray-800 p-4 rounded-lg shadow">
          <div className="text-2xl font-bold text-gray-900 dark:text-white">
            {Math.round(plays.reduce((acc, play) => acc + play.duration, 0) / plays.length)} min
          </div>
          <div className="text-sm text-gray-600 dark:text-gray-400">Avg Duration</div>
        </div>
      </div>

      {/* Plays Grid/List */}
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

      {/* Empty State */}
      {filteredPlays.length === 0 && (
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
      )}
    </div>
  )
}


