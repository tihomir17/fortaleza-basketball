import { Bars3Icon, ArrowRightOnRectangleIcon, PaintBrushIcon } from '@heroicons/react/24/outline'
import { useAuthStore } from '../../store/authStore'
import { ThemeToggle } from '../ui/ThemeToggle'
import { NotificationPanel } from '../ui/Notification'
import { ThemeCustomizer } from '../ui/ThemeCustomizer'
import { useState } from 'react'

interface HeaderProps {
  onMenuClick: () => void
}

type ThemeColors = {
  primary: string
  secondary: string
  accent: string
  background: string
  surface: string
  text: string
}

export function Header({ onMenuClick }: HeaderProps) {
  const { user, logout } = useAuthStore()
  const [showThemeCustomizer, setShowThemeCustomizer] = useState(false)
  
  const applyThemeToDocument = (colors: ThemeColors, isDark?: boolean) => {
    const root = document.documentElement
    root.style.setProperty('--color-primary', colors.primary)
    root.style.setProperty('--color-secondary', colors.secondary)
    root.style.setProperty('--color-accent', colors.accent)
    root.style.setProperty('--color-background', colors.background)
    root.style.setProperty('--color-surface', colors.surface)
    root.style.setProperty('--color-text', colors.text)

    if (isDark !== undefined) {
      root.classList.toggle('dark', isDark)
    }
  }

  const handleThemeChange = (theme: { id: string; colors: ThemeColors }) => {
    // Persist
    localStorage.setItem('app_theme', JSON.stringify(theme))
    // Apply
    applyThemeToDocument(theme.colors, theme.id === 'dark')
  }

  // Load saved theme once
  if (typeof window !== 'undefined') {
    const saved = localStorage.getItem('app_theme')
    if (saved) {
      try {
        const parsed = JSON.parse(saved) as { id: string; colors: ThemeColors }
        applyThemeToDocument(parsed.colors, parsed.id === 'dark')
      } catch {}
    }
  }

  const handleLogout = async () => {
    await logout()
  }

  const getUserInitials = () => {
    if (!user) return 'U'
    return `${user.firstName?.[0] || ''}${user.lastName?.[0] || ''}`.toUpperCase() || 'U'
  }

  const getUserName = () => {
    if (!user) return 'User'
    return `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.email
  }

  return (
    <header className="fixed top-0 left-0 right-0 z-50 h-16 animate-fade-in-down">
      <div className="h-full bg-white/80 dark:bg-gray-900/80 backdrop-blur-xl border-b border-white/20 dark:border-gray-700/50 shadow-lg shadow-black/5">
        <div className="flex items-center justify-between px-4 h-full">
        {/* Left side - Mobile menu button and Logo */}
        <div className="flex items-center space-x-4">
          {/* Mobile menu button */}
          <button
            onClick={onMenuClick}
            className="lg:hidden p-2 rounded-md text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-all duration-200 hover:scale-105"
          >
            <Bars3Icon className="w-6 h-6" />
          </button>

          {/* Logo */}
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-600 to-indigo-700 rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/25">
              <span className="text-white font-bold text-lg">F</span>
            </div>
            <div className="flex flex-col">
              <span className="text-xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 dark:from-white dark:to-gray-300 bg-clip-text text-transparent hidden sm:block">Fortaleza Analytics</span>
              <span className="text-lg font-bold bg-gradient-to-r from-gray-900 to-gray-700 dark:from-white dark:to-gray-300 bg-clip-text text-transparent sm:hidden">Fortaleza</span>
            </div>
          </div>
        </div>

        {/* Center - Desktop sidebar toggle */}
        <button
          onClick={onMenuClick}
          className="hidden lg:flex items-center justify-center w-10 h-10 rounded-xl text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200 hover:bg-white/50 dark:hover:bg-gray-700/50 backdrop-blur-sm transition-all duration-200 hover:scale-105 hover:shadow-lg"
        >
          <Bars3Icon className="w-5 h-5" />
        </button>

          {/* Right side - Notifications, Theme toggle and User profile */}
          <div className="flex items-center space-x-3">
            <NotificationPanel />
            <button
              onClick={() => setShowThemeCustomizer(true)}
              className="p-2 rounded-xl text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-white/50 dark:hover:bg-gray-700/50 backdrop-blur-sm transition-all duration-200 hover:scale-105"
              title="Customize Theme"
            >
              <PaintBrushIcon className="w-5 h-5" />
            </button>
            <ThemeToggle size="sm" />
            
            {/* User Profile */}
            <div className="flex items-center space-x-3 p-2 rounded-xl hover:bg-white/50 dark:hover:bg-gray-700/50 backdrop-blur-sm transition-all duration-200 hover:scale-105 hover:shadow-lg">
              <div className="w-9 h-9 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-full flex items-center justify-center shadow-lg shadow-blue-500/25">
                <span className="text-white font-medium text-sm">{getUserInitials()}</span>
              </div>
              <div className="hidden sm:block text-left">
                <div className="text-sm font-medium text-gray-900 dark:text-white">{getUserName()}</div>
                <div className="text-xs text-gray-500 dark:text-gray-400">Admin</div>
              </div>
            </div>
            
            <button
              onClick={handleLogout}
              className="p-2 rounded-xl text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200 hover:bg-white/50 dark:hover:bg-gray-700/50 backdrop-blur-sm transition-all duration-200 hover:scale-105"
              title="Logout"
            >
              <ArrowRightOnRectangleIcon className="w-5 h-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Theme Customizer Modal */}
      <ThemeCustomizer
        isOpen={showThemeCustomizer}
        onClose={() => setShowThemeCustomizer(false)}
        currentTheme="fortaleza"
        onThemeChange={handleThemeChange}
      />
    </header>
  )
}