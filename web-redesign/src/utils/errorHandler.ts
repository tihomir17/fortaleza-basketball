import { AxiosError } from 'axios'

export interface ApiError {
  message: string
  status?: number
  code?: string
  details?: any
}

export class CustomError extends Error {
  public status?: number
  public code?: string
  public details?: any

  constructor(message: string, status?: number, code?: string, details?: any) {
    super(message)
    this.name = 'CustomError'
    this.status = status
    this.code = code
    this.details = details
  }
}

export function handleApiError(error: any): ApiError {
  if (error instanceof CustomError) {
    return {
      message: error.message,
      status: error.status,
      code: error.code,
      details: error.details,
    }
  }

  if (error instanceof AxiosError) {
    const response = error.response
    const request = error.request

    // Network error
    if (!response && request) {
      return {
        message: 'Network error. Please check your internet connection.',
        status: 0,
        code: 'NETWORK_ERROR',
      }
    }

    // Server error
    if (response) {
      const { status, data } = response
      
      return {
        message: data?.message || getDefaultErrorMessage(status),
        status,
        code: data?.code || `HTTP_${status}`,
        details: data?.details,
      }
    }
  }

  // Generic error
  return {
    message: error.message || 'An unexpected error occurred',
    status: 500,
    code: 'UNKNOWN_ERROR',
  }
}

function getDefaultErrorMessage(status: number): string {
  const errorMessages: Record<number, string> = {
    400: 'Bad request. Please check your input.',
    401: 'Unauthorized. Please log in again.',
    403: 'Forbidden. You do not have permission to perform this action.',
    404: 'Resource not found.',
    409: 'Conflict. The resource already exists.',
    422: 'Validation error. Please check your input.',
    429: 'Too many requests. Please try again later.',
    500: 'Internal server error. Please try again later.',
    502: 'Bad gateway. The server is temporarily unavailable.',
    503: 'Service unavailable. Please try again later.',
    504: 'Gateway timeout. The server is taking too long to respond.',
  }

  return errorMessages[status] || 'An error occurred'
}

export function isRetryableError(error: any): boolean {
  if (error instanceof AxiosError) {
    const status = error.response?.status
    
    // Retry on network errors and specific HTTP status codes
    if (!error.response) {
      return true // Network error
    }
    
    if (status && [408, 429, 500, 502, 503, 504].includes(status)) {
      return true
    }
  }
  
  return false
}

export function getRetryDelay(attempt: number, baseDelay: number = 1000): number {
  // Exponential backoff with jitter
  const exponentialDelay = baseDelay * Math.pow(2, attempt - 1)
  const jitter = Math.random() * 0.1 * exponentialDelay
  return Math.min(exponentialDelay + jitter, 30000) // Max 30 seconds
}

export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  let lastError: any

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn()
    } catch (error) {
      lastError = error

      if (attempt === maxRetries || !isRetryableError(error)) {
        throw error
      }

      const delay = getRetryDelay(attempt, baseDelay)
      await new Promise(resolve => setTimeout(resolve, delay))
    }
  }

  throw lastError
}

export function createErrorBoundary(error: ApiError) {
  return {
    message: error.message,
    status: error.status,
    code: error.code,
    details: error.details,
    timestamp: new Date().toISOString(),
    userAgent: navigator.userAgent,
    url: window.location.href,
  }
}

export function logError(error: ApiError, context?: string) {
  const errorInfo = createErrorBoundary(error)
  
  console.error(`[${context || 'API'}] Error:`, errorInfo)
  
  // In production, you might want to send this to an error tracking service
  if (import.meta.env.PROD) {
    // Example: send to Sentry, LogRocket, etc.
    // errorTrackingService.captureException(errorInfo)
  }
}

export function showUserFriendlyError(error: ApiError): string {
  // Map technical errors to user-friendly messages
  const userFriendlyMessages: Record<string, string> = {
    NETWORK_ERROR: 'Unable to connect to the server. Please check your internet connection and try again.',
    HTTP_401: 'Your session has expired. Please log in again.',
    HTTP_403: 'You do not have permission to perform this action.',
    HTTP_404: 'The requested resource was not found.',
    HTTP_409: 'This resource already exists.',
    HTTP_422: 'Please check your input and try again.',
    HTTP_429: 'Too many requests. Please wait a moment and try again.',
    HTTP_500: 'Something went wrong on our end. Please try again later.',
    HTTP_502: 'The server is temporarily unavailable. Please try again later.',
    HTTP_503: 'The service is temporarily unavailable. Please try again later.',
    HTTP_504: 'The request is taking too long. Please try again later.',
  }

  return userFriendlyMessages[error.code || ''] || error.message
}

export function isValidationError(error: ApiError): boolean {
  return error.status === 422 || error.code === 'VALIDATION_ERROR'
}

export function isAuthenticationError(error: ApiError): boolean {
  return error.status === 401 || error.code === 'AUTHENTICATION_ERROR'
}

export function isAuthorizationError(error: ApiError): boolean {
  return error.status === 403 || error.code === 'AUTHORIZATION_ERROR'
}

export function isNetworkError(error: ApiError): boolean {
  return error.status === 0 || error.code === 'NETWORK_ERROR'
}

export function isServerError(error: ApiError): boolean {
  return error.status ? error.status >= 500 : false
}

export function isClientError(error: ApiError): boolean {
  return error.status ? error.status >= 400 && error.status < 500 : false
}
