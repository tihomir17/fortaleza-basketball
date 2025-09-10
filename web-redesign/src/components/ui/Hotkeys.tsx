import { useEffect } from 'react'
// import { useKeyboardShortcut, KeyboardShortcuts } from './KeyboardNavigation'

interface HotkeyConfig {
  key: string
  ctrlKey?: boolean
  metaKey?: boolean
  shiftKey?: boolean
  altKey?: boolean
  callback: () => void
  description: string
  category?: string
}

interface HotkeyProviderProps {
  children: React.ReactNode
  hotkeys: HotkeyConfig[]
}

export function HotkeyProvider({ children, hotkeys }: HotkeyProviderProps) {
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      const matchingHotkey = hotkeys.find(hotkey => {
        return hotkey.key.toLowerCase() === event.key.toLowerCase() &&
               !!hotkey.ctrlKey === event.ctrlKey &&
               !!hotkey.metaKey === event.metaKey &&
               !!hotkey.shiftKey === event.shiftKey &&
               !!hotkey.altKey === event.altKey
      })

      if (matchingHotkey) {
        event.preventDefault()
        matchingHotkey.callback()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [hotkeys])

  return <>{children}</>
}

// Global hotkeys for the application
export const globalHotkeys: HotkeyConfig[] = [
  {
    key: 'h',
    ctrlKey: true,
    callback: () => window.location.href = '/',
    description: 'Navigate to Home',
    category: 'Navigation'
  },
  {
    key: 'g',
    ctrlKey: true,
    callback: () => window.location.href = '/games',
    description: 'Navigate to Games',
    category: 'Navigation'
  },
  {
    key: 't',
    ctrlKey: true,
    callback: () => window.location.href = '/teams',
    description: 'Navigate to Teams',
    category: 'Navigation'
  },
  {
    key: 'a',
    ctrlKey: true,
    callback: () => window.location.href = '/analytics',
    description: 'Navigate to Analytics',
    category: 'Navigation'
  },
  {
    key: 'u',
    ctrlKey: true,
    callback: () => window.location.href = '/users',
    description: 'Navigate to Users',
    category: 'Navigation'
  },
  {
    key: 'n',
    ctrlKey: true,
    callback: () => {
      // Trigger create new action based on current page
      const path = window.location.pathname
      if (path.includes('/games')) {
        // Trigger create game modal
        console.log('Create new game')
      } else if (path.includes('/teams')) {
        // Trigger create team modal
        console.log('Create new team')
      } else if (path.includes('/users')) {
        // Trigger create user modal
        console.log('Create new user')
      }
    },
    description: 'Create New Item',
    category: 'Actions'
  },
  {
    key: 's',
    ctrlKey: true,
    callback: () => {
      // Trigger save action
      console.log('Save current changes')
    },
    description: 'Save Changes',
    category: 'Actions'
  },
  {
    key: 'f',
    ctrlKey: true,
    callback: () => {
      // Focus search input
      const searchInput = document.querySelector('input[type="search"], input[placeholder*="search" i]') as HTMLInputElement
      if (searchInput) {
        searchInput.focus()
      }
    },
    description: 'Focus Search',
    category: 'Actions'
  },
  {
    key: 'e',
    ctrlKey: true,
    callback: () => {
      // Trigger export action
      console.log('Export data')
    },
    description: 'Export Data',
    category: 'Actions'
  },
  {
    key: 'l',
    ctrlKey: true,
    callback: () => {
      // Toggle theme
      const themeToggle = document.querySelector('[data-theme-toggle]') as HTMLElement
      if (themeToggle) {
        themeToggle.click()
      }
    },
    description: 'Toggle Theme',
    category: 'UI'
  },
  {
    key: 'b',
    ctrlKey: true,
    callback: () => {
      // Toggle sidebar
      const sidebarToggle = document.querySelector('[data-sidebar-toggle]') as HTMLElement
      if (sidebarToggle) {
        sidebarToggle.click()
      }
    },
    description: 'Toggle Sidebar',
    category: 'UI'
  },
  {
    key: 'm',
    ctrlKey: true,
    callback: () => {
      // Toggle notifications
      const notificationToggle = document.querySelector('[data-notification-toggle]') as HTMLElement
      if (notificationToggle) {
        notificationToggle.click()
      }
    },
    description: 'Toggle Notifications',
    category: 'UI'
  },
  {
    key: '?',
    callback: () => {
      // Show hotkeys help
      const helpModal = document.querySelector('[data-hotkeys-help]') as HTMLElement
      if (helpModal) {
        helpModal.style.display = 'block'
      }
    },
    description: 'Show Hotkeys Help',
    category: 'Help'
  }
]

