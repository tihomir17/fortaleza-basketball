// Common API types
export interface ApiResponse<T = unknown> {
  data: T
  message?: string
  status: number
}

export interface ApiError {
  message: string
  code?: string
  details?: Record<string, unknown>
}

export interface PaginatedResponse<T> {
  results: T[]
  count: number
  next?: string
  previous?: string
}

// Generic types for common use cases
export type ApiCallback<T = unknown> = (data: T) => void
export type ApiErrorCallback = (error: ApiError) => void
export type ApiRequestConfig = Record<string, unknown>
export type ApiResponseData = Record<string, unknown>
