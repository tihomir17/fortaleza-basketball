import { Bars3Icon, ArrowRightOnRectangleIcon, PaintBrushIcon } from '@heroicons/react/24/outline'
import { useAuthStore } from '../../store/authStore'
import { ThemeToggle } from '../ui/ThemeToggle'
import { NotificationPanel } from '../ui/Notification'
import { ThemeCustomizer } from '../ui/ThemeCustomizer'
import { useState } from 'react'

interface HeaderProps {
  onMenuClick: () => void
}

export function Header({ onMenuClick }: HeaderProps) {
  const { user, logout } = useAuthStore()
  const [showThemeCustomizer, setShowThemeCustomizer] = useState(false)

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
    <header className="bg-white dark:bg-gray-900 shadow-sm border-b border-gray-200 dark:border-gray-700 fixed top-0 left-0 right-0 z-50 h-16 animate-fade-in-down">
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
            <div className="w-8 h-8 bg-fortaleza-blue rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">F</span>
            </div>
            <span className="text-xl font-bold text-gray-900 dark:text-white hidden sm:block">Fortaleza Analytics</span>
            <span className="text-lg font-bold text-gray-900 dark:text-white sm:hidden">Fortaleza</span>
          </div>
        </div>

        {/* Center - Desktop sidebar toggle */}
        <button
          onClick={onMenuClick}
          className="hidden lg:block p-2 rounded-md text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-all duration-200 hover:scale-105"
        >
          <Bars3Icon className="w-5 h-5" />
        </button>

          {/* Right side - Notifications, Theme toggle and User profile */}
          <div className="flex items-center space-x-3">
            <NotificationPanel />
            <button
              onClick={() => setShowThemeCustomizer(true)}
              className="p-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
              title="Customize Theme"
            >
              <PaintBrushIcon className="w-5 h-5" />
            </button>
            <ThemeToggle size="sm" />
          <div className="w-8 h-8 bg-fortaleza-gold rounded-full flex items-center justify-center">
            <span className="text-white font-semibold text-sm">{getUserInitials()}</span>
          </div>
          <span className="hidden sm:block text-sm font-medium text-gray-700 dark:text-gray-300">{getUserName()}</span>
          <button
            onClick={handleLogout}
            className="p-2 rounded-md text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-all duration-200 hover:scale-105"
            title="Logout"
          >
            <ArrowRightOnRectangleIcon className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Theme Customizer Modal */}
      <ThemeCustomizer
        isOpen={showThemeCustomizer}
        onClose={() => setShowThemeCustomizer(false)}
        currentTheme="fortaleza"
        onThemeChange={(theme) => {
          console.log('Theme changed to:', theme.name)
          // Here you would implement the actual theme change logic
        }}
      />
    </header>
  )
}