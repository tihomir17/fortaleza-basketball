import { useState, useEffect } from 'react'
import { CheckCircleIcon, ExclamationTriangleIcon, XCircleIcon } from '@heroicons/react/24/outline'
import { initializeBackendStatus } from '../services/apiWithFallback'

interface BackendStatusProps {
  className?: string
}

export function BackendStatus({ className = '' }: BackendStatusProps) {
  const [status, setStatus] = useState<'checking' | 'connected' | 'disconnected'>('checking')
  const [isVisible, setIsVisible] = useState(false)

  useEffect(() => {
    const checkStatus = async () => {
      try {
        const isHealthy = await initializeBackendStatus()
        setStatus(isHealthy ? 'connected' : 'disconnected')
        setIsVisible(true)
        
        // Auto-hide after 5 seconds if connected
        if (isHealthy) {
          setTimeout(() => setIsVisible(false), 5000)
        }
      } catch (error) {
        setStatus('disconnected')
        setIsVisible(true)
      }
    }

    checkStatus()
  }, [])

  if (!isVisible) return null

  const getStatusConfig = () => {
    switch (status) {
      case 'checking':
        return {
          icon: ExclamationTriangleIcon,
          text: 'Checking backend...',
          bgColor: 'bg-yellow-50 dark:bg-yellow-900/50',
          textColor: 'text-yellow-800 dark:text-yellow-300',
          iconColor: 'text-yellow-600 dark:text-yellow-400'
        }
      case 'connected':
        return {
          icon: CheckCircleIcon,
          text: 'Backend connected',
          bgColor: 'bg-green-50 dark:bg-green-900/50',
          textColor: 'text-green-800 dark:text-green-300',
          iconColor: 'text-green-600 dark:text-green-400'
        }
      case 'disconnected':
        return {
          icon: XCircleIcon,
          text: 'Using mock data - backend unavailable',
          bgColor: 'bg-red-50 dark:bg-red-900/50',
          textColor: 'text-red-800 dark:text-red-300',
          iconColor: 'text-red-600 dark:text-red-400'
        }
    }
  }

  const config = getStatusConfig()
  const Icon = config.icon

  return (
    <div className={`fixed top-4 right-4 z-50 ${className}`}>
      <div className={`flex items-center space-x-2 px-4 py-2 rounded-lg border shadow-lg ${config.bgColor} ${config.textColor}`}>
        <Icon className={`w-5 h-5 ${config.iconColor}`} />
        <span className="text-sm font-medium">{config.text}</span>
        <button
          onClick={() => setIsVisible(false)}
          className="ml-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
        >
          <XCircleIcon className="w-4 h-4" />
        </button>
      </div>
    </div>
  )
}