// Hotkey help modal
interface HotkeyHelpModalProps {
  isOpen: boolean
  onClose: () => void
  hotkeys?: HotkeyConfig[]
}

export function HotkeyHelpModal({ isOpen, onClose, hotkeys = globalHotkeys }: HotkeyHelpModalProps) {
  if (!isOpen) return null

  const groupedHotkeys = hotkeys.reduce((acc, hotkey) => {
    const category = hotkey.category || 'Other'
    if (!acc[category]) {
      acc[category] = []
    }
    acc[category].push(hotkey)
    return acc
  }, {} as Record<string, HotkeyConfig[]>)

  const formatKeyCombo = (hotkey: HotkeyConfig) => {
    const parts = []
    if (hotkey.ctrlKey) parts.push('Ctrl')
    if (hotkey.metaKey) parts.push('Cmd')
    if (hotkey.shiftKey) parts.push('Shift')
    if (hotkey.altKey) parts.push('Alt')
    parts.push(hotkey.key.toUpperCase())
    return parts.join(' + ')
  }

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex min-h-full items-center justify-center p-4">
        <div className="fixed inset-0 bg-black bg-opacity-50" onClick={onClose} />
        <div className="relative bg-white dark:bg-gray-800 rounded-lg shadow-xl max-w-2xl w-full max-h-[80vh] overflow-y-auto">
          <div className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Keyboard Shortcuts
              </h3>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
              >
                {/* <XMarkIcon className="w-6 h-6" /> */}
                <span className="w-6 h-6">×</span>
              </button>
            </div>

            <div className="space-y-6">
              {Object.entries(groupedHotkeys).map(([category, categoryHotkeys]) => (
                <div key={category}>
                  <h4 className="text-sm font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-3">
                    {category}
                  </h4>
                  <div className="space-y-2">
                    {categoryHotkeys.map((hotkey, index) => (
                      <div key={index} className="flex items-center justify-between py-2">
                        <span className="text-sm text-gray-700 dark:text-gray-300">
                          {hotkey.description}
                        </span>
                        <kbd className="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-200 rounded text-xs font-mono">
                          {formatKeyCombo(hotkey)}
                        </kbd>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

// Hook for registering hotkeys
export function useHotkeys(hotkeys: HotkeyConfig[]) {
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      const matchingHotkey = hotkeys.find(hotkey => {
        return hotkey.key.toLowerCase() === event.key.toLowerCase() &&
               !!hotkey.ctrlKey === event.ctrlKey &&
               !!hotkey.metaKey === event.metaKey &&
               !!hotkey.shiftKey === event.shiftKey &&
               !!hotkey.altKey === event.altKey
      })

      if (matchingHotkey) {
        event.preventDefault()
        matchingHotkey.callback()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [hotkeys])
}

// Quick action hotkeys for specific pages
export const gameHotkeys: HotkeyConfig[] = [
  {
    key: 'n',
    ctrlKey: true,
    callback: () => console.log('Create new game'),
    description: 'Create New Game',
    category: 'Games'
  },
  {
    key: 'r',
    ctrlKey: true,
    callback: () => console.log('Refresh games'),
    description: 'Refresh Games List',
    category: 'Games'
  }
]

export const teamHotkeys: HotkeyConfig[] = [
  {
    key: 'n',
    ctrlKey: true,
    callback: () => console.log('Create new team'),
    description: 'Create New Team',
    category: 'Teams'
  },
  {
    key: 'p',
    ctrlKey: true,
    callback: () => console.log('Add new player'),
    description: 'Add New Player',
    category: 'Teams'
  }
]

export const userHotkeys: HotkeyConfig[] = [
  {
    key: 'n',
    ctrlKey: true,
    callback: () => console.log('Create new user'),
    description: 'Create New User',
    category: 'Users'
  },
  {
    key: 'i',
    ctrlKey: true,
    callback: () => console.log('Invite users'),
    description: 'Invite Users',
    category: 'Users'
  }
]
