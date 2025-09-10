import { useEffect, useState } from 'react'

interface PageLoaderProps {
  message?: string
}

export function PageLoader({ message = 'Loading...' }: PageLoaderProps) {
  const [dots, setDots] = useState('')

  useEffect(() => {
    const interval = setInterval(() => {
      setDots(prev => prev.length >= 3 ? '' : prev + '.')
    }, 500)

    return () => clearInterval(interval)
  }, [])

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
      <div className="text-center">
        <div className="relative">
          <div className="w-16 h-16 border-4 border-gray-200 dark:border-gray-700 border-t-fortaleza-blue rounded-full animate-spin mx-auto mb-4"></div>
          <div className="absolute inset-0 flex items-center justify-center">
            <div className="w-8 h-8 bg-fortaleza-blue rounded-full animate-pulse"></div>
          </div>
        </div>
        <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
          {message}
        </h3>
        <p className="text-gray-600 dark:text-gray-400">
          Please wait while we load the page{dots}
        </p>
      </div>
    </div>
  )
}

// Specialized loaders for different pages
export function DashboardLoader() {
  return <PageLoader message="Loading Dashboard" />
}

export function GamesLoader() {
  return <PageLoader message="Loading Games" />
}

export function TeamsLoader() {
  return <PageLoader message="Loading Teams" />
}

export function LiveTrackingLoader() {
  return <PageLoader message="Loading Live Tracking" />
}

export function AnalyticsLoader() {
  return <PageLoader message="Loading Analytics" />
}

export function ScoutingLoader() {
  return <PageLoader message="Loading Scouting" />
}

export function UserManagementLoader() {
  return <PageLoader message="Loading User Management" />
}
