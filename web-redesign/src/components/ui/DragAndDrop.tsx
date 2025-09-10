import { useState } from 'react'
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  // DragEndEvent,
} from '@dnd-kit/core'
import type { DragEndEvent } from '@dnd-kit/core'
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  verticalListSortingStrategy,
} from '@dnd-kit/sortable'
import {
  useSortable,
} from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import { Bars3Icon } from '@heroicons/react/24/outline'
import { cn } from '../../utils/cn'

interface SortableItemProps {
  id: string
  children: React.ReactNode
  className?: string
}

function SortableItem({ id, children, className }: SortableItemProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id })

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
  }

  return (
    <div
      ref={setNodeRef}
      style={style}
      className={cn(
        'flex items-center space-x-3 p-3 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg',
        isDragging && 'opacity-50 shadow-lg',
        className
      )}
      {...attributes}
    >
      <div
        {...listeners}
        className="cursor-grab active:cursor-grabbing text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
      >
        <Bars3Icon className="w-5 h-5" />
      </div>
      <div className="flex-1">{children}</div>
    </div>
  )
}

interface DragAndDropListProps<T extends { id: string } = { id: string; [key: string]: unknown }> {
  items: T[]
  onReorder: (items: T[]) => void
  renderItem: (item: T) => React.ReactNode
  className?: string
}

export function DragAndDropList<T extends { id: string } = { id: string; [key: string]: unknown }>({ items, onReorder, renderItem, className }: DragAndDropListProps<T>) {
  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates,
    })
  )

  function handleDragEnd(event: DragEndEvent) {
    const { active, over } = event

    if (active.id !== over?.id) {
      const oldIndex = items.findIndex((item) => item.id === active.id)
      const newIndex = items.findIndex((item) => item.id === over?.id)

      const newItems = arrayMove(items, oldIndex, newIndex)
      onReorder(newItems)
    }
  }

  return (
    <DndContext
      sensors={sensors}
      collisionDetection={closestCenter}
      onDragEnd={handleDragEnd}
    >
      <SortableContext items={items.map(item => item.id)} strategy={verticalListSortingStrategy}>
        <div className={cn('space-y-2', className)}>
          {items.map((item) => (
            <SortableItem key={item.id} id={item.id}>
              {renderItem(item)}
            </SortableItem>
          ))}
        </div>
      </SortableContext>
    </DndContext>
  )
}

// Player lineup drag and drop
interface Player {
  id: string
  name: string
  position: string
  jersey: number
}

interface PlayerLineupProps {
  players: Player[]
  onReorder: (players: Player[]) => void
  title?: string
}

export function PlayerLineup({ players, onReorder, title = 'Starting Lineup' }: PlayerLineupProps) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-100 dark:border-gray-700 p-6">
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">{title}</h3>
      <DragAndDropList
        items={players}
        onReorder={onReorder}
        renderItem={(player) => (
          <div className="flex items-center justify-between w-full">
            <div className="flex items-center space-x-3">
              <div className="w-8 h-8 bg-fortaleza-blue text-white rounded-full flex items-center justify-center text-sm font-medium">
                {player.jersey}
              </div>
              <div>
                <div className="font-medium text-gray-900 dark:text-white">{player.name}</div>
                <div className="text-sm text-gray-500 dark:text-gray-400">{player.position}</div>
              </div>
            </div>
          </div>
        )}
      />
    </div>
  )
}

// Game schedule drag and drop
interface Game {
  id: string
  homeTeam: string
  awayTeam: string
  date: string
  time: string
}

interface GameScheduleProps {
  games: Game[]
  onReorder: (games: Game[]) => void
  title?: string
}

export function GameSchedule({ games, onReorder, title = 'Game Schedule' }: GameScheduleProps) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-100 dark:border-gray-700 p-6">
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">{title}</h3>
      <DragAndDropList
        items={games}
        onReorder={onReorder}
        renderItem={(game) => (
          <div className="flex items-center justify-between w-full">
            <div className="flex items-center space-x-4">
              <div className="text-center">
                <div className="font-medium text-gray-900 dark:text-white">{game.homeTeam}</div>
                <div className="text-sm text-gray-500 dark:text-gray-400">vs</div>
                <div className="font-medium text-gray-900 dark:text-white">{game.awayTeam}</div>
              </div>
            </div>
            <div className="text-right">
              <div className="text-sm text-gray-900 dark:text-white">{game.date}</div>
              <div className="text-sm text-gray-500 dark:text-gray-400">{game.time}</div>
            </div>
          </div>
        )}
      />
    </div>
  )
}

// Simple drag and drop zone
interface DropZoneProps {
  onDrop: (files: File[]) => void
  accept?: string
  maxFiles?: number
  className?: string
  children?: React.ReactNode
}

export function DropZone({ onDrop, maxFiles = 10, className, children }: DropZoneProps) {
  const [isDragOver, setIsDragOver] = useState(false)

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(true)
  }

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(false)
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragOver(false)

    const files = Array.from(e.dataTransfer.files)
    if (files.length <= maxFiles) {
      onDrop(files)
    }
  }

  return (
    <div
      className={cn(
        'border-2 border-dashed rounded-lg p-8 text-center transition-colors',
        isDragOver
          ? 'border-fortaleza-blue bg-blue-50 dark:bg-blue-900/20'
          : 'border-gray-300 dark:border-gray-600 hover:border-gray-400 dark:hover:border-gray-500',
        className
      )}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      {children || (
        <div>
          <div className="text-gray-600 dark:text-gray-400 mb-2">
            Drag and drop files here, or click to select
          </div>
          <div className="text-sm text-gray-500 dark:text-gray-500">
            Max {maxFiles} files
          </div>
        </div>
      )}
    </div>
  )
}
