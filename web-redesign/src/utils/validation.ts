// Validation utilities for input sanitization and validation

export interface ValidationRule {
  required?: boolean
  minLength?: number
  maxLength?: number
  pattern?: RegExp
  custom?: (value: any) => string | null
  message?: string
}

export interface ValidationResult {
  isValid: boolean
  errors: Record<string, string>
}

// Common validation patterns
export const patterns = {
  email: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
  phone: /^\+?[\d\s\-\(\)]+$/,
  password: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/,
  username: /^[a-zA-Z0-9_-]+$/,
  url: /^https?:\/\/.+/,
  date: /^\d{4}-\d{2}-\d{2}$/,
  time: /^\d{2}:\d{2}$/,
  numeric: /^\d+$/,
  alphanumeric: /^[a-zA-Z0-9]+$/,
  name: /^[a-zA-Z\s'-]+$/,
}

// Common validation rules
export const rules = {
  required: (message = 'This field is required'): ValidationRule => ({
    required: true,
    message,
  }),

  email: (message = 'Please enter a valid email address'): ValidationRule => ({
    pattern: patterns.email,
    message,
  }),

  password: (message = 'Password must contain at least 8 characters, including uppercase, lowercase, number, and special character'): ValidationRule => ({
    minLength: 8,
    pattern: patterns.password,
    message,
  }),

  phone: (message = 'Please enter a valid phone number'): ValidationRule => ({
    pattern: patterns.phone,
    message,
  }),

  url: (message = 'Please enter a valid URL'): ValidationRule => ({
    pattern: patterns.url,
    message,
  }),

  minLength: (min: number, message?: string): ValidationRule => ({
    minLength: min,
    message: message || `Must be at least ${min} characters long`,
  }),

  maxLength: (max: number, message?: string): ValidationRule => ({
    maxLength: max,
    message: message || `Must be no more than ${max} characters long`,
  }),

  numeric: (message = 'Must be a number'): ValidationRule => ({
    pattern: patterns.numeric,
    message,
  }),

  alphanumeric: (message = 'Must contain only letters and numbers'): ValidationRule => ({
    pattern: patterns.alphanumeric,
    message,
  }),

  name: (message = 'Must contain only letters, spaces, hyphens, and apostrophes'): ValidationRule => ({
    pattern: patterns.name,
    message,
  }),

  custom: (validator: (value: any) => string | null): ValidationRule => ({
    custom: validator,
  }),
}

// Validation function
export function validate(value: any, rules: ValidationRule[]): string | null {
  for (const rule of rules) {
    // Required check
    if (rule.required && (!value || value.toString().trim() === '')) {
      return rule.message || 'This field is required'
    }

    // Skip other validations if value is empty and not required
    if (!value || value.toString().trim() === '') {
      continue
    }

    const stringValue = value.toString()

    // Min length check
    if (rule.minLength && stringValue.length < rule.minLength) {
      return rule.message || `Must be at least ${rule.minLength} characters long`
    }

    // Max length check
    if (rule.maxLength && stringValue.length > rule.maxLength) {
      return rule.message || `Must be no more than ${rule.maxLength} characters long`
    }

    // Pattern check
    if (rule.pattern && !rule.pattern.test(stringValue)) {
      return rule.message || 'Invalid format'
    }

    // Custom validation
    if (rule.custom) {
      const customError = rule.custom(value)
      if (customError) {
        return customError
      }
    }
  }

  return null
}

// Validate multiple fields
export function validateFields(
  data: Record<string, any>,
  schema: Record<string, ValidationRule[]>
): ValidationResult {
  const errors: Record<string, string> = {}

  for (const [field, rules] of Object.entries(schema)) {
    const error = validate(data[field], rules)
    if (error) {
      errors[field] = error
    }
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors,
  }
}

// Sanitization utilities
export const sanitize = {
  // Remove HTML tags
  html: (input: string): string => {
    return input.replace(/<[^>]*>/g, '')
  },

  // Remove script tags and javascript: protocols
  script: (input: string): string => {
    return input
      .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
      .replace(/javascript:/gi, '')
      .replace(/on\w+\s*=/gi, '')
  },

  // Escape HTML entities
  htmlEntities: (input: string): string => {
    const entityMap: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;',
      '/': '&#x2F;',
    }
    
    return input.replace(/[&<>"'/]/g, (s) => entityMap[s])
  },

  // Remove special characters
  specialChars: (input: string): string => {
    return input.replace(/[^a-zA-Z0-9\s]/g, '')
  },

  // Normalize whitespace
  whitespace: (input: string): string => {
    return input.replace(/\s+/g, ' ').trim()
  },

  // Remove extra spaces
  extraSpaces: (input: string): string => {
    return input.replace(/\s{2,}/g, ' ')
  },

  // Convert to lowercase
  lowercase: (input: string): string => {
    return input.toLowerCase()
  },

  // Convert to uppercase
  uppercase: (input: string): string => {
    return input.toUpperCase()
  },

  // Capitalize first letter
  capitalize: (input: string): string => {
    return input.charAt(0).toUpperCase() + input.slice(1).toLowerCase()
  },

  // Title case
  titleCase: (input: string): string => {
    return input.replace(/\w\S*/g, (txt) => 
      txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
    )
  },
}

// Input sanitization function
export function sanitizeInput(input: any, options: {
  html?: boolean
  script?: boolean
  htmlEntities?: boolean
  specialChars?: boolean
  whitespace?: boolean
  extraSpaces?: boolean
  case?: 'lowercase' | 'uppercase' | 'capitalize' | 'titleCase'
} = {}): string {
  if (typeof input !== 'string') {
    return String(input)
  }

  let result = input

  if (options.html) {
    result = sanitize.html(result)
  }

  if (options.script) {
    result = sanitize.script(result)
  }

  if (options.specialChars) {
    result = sanitize.specialChars(result)
  }

  if (options.whitespace) {
    result = sanitize.whitespace(result)
  }

  if (options.extraSpaces) {
    result = sanitize.extraSpaces(result)
  }

  if (options.htmlEntities) {
    result = sanitize.htmlEntities(result)
  }

  if (options.case) {
    switch (options.case) {
      case 'lowercase':
        result = sanitize.lowercase(result)
        break
      case 'uppercase':
        result = sanitize.uppercase(result)
        break
      case 'capitalize':
        result = sanitize.capitalize(result)
        break
      case 'titleCase':
        result = sanitize.titleCase(result)
        break
    }
  }

  return result
}

// Form validation schemas
export const schemas = {
  login: {
    email: [rules.required(), rules.email()],
    password: [rules.required(), rules.minLength(8)],
  },

  register: {
    email: [rules.required(), rules.email()],
    password: [rules.required(), rules.password()],
    confirmPassword: [rules.required()],
    firstName: [rules.required(), rules.name(), rules.minLength(2)],
    lastName: [rules.required(), rules.name(), rules.minLength(2)],
  },

  profile: {
    firstName: [rules.required(), rules.name(), rules.minLength(2)],
    lastName: [rules.required(), rules.name(), rules.minLength(2)],
    email: [rules.required(), rules.email()],
    phone: [rules.phone()],
  },

  game: {
    homeTeam: [rules.required(), rules.minLength(2)],
    awayTeam: [rules.required(), rules.minLength(2)],
    date: [rules.required()],
    location: [rules.required(), rules.minLength(2)],
  },

  team: {
    name: [rules.required(), rules.minLength(2)],
    city: [rules.required(), rules.minLength(2)],
    state: [rules.required(), rules.minLength(2)],
    league: [rules.required()],
  },

  player: {
    name: [rules.required(), rules.name(), rules.minLength(2)],
    position: [rules.required()],
    jerseyNumber: [rules.required(), rules.numeric()],
    teamId: [rules.required()],
  },
}

// Custom validators
export const validators = {
  // Password confirmation
  passwordMatch: (password: string) => (confirmPassword: string) => {
    return password === confirmPassword ? null : 'Passwords do not match'
  },

  // Age validation
  age: (minAge: number, maxAge: number) => (birthDate: string) => {
    const age = new Date().getFullYear() - new Date(birthDate).getFullYear()
    return age >= minAge && age <= maxAge ? null : `Age must be between ${minAge} and ${maxAge}`
  },

  // Date validation
  futureDate: (date: string) => {
    return new Date(date) > new Date() ? null : 'Date must be in the future'
  },

  pastDate: (date: string) => {
    return new Date(date) < new Date() ? null : 'Date must be in the past'
  },

  // File validation
  fileSize: (maxSize: number) => (file: File) => {
    return file.size <= maxSize ? null : `File size must be less than ${maxSize / 1024 / 1024}MB`
  },

  fileType: (allowedTypes: string[]) => (file: File) => {
    return allowedTypes.includes(file.type) ? null : `File type must be one of: ${allowedTypes.join(', ')}`
  },

  // URL validation
  validUrl: (url: string) => {
    try {
      new URL(url)
      return null
    } catch {
      return 'Please enter a valid URL'
    }
  },

  // Phone number validation
  validPhone: (phone: string) => {
    const cleaned = phone.replace(/\D/g, '')
    return cleaned.length >= 10 ? null : 'Please enter a valid phone number'
  },
}
