import * as Sentry from '@sentry/react'
import { BrowserTracing } from '@sentry/tracing'

// Initialize Sentry
export function initMonitoring() {
  const dsn = import.meta.env.VITE_SENTRY_DSN
  
  if (dsn && import.meta.env.PROD) {
    Sentry.init({
      dsn,
      environment: import.meta.env.MODE,
      integrations: [
        new BrowserTracing({
          // Set sampling rate for performance monitoring
          tracingOrigins: ['localhost', 'fortaleza-basketball.com', /^\//],
        }) as any,
      ],
      // Performance Monitoring
      tracesSampleRate: 0.1,
      // Session Replay
      replaysSessionSampleRate: 0.1,
      replaysOnErrorSampleRate: 1.0,
      // Release tracking
      release: import.meta.env.VITE_APP_VERSION,
    })
  }
}

// Performance monitoring utilities
export const performanceMonitor = {
  // Measure function execution time
  measureFunction: <T extends (...args: any[]) => any>(
    name: string,
    fn: T
  ): T => {
    return ((...args: Parameters<T>) => {
      const start = performance.now()
      const result = fn(...args)
      
      if (result instanceof Promise) {
        return result.finally(() => {
          const end = performance.now()
          const duration = end - start
          
          // Log to console in development
          if (import.meta.env.DEV) {
            console.log(`[Performance] ${name}: ${duration.toFixed(2)}ms`)
          }
          
          // Send to Sentry in production
          if (import.meta.env.PROD) {
            Sentry.addBreadcrumb({
              message: `Function ${name} executed`,
              category: 'performance',
              data: { duration },
              level: 'info',
            })
          }
        })
      } else {
        const end = performance.now()
        const duration = end - start
        
        if (import.meta.env.DEV) {
          console.log(`[Performance] ${name}: ${duration.toFixed(2)}ms`)
        }
        
        if (import.meta.env.PROD) {
          Sentry.addBreadcrumb({
            message: `Function ${name} executed`,
            category: 'performance',
            data: { duration },
            level: 'info',
          })
        }
        
        return result
      }
    }) as T
  },

  // Measure component render time
  measureRender: (componentName: string) => {
    const start = performance.now()
    
    return () => {
      const end = performance.now()
      const duration = end - start
      
      if (import.meta.env.DEV) {
        console.log(`[Performance] ${componentName} render: ${duration.toFixed(2)}ms`)
      }
      
      if (import.meta.env.PROD) {
        Sentry.addBreadcrumb({
          message: `Component ${componentName} rendered`,
          category: 'performance',
          data: { duration },
          level: 'info',
        })
      }
    }
  },

  // Measure API call performance
  measureApiCall: async <T>(
    apiCall: () => Promise<T>,
    endpoint: string
  ): Promise<T> => {
    const start = performance.now()
    
    try {
      const result = await apiCall()
      const end = performance.now()
      const duration = end - start
      
      if (import.meta.env.DEV) {
        console.log(`[Performance] API ${endpoint}: ${duration.toFixed(2)}ms`)
      }
      
      if (import.meta.env.PROD) {
        Sentry.addBreadcrumb({
          message: `API call to ${endpoint}`,
          category: 'performance',
          data: { duration, endpoint },
          level: 'info',
        })
      }
      
      return result
    } catch (error) {
      const end = performance.now()
      const duration = end - start
      
      if (import.meta.env.PROD) {
        Sentry.addBreadcrumb({
          message: `API call to ${endpoint} failed`,
          category: 'performance',
          data: { duration, endpoint, error: (error as any)?.message || 'Unknown error' },
          level: 'error',
        })
      }
      
      throw error
    }
  },
}

// Error tracking utilities
export const errorTracker = {
  // Capture and report errors
  captureError: (error: Error, context?: Record<string, any>) => {
    if (import.meta.env.PROD) {
      Sentry.captureException(error, {
        extra: context,
      })
    } else {
      console.error('Error captured:', error, context)
    }
  },

  // Capture messages
  captureMessage: (message: string, level: 'info' | 'warning' | 'error' = 'info') => {
    if (import.meta.env.PROD) {
      Sentry.captureMessage(message, level)
    } else {
      console.log(`[${level.toUpperCase()}] ${message}`)
    }
  },

  // Set user context
  setUser: (user: { id: string; email?: string; username?: string }) => {
    if (import.meta.env.PROD) {
      Sentry.setUser(user)
    }
  },

  // Set additional context
  setContext: (key: string, context: Record<string, any>) => {
    if (import.meta.env.PROD) {
      Sentry.setContext(key, context)
    }
  },

  // Add breadcrumb
  addBreadcrumb: (breadcrumb: {
    message: string
    category?: string
    level?: 'info' | 'warning' | 'error'
    data?: Record<string, any>
  }) => {
    if (import.meta.env.PROD) {
      Sentry.addBreadcrumb(breadcrumb)
    } else {
      console.log(`[Breadcrumb] ${breadcrumb.message}`, breadcrumb.data)
    }
  },
}

// User behavior tracking
export const behaviorTracker = {
  // Track page views
  trackPageView: (path: string, title?: string) => {
    if (import.meta.env.PROD) {
      Sentry.addBreadcrumb({
        message: `Page view: ${path}`,
        category: 'navigation',
        data: { path, title },
        level: 'info',
      })
    }
  },

  // Track user actions
  trackAction: (action: string, data?: Record<string, any>) => {
    if (import.meta.env.PROD) {
      Sentry.addBreadcrumb({
        message: `User action: ${action}`,
        category: 'user',
        data,
        level: 'info',
      })
    }
  },

  // Track form submissions
  trackFormSubmission: (formName: string, success: boolean, data?: Record<string, any>) => {
    if (import.meta.env.PROD) {
      Sentry.addBreadcrumb({
        message: `Form submission: ${formName}`,
        category: 'form',
        data: { formName, success, ...data },
        level: success ? 'info' : 'warning',
      })
    }
  },

  // Track API calls
  trackApiCall: (endpoint: string, method: string, success: boolean, duration?: number) => {
    if (import.meta.env.PROD) {
      Sentry.addBreadcrumb({
        message: `API call: ${method} ${endpoint}`,
        category: 'api',
        data: { endpoint, method, success, duration },
        level: success ? 'info' : 'error',
      })
    }
  },
}

// Performance metrics collection
export const metricsCollector = {
  // Collect Core Web Vitals
  collectWebVitals: () => {
    if (import.meta.env.PROD && 'web-vital' in window) {
      // This would require installing web-vitals package
      // import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals'
      
      // getCLS((metric) => {
      //   Sentry.addBreadcrumb({
      //     message: 'Core Web Vital: CLS',
      //     category: 'performance',
      //     data: { value: metric.value, rating: metric.rating },
      //     level: 'info',
      //   })
      // })
      
      // Similar for other metrics...
    }
  },

  // Collect memory usage
  collectMemoryUsage: () => {
    if (import.meta.env.PROD && 'memory' in performance) {
      const memory = (performance as any).memory
      if (memory) {
        Sentry.addBreadcrumb({
          message: 'Memory usage',
          category: 'performance',
          data: {
            usedJSHeapSize: memory.usedJSHeapSize,
            totalJSHeapSize: memory.totalJSHeapSize,
            jsHeapSizeLimit: memory.jsHeapSizeLimit,
          },
          level: 'info',
        })
      }
    }
  },

  // Collect network information
  collectNetworkInfo: () => {
    if (import.meta.env.PROD && 'connection' in navigator) {
      const connection = (navigator as any).connection
      if (connection) {
        Sentry.addBreadcrumb({
          message: 'Network information',
          category: 'performance',
          data: {
            effectiveType: connection.effectiveType,
            downlink: connection.downlink,
            rtt: connection.rtt,
          },
          level: 'info',
        })
      }
    }
  },
}

// Initialize monitoring when the module is imported
if (import.meta.env.PROD) {
  initMonitoring()
}
