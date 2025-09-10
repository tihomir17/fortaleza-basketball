import { useState, useCallback, useMemo } from 'react'
import { validate, validateFields, sanitizeInput } from '../utils/validation'
import type { ValidationRule, ValidationResult } from '../utils/validation'

interface UseValidationOptions {
  sanitize?: boolean
  sanitizeOptions?: {
    html?: boolean
    script?: boolean
    htmlEntities?: boolean
    specialChars?: boolean
    whitespace?: boolean
    extraSpaces?: boolean
    case?: 'lowercase' | 'uppercase' | 'capitalize' | 'titleCase'
  }
}

export function useValidation<T extends Record<string, any>>(
  schema: Record<keyof T, ValidationRule[]>,
  options: UseValidationOptions = {}
) {
  const [errors, setErrors] = useState<Record<keyof T, string>>({} as Record<keyof T, string>)
  const [touched, setTouched] = useState<Record<keyof T, boolean>>({} as Record<keyof T, boolean>)

  // Validate a single field
  const validateField = useCallback((field: keyof T, value: any): string | null => {
    const rules = schema[field]
    if (!rules) return null

    let sanitizedValue = value
    if (options.sanitize && typeof value === 'string') {
      sanitizedValue = sanitizeInput(value, options.sanitizeOptions)
    }

    return validate(sanitizedValue, rules)
  }, [schema, options])

  // Validate all fields
  const validateAll = useCallback((data: T): ValidationResult => {
    let sanitizedData = data

    if (options.sanitize) {
      sanitizedData = Object.entries(data).reduce((acc, [key, value]) => {
        if (typeof value === 'string') {
          acc[key as keyof T] = sanitizeInput(value, options.sanitizeOptions) as T[keyof T]
        } else {
          acc[key as keyof T] = value
        }
        return acc
      }, {} as T)
    }

    return validateFields(sanitizedData, schema)
  }, [schema, options])

  // Set field error
  const setFieldError = useCallback((field: keyof T, error: string | null) => {
    setErrors(prev => ({
      ...prev,
      [field]: error || '',
    }))
  }, [])

  // Set field touched
  const setFieldTouched = useCallback((field: keyof T, touched: boolean = true) => {
    setTouched(prev => ({
      ...prev,
      [field]: touched,
    }))
  }, [])

  // Validate and set error for a field
  const validateAndSetError = useCallback((field: keyof T, value: any) => {
    const error = validateField(field, value)
    setFieldError(field, error)
    return error
  }, [validateField, setFieldError])

  // Clear field error
  const clearFieldError = useCallback((field: keyof T) => {
    setFieldError(field, null)
  }, [setFieldError])

  // Clear all errors
  const clearAllErrors = useCallback(() => {
    setErrors({} as Record<keyof T, string>)
  }, [])

  // Clear all touched
  const clearAllTouched = useCallback(() => {
    setTouched({} as Record<keyof T, boolean>)
  }, [])

  // Reset validation state
  const reset = useCallback(() => {
    clearAllErrors()
    clearAllTouched()
  }, [clearAllErrors, clearAllTouched])

  // Check if field has error
  const hasError = useCallback((field: keyof T): boolean => {
    return !!(errors[field] && touched[field])
  }, [errors, touched])

  // Get field error
  const getFieldError = useCallback((field: keyof T): string => {
    return hasError(field) ? errors[field] : ''
  }, [errors, hasError])

  // Check if form is valid
  const isValid = useMemo(() => {
    return Object.keys(errors).length === 0 || Object.values(errors).every(error => !error)
  }, [errors])

  // Check if form has been touched
  const isTouched = useMemo(() => {
    return Object.values(touched).some(touched => touched)
  }, [touched])

  // Get validation summary
  const getValidationSummary = useCallback(() => {
    const errorCount = Object.values(errors).filter(error => error).length
    const touchedCount = Object.values(touched).filter(touched => touched).length
    
    return {
      errorCount,
      touchedCount,
      isValid,
      isTouched,
      hasErrors: errorCount > 0,
    }
  }, [errors, touched, isValid, isTouched])

  return {
    errors,
    touched,
    validateField,
    validateAll,
    setFieldError,
    setFieldTouched,
    validateAndSetError,
    clearFieldError,
    clearAllErrors,
    clearAllTouched,
    reset,
    hasError,
    getFieldError,
    isValid,
    isTouched,
    getValidationSummary,
  }
}

