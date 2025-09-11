// User behavior tracking utilities

interface BehaviorEvent {
  id: string
  timestamp: number
  type: string
  category: string
  action: string
  label?: string
  value?: number
  metadata?: Record<string, any>
  sessionId: string
  userId?: string
}

interface SessionData {
  id: string
  startTime: number
  lastActivity: number
  pageViews: number
  events: number
  duration: number
}

class BehaviorTracker {
  private events: BehaviorEvent[] = []
  private sessionData: SessionData
  private readonly maxEvents = 1000
  private readonly batchSize = 50
  private batchTimeout: ReturnType<typeof setTimeout> | null = null
  private isTracking = false

  constructor() {
    this.sessionData = {
      id: this.generateSessionId(),
      startTime: Date.now(),
      lastActivity: Date.now(),
      pageViews: 0,
      events: 0,
      duration: 0,
    }

    this.initializeTracking()
  }

  private generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }

  private generateEventId(): string {
    return `event_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
  }

  private initializeTracking() {
    if (typeof window === 'undefined') return

    this.isTracking = true
    this.setupEventListeners()
    this.startSessionMonitoring()
  }

  private setupEventListeners() {
    // Track page visibility changes
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        this.trackEvent('page_hidden', 'engagement')
      } else {
        this.trackEvent('page_visible', 'engagement')
        this.updateLastActivity()
      }
    })

    // Track page unload
    window.addEventListener('beforeunload', () => {
      this.trackEvent('page_unload', 'navigation')
      this.flushEvents()
    })

    // Track scroll events
    let scrollTimeout: ReturnType<typeof setTimeout>
    window.addEventListener('scroll', () => {
      clearTimeout(scrollTimeout)
      scrollTimeout = setTimeout(() => {
        this.trackScrollDepth()
      }, 1000)
    })

    // Track mouse movements (throttled)
    let mouseTimeout: ReturnType<typeof setTimeout>
    document.addEventListener('mousemove', () => {
      clearTimeout(mouseTimeout)
      mouseTimeout = setTimeout(() => {
        this.updateLastActivity()
      }, 5000)
    })

    // Track keyboard activity
    document.addEventListener('keydown', () => {
      this.updateLastActivity()
    })

    // Track clicks
    document.addEventListener('click', (event) => {
      this.trackClick(event)
    })

    // Track form interactions
    document.addEventListener('submit', (event) => {
      this.trackFormSubmission(event)
    })

    // Track focus events
    document.addEventListener('focusin', (event) => {
      this.trackFocus(event)
    })
  }

  private startSessionMonitoring() {
    setInterval(() => {
      this.updateSessionDuration()
    }, 60000) // Update every minute
  }

  private updateLastActivity() {
    this.sessionData.lastActivity = Date.now()
  }

  private updateSessionDuration() {
    this.sessionData.duration = Date.now() - this.sessionData.startTime
  }

  private trackScrollDepth() {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop
    const scrollHeight = document.documentElement.scrollHeight - window.innerHeight
    const scrollPercent = Math.round((scrollTop / scrollHeight) * 100)

    if (scrollPercent > 0 && scrollPercent % 25 === 0) {
      this.trackEvent('scroll_depth', 'engagement', `${scrollPercent}%`)
    }
  }

  private trackClick(event: Event) {
    const target = event.target as HTMLElement
    if (!target) return

    const element = this.getElementInfo(target)
    this.trackEvent('click', 'interaction', element.text, undefined, {
      element: element.tag,
      className: element.className,
      id: element.id,
      href: element.href,
    })
  }

  private trackFormSubmission(event: Event) {
    const form = event.target as HTMLFormElement
    if (!form) return

    const formName = form.name || form.id || 'unnamed_form'
    this.trackEvent('form_submit', 'interaction', formName, undefined, {
      formName,
      action: form.action,
      method: form.method,
    })
  }

  private trackFocus(event: Event) {
    const target = event.target as HTMLElement
    if (!target) return

    const element = this.getElementInfo(target)
    if (element.tag === 'input' || element.tag === 'textarea' || element.tag === 'select') {
      this.trackEvent('form_focus', 'interaction', element.text, undefined, {
        element: element.tag,
        type: (target as HTMLInputElement).type,
        name: (target as HTMLInputElement).name,
      })
    }
  }

  private getElementInfo(element: HTMLElement) {
    return {
      tag: element.tagName.toLowerCase(),
      text: element.textContent?.trim().substring(0, 50) || '',
      className: element.className || '',
      id: element.id || '',
      href: (element as HTMLAnchorElement).href || '',
    }
  }

  // Public methods
  trackEvent(
    action: string,
    category: string,
    label?: string,
    value?: number,
    metadata?: Record<string, any>
  ) {
    if (!this.isTracking) return

    const event: BehaviorEvent = {
      id: this.generateEventId(),
      timestamp: Date.now(),
      type: 'behavior',
      category,
      action,
      label,
      value,
      metadata,
      sessionId: this.sessionData.id,
      userId: this.getCurrentUserId(),
    }

    this.events.push(event)
    this.sessionData.events++
    this.updateLastActivity()

    // Batch events for sending
    this.scheduleBatchSend()
  }

  trackPageView(path: string, title?: string) {
    this.sessionData.pageViews++
    this.trackEvent('page_view', 'navigation', path, undefined, {
      title: title || document.title,
      path,
      referrer: document.referrer,
    })
  }

  trackUserAction(action: string, details?: Record<string, any>) {
    this.trackEvent('user_action', 'user', action, undefined, details)
  }

  trackError(error: string, context?: Record<string, any>) {
    this.trackEvent('error', 'error', error, undefined, context)
  }

  trackPerformance(metric: string, value: number, context?: Record<string, any>) {
    this.trackEvent('performance', 'performance', metric, value, context)
  }

  private getCurrentUserId(): string | undefined {
    // This would typically get the user ID from your auth store
    return undefined
  }

  private scheduleBatchSend() {
    if (this.batchTimeout) {
      clearTimeout(this.batchTimeout)
    }

    this.batchTimeout = setTimeout(() => {
      this.sendBatch()
    }, 5000) // Send batch every 5 seconds
  }

  private sendBatch() {
    if (this.events.length === 0) return

    const batch = this.events.splice(0, this.batchSize)
    
    // Send to analytics service
    this.sendToAnalytics(batch)
    
    // Keep only recent events
    if (this.events.length > this.maxEvents) {
      this.events = this.events.slice(-this.maxEvents)
    }
  }

  private sendToAnalytics(events: BehaviorEvent[]) {
    // Send to Google Analytics
    events.forEach(event => {
      if (typeof window !== 'undefined' && window.gtag) {
        window.gtag('event', event.action, {
          event_category: event.category,
          event_label: event.label,
          value: event.value,
          custom_parameters: event.metadata,
        })
      }
    })

    // Send to custom analytics endpoint
    if (import.meta.env.PROD) {
      fetch('/api/analytics/events', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          session: this.sessionData,
          events: events,
        }),
      }).catch(error => {
        console.error('Failed to send analytics events:', error)
      })
    }
  }

  flushEvents() {
    if (this.batchTimeout) {
      clearTimeout(this.batchTimeout)
    }
    this.sendBatch()
  }

  getSessionData(): SessionData {
    return { ...this.sessionData }
  }

  getEventCount(): number {
    return this.events.length
  }

  clearEvents() {
    this.events = []
  }

  stopTracking() {
    this.isTracking = false
    this.flushEvents()
  }
}

// Global behavior tracker instance
export const behaviorTracker = new BehaviorTracker()

// Convenience functions
export const trackBehavior = {
  // Page tracking
  pageView: (path: string, title?: string) => {
    behaviorTracker.trackPageView(path, title)
  },

  // User actions
  buttonClick: (buttonName: string, location?: string) => {
    behaviorTracker.trackUserAction('button_click', { buttonName, location })
  },

  linkClick: (linkText: string, destination: string) => {
    behaviorTracker.trackUserAction('link_click', { linkText, destination })
  },

  formSubmit: (formName: string, success: boolean) => {
    behaviorTracker.trackUserAction('form_submit', { formName, success })
  },

  search: (query: string, resultsCount?: number) => {
    behaviorTracker.trackUserAction('search', { query, resultsCount })
  },

  // Feature usage
  featureUse: (feature: string, context?: Record<string, any>) => {
    behaviorTracker.trackUserAction('feature_use', { feature, ...context })
  },

  // Navigation
  navigation: (from: string, to: string) => {
    behaviorTracker.trackUserAction('navigation', { from, to })
  },

  // Errors
  error: (error: string, context?: Record<string, any>) => {
    behaviorTracker.trackError(error, context)
  },

  // Performance
  performance: (metric: string, value: number, context?: Record<string, any>) => {
    behaviorTracker.trackPerformance(metric, value, context)
  },
}

// React hook for behavior tracking
export function useBehaviorTracking() {
  return {
    track: behaviorTracker.trackEvent.bind(behaviorTracker),
    trackPageView: behaviorTracker.trackPageView.bind(behaviorTracker),
    trackUserAction: behaviorTracker.trackUserAction.bind(behaviorTracker),
    trackError: behaviorTracker.trackError.bind(behaviorTracker),
    trackPerformance: behaviorTracker.trackPerformance.bind(behaviorTracker),
    getSessionData: behaviorTracker.getSessionData.bind(behaviorTracker),
  }
}

// Initialize behavior tracking
if (typeof window !== 'undefined') {
  // Track initial page view
  behaviorTracker.trackPageView(window.location.pathname, document.title)
}
