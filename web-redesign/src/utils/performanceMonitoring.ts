// Performance monitoring utilities

interface PerformanceMetric {
  name: string
  value: number
  timestamp: number
  type: 'timing' | 'counter' | 'gauge'
  metadata?: Record<string, any>
}

// interface PerformanceEntry {
//   name: string
//   entryType: string
//   startTime: number
//   duration: number
//   timestamp: number
// }

class PerformanceMonitor {
  private metrics: PerformanceMetric[] = []
  private observers: PerformanceObserver[] = []
  // private isMonitoring = false
  private readonly maxMetrics = 1000

  constructor() {
    this.initializeMonitoring()
  }

  private initializeMonitoring() {
    if (typeof window === 'undefined') return

    // this.isMonitoring = true
    this.setupPerformanceObservers()
    this.startCoreWebVitalsMonitoring()
    this.startCustomMetricsMonitoring()
  }

  private setupPerformanceObservers() {
    // Navigation timing
    if ('PerformanceObserver' in window) {
      try {
        const navigationObserver = new PerformanceObserver((list) => {
          list.getEntries().forEach((entry) => {
            this.handleNavigationEntry(entry as any)
          })
        })
        navigationObserver.observe({ entryTypes: ['navigation'] })
        this.observers.push(navigationObserver)
      } catch (error) {
        console.warn('Navigation timing observer not supported:', error)
      }

      // Resource timing
      try {
        const resourceObserver = new PerformanceObserver((list) => {
          list.getEntries().forEach((entry) => {
            this.handleResourceEntry(entry as any)
          })
        })
        resourceObserver.observe({ entryTypes: ['resource'] })
        this.observers.push(resourceObserver)
      } catch (error) {
        console.warn('Resource timing observer not supported:', error)
      }

      // Paint timing
      try {
        const paintObserver = new PerformanceObserver((list) => {
          list.getEntries().forEach((entry) => {
            this.handlePaintEntry(entry as any)
          })
        })
        paintObserver.observe({ entryTypes: ['paint'] })
        this.observers.push(paintObserver)
      } catch (error) {
        console.warn('Paint timing observer not supported:', error)
      }

      // Long task monitoring
      try {
        const longTaskObserver = new PerformanceObserver((list) => {
          list.getEntries().forEach((entry) => {
            this.handleLongTaskEntry(entry as any)
          })
        })
        longTaskObserver.observe({ entryTypes: ['longtask'] })
        this.observers.push(longTaskObserver)
      } catch (error) {
        console.warn('Long task observer not supported:', error)
      }
    }
  }

  private startCoreWebVitalsMonitoring() {
    // First Contentful Paint (FCP)
    this.measureFCP()
    
    // Largest Contentful Paint (LCP)
    this.measureLCP()
    
    // First Input Delay (FID)
    this.measureFID()
    
    // Cumulative Layout Shift (CLS)
    this.measureCLS()
    
    // Time to First Byte (TTFB)
    this.measureTTFB()
  }

  private startCustomMetricsMonitoring() {
    // Memory usage monitoring
    this.startMemoryMonitoring()
    
    // Network monitoring
    this.startNetworkMonitoring()
    
    // Custom timing measurements
    this.startCustomTimingMonitoring()
  }

  private measureFCP() {
    if ('PerformanceObserver' in window) {
      try {
        const observer = new PerformanceObserver((list) => {
          list.getEntries().forEach((entry) => {
            if (entry.name === 'first-contentful-paint') {
              this.recordMetric('fcp', entry.startTime, 'timing', {
                entryType: 'paint',
              })
            }
          })
        })
        observer.observe({ entryTypes: ['paint'] })
        this.observers.push(observer)
      } catch (error) {
        console.warn('FCP measurement not supported:', error)
      }
    }
  }

  private measureLCP() {
    if ('PerformanceObserver' in window) {
      try {
        const observer = new PerformanceObserver((list) => {
          const entries = list.getEntries()
          const lastEntry = entries[entries.length - 1]
          this.recordMetric('lcp', lastEntry.startTime, 'timing', {
            entryType: 'largest-contentful-paint',
            element: (lastEntry as any).element?.tagName,
          })
        })
        observer.observe({ entryTypes: ['largest-contentful-paint'] })
        this.observers.push(observer)
      } catch (error) {
        console.warn('LCP measurement not supported:', error)
      }
    }
  }

  private measureFID() {
    if ('PerformanceObserver' in window) {
      try {
        const observer = new PerformanceObserver((list) => {
          list.getEntries().forEach((entry) => {
            this.recordMetric('fid', (entry as any).processingStart - entry.startTime, 'timing', {
              entryType: 'first-input',
              eventType: entry.name,
            })
          })
        })
        observer.observe({ entryTypes: ['first-input'] })
        this.observers.push(observer)
      } catch (error) {
        console.warn('FID measurement not supported:', error)
      }
    }
  }

