import { useState, useEffect } from 'react'
import { Card } from './ui/Card'
import { Button } from './ui/Button'
import { performanceMonitor, errorTracker, behaviorTracker, metricsCollector } from '../utils/monitoring'

interface PerformanceMetrics {
  memoryUsage: {
    used: number
    total: number
    limit: number
  } | null
  networkInfo: {
    effectiveType: string
    downlink: number
    rtt: number
  } | null
  pageLoadTime: number
  renderCount: number
}

export function MonitoringDashboard() {
  const [metrics, setMetrics] = useState<PerformanceMetrics>({
    memoryUsage: null,
    networkInfo: null,
    pageLoadTime: 0,
    renderCount: 0,
  })
  const [isVisible, setIsVisible] = useState(false)

  useEffect(() => {
    if (!import.meta.env.DEV) return

    const updateMetrics = () => {
      // Memory usage
      let memoryUsage = null
      if ('memory' in performance) {
        const memory = (performance as any).memory
        memoryUsage = {
          used: Math.round(memory.usedJSHeapSize / 1024 / 1024),
          total: Math.round(memory.totalJSHeapSize / 1024 / 1024),
          limit: Math.round(memory.jsHeapSizeLimit / 1024 / 1024),
        }
      }

      // Network information
      let networkInfo = null
      if ('connection' in navigator) {
        const connection = (navigator as any).connection
        networkInfo = {
          effectiveType: connection.effectiveType || 'unknown',
          downlink: connection.downlink || 0,
          rtt: connection.rtt || 0,
        }
      }

      // Page load time
      const pageLoadTime = performance.timing
        ? performance.timing.loadEventEnd - performance.timing.navigationStart
        : 0

      setMetrics(prev => ({
        memoryUsage,
        networkInfo,
        pageLoadTime,
        renderCount: prev.renderCount + 1,
      }))
    }

    // Update metrics immediately
    updateMetrics()

    // Update metrics every 5 seconds
    const interval = setInterval(updateMetrics, 5000)

    return () => clearInterval(interval)
  }, [])

  const handleTestError = () => {
    try {
      throw new Error('Test error for monitoring')
    } catch (error) {
      errorTracker.captureError(error as Error, { source: 'monitoring-dashboard' })
    }
  }

  const handleTestPerformance = () => {
    const testFunction = performanceMonitor.measureFunction('test-function', () => {
      // Simulate some work
      let result = 0
      for (let i = 0; i < 1000000; i++) {
        result += Math.random()
      }
      return result
    })

    testFunction()
  }

  const handleTestBehavior = () => {
    behaviorTracker.trackAction('test-button-clicked', { timestamp: Date.now() })
  }

  const handleCollectMetrics = () => {
    metricsCollector.collectMemoryUsage()
    metricsCollector.collectNetworkInfo()
    behaviorTracker.trackAction('metrics-collected', { timestamp: Date.now() })
  }

  if (!import.meta.env.DEV && !isVisible) {
    return null
  }

  return (
    <div className="fixed bottom-4 right-4 z-50">
      <Card className="w-80 max-h-96 overflow-y-auto">
        <div className="p-4">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-semibold">Monitoring Dashboard</h3>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => setIsVisible(!isVisible)}
            >
              {isVisible ? 'Hide' : 'Show'}
            </Button>
          </div>

          <div className="space-y-4">
            {/* Performance Metrics */}
            <div>
              <h4 className="font-medium mb-2">Performance Metrics</h4>
              <div className="text-sm space-y-1">
                <div>Page Load Time: {metrics.pageLoadTime}ms</div>
                <div>Render Count: {metrics.renderCount}</div>
                {metrics.memoryUsage && (
                  <div>
                    Memory: {metrics.memoryUsage.used}MB / {metrics.memoryUsage.total}MB
                    (Limit: {metrics.memoryUsage.limit}MB)
                  </div>
                )}
                {metrics.networkInfo && (
                  <div>
                    Network: {metrics.networkInfo.effectiveType} 
                    ({metrics.networkInfo.downlink}Mbps, {metrics.networkInfo.rtt}ms RTT)
                  </div>
                )}
              </div>
            </div>

            {/* Test Buttons */}
            <div>
              <h4 className="font-medium mb-2">Test Functions</h4>
              <div className="space-y-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleTestError}
                  className="w-full"
                >
                  Test Error Tracking
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleTestPerformance}
                  className="w-full"
                >
                  Test Performance
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleTestBehavior}
                  className="w-full"
                >
                  Test Behavior Tracking
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleCollectMetrics}
                  className="w-full"
                >
                  Collect Metrics
                </Button>
              </div>
            </div>

            {/* Environment Info */}
            <div>
              <h4 className="font-medium mb-2">Environment</h4>
              <div className="text-sm space-y-1">
                <div>Mode: {import.meta.env.MODE}</div>
                <div>Version: {import.meta.env.VITE_APP_VERSION || 'Unknown'}</div>
                <div>API URL: {import.meta.env.VITE_API_BASE_URL || 'Not set'}</div>
              </div>
            </div>
          </div>
        </div>
      </Card>
    </div>
  )
}
