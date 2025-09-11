import React from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  CheckCircleIcon, 
  ExclamationTriangleIcon, 
  InformationCircleIcon, 
  XCircleIcon,
  XMarkIcon,
  BellIcon
} from '@heroicons/react/24/outline'
import { useNotificationsStore } from '../../store/notificationsStore'

// Individual Notification Toast
const NotificationToast: React.FC<{
  notification: any
  onClose: (id: string) => void
}> = ({ notification, onClose }) => {
  const getIcon = () => {
    switch (notification.type) {
      case 'success':
        return <CheckCircleIcon className="w-5 h-5 text-green-500" />
      case 'error':
        return <XCircleIcon className="w-5 h-5 text-red-500" />
      case 'warning':
        return <ExclamationTriangleIcon className="w-5 h-5 text-yellow-500" />
      case 'info':
      default:
        return <InformationCircleIcon className="w-5 h-5 text-blue-500" />
    }
  }

  const getBackgroundColor = () => {
    switch (notification.type) {
      case 'success':
        return 'bg-green-50 border-green-200 dark:bg-green-900/20 dark:border-green-800'
      case 'error':
        return 'bg-red-50 border-red-200 dark:bg-red-900/20 dark:border-red-800'
      case 'warning':
        return 'bg-yellow-50 border-yellow-200 dark:bg-yellow-900/20 dark:border-yellow-800'
      case 'info':
      default:
        return 'bg-blue-50 border-blue-200 dark:bg-blue-900/20 dark:border-blue-800'
    }
  }

  return (
    <motion.div
      className={`max-w-sm w-full ${getBackgroundColor()} border rounded-lg shadow-lg p-4`}
      initial={{ opacity: 0, x: 300, scale: 0.8 }}
      animate={{ opacity: 1, x: 0, scale: 1 }}
      exit={{ opacity: 0, x: 300, scale: 0.8 }}
      transition={{ duration: 0.3, ease: 'easeOut' }}
      layout
    >
      <div className="flex items-start">
        <div className="flex-shrink-0">
          {getIcon()}
        </div>
        <div className="ml-3 flex-1">
          <h4 className="text-sm font-medium text-gray-900 dark:text-white">
            {notification.title}
          </h4>
          <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
            {notification.message}
          </p>
        </div>
        <div className="ml-4 flex-shrink-0">
          <button
            onClick={() => onClose(notification.id)}
            className="inline-flex text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 focus:outline-none"
          >
            <XMarkIcon className="w-4 h-4" />
          </button>
        </div>
      </div>
    </motion.div>
  )
}

// Notification Bell with Badge
export const NotificationBell: React.FC<{
  onClick: () => void
  className?: string
}> = ({ onClick, className = '' }) => {
  const { unreadCount } = useNotificationsStore()

  return (
    <motion.button
      onClick={onClick}
      className={`relative p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 focus:outline-none ${className}`}
      whileHover={{ scale: 1.1 }}
      whileTap={{ scale: 0.9 }}
      transition={{ duration: 0.2 }}
    >
      <BellIcon className="w-6 h-6" />
      {unreadCount > 0 && (
        <motion.span
          className="absolute -top-1 -right-1 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white bg-red-600 rounded-full"
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ duration: 0.2 }}
        >
          {unreadCount > 99 ? '99+' : unreadCount}
        </motion.span>
      )}
    </motion.button>
  )
}

// Notification Panel
export const NotificationPanel: React.FC<{
  isOpen: boolean
  onClose: () => void
}> = ({ isOpen, onClose }) => {
  const { notifications, markAsRead, markAllAsRead, clearAll } = useNotificationsStore()

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className="fixed inset-0 z-50 overflow-hidden"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
        >
          <div className="absolute inset-0 bg-gray-500 bg-opacity-25 backdrop-blur-sm" onClick={onClose} />
          
          <motion.div
            className="absolute right-0 top-0 h-full w-96 bg-white dark:bg-gray-800 shadow-xl"
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ duration: 0.3, ease: 'easeOut' }}
          >
            <div className="flex flex-col h-full">
              {/* Header */}
              <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700">
                <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                  Notifications
                </h2>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={markAllAsRead}
                    className="text-sm text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300"
                  >
                    Mark all read
                  </button>
                  <button
                    onClick={clearAll}
                    className="text-sm text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300"
                  >
                    Clear all
                  </button>
                  <button
                    onClick={onClose}
                    className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                  >
                    <XMarkIcon className="w-5 h-5" />
                  </button>
                </div>
              </div>

              {/* Notifications List */}
              <div className="flex-1 overflow-y-auto">
                {notifications.length === 0 ? (
                  <div className="flex flex-col items-center justify-center h-full text-gray-500 dark:text-gray-400">
                    <BellIcon className="w-12 h-12 mb-4" />
                    <p>No notifications</p>
                  </div>
                ) : (
                  <div className="p-4 space-y-3">
                    {notifications.map((notification) => (
                      <motion.div
                        key={notification.id}
                        className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                          notification.read 
                            ? 'bg-gray-50 dark:bg-gray-700 border-gray-200 dark:border-gray-600' 
                            : 'bg-white dark:bg-gray-800 border-blue-200 dark:border-blue-800'
                        }`}
                        onClick={() => markAsRead(notification.id)}
                        whileHover={{ scale: 1.02 }}
                        transition={{ duration: 0.2 }}
                      >
                        <div className="flex items-start space-x-3">
                          <div className="flex-shrink-0">
                            {notification.type === 'success' && <CheckCircleIcon className="w-5 h-5 text-green-500" />}
                            {notification.type === 'error' && <XCircleIcon className="w-5 h-5 text-red-500" />}
                            {notification.type === 'warning' && <ExclamationTriangleIcon className="w-5 h-5 text-yellow-500" />}
                            {notification.type === 'info' && <InformationCircleIcon className="w-5 h-5 text-blue-500" />}
                          </div>
                          <div className="flex-1 min-w-0">
                            <h4 className="text-sm font-medium text-gray-900 dark:text-white">
                              {notification.title}
                            </h4>
                            <p className="mt-1 text-sm text-gray-600 dark:text-gray-300">
                              {notification.message}
                            </p>
                            <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                              {new Date(notification.timestamp).toLocaleTimeString()}
                            </p>
                          </div>
                          {!notification.read && (
                            <div className="w-2 h-2 bg-blue-500 rounded-full flex-shrink-0" />
                          )}
                        </div>
                      </motion.div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

// Toast Container
export const ToastContainer: React.FC = () => {
  const { notifications, removeNotification } = useNotificationsStore()

  return (
    <div className="fixed top-4 right-4 z-50 space-y-2">
      <AnimatePresence>
        {notifications.slice(0, 3).map((notification) => (
          <NotificationToast
            key={notification.id}
            notification={notification}
            onClose={removeNotification}
          />
        ))}
      </AnimatePresence>
    </div>
  )
}

// Hook for easy notification usage
export const useNotifications = () => {
  const { addNotification } = useNotificationsStore()

  return {
    showSuccess: (title: string, message: string, duration = 5000) => 
      addNotification({ type: 'success', title, message, duration }),
    showError: (title: string, message: string, duration = 7000) => 
      addNotification({ type: 'error', title, message, duration }),
    showWarning: (title: string, message: string, duration = 6000) => 
      addNotification({ type: 'warning', title, message, duration }),
    showInfo: (title: string, message: string, duration = 5000) => 
      addNotification({ type: 'info', title, message, duration })
  }
}
