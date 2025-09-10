import { useEffect } from 'react'
import { SunIcon, MoonIcon, ComputerDesktopIcon } from '@heroicons/react/24/outline'
import { useThemeStore } from '../../store/themeStore'

interface ThemeToggleProps {
  showLabel?: boolean
  size?: 'sm' | 'md' | 'lg'
}

export function ThemeToggle({ showLabel = false, size = 'md' }: ThemeToggleProps) {
  const { theme, setTheme, initialize } = useThemeStore()

  useEffect(() => {
    const cleanup = initialize()
    return cleanup
  }, [initialize])

  const sizeClasses = {
    sm: 'w-8 h-8',
    md: 'w-10 h-10',
    lg: 'w-12 h-12'
  }

  const iconSizes = {
    sm: 'w-4 h-4',
    md: 'w-5 h-5',
    lg: 'w-6 h-6'
  }

  const getIcon = () => {
    switch (theme) {
      case 'light':
        return <SunIcon className={iconSizes[size]} />
      case 'dark':
        return <MoonIcon className={iconSizes[size]} />
      case 'system':
        return <ComputerDesktopIcon className={iconSizes[size]} />
      default:
        return <SunIcon className={iconSizes[size]} />
    }
  }

  const getNextTheme = () => {
    switch (theme) {
      case 'light':
        return 'dark'
      case 'dark':
        return 'system'
      case 'system':
        return 'light'
      default:
        return 'dark'
    }
  }

  const handleClick = () => {
    const nextTheme = getNextTheme()
    setTheme(nextTheme)
  }

  return (
    <div className="flex items-center space-x-2">
      <button
        onClick={handleClick}
        className={`
          ${sizeClasses[size]}
          p-2 rounded-lg
          bg-gray-100 dark:bg-gray-800
          text-gray-700 dark:text-gray-300
          hover:bg-gray-200 dark:hover:bg-gray-700
          transition-all duration-200
          hover:scale-105
          focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:focus:ring-offset-gray-900
        `}
        title={`Current theme: ${theme}. Click to switch to ${getNextTheme()}`}
      >
        {getIcon()}
      </button>
      
      {showLabel && (
        <span className="text-sm font-medium text-gray-700 dark:text-gray-300 capitalize">
          {theme}
        </span>
      )}
    </div>
  )
}

// Dropdown version for more options
export function ThemeDropdown() {
  const { theme, setTheme, initialize } = useThemeStore()

  useEffect(() => {
    const cleanup = initialize()
    return cleanup
  }, [initialize])

  const themes = [
    { value: 'light', label: 'Light', icon: SunIcon },
    { value: 'dark', label: 'Dark', icon: MoonIcon },
    { value: 'system', label: 'System', icon: ComputerDesktopIcon },
  ] as const

  return (
    <div className="relative">
      <div className="flex flex-col space-y-1 p-2 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700">
        {themes.map(({ value, label, icon: Icon }) => (
          <button
            key={value}
            onClick={() => setTheme(value as 'light' | 'dark' | 'system')}
            className={`
              flex items-center space-x-3 px-3 py-2 rounded-md text-sm font-medium
              transition-all duration-200
              ${theme === value
                ? 'bg-blue-50 dark:bg-blue-900/50 text-blue-700 dark:text-blue-300'
                : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
              }
            `}
          >
            <Icon className="w-4 h-4" />
            <span>{label}</span>
            {theme === value && (
              <div className="ml-auto w-2 h-2 bg-blue-500 rounded-full" />
            )}
          </button>
        ))}
      </div>
    </div>
  )
}
