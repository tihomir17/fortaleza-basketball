// Analytics utilities for Google Analytics and other tracking services

declare global {
  interface Window {
    gtag: (...args: any[]) => void
    dataLayer: any[]
  }
}

// Google Analytics configuration
export const GA_CONFIG = {
  measurementId: import.meta.env.VITE_GOOGLE_ANALYTICS_ID,
  enabled: import.meta.env.PROD && !!import.meta.env.VITE_GOOGLE_ANALYTICS_ID,
}

// Initialize Google Analytics
export function initializeGoogleAnalytics() {
  if (!GA_CONFIG.enabled) return

  // Load Google Analytics script
  const script = document.createElement('script')
  script.async = true
  script.src = `https://www.googletagmanager.com/gtag/js?id=${GA_CONFIG.measurementId}`
  document.head.appendChild(script)

  // Initialize gtag
  window.dataLayer = window.dataLayer || []
  window.gtag = function() {
    window.dataLayer.push(arguments)
  }

  window.gtag('js', new Date())
  window.gtag('config', GA_CONFIG.measurementId, {
    page_title: document.title,
    page_location: window.location.href,
  })
}

// Track page views
export function trackPageView(path: string, title?: string) {
  if (!GA_CONFIG.enabled) return

  window.gtag('config', GA_CONFIG.measurementId, {
    page_path: path,
    page_title: title || document.title,
  })
}

// Track custom events
export function trackEvent(
  action: string,
  category: string,
  label?: string,
  value?: number
) {
  if (!GA_CONFIG.enabled) return

  window.gtag('event', action, {
    event_category: category,
    event_label: label,
    value: value,
  })
}

// Track user interactions
export const userInteractions = {
  // Button clicks
  trackButtonClick: (buttonName: string, location?: string) => {
    trackEvent('click', 'button', `${buttonName}${location ? ` - ${location}` : ''}`)
  },

  // Form submissions
  trackFormSubmission: (formName: string, success: boolean) => {
    trackEvent('submit', 'form', `${formName} - ${success ? 'success' : 'error'}`)
  },

  // Link clicks
  trackLinkClick: (linkText: string, destination: string) => {
    trackEvent('click', 'link', `${linkText} -> ${destination}`)
  },

  // Search queries
  trackSearch: (query: string, resultsCount?: number) => {
    trackEvent('search', 'search', query, resultsCount)
  },

  // File downloads
  trackDownload: (fileName: string, fileType: string) => {
    trackEvent('download', 'file', `${fileName} (${fileType})`)
  },

  // Video interactions
  trackVideoPlay: (videoTitle: string) => {
    trackEvent('play', 'video', videoTitle)
  },

  trackVideoPause: (videoTitle: string) => {
    trackEvent('pause', 'video', videoTitle)
  },

  // Social media interactions
  trackSocialShare: (platform: string, content: string) => {
    trackEvent('share', 'social', `${platform} - ${content}`)
  },
}

// Track business events
export const businessEvents = {
  // User registration
  trackUserRegistration: (method: string) => {
    trackEvent('sign_up', 'user', method)
  },

  // User login
  trackUserLogin: (method: string) => {
    trackEvent('login', 'user', method)
  },

  // User logout
  trackUserLogout: () => {
    trackEvent('logout', 'user')
  },

  // Game creation
  trackGameCreation: (gameType: string) => {
    trackEvent('create', 'game', gameType)
  },

  // Game update
  trackGameUpdate: (gameId: string) => {
    trackEvent('update', 'game', gameId)
  },

  // Game deletion
  trackGameDeletion: (gameId: string) => {
    trackEvent('delete', 'game', gameId)
  },

  // Team creation
  trackTeamCreation: (teamName: string) => {
    trackEvent('create', 'team', teamName)
  },

  // Player addition
  trackPlayerAddition: (playerName: string, teamName: string) => {
    trackEvent('add', 'player', `${playerName} to ${teamName}`)
  },

  // Data export
  trackDataExport: (exportType: string, recordCount: number) => {
    trackEvent('export', 'data', exportType, recordCount)
  },

  // Report generation
  trackReportGeneration: (reportType: string) => {
    trackEvent('generate', 'report', reportType)
  },
}

