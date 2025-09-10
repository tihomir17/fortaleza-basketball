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
        fixed lg:relative inset-y-0 left-0 z-40 w-64 bg-white dark:bg-gray-800 shadow-lg lg:shadow-none border-r border-gray-200 dark:border-gray-700
        transform transition-all duration-300 ease-in-out lg:transform-none
        ${isOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
        pt-16 lg:pt-0
        ${isOpen ? 'animate-slide-in-left' : ''}
      `}>
        {/* Close button for mobile */}
        <div className="flex items-center justify-between p-4 lg:hidden">
          <div className="flex items-center">
            <div className="w-8 h-8 bg-fortaleza-blue rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">F</span>
            </div>
            <span className="ml-2 text-lg font-bold text-gray-900 dark:text-white">Fortaleza</span>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-md text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700"
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
                      flex items-center px-3 py-3 text-sm font-medium rounded-lg transition-all duration-200
                      ${isActive 
                        ? 'text-fortaleza-blue bg-blue-50 dark:bg-blue-900/50 border-r-2 border-fortaleza-blue' 
                        : 'text-gray-700 dark:text-gray-300 hover:text-fortaleza-blue hover:bg-gray-50 dark:hover:bg-gray-700 hover:translate-x-1'
                      }
                    `}
                  >
                    <item.icon className="w-5 h-5 mr-3" />
                    {item.name}
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
