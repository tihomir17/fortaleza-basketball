import { Link, useLocation } from 'react-router-dom'
import { ChevronRightIcon, HomeIcon } from '@heroicons/react/24/outline'

interface BreadcrumbItem {
  name: string
  href: string
  current?: boolean
}

interface BreadcrumbProps {
  items?: BreadcrumbItem[]
  className?: string
}

export function Breadcrumb({ items, className = '' }: BreadcrumbProps) {
  const location = useLocation()

  // Generate breadcrumb items from current path if not provided
  const generateBreadcrumbs = (): BreadcrumbItem[] => {
    if (items) return items

    const pathSegments = location.pathname.split('/').filter(Boolean)
    const breadcrumbs: BreadcrumbItem[] = [
      { name: 'Dashboard', href: '/' }
    ]

    let currentPath = ''
    pathSegments.forEach((segment, index) => {
      currentPath += `/${segment}`
      const isLast = index === pathSegments.length - 1
      
      // Convert segment to readable name
      const name = segment
        .split('-')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ')

      breadcrumbs.push({
        name,
        href: currentPath,
        current: isLast
      })
    })

    return breadcrumbs
  }

  const breadcrumbItems = generateBreadcrumbs()

  return (
    <nav className={`flex ${className}`} aria-label="Breadcrumb">
      <ol className="flex items-center space-x-2">
        {breadcrumbItems.map((item, index) => (
          <li key={item.href} className="flex items-center">
            {index > 0 && (
              <ChevronRightIcon className="w-4 h-4 text-gray-400 dark:text-gray-500 mx-2" />
            )}
            
            {index === 0 ? (
              <Link
                to={item.href}
                className="flex items-center text-sm font-medium text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
              >
                <HomeIcon className="w-4 h-4 mr-1" />
                {item.name}
              </Link>
            ) : item.current ? (
              <span className="text-sm font-medium text-gray-900 dark:text-white">
                {item.name}
              </span>
            ) : (
              <Link
                to={item.href}
                className="text-sm font-medium text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
              >
                {item.name}
              </Link>
            )}
          </li>
        ))}
      </ol>
    </nav>
  )
}

// Custom breadcrumb for specific pages
export function DashboardBreadcrumb() {
  return (
    <Breadcrumb 
      items={[
        { name: 'Dashboard', href: '/', current: true }
      ]}
    />
  )
}

export function GamesBreadcrumb() {
  return (
    <Breadcrumb 
      items={[
        { name: 'Dashboard', href: '/' },
        { name: 'Games', href: '/games', current: true }
      ]}
    />
  )
}

export function TeamsBreadcrumb() {
  return (
    <Breadcrumb 
      items={[
        { name: 'Dashboard', href: '/' },
        { name: 'Teams', href: '/teams', current: true }
      ]}
    />
  )
}

export function LiveTrackingBreadcrumb() {
  return (
    <Breadcrumb 
      items={[
        { name: 'Dashboard', href: '/' },
        { name: 'Live Tracking', href: '/live', current: true }
      ]}
    />
  )
}

export function AnalyticsBreadcrumb() {
  return (
    <Breadcrumb 
      items={[
        { name: 'Dashboard', href: '/' },
        { name: 'Analytics', href: '/analytics', current: true }
      ]}
    />
  )
}

export function ScoutingBreadcrumb() {
  return (
    <Breadcrumb 
      items={[
        { name: 'Dashboard', href: '/' },
        { name: 'Scouting', href: '/scouting', current: true }
      ]}
    />
  )
}