// Track performance metrics
export const performanceTracking = {
  // Page load time
  trackPageLoadTime: (loadTime: number) => {
    trackEvent('timing_complete', 'performance', 'page_load', Math.round(loadTime))
  },

  // API response time
  trackApiResponseTime: (endpoint: string, responseTime: number) => {
    trackEvent('timing_complete', 'api', endpoint, Math.round(responseTime))
  },

  // Component render time
  trackComponentRender: (componentName: string, renderTime: number) => {
    trackEvent('timing_complete', 'component', componentName, Math.round(renderTime))
  },

  // Search response time
  trackSearchResponseTime: (query: string, responseTime: number) => {
    trackEvent('timing_complete', 'search', query, Math.round(responseTime))
  },
}

// Track errors
export const errorTracking = {
  // JavaScript errors
  trackJavaScriptError: (error: string, source?: string) => {
    trackEvent('exception', 'error', `${error}${source ? ` - ${source}` : ''}`)
  },

  // API errors
  trackApiError: (endpoint: string, statusCode: number, error: string) => {
    trackEvent('exception', 'api_error', `${endpoint} - ${statusCode} - ${error}`)
  },

  // Form validation errors
  trackValidationError: (formName: string, fieldName: string, error: string) => {
    trackEvent('exception', 'validation_error', `${formName}.${fieldName} - ${error}`)
  },

  // Network errors
  trackNetworkError: (url: string, error: string) => {
    trackEvent('exception', 'network_error', `${url} - ${error}`)
  },
}

// Track user engagement
export const engagementTracking = {
  // Time on page
  trackTimeOnPage: (page: string, timeSpent: number) => {
    trackEvent('timing_complete', 'engagement', `time_on_${page}`, Math.round(timeSpent))
  },

  // Scroll depth
  trackScrollDepth: (page: string, depth: number) => {
    trackEvent('scroll', 'engagement', `${page} - ${depth}%`)
  },

  // Session duration
  trackSessionDuration: (duration: number) => {
    trackEvent('timing_complete', 'engagement', 'session_duration', Math.round(duration))
  },

  // Feature usage
  trackFeatureUsage: (feature: string, usageCount: number) => {
    trackEvent('feature_usage', 'engagement', feature, usageCount)
  },
}

// Set user properties
export function setUserProperties(properties: {
  userId?: string
  userRole?: string
  userStatus?: string
  [key: string]: any
}) {
  if (!GA_CONFIG.enabled) return

  window.gtag('config', GA_CONFIG.measurementId, {
    user_id: properties.userId,
    custom_map: {
      user_role: properties.userRole,
      user_status: properties.userStatus,
    },
  })
}

// Track e-commerce events (if applicable)
export const ecommerceTracking = {
  // Purchase
  trackPurchase: (transactionId: string, value: number, currency: string = 'USD') => {
    if (!GA_CONFIG.enabled) return

    window.gtag('event', 'purchase', {
      transaction_id: transactionId,
      value: value,
      currency: currency,
    })
  },

  // Add to cart
  trackAddToCart: (itemId: string, itemName: string, value: number) => {
    if (!GA_CONFIG.enabled) return

    window.gtag('event', 'add_to_cart', {
      currency: 'USD',
      value: value,
      items: [{
        item_id: itemId,
        item_name: itemName,
        price: value,
        quantity: 1,
      }],
    })
  },

  // Remove from cart
  trackRemoveFromCart: (itemId: string, itemName: string, value: number) => {
    if (!GA_CONFIG.enabled) return

    window.gtag('event', 'remove_from_cart', {
      currency: 'USD',
      value: value,
      items: [{
        item_id: itemId,
        item_name: itemName,
        price: value,
        quantity: 1,
      }],
    })
  },
}

// Custom analytics service
export class AnalyticsService {
  private static instance: AnalyticsService
  private isInitialized = false

  static getInstance(): AnalyticsService {
    if (!AnalyticsService.instance) {
      AnalyticsService.instance = new AnalyticsService()
    }
    return AnalyticsService.instance
  }

  initialize() {
    if (this.isInitialized) return

    initializeGoogleAnalytics()
    this.isInitialized = true
  }

  trackPageView(path: string, title?: string) {
    trackPageView(path, title)
  }

  trackEvent(action: string, category: string, label?: string, value?: number) {
    trackEvent(action, category, label, value)
  }

  setUserProperties(properties: Record<string, any>) {
    setUserProperties(properties)
  }
}

// Global analytics instance
export const analytics = AnalyticsService.getInstance()

// Initialize analytics on app start
if (typeof window !== 'undefined') {
  analytics.initialize()
}
