import { Link, useLocation } from 'react-router-dom'
import { 
  HomeIcon, 
  CalendarDaysIcon, 
  UserGroupIcon, 
  ChartBarIcon,
  EyeIcon,
  XMarkIcon,
  PlayIcon,
  UsersIcon
} from '@heroicons/react/24/outline'

interface SidebarProps {
  isOpen: boolean
  onClose: () => void
}

  const navigation = [
    { name: 'Dashboard', href: '/', icon: HomeIcon },
    { name: 'Games', href: '/games', icon: CalendarDaysIcon },
    { name: 'Teams', href: '/teams', icon: UserGroupIcon },
    { name: 'Roster', href: '/teams/roster', icon: UsersIcon },
    { name: 'Calendar', href: '/calendar', icon: CalendarDaysIcon },
    { name: 'Events', href: '/events', icon: CalendarDaysIcon },
    { name: 'Live Tracking', href: '/live', icon: PlayIcon },
    { name: 'Analytics', href: '/analytics', icon: ChartBarIcon },
    { name: 'Scouting', href: '/scouting', icon: EyeIcon },
    { name: 'User Management', href: '/users', icon: UsersIcon },
  ]

export function Sidebar({ isOpen, onClose }: SidebarProps) {
  const location = useLocation()

  return (
    <>
      {/* Mobile overlay */}
      {isOpen && (
        <div 
          className="fixed inset-0 bg-black bg-opacity-50 z-30 lg:hidden"
          onClick={onClose}
        />
      )}
      
      {/* Sidebar */}
      <aside className={`
        fixed lg:relative inset-y-0 left-0 z-40 w-64 bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl shadow-2xl lg:shadow-none border-r border-white/20 dark:border-gray-700/50
        transform transition-all duration-300 ease-in-out lg:transform-none
        ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
        pt-16 lg:pt-0
        ${isOpen ? 'animate-slide-in-left' : ''}
      `}>
        {/* Close button for mobile */}
        <div className="flex items-center justify-between p-4 lg:hidden">
          <div className="flex items-center">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-600 to-indigo-700 rounded-xl flex items-center justify-center shadow-lg shadow-blue-500/25">
              <span className="text-white font-bold text-lg">F</span>
            </div>
            <span className="ml-3 text-lg font-bold bg-gradient-to-r from-gray-900 to-gray-700 dark:from-white dark:to-gray-300 bg-clip-text text-transparent">Fortaleza</span>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-xl text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200 hover:bg-white/50 dark:hover:bg-gray-700/50 backdrop-blur-sm transition-all duration-200 hover:scale-105"
          >
            <XMarkIcon className="w-6 h-6" />
          </button>
        </div>

        <nav className="mt-8 px-4">
          <ul className="space-y-1">
            {navigation.map((item) => {
              const isActive = location.pathname === item.href
              return (
                <li key={item.name}>
                  <Link
                    to={item.href}
                    onClick={() => {
                      // Close mobile menu when navigating
                      if (window.innerWidth < 1024) {
                        onClose()
                      }
                    }}
                    className={`
                      group flex items-center px-4 py-3 text-sm font-medium rounded-xl transition-all duration-200 relative overflow-hidden
                      ${isActive 
                        ? 'text-white bg-gradient-to-r from-blue-600 to-indigo-600 shadow-lg shadow-blue-500/25' 
                        : 'text-gray-700 dark:text-gray-300 hover:text-white hover:bg-gradient-to-r hover:from-blue-500 hover:to-indigo-500 hover:shadow-lg hover:shadow-blue-500/25 hover:scale-105'
                      }
                    `}
                  >
                    <item.icon className={`w-5 h-5 mr-3 transition-all duration-200 ${isActive ? 'text-white' : 'text-gray-500 group-hover:text-white'}`} />
                    <span className="relative z-10">{item.name}</span>
                    {isActive && (
                      <div className="absolute inset-0 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-xl opacity-90"></div>
                    )}
                  </Link>
                </li>
              )
            })}
          </ul>
        </nav>
      </aside>
    </>
  )
}
