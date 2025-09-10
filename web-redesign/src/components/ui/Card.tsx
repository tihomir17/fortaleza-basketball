import type { ReactNode } from 'react'
import { cn } from '../../utils/cn'

interface CardProps {
  children: ReactNode
  className?: string
  padding?: 'none' | 'sm' | 'md' | 'lg'
  shadow?: 'none' | 'sm' | 'md' | 'lg'
  border?: boolean
  hover?: boolean
}

export function Card({
  children,
  className,
  padding = 'md',
  shadow = 'sm',
  border: _border = true,
  hover = false
}: CardProps) {
  const paddingClasses = {
    none: '',
    sm: 'p-4',
    md: 'p-6',
    lg: 'p-8'
  }

  const shadowClasses = {
    none: '',
    sm: 'shadow-sm',
    md: 'shadow-md',
    lg: 'shadow-lg'
  }

  return (
    <div
      className={cn(
        'bg-white/80 dark:bg-gray-800/80 backdrop-blur-xl rounded-2xl border border-white/20 dark:border-gray-700/50',
        paddingClasses[padding],
        shadowClasses[shadow],
        hover && 'hover:shadow-xl hover:shadow-black/10 hover:scale-[1.02] transition-all duration-300',
        'relative overflow-hidden',
        className
      )}
    >
      {/* Subtle gradient overlay */}
      <div className="absolute inset-0 bg-gradient-to-br from-white/10 to-transparent pointer-events-none"></div>
      <div className="relative z-10">
        {children}
      </div>
    </div>
  )
}

interface CardHeaderProps {
  children: ReactNode
  className?: string
}

export function CardHeader({ children, className }: CardHeaderProps) {
  return (
    <div className={cn('mb-4', className)}>
      {children}
    </div>
  )
}

interface CardTitleProps {
  children: ReactNode
  className?: string
}

export function CardTitle({ children, className }: CardTitleProps) {
  return (
    <h3 className={cn('text-lg font-semibold text-gray-900 dark:text-white', className)}>
      {children}
    </h3>
  )
}

interface CardDescriptionProps {
  children: ReactNode
  className?: string
}

export function CardDescription({ children, className }: CardDescriptionProps) {
  return (
    <p className={cn('text-sm text-gray-600 dark:text-gray-400 mt-1', className)}>
      {children}
    </p>
  )
}

interface CardContentProps {
  children: ReactNode
  className?: string
}

export function CardContent({ children, className }: CardContentProps) {
  return (
    <div className={cn('', className)}>
      {children}
    </div>
  )
}

interface CardFooterProps {
  children: ReactNode
  className?: string
}

export function CardFooter({ children, className }: CardFooterProps) {
  return (
    <div className={cn('mt-4 pt-4 border-t border-gray-100 dark:border-gray-700', className)}>
      {children}
    </div>
  )
}
