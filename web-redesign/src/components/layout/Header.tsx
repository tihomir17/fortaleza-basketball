import { Bars3Icon, ArrowRightOnRectangleIcon, UserGroupIcon } from '@heroicons/react/24/outline'
import { useAuthStore } from '../../store/authStore'
import { useThemeStore } from '../../store/themeStore'
import { ThemeToggle } from '../ui/ThemeToggle'
import { NotificationBell, NotificationPanel } from '../ui/NotificationSystem'
import { useState, useEffect } from 'react'
import { DensityToggle } from '../ui/DensityToggle'
import { useNavigate } from 'react-router-dom'
import { useTeamsStore } from '../../store/teamsStore'

interface HeaderProps {
  onMenuClick: () => void
}


export function Header({ onMenuClick }: HeaderProps) {
  const { user, logout } = useAuthStore()
  const { initialize } = useThemeStore()
  const { teams, fetchTeams } = useTeamsStore()
  const navigate = useNavigate()
  const [showNotifications, setShowNotifications] = useState(false)
  
  // Initialize theme store on component mount
  useEffect(() => {
    initialize()
  }, [initialize])

  const handleLogout = async () => {
    await logout()
  }

  const handleMyTeamClick = async () => {
    try {
      // Fetch user's teams (backend automatically filters to user's teams)
      await fetchTeams()
      
      if (teams.length === 1) {
        // If user is in only one team, navigate directly to that team
        navigate(`/teams/${teams[0].id}`)
      } else if (teams.length > 1) {
        // If user is in multiple teams, navigate to teams list
        navigate('/teams')
      } else {
        // If user is not in any team, navigate to teams list
        navigate('/teams')
      }
    } catch (error) {
      console.error('Error fetching user teams:', error)
      // Fallback to teams list
      navigate('/teams')
    }
  }

  const getUserInitials = () => {
    if (!user) return 'U'
    return `${user.first_name?.[0] || ''}${user.last_name?.[0] || ''}`.toUpperCase() || 'U'
  }

  const getUserName = () => {
    if (!user) return 'User'
    return `${user.first_name || ''} ${user.last_name || ''}`.trim() || user.email
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
              <span className="text-white font-bold text-lg">I</span>
            </div>
            <div className="flex flex-col">
              <span className="text-xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 dark:from-white dark:to-gray-300 bg-clip-text text-transparent hidden sm:block">INAT DRIVE</span>
              <span className="text-lg font-bold bg-gradient-to-r from-gray-900 to-gray-700 dark:from-white dark:to-gray-300 bg-clip-text text-transparent sm:hidden">INAT</span>
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
            <NotificationBell onClick={() => setShowNotifications(true)} />
            <ThemeToggle size="sm" />
            <DensityToggle />
            
            {/* My Team Button */}
            <button
              onClick={handleMyTeamClick}
              className="flex items-center space-x-2 px-3 py-2 rounded-xl text-gray-700 dark:text-gray-300 hover:text-white hover:bg-gradient-to-r hover:from-blue-500 hover:to-indigo-500 hover:shadow-lg hover:shadow-blue-500/25 transition-all duration-200 hover:scale-105"
              title="My Team"
            >
              <UserGroupIcon className="w-5 h-5" />
              <span className="hidden sm:block text-sm font-medium">My Team</span>
            </button>
            
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


      {/* Notification Panel */}
      <NotificationPanel
        isOpen={showNotifications}
        onClose={() => setShowNotifications(false)}
      />
    </header>
  )
}