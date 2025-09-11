import { Link, useLocation } from 'react-router-dom'
import { 
  HomeIcon, 
  CalendarDaysIcon, 
  UserGroupIcon, 
  ChartBarIcon,
  EyeIcon,
  PlayIcon,
  UsersIcon,
  BookOpenIcon,
  BugAntIcon
} from '@heroicons/react/24/outline'

interface SidebarProps {
  isOpen: boolean
  onClose: () => void
}

const navigation = [
    { name: 'Dashboard', href: '/', icon: HomeIcon },
    { name: 'Games', href: '/games', icon: CalendarDaysIcon },
    { name: 'Teams', href: '/teams', icon: UserGroupIcon },
    { name: 'Playbook', href: '/playbook', icon: BookOpenIcon },
    { name: 'Calendar', href: '/calendar', icon: CalendarDaysIcon },
    { name: 'Events', href: '/events', icon: CalendarDaysIcon },
    { name: 'Live Tracking', href: '/live', icon: PlayIcon },
    { name: 'Analytics', href: '/analytics', icon: ChartBarIcon },
    { name: 'Scouting', href: '/scouting', icon: EyeIcon },
    { name: 'User Management', href: '/users', icon: UsersIcon },
    { name: 'Debug', href: '/debug', icon: BugAntIcon },
  ]

export function Sidebar({ isOpen: _isOpen, onClose: _onClose }: SidebarProps) {
  // Parameters kept for interface compatibility but not used since sidebar is always visible
  const location = useLocation()

  return (
    <>
      {/* Sidebar */}
      <aside className="fixed inset-x-0 bottom-0 z-40 h-16 bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl shadow-2xl border-t border-white/20 dark:border-gray-700/50">
        <nav className="px-4 py-2 h-full">
          <ul className="flex justify-center items-center gap-1 h-full">
            {navigation.map((item) => {
              const isActive = location.pathname === item.href
              return (
                <li key={item.name}>
                  <Link
                    to={item.href}
                    className={`
                      group flex items-center px-3 py-2 text-sm font-medium rounded-lg transition-all duration-200 relative overflow-hidden
                      ${isActive 
                        ? 'text-white bg-gradient-to-r from-blue-600 to-indigo-600 shadow-lg shadow-blue-500/25' 
                        : 'text-gray-700 dark:text-gray-300 hover:text-white hover:bg-gradient-to-r hover:from-blue-500 hover:to-indigo-500 hover:shadow-lg hover:shadow-blue-500/25 hover:scale-105'
                      }
                    `}
                    title={item.name}
                  >
                    <item.icon className={`w-8 h-8 transition-all duration-200 ${isActive ? 'text-white' : 'text-gray-500 group-hover:text-white'}`} />
                    {isActive && (
                      <div className="absolute inset-0 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-lg opacity-90"></div>
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