  private measureCLS() {
    if ('PerformanceObserver' in window) {
      try {
        let clsValue = 0
        const observer = new PerformanceObserver((list) => {
          list.getEntries().forEach((entry) => {
            if (!(entry as any).hadRecentInput) {
              clsValue += (entry as any).value
            }
          })
          this.recordMetric('cls', clsValue, 'timing', {
            entryType: 'layout-shift',
          })
        })
        observer.observe({ entryTypes: ['layout-shift'] })
        this.observers.push(observer)
      } catch (error) {
        console.warn('CLS measurement not supported:', error)
      }
    }
  }

  private measureTTFB() {
    if ('PerformanceObserver' in window) {
      try {
        const observer = new PerformanceObserver((list) => {
          list.getEntries().forEach((entry) => {
            if (entry.entryType === 'navigation') {
              const ttfb = (entry as any).responseStart - (entry as any).requestStart
              this.recordMetric('ttfb', ttfb, 'timing', {
                entryType: 'navigation',
              })
            }
          })
        })
        observer.observe({ entryTypes: ['navigation'] })
        this.observers.push(observer)
      } catch (error) {
        console.warn('TTFB measurement not supported:', error)
      }
    }
  }

  private startMemoryMonitoring() {
    if ('memory' in performance) {
      setInterval(() => {
        const memory = (performance as any).memory
        this.recordMetric('memory_used', memory.usedJSHeapSize, 'gauge', {
          total: memory.totalJSHeapSize,
          limit: memory.jsHeapSizeLimit,
        })
      }, 30000) // Every 30 seconds
    }
  }

  private startNetworkMonitoring() {
    if ('connection' in navigator) {
      const connection = (navigator as any).connection
      if (connection) {
        this.recordMetric('network_effective_type', this.getNetworkScore(connection.effectiveType), 'gauge', {
          effectiveType: connection.effectiveType,
          downlink: connection.downlink,
          rtt: connection.rtt,
        })
      }
    }
  }

  private startCustomTimingMonitoring() {
    // Monitor page load time
    window.addEventListener('load', () => {
      const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart
      this.recordMetric('page_load_time', loadTime, 'timing')
    })

    // Monitor DOM content loaded time
    document.addEventListener('DOMContentLoaded', () => {
      const domContentLoadedTime = performance.timing.domContentLoadedEventEnd - performance.timing.navigationStart
      this.recordMetric('dom_content_loaded_time', domContentLoadedTime, 'timing')
    })
  }

  private getNetworkScore(effectiveType: string): number {
    const scores: Record<string, number> = {
      'slow-2g': 1,
      '2g': 2,
      '3g': 3,
      '4g': 4,
    }
    return scores[effectiveType] || 0
  }

  private handleNavigationEntry(entry: any) {
    this.recordMetric('navigation_duration', entry.duration, 'timing', {
      entryType: entry.entryType,
      name: entry.name,
    })
  }

  private handleResourceEntry(entry: any) {
    if (entry.duration > 1000) { // Only track slow resources
      this.recordMetric('slow_resource', entry.duration, 'timing', {
        entryType: entry.entryType,
        name: entry.name,
      })
    }
  }

  private handlePaintEntry(entry: any) {
    this.recordMetric(`paint_${entry.name}`, entry.startTime, 'timing', {
      entryType: entry.entryType,
    })
  }

  private handleLongTaskEntry(entry: any) {
    this.recordMetric('long_task', entry.duration, 'timing', {
      entryType: entry.entryType,
      startTime: entry.startTime,
    })
  }

  // Public methods
  recordMetric(
    name: string,
    value: number,
    type: 'timing' | 'counter' | 'gauge' = 'timing',
    metadata?: Record<string, any>
  ) {
    const metric: PerformanceMetric = {
      name,
      value,
      timestamp: Date.now(),
      type,
      metadata,
    }

    this.metrics.push(metric)

    // Keep only recent metrics
    if (this.metrics.length > this.maxMetrics) {
      this.metrics = this.metrics.slice(-this.maxMetrics)
    }

    // Send to analytics
    this.sendToAnalytics(metric)
  }

  measureFunction<T extends (...args: any[]) => any>(
    name: string,
    fn: T
  ): T {
    return ((...args: Parameters<T>) => {
      const start = performance.now()
      const result = fn(...args)
      
      if (result instanceof Promise) {
        return result.finally(() => {
          const end = performance.now()
          this.recordMetric(`function_${name}`, end - start, 'timing')
        })
      } else {
        const end = performance.now()
        this.recordMetric(`function_${name}`, end - start, 'timing')
        return result
      }
    }) as T
  }

  measureAsyncFunction<T extends (...args: any[]) => Promise<any>>(
    name: string,
    fn: T
  ): T {
    return (async (...args: Parameters<T>) => {
      const start = performance.now()
      try {
        const result = await fn(...args)
        const end = performance.now()
        this.recordMetric(`async_function_${name}`, end - start, 'timing', {
          success: true,
        })
        return result
      } catch (error) {
        const end = performance.now()
        this.recordMetric(`async_function_${name}`, end - start, 'timing', {
          success: false,
          error: (error as any)?.message || 'Unknown error',
        })
        throw error
      }
    }) as T
  }

