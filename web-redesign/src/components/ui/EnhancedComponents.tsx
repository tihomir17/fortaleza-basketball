import React, { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

// Enhanced Button with animations
interface EnhancedButtonProps {
  children: React.ReactNode
  onClick?: () => void
  variant?: 'primary' | 'secondary' | 'success' | 'warning' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  loading?: boolean
  className?: string
  icon?: React.ReactNode
}

export const EnhancedButton: React.FC<EnhancedButtonProps> = ({
  children,
  onClick,
  variant = 'primary',
  size = 'md',
  disabled = false,
  loading = false,
  className = '',
  icon
}) => {
  const [isPressed, setIsPressed] = useState(false)

  const baseClasses = 'relative inline-flex items-center justify-center font-medium rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed'
  
  const variantClasses = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500 shadow-lg hover:shadow-xl',
    secondary: 'bg-gray-600 text-white hover:bg-gray-700 focus:ring-gray-500 shadow-lg hover:shadow-xl',
    success: 'bg-green-600 text-white hover:bg-green-700 focus:ring-green-500 shadow-lg hover:shadow-xl',
    warning: 'bg-yellow-600 text-white hover:bg-yellow-700 focus:ring-yellow-500 shadow-lg hover:shadow-xl',
    danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500 shadow-lg hover:shadow-xl'
  }
  
  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg'
  }

  return (
    <motion.button
      className={`${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
      onClick={onClick}
      disabled={disabled || loading}
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
      onMouseDown={() => setIsPressed(true)}
      onMouseUp={() => setIsPressed(false)}
      onMouseLeave={() => setIsPressed(false)}
    >
      <AnimatePresence>
        {loading && (
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.8 }}
            className="mr-2"
          >
            <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
          </motion.div>
        )}
      </AnimatePresence>
      
      {icon && !loading && (
        <span className="mr-2">{icon}</span>
      )}
      
      <motion.span
        animate={{ opacity: loading ? 0.7 : 1 }}
        transition={{ duration: 0.2 }}
      >
        {children}
      </motion.span>
      
      {isPressed && (
        <motion.div
          className="absolute inset-0 bg-white opacity-20 rounded-lg"
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          exit={{ scale: 0, opacity: 0 }}
          transition={{ duration: 0.1 }}
        />
      )}
    </motion.button>
  )
}

// Enhanced Card with hover effects
interface EnhancedCardProps {
  children: React.ReactNode
  className?: string
  hover?: boolean
  clickable?: boolean
  onClick?: () => void
}

export const EnhancedCard: React.FC<EnhancedCardProps> = ({
  children,
  className = '',
  hover = true,
  clickable = false,
  onClick
}) => {
  return (
    <motion.div
      className={`bg-white dark:bg-gray-800 rounded-lg shadow-md border border-gray-200 dark:border-gray-700 ${className}`}
      whileHover={hover ? { y: -2 } : {}}
      whileTap={clickable ? { scale: 0.98 } : {}}
      onClick={onClick}
      style={{ cursor: clickable ? 'pointer' : 'default' }}
      transition={{ duration: 0.2 }}
    >
      {children}
    </motion.div>
  )
}

// Enhanced Input with focus animations
interface EnhancedInputProps {
  value: string
  onChange: (value: string) => void
  placeholder?: string
  type?: string
  label?: string
  error?: string
  icon?: React.ReactNode
  className?: string
}

export const EnhancedInput: React.FC<EnhancedInputProps> = ({
  value,
  onChange,
  placeholder,
  type = 'text',
  label,
  error,
  icon,
  className = ''
}) => {
  const [isFocused, setIsFocused] = useState(false)

  return (
    <div className={`relative ${className}`}>
      {label && (
        <motion.label
          className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2"
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.2 }}
        >
          {label}
        </motion.label>
      )}
      
      <div className="relative">
        {icon && (
          <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <span className="text-gray-400">{icon}</span>
          </div>
        )}
        
        <motion.input
          type={type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          className={`w-full ${icon ? 'pl-10' : 'pl-3'} pr-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:bg-gray-700 dark:text-white dark:border-gray-600 ${
            error ? 'border-red-500' : 'border-gray-300'
          }`}
          whileFocus={{ scale: 1.01 }}
          transition={{ duration: 0.2 }}
        />
        
        <motion.div
          className="absolute inset-x-0 bottom-0 h-0.5 bg-blue-500"
          initial={{ scaleX: 0 }}
          animate={{ scaleX: isFocused ? 1 : 0 }}
          transition={{ duration: 0.3 }}
        />
      </div>
      
      {error && (
        <motion.p
          className="mt-1 text-sm text-red-600"
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.2 }}
        >
          {error}
        </motion.p>
      )}
    </div>
  )
}

// Enhanced Modal with backdrop blur
interface EnhancedModalProps {
  isOpen: boolean
  onClose: () => void
  children: React.ReactNode
  title?: string
  size?: 'sm' | 'md' | 'lg' | 'xl'
}

export const EnhancedModal: React.FC<EnhancedModalProps> = ({
  isOpen,
  onClose,
  children,
  title,
  size = 'md'
}) => {
  const sizeClasses = {
    sm: 'max-w-md',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl'
  }

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          className="fixed inset-0 z-50 overflow-y-auto"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
        >
          <div className="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
            <motion.div
              className="fixed inset-0 bg-gray-500 bg-opacity-75 backdrop-blur-sm"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={onClose}
            />
            
            <motion.div
              className={`inline-block align-bottom bg-white dark:bg-gray-800 rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle w-full ${sizeClasses[size]}`}
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              transition={{ duration: 0.3 }}
            >
              {title && (
                <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                  <h3 className="text-lg font-medium text-gray-900 dark:text-white">
                    {title}
                  </h3>
                </div>
              )}
              
              <div className="px-6 py-4">
                {children}
              </div>
            </motion.div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

// Enhanced Progress Bar with animations
interface EnhancedProgressBarProps {
  value: number
  max?: number
  color?: 'blue' | 'green' | 'yellow' | 'red' | 'purple'
  size?: 'sm' | 'md' | 'lg'
  showLabel?: boolean
  className?: string
}

export const EnhancedProgressBar: React.FC<EnhancedProgressBarProps> = ({
  value,
  max = 100,
  color = 'blue',
  size = 'md',
  showLabel = true,
  className = ''
}) => {
  const percentage = Math.min((value / max) * 100, 100)
  
  const colorClasses = {
    blue: 'bg-blue-500',
    green: 'bg-green-500',
    yellow: 'bg-yellow-500',
    red: 'bg-red-500',
    purple: 'bg-purple-500'
  }
  
  const sizeClasses = {
    sm: 'h-2',
    md: 'h-3',
    lg: 'h-4'
  }

  return (
    <div className={`w-full ${className}`}>
      {showLabel && (
        <div className="flex justify-between text-sm text-gray-600 dark:text-gray-400 mb-1">
          <span>Progress</span>
          <span>{Math.round(percentage)}%</span>
        </div>
      )}
      
      <div className={`w-full bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden ${sizeClasses[size]}`}>
        <motion.div
          className={`h-full ${colorClasses[color]} rounded-full`}
          initial={{ width: 0 }}
          animate={{ width: `${percentage}%` }}
          transition={{ duration: 1, ease: 'easeOut' }}
        />
      </div>
    </div>
  )
}

// Enhanced Tabs with smooth transitions
interface EnhancedTabsProps {
  tabs: Array<{ id: string; label: string; icon?: React.ReactNode }>
  activeTab: string
  onTabChange: (tabId: string) => void
  className?: string
}

export const EnhancedTabs: React.FC<EnhancedTabsProps> = ({
  tabs,
  activeTab,
  onTabChange,
  className = ''
}) => {
  return (
    <div className={`border-b border-gray-200 dark:border-gray-700 ${className}`}>
      <nav className="-mb-px flex space-x-8">
        {tabs.map((tab) => (
          <motion.button
            key={tab.id}
            onClick={() => onTabChange(tab.id)}
            className={`py-2 px-1 border-b-2 font-medium text-sm flex items-center ${
              activeTab === tab.id
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
            whileHover={{ y: -1 }}
            whileTap={{ y: 0 }}
            transition={{ duration: 0.2 }}
          >
            {tab.icon && <span className="mr-2">{tab.icon}</span>}
            {tab.label}
          </motion.button>
        ))}
      </nav>
    </div>
  )
}

