import { retryWithBackoff, isRetryableError, getRetryDelay } from './errorHandler'

export interface RetryOptions {
  maxRetries?: number
  baseDelay?: number
  maxDelay?: number
  retryCondition?: (error: any) => boolean
  onRetry?: (attempt: number, error: any) => void
}

export class RetryManager {
  private static instance: RetryManager
  private retryQueues: Map<string, Promise<any>> = new Map()

  static getInstance(): RetryManager {
    if (!RetryManager.instance) {
      RetryManager.instance = new RetryManager()
    }
    return RetryManager.instance
  }

  async execute<T>(
    key: string,
    fn: () => Promise<T>,
    options: RetryOptions = {}
  ): Promise<T> {
    const {
      maxRetries = 3,
      baseDelay = 1000,
      retryCondition = isRetryableError,
      onRetry,
    } = options

    // Check if there's already a retry in progress for this key
    if (this.retryQueues.has(key)) {
      return this.retryQueues.get(key)!
    }

    const retryPromise = this.performRetry(fn, {
      maxRetries,
      baseDelay,
      retryCondition,
      onRetry,
    })

    this.retryQueues.set(key, retryPromise)

    try {
      const result = await retryPromise
      return result
    } finally {
      this.retryQueues.delete(key)
    }
  }

  private async performRetry<T>(
    fn: () => Promise<T>,
    options: RetryOptions
  ): Promise<T> {
    const { maxRetries = 3, baseDelay = 1000, retryCondition, onRetry } = options
    let lastError: any

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await fn()
      } catch (error) {
        lastError = error

        if (attempt === maxRetries || !retryCondition?.(error)) {
          throw error
        }

        onRetry?.(attempt, error)

        const delay = getRetryDelay(attempt, baseDelay)
        await this.delay(delay)
      }
    }

    throw lastError
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  clearQueue(key: string): void {
    this.retryQueues.delete(key)
  }

  clearAllQueues(): void {
    this.retryQueues.clear()
  }

  getQueueSize(): number {
    return this.retryQueues.size
  }
}

// Convenience function for simple retry operations
export async function retry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const retryManager = RetryManager.getInstance()
  const key = `retry_${Date.now()}_${Math.random()}`
  return retryManager.execute(key, fn, options)
}

// Retry with exponential backoff
export async function retryWithExponentialBackoff<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  return retryWithBackoff(fn, maxRetries, baseDelay)
}

// Retry with custom condition
export async function retryWithCondition<T>(
  fn: () => Promise<T>,
  condition: (error: any) => boolean,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  return retry(fn, {
    maxRetries,
    baseDelay,
    retryCondition: condition,
  })
}

// Retry for network operations
export async function retryNetworkOperation<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3
): Promise<T> {
  return retry(fn, {
    maxRetries,
    baseDelay: 1000,
    retryCondition: (error) => {
      // Retry on network errors, timeouts, and 5xx errors
      return (
        !error.response ||
        error.response.status >= 500 ||
        error.code === 'ECONNABORTED' ||
        error.code === 'ETIMEDOUT'
      )
    },
  })
}

// Retry for authentication operations
export async function retryAuthOperation<T>(
  fn: () => Promise<T>,
  maxRetries: number = 2
): Promise<T> {
  return retry(fn, {
    maxRetries,
    baseDelay: 500,
    retryCondition: (error) => {
      // Only retry on 401 errors (might be token refresh)
      return error.response?.status === 401
    },
  })
}

// Retry for file upload operations
export async function retryFileUpload<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3
): Promise<T> {
  return retry(fn, {
    maxRetries,
    baseDelay: 2000,
    retryCondition: (error) => {
      // Retry on network errors and 5xx errors
      return (
        !error.response ||
        error.response.status >= 500 ||
        error.code === 'ECONNABORTED'
      )
    },
  })
}

// Circuit breaker pattern
export class CircuitBreaker {
  private failures: number = 0
  private lastFailureTime: number = 0
  private state: 'CLOSED' | 'OPEN' | 'HALF_OPEN' = 'CLOSED'

  private threshold: number
  // private timeout: number
  private resetTimeout: number

  constructor(
    threshold: number = 5,
    _timeout: number = 60000, // 1 minute
    resetTimeout: number = 30000 // 30 seconds
  ) {
    this.threshold = threshold
    // this.timeout = timeout
    this.resetTimeout = resetTimeout
  }

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'OPEN') {
      if (Date.now() - this.lastFailureTime > this.resetTimeout) {
        this.state = 'HALF_OPEN'
      } else {
        throw new Error('Circuit breaker is OPEN')
      }
    }

    try {
      const result = await fn()
      this.onSuccess()
      return result
    } catch (error) {
      this.onFailure()
      throw error
    }
  }

  private onSuccess(): void {
    this.failures = 0
    this.state = 'CLOSED'
  }

  private onFailure(): void {
    this.failures++
    this.lastFailureTime = Date.now()

    if (this.failures >= this.threshold) {
      this.state = 'OPEN'
    }
  }

  getState(): string {
    return this.state
  }

  getFailures(): number {
    return this.failures
  }

  reset(): void {
    this.failures = 0
    this.state = 'CLOSED'
    this.lastFailureTime = 0
  }
}