  measureApiCall<T>(name: string, apiCall: () => Promise<T>): Promise<T> {
    const start = performance.now()
    return apiCall()
      .then(result => {
        const end = performance.now()
        this.recordMetric(`api_${name}`, end - start, 'timing', {
          success: true,
        })
        return result
      })
      .catch(error => {
        const end = performance.now()
        this.recordMetric(`api_${name}`, end - start, 'timing', {
          success: false,
          error: (error as any)?.message || 'Unknown error',
        })
        throw error
      })
  }

  measureComponentRender(componentName: string, renderFn: () => void) {
    const start = performance.now()
    renderFn()
    const end = performance.now()
    this.recordMetric(`component_${componentName}`, end - start, 'timing')
  }

  private sendToAnalytics(metric: PerformanceMetric) {
    // Send to Google Analytics
    if (typeof window !== 'undefined' && window.gtag) {
      window.gtag('event', 'timing_complete', {
        name: metric.name,
        value: Math.round(metric.value),
        event_category: 'performance',
        event_label: metric.type,
        custom_parameters: metric.metadata,
      })
    }

    // Send to custom analytics endpoint
    if (import.meta.env.PROD) {
      fetch('/api/analytics/performance', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(metric),
      }).catch(error => {
        console.error('Failed to send performance metric:', error)
      })
    }
  }

  getMetrics(filter?: {
    name?: string
    type?: string
    since?: number
  }): PerformanceMetric[] {
    let filtered = this.metrics

    if (filter?.name) {
      filtered = filtered.filter(m => m.name === filter.name)
    }

    if (filter?.type) {
      filtered = filtered.filter(m => m.type === filter.type)
    }

    if (filter?.since) {
      filtered = filtered.filter(m => m.timestamp >= filter.since!)
    }

    return filtered
  }

  getPerformanceSummary(): {
    totalMetrics: number
    metricsByType: Record<string, number>
    averageValues: Record<string, number>
    recentMetrics: number
  } {
    const now = Date.now()
    const recentThreshold = 5 * 60 * 1000 // 5 minutes

    const recentMetrics = this.metrics.filter(
      m => now - m.timestamp < recentThreshold
    ).length

    const metricsByType = this.metrics.reduce((acc, metric) => {
      acc[metric.type] = (acc[metric.type] || 0) + 1
      return acc
    }, {} as Record<string, number>)

    const averageValues = this.metrics.reduce((acc, metric) => {
      if (!acc[metric.name]) {
        acc[metric.name] = { sum: 0, count: 0 }
      }
      acc[metric.name].sum += metric.value
      acc[metric.name].count += 1
      return acc
    }, {} as Record<string, { sum: number; count: number }>)

    const finalAverageValues: Record<string, number> = {}
    Object.keys(averageValues).forEach(name => {
      finalAverageValues[name] = (averageValues[name] as any).sum / (averageValues[name] as any).count
    })

    return {
      totalMetrics: this.metrics.length,
      metricsByType,
      averageValues: finalAverageValues,
      recentMetrics,
    }
  }

  clearMetrics() {
    this.metrics = []
  }

  stopMonitoring() {
    // this.isMonitoring = false
    this.observers.forEach(observer => observer.disconnect())
    this.observers = []
  }
}

// Global performance monitor instance
export const performanceMonitor = new PerformanceMonitor()

// Convenience functions
export const trackPerformance = {
  // Function timing
  function: performanceMonitor.measureFunction.bind(performanceMonitor),
  asyncFunction: performanceMonitor.measureAsyncFunction.bind(performanceMonitor),
  apiCall: performanceMonitor.measureApiCall.bind(performanceMonitor),
  componentRender: performanceMonitor.measureComponentRender.bind(performanceMonitor),

  // Custom metrics
  timing: (name: string, value: number, metadata?: Record<string, any>) => {
    performanceMonitor.recordMetric(name, value, 'timing', metadata)
  },

  counter: (name: string, value: number, metadata?: Record<string, any>) => {
    performanceMonitor.recordMetric(name, value, 'counter', metadata)
  },

  gauge: (name: string, value: number, metadata?: Record<string, any>) => {
    performanceMonitor.recordMetric(name, value, 'gauge', metadata)
  },
}

// React hook for performance monitoring
export function usePerformanceMonitoring() {
  return {
    measure: performanceMonitor.recordMetric.bind(performanceMonitor),
    measureFunction: performanceMonitor.measureFunction.bind(performanceMonitor),
    measureAsyncFunction: performanceMonitor.measureAsyncFunction.bind(performanceMonitor),
    measureApiCall: performanceMonitor.measureApiCall.bind(performanceMonitor),
    measureComponentRender: performanceMonitor.measureComponentRender.bind(performanceMonitor),
    getMetrics: performanceMonitor.getMetrics.bind(performanceMonitor),
    getSummary: performanceMonitor.getPerformanceSummary.bind(performanceMonitor),
  }
}

// Initialize performance monitoring
if (typeof window !== 'undefined') {
  // Monitor initial page load
  window.addEventListener('load', () => {
    const loadTime = performance.timing.loadEventEnd - performance.timing.navigationStart
    performanceMonitor.recordMetric('initial_page_load', loadTime, 'timing')
  })
}