// Hook for form validation with real-time validation
export function useFormValidation<T extends Record<string, any>>(
  schema: Record<keyof T, ValidationRule[]>,
  options: UseValidationOptions = {}
) {
  const validation = useValidation(schema, options)
  const [values, setFormValues] = useState<T>({} as T)

  // Update field value and validate
  const setValue = useCallback((field: keyof T, value: any) => {
    setFormValues(prev => ({
      ...prev,
      [field]: value,
    }))

    // Validate if field has been touched
    if (validation.touched[field]) {
      validation.validateAndSetError(field, value)
    }
  }, [validation])

  // Handle field blur (mark as touched and validate)
  const handleBlur = useCallback((field: keyof T) => {
    validation.setFieldTouched(field, true)
    validation.validateAndSetError(field, values[field])
  }, [validation, values])

  // Handle field focus (clear error if field is valid)
  const handleFocus = useCallback((field: keyof T) => {
    const error = validation.validateField(field, values[field])
    if (!error) {
      validation.clearFieldError(field)
    }
  }, [validation, values])

  // Validate all fields
  const validateForm = useCallback(() => {
    const result = validation.validateAll(values)
    
    // Set all fields as touched
    Object.keys(schema).forEach(field => {
      validation.setFieldTouched(field as keyof T, true)
    })

    return result
  }, [validation, values, schema])

  // Reset form
  const resetForm = useCallback(() => {
    setFormValues({} as T)
    validation.reset()
  }, [validation])

  // Set form values
  const setAllValues = useCallback((newValues: T) => {
    setFormValues(newValues)
  }, [])

  return {
    ...validation,
    values,
    setValue,
    handleBlur,
    handleFocus,
    validateForm,
    resetForm,
    setValues: setAllValues,
  }
}

// Hook for async validation
export function useAsyncValidation<T extends Record<string, any>>(
  schema: Record<keyof T, ValidationRule[]>,
  asyncValidators: Record<keyof T, (value: any) => Promise<string | null>> = {} as Record<keyof T, (value: any) => Promise<string | null>>,
  options: UseValidationOptions = {}
) {
  const validation = useValidation(schema, options)
  const [asyncErrors, setAsyncErrors] = useState<Record<keyof T, string>>({} as Record<keyof T, string>)
  const [validating, setValidating] = useState<Record<keyof T, boolean>>({} as Record<keyof T, boolean>)

  // Validate field asynchronously
  const validateFieldAsync = useCallback(async (field: keyof T, value: any) => {
    const asyncValidator = asyncValidators[field]
    if (!asyncValidator) return null

    setValidating(prev => ({ ...prev, [field]: true }))

    try {
      const error = await asyncValidator(value)
      setAsyncErrors(prev => ({ ...prev, [field]: error || '' }))
      return error
    } catch {
      const errorMessage = 'Validation failed'
      setAsyncErrors(prev => ({ ...prev, [field]: errorMessage }))
      return errorMessage
    } finally {
      setValidating(prev => ({ ...prev, [field]: false }))
    }
  }, [asyncValidators])

  // Validate all fields asynchronously
  const validateAllAsync = useCallback(async (data: T) => {
    const promises = Object.keys(asyncValidators).map(async (field) => {
      const key = field as keyof T
      return validateFieldAsync(key, data[key])
    })

    const results = await Promise.all(promises)
    const hasErrors = results.some(result => result !== null)

    return {
      isValid: !hasErrors,
      errors: results,
    }
  }, [asyncValidators, validateFieldAsync])

  // Check if field is validating
  const isFieldValidating = useCallback((field: keyof T): boolean => {
    return !!validating[field]
  }, [validating])

  // Get async error for field
  const getAsyncError = useCallback((field: keyof T): string => {
    return asyncErrors[field] || ''
  }, [asyncErrors])

  // Check if field has async error
  const hasAsyncError = useCallback((field: keyof T): boolean => {
    return !!(asyncErrors[field] && validation.touched[field])
  }, [asyncErrors, validation.touched])

  return {
    ...validation,
    validateFieldAsync,
    validateAllAsync,
    isFieldValidating,
    getAsyncError,
    hasAsyncError,
    asyncErrors,
    validating,
  }
}
