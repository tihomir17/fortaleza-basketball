import { useEffect, useRef } from 'react'
import { handleKeyboardNavigation } from '../../utils/accessibility'

interface KeyboardNavigationProps {
  onEnter?: () => void
  onEscape?: () => void
  onArrowUp?: () => void
  onArrowDown?: () => void
  onArrowLeft?: () => void
  onArrowRight?: () => void
  children: React.ReactNode
  className?: string
}

export function KeyboardNavigation({
  onEnter,
  onEscape,
  onArrowUp,
  onArrowDown,
  onArrowLeft,
  onArrowRight,
  children,
  className = ''
}: KeyboardNavigationProps) {
  const elementRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const element = elementRef.current
    if (!element) return

    const handleKeyDown = (event: KeyboardEvent) => {
      handleKeyboardNavigation(
        event,
        onEnter,
        onEscape,
        onArrowUp,
        onArrowDown,
        onArrowLeft,
        onArrowRight
      )
    }

    element.addEventListener('keydown', handleKeyDown)
    return () => element.removeEventListener('keydown', handleKeyDown)
  }, [onEnter, onEscape, onArrowUp, onArrowDown, onArrowLeft, onArrowRight])

  return (
    <div ref={elementRef} className={className} tabIndex={0}>
      {children}
    </div>
  )
}

// Keyboard shortcut hook
export const useKeyboardShortcut = (
  key: string,
  callback: () => void,
  dependencies: any[] = []
) => {
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === key && (event.ctrlKey || event.metaKey)) {
        event.preventDefault()
        callback()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, dependencies)
}

// Common keyboard shortcuts
export const KeyboardShortcuts = {
  // Navigation shortcuts
  NAVIGATE_HOME: 'h',
  NAVIGATE_GAMES: 'g',
  NAVIGATE_TEAMS: 't',
  NAVIGATE_ANALYTICS: 'a',
  NAVIGATE_USERS: 'u',
  
  // Action shortcuts
  CREATE_NEW: 'n',
  SAVE: 's',
  DELETE: 'd',
  SEARCH: 'f',
  EXPORT: 'e',
  
  // UI shortcuts
  TOGGLE_SIDEBAR: 'b',
  TOGGLE_THEME: 'l',
  TOGGLE_NOTIFICATIONS: 'm',
  
  // General shortcuts
  ESCAPE: 'Escape',
  ENTER: 'Enter',
  TAB: 'Tab'
}

// Keyboard shortcut provider component
interface KeyboardShortcutProviderProps {
  children: React.ReactNode
}

export function KeyboardShortcutProvider({ children }: KeyboardShortcutProviderProps) {
  useKeyboardShortcut(KeyboardShortcuts.NAVIGATE_HOME, () => {
    window.location.href = '/'
  })

  useKeyboardShortcut(KeyboardShortcuts.NAVIGATE_GAMES, () => {
    window.location.href = '/games'
  })

  useKeyboardShortcut(KeyboardShortcuts.NAVIGATE_TEAMS, () => {
    window.location.href = '/teams'
  })

  useKeyboardShortcut(KeyboardShortcuts.NAVIGATE_ANALYTICS, () => {
    window.location.href = '/analytics'
  })

  useKeyboardShortcut(KeyboardShortcuts.NAVIGATE_USERS, () => {
    window.location.href = '/users'
  })

  useKeyboardShortcut(KeyboardShortcuts.TOGGLE_THEME, () => {
    // Toggle theme logic would go here
    console.log('Toggle theme shortcut triggered')
  })

  useKeyboardShortcut(KeyboardShortcuts.TOGGLE_NOTIFICATIONS, () => {
    // Toggle notifications logic would go here
    console.log('Toggle notifications shortcut triggered')
  })

  return <>{children}</>
}

// Keyboard shortcut help component
export function KeyboardShortcutHelp() {
  const shortcuts = [
    { key: 'Ctrl/Cmd + H', description: 'Navigate to Home' },
    { key: 'Ctrl/Cmd + G', description: 'Navigate to Games' },
    { key: 'Ctrl/Cmd + T', description: 'Navigate to Teams' },
    { key: 'Ctrl/Cmd + A', description: 'Navigate to Analytics' },
    { key: 'Ctrl/Cmd + U', description: 'Navigate to Users' },
    { key: 'Ctrl/Cmd + N', description: 'Create New Item' },
    { key: 'Ctrl/Cmd + S', description: 'Save' },
    { key: 'Ctrl/Cmd + F', description: 'Search' },
    { key: 'Ctrl/Cmd + E', description: 'Export' },
    { key: 'Ctrl/Cmd + L', description: 'Toggle Theme' },
    { key: 'Ctrl/Cmd + M', description: 'Toggle Notifications' },
    { key: 'Esc', description: 'Close Modal/Cancel' },
    { key: 'Enter', description: 'Confirm/Submit' },
    { key: 'Tab', description: 'Navigate Between Elements' },
    { key: 'Shift + Tab', description: 'Navigate Backwards' },
    { key: 'Arrow Keys', description: 'Navigate Lists/Menus' },
  ]

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 max-w-2xl">
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        Keyboard Shortcuts
      </h3>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {shortcuts.map((shortcut, index) => (
          <div key={index} className="flex justify-between items-center">
            <kbd className="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-200 rounded text-sm font-mono">
              {shortcut.key}
            </kbd>
            <span className="text-sm text-gray-600 dark:text-gray-400">
              {shortcut.description}
            </span>
          </div>
        ))}
      </div>
    </div>
  )
}
