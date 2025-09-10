import React, { useEffect } from 'react'

interface HealthStatus {
  status: 'healthy' | 'unhealthy' | 'degraded'
  timestamp: string
  version: string
  uptime: number
  checks: {
    api: 'healthy' | 'unhealthy'
    database: 'healthy' | 'unhealthy'
    cache: 'healthy' | 'unhealthy'
  }
  metrics: {
    memoryUsage: number
    responseTime: number
  }
}

export class HealthChecker {
  private startTime: number
  private version: string

  constructor() {
    this.startTime = Date.now()
    this.version = import.meta.env.VITE_APP_VERSION || '1.0.0'
  }

  async checkHealth(): Promise<HealthStatus> {
    const checks = await this.performChecks()
    const metrics = await this.collectMetrics()
    
    const overallStatus = this.determineOverallStatus(checks)
    
    return {
      status: overallStatus,
      timestamp: new Date().toISOString(),
      version: this.version,
      uptime: Date.now() - this.startTime,
      checks,
      metrics,
    }
  }

  private async performChecks(): Promise<HealthStatus['checks']> {
    const [api, database, cache] = await Promise.allSettled([
      this.checkApi(),
      this.checkDatabase(),
      this.checkCache(),
    ])

    return {
      api: api.status === 'fulfilled' && api.value ? 'healthy' : 'unhealthy',
      database: database.status === 'fulfilled' && database.value ? 'healthy' : 'unhealthy',
      cache: cache.status === 'fulfilled' && cache.value ? 'healthy' : 'unhealthy',
    }
  }

  private async checkApi(): Promise<boolean> {
    try {
      const response = await fetch('/api/health', {
        method: 'GET',
        timeout: 5000,
      } as any)
      return response.ok
    } catch {
      return false
    }
  }

  private async checkDatabase(): Promise<boolean> {
    try {
      // This would be a real database health check
      // For now, we'll simulate it
      return true
    } catch {
      return false
    }
  }

  private async checkCache(): Promise<boolean> {
    try {
      // This would be a real cache health check
      // For now, we'll simulate it
      return true
    } catch {
      return false
    }
  }

  private async collectMetrics(): Promise<HealthStatus['metrics']> {
    const memoryUsage = this.getMemoryUsage()
    const responseTime = await this.measureResponseTime()

    return {
      memoryUsage,
      responseTime,
    }
  }

  private getMemoryUsage(): number {
    if ('memory' in performance) {
      const memory = (performance as any).memory
      return Math.round((memory.usedJSHeapSize / memory.jsHeapSizeLimit) * 100)
    }
    return 0
  }

  private async measureResponseTime(): Promise<number> {
    const start = performance.now()
    try {
      await fetch('/api/health', { method: 'GET' })
    } catch {
      // Ignore errors for response time measurement
    }
    return Math.round(performance.now() - start)
  }

  private determineOverallStatus(checks: HealthStatus['checks']): HealthStatus['status'] {
    const healthyChecks = Object.values(checks).filter(status => status === 'healthy').length
    const totalChecks = Object.keys(checks).length

    if (healthyChecks === totalChecks) {
      return 'healthy'
    } else if (healthyChecks > totalChecks / 2) {
      return 'degraded'
    } else {
      return 'unhealthy'
    }
  }
}

// Global health checker instance
export const healthChecker = new HealthChecker()

// Health check endpoint handler
export async function handleHealthCheck(): Promise<Response> {
  try {
    const health = await healthChecker.checkHealth()
    
    const statusCode = health.status === 'healthy' ? 200 : 
                      health.status === 'degraded' ? 200 : 503

    return new Response(JSON.stringify(health), {
      status: statusCode,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
    })
  } catch (error) {
    return new Response(JSON.stringify({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: (error as any)?.message || 'Unknown error',
    }), {
      status: 503,
      headers: {
        'Content-Type': 'application/json',
      },
    })
  }
}

// Health check hook for React components
export function useHealthCheck(interval: number = 30000) {
  const [health, setHealth] = React.useState<HealthStatus | null>(null)
  const [loading, setLoading] = React.useState(true)

  useEffect(() => {
    const checkHealth = async () => {
      try {
        const healthStatus = await healthChecker.checkHealth()
        setHealth(healthStatus)
      } catch {
        console.error('Health check failed')
      } finally {
        setLoading(false)
      }
    }

    // Initial check
    checkHealth()

    // Set up interval
    const intervalId = setInterval(checkHealth, interval)

    return () => clearInterval(intervalId)
  }, [interval])

  return { health, loading }
}
