import { SECURITY_HEADERS, rateLimiter, logSecurityEvent } from '../utils/security'

// Security middleware for API requests
export function securityMiddleware(request: Request): Response | null {
  const url = new URL(request.url)
  const clientIP = getClientIP(request)
  
  // Rate limiting
  if (!rateLimiter.isAllowed(clientIP)) {
    logSecurityEvent('rate-limit-exceeded', {
      ip: clientIP,
      url: url.pathname,
      userAgent: request.headers.get('User-Agent'),
    })
    
    return new Response('Rate limit exceeded', {
      status: 429,
      headers: {
        'Retry-After': '60',
        ...SECURITY_HEADERS,
      },
    })
  }
  
  // Check for suspicious patterns
  if (isSuspiciousRequest(request)) {
    logSecurityEvent('suspicious-request', {
      ip: clientIP,
      url: url.pathname,
      userAgent: request.headers.get('User-Agent'),
      headers: Object.fromEntries(request.headers.entries()),
    })
    
    return new Response('Forbidden', {
      status: 403,
      headers: SECURITY_HEADERS,
    })
  }
  
  return null
}

// Get client IP address
function getClientIP(request: Request): string {
  const forwarded = request.headers.get('X-Forwarded-For')
  const realIP = request.headers.get('X-Real-IP')
  const remoteAddr = request.headers.get('X-Remote-Addr')
  
  if (forwarded) {
    return forwarded.split(',')[0].trim()
  }
  
  if (realIP) {
    return realIP
  }
  
  if (remoteAddr) {
    return remoteAddr
  }
  
  return 'unknown'
}