// Enhanced Loading Spinner
interface EnhancedLoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg'
  color?: 'blue' | 'green' | 'yellow' | 'red' | 'purple'
  className?: string
}

export const EnhancedLoadingSpinner: React.FC<EnhancedLoadingSpinnerProps> = ({
  size = 'md',
  color = 'blue',
  className = ''
}) => {
  const sizeClasses = {
    sm: 'w-4 h-4',
    md: 'w-8 h-8',
    lg: 'w-12 h-12'
  }
  
  const colorClasses = {
    blue: 'border-blue-500',
    green: 'border-green-500',
    yellow: 'border-yellow-500',
    red: 'border-red-500',
    purple: 'border-purple-500'
  }

  return (
    <motion.div
      className={`${sizeClasses[size]} ${colorClasses[color]} border-2 border-t-transparent rounded-full animate-spin ${className}`}
      animate={{ rotate: 360 }}
      transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}
    />
  )
}

// Enhanced Notification Toast
interface EnhancedToastProps {
  message: string
  type?: 'success' | 'error' | 'warning' | 'info'
  duration?: number
  onClose: () => void
}

export const EnhancedToast: React.FC<EnhancedToastProps> = ({
  message,
  type = 'info',
  duration = 3000,
  onClose
}) => {
  const typeClasses = {
    success: 'bg-green-500 text-white',
    error: 'bg-red-500 text-white',
    warning: 'bg-yellow-500 text-white',
    info: 'bg-blue-500 text-white'
  }

  useEffect(() => {
    const timer = setTimeout(onClose, duration)
    return () => clearTimeout(timer)
  }, [duration, onClose])

  return (
    <motion.div
      className={`fixed top-4 right-4 z-50 px-6 py-3 rounded-lg shadow-lg ${typeClasses[type]}`}
      initial={{ opacity: 0, x: 300, scale: 0.8 }}
      animate={{ opacity: 1, x: 0, scale: 1 }}
      exit={{ opacity: 0, x: 300, scale: 0.8 }}
      transition={{ duration: 0.3 }}
    >
      <div className="flex items-center justify-between">
        <span className="font-medium">{message}</span>
        <button
          onClick={onClose}
          className="ml-4 text-white hover:text-gray-200"
        >
          ×
        </button>
      </div>
    </motion.div>
  )
}