// Check for suspicious request patterns
function isSuspiciousRequest(request: Request): boolean {
  const url = new URL(request.url)
  const userAgent = request.headers.get('User-Agent') || ''
  
  // Check for common attack patterns
  const suspiciousPatterns = [
    /\.\.\//, // Directory traversal
    /<script/i, // XSS attempts
    /javascript:/i, // JavaScript protocol
    /on\w+\s*=/i, // Event handlers
    /union\s+select/i, // SQL injection
    /drop\s+table/i, // SQL injection
    /exec\s*\(/i, // Command injection
    /eval\s*\(/i, // Code injection
  ]
  
  // Check URL path
  for (const pattern of suspiciousPatterns) {
    if (pattern.test(url.pathname) || pattern.test(url.search)) {
      return true
    }
  }
  
  // Check User-Agent for suspicious patterns
  const suspiciousUserAgents = [
    /sqlmap/i,
    /nikto/i,
    /nmap/i,
    /masscan/i,
    /zap/i,
    /burp/i,
    /w3af/i,
    /havij/i,
  ]
  
  for (const pattern of suspiciousUserAgents) {
    if (pattern.test(userAgent)) {
      return true
    }
  }
  
  // Check for missing or suspicious headers
  const requiredHeaders = ['User-Agent', 'Accept']
  for (const header of requiredHeaders) {
    if (!request.headers.get(header)) {
      return true
    }
  }
  
  return false
}

// CORS security configuration
export const CORS_CONFIG = {
  origin: (origin: string | null): boolean => {
    if (!origin) return false
    
    const allowedOrigins = [
      'https://fortaleza-basketball.com',
      'https://www.fortaleza-basketball.com',
      'https://app.fortaleza-basketball.com',
    ]
    
    // Allow localhost in development
    if (import.meta.env.DEV) {
      allowedOrigins.push('http://localhost:3000', 'http://localhost:5173')
    }
    
    return allowedOrigins.includes(origin)
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'X-Requested-With',
    'X-CSRF-Token',
  ],
  exposedHeaders: ['X-Rate-Limit-Remaining', 'X-Rate-Limit-Reset'],
  maxAge: 86400, // 24 hours
}

// Security headers for API responses
export function addSecurityHeaders(response: Response): Response {
  Object.entries(SECURITY_HEADERS).forEach(([key, value]) => {
    response.headers.set(key, value)
  })
  
  return response
}

// Request validation middleware
export function validateRequest(request: Request): Response | null {
  const contentType = request.headers.get('Content-Type')
  const contentLength = request.headers.get('Content-Length')
  
  // Check content length
  if (contentLength && parseInt(contentLength) > 10 * 1024 * 1024) { // 10MB limit
    return new Response('Request too large', {
      status: 413,
      headers: SECURITY_HEADERS,
    })
  }
  
  // Check content type for POST/PUT requests
  if (['POST', 'PUT', 'PATCH'].includes(request.method)) {
    if (!contentType || !contentType.includes('application/json')) {
      return new Response('Invalid content type', {
        status: 415,
        headers: SECURITY_HEADERS,
      })
    }
  }
  
  return null
}

// Authentication middleware
export function authenticateRequest(request: Request): Response | null {
  const authHeader = request.headers.get('Authorization')
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response('Unauthorized', {
      status: 401,
      headers: {
        ...SECURITY_HEADERS,
        'WWW-Authenticate': 'Bearer',
      },
    })
  }
  
  const token = authHeader.substring(7)
  
  // Basic token validation (in a real app, you'd verify the JWT)
  if (!token || token.length < 10) {
    return new Response('Invalid token', {
      status: 401,
      headers: {
        ...SECURITY_HEADERS,
        'WWW-Authenticate': 'Bearer',
      },
    })
  }
  
  return null
}

// Authorization middleware
export function authorizeRequest(
  _request: Request,
  _requiredPermissions: string[] = [] // eslint-disable-line @typescript-eslint/no-unused-vars
): Response | null {
  // This would typically decode the JWT and check permissions
  // For now, we'll just return null (allow)
  return null
}

// Security event monitoring
export class SecurityMonitor {
  private events: Array<{
    timestamp: Date
    event: string
    details: Record<string, any>
  }> = []
  
  private readonly maxEvents = 1000
  
  logEvent(event: string, details: Record<string, any> = {}) {
    this.events.push({
      timestamp: new Date(),
      event,
      details,
    })
    
    // Keep only the most recent events
    if (this.events.length > this.maxEvents) {
      this.events = this.events.slice(-this.maxEvents)
    }
    
    // Check for security patterns
    this.checkSecurityPatterns(event, details)
  }
  
  private checkSecurityPatterns(event: string, _details: Record<string, any>) { // eslint-disable-line @typescript-eslint/no-unused-vars
    // Check for multiple failed login attempts
    if (event === 'login-failed') {
      const recentFailures = this.events
        .filter(e => e.event === 'login-failed' && 
                Date.now() - e.timestamp.getTime() < 15 * 60 * 1000) // 15 minutes
        .length
      
      if (recentFailures > 5) {
        this.logEvent('potential-brute-force', {
          failures: recentFailures,
          timeWindow: '15 minutes',
        })
      }
    }
    
    // Check for suspicious activity patterns
    if (event === 'suspicious-request') {
      const recentSuspicious = this.events
        .filter(e => e.event === 'suspicious-request' && 
                Date.now() - e.timestamp.getTime() < 60 * 1000) // 1 minute
        .length
      
      if (recentSuspicious > 10) {
        this.logEvent('potential-attack', {
          suspiciousRequests: recentSuspicious,
          timeWindow: '1 minute',
        })
      }
    }
  }
  
  getEvents(filter?: { event?: string; since?: Date }): Array<{
    timestamp: Date
    event: string
    details: Record<string, any>
  }> {
    let filtered = this.events
    
    if (filter?.event) {
      filtered = filtered.filter(e => e.event === filter.event)
    }
    
    if (filter?.since) {
      filtered = filtered.filter(e => e.timestamp >= filter.since!)
    }
    
    return filtered
  }
  
  getSecuritySummary(): {
    totalEvents: number
    eventsByType: Record<string, number>
    recentEvents: number
  } {
    const now = Date.now()
    const recentThreshold = 24 * 60 * 60 * 1000 // 24 hours
    
    const recentEvents = this.events.filter(
      e => now - e.timestamp.getTime() < recentThreshold
    ).length
    
    const eventsByType = this.events.reduce((acc, event) => {
      acc[event.event] = (acc[event.event] || 0) + 1
      return acc
    }, {} as Record<string, number>)
    
    return {
      totalEvents: this.events.length,
      eventsByType,
      recentEvents,
    }
  }
}

// Global security monitor instance
export const securityMonitor = new SecurityMonitor()
