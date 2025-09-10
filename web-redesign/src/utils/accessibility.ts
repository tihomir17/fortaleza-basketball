// Accessibility utilities for WCAG 2.1 AA compliance

// Focus management
export const trapFocus = (element: HTMLElement) => {
  const focusableElements = element.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  )
  const firstElement = focusableElements[0] as HTMLElement
  const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement

  const handleTabKey = (e: KeyboardEvent) => {
    if (e.key === 'Tab') {
      if (e.shiftKey) {
        if (document.activeElement === firstElement) {
          lastElement.focus()
          e.preventDefault()
        }
      } else {
        if (document.activeElement === lastElement) {
          firstElement.focus()
          e.preventDefault()
        }
      }
    }
  }

  element.addEventListener('keydown', handleTabKey)
  firstElement?.focus()

  return () => {
    element.removeEventListener('keydown', handleTabKey)
  }
}

// Announce to screen readers
export const announceToScreenReader = (message: string, priority: 'polite' | 'assertive' = 'polite') => {
  const announcement = document.createElement('div')
  announcement.setAttribute('aria-live', priority)
  announcement.setAttribute('aria-atomic', 'true')
  announcement.className = 'sr-only'
  announcement.textContent = message

  document.body.appendChild(announcement)

  setTimeout(() => {
    document.body.removeChild(announcement)
  }, 1000)
}

// Skip to main content link
export const createSkipLink = () => {
  const skipLink = document.createElement('a')
  skipLink.href = '#main-content'
  skipLink.textContent = 'Skip to main content'
  skipLink.className = 'sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-fortaleza-blue text-white px-4 py-2 rounded z-50'
  
  skipLink.addEventListener('click', (e) => {
    e.preventDefault()
    const mainContent = document.getElementById('main-content')
    if (mainContent) {
      mainContent.focus()
      mainContent.scrollIntoView()
    }
  })

  return skipLink
}

// Keyboard navigation helpers
export const handleKeyboardNavigation = (
  event: KeyboardEvent,
  onEnter?: () => void,
  onEscape?: () => void,
  onArrowUp?: () => void,
  onArrowDown?: () => void,
  onArrowLeft?: () => void,
  onArrowRight?: () => void
) => {
  switch (event.key) {
    case 'Enter':
    case ' ':
      onEnter?.()
      break
    case 'Escape':
      onEscape?.()
      break
    case 'ArrowUp':
      onArrowUp?.()
      break
    case 'ArrowDown':
      onArrowDown?.()
      break
    case 'ArrowLeft':
      onArrowLeft?.()
      break
    case 'ArrowRight':
      onArrowRight?.()
      break
  }
}

// Color contrast checker
export const getContrastRatio = (color1: string, color2: string): number => {
  const getLuminance = (color: string): number => {
    const rgb = hexToRgb(color)
    if (!rgb) return 0

    const { r, g, b } = rgb
    const [rs, gs, bs] = [r, g, b].map(c => {
      c = c / 255
      return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
    })

    return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs
  }

  const luminance1 = getLuminance(color1)
  const luminance2 = getLuminance(color2)
  const brightest = Math.max(luminance1, luminance2)
  const darkest = Math.min(luminance1, luminance2)

  return (brightest + 0.05) / (darkest + 0.05)
}

// Check if color combination meets WCAG AA standards
export const meetsWCAGAA = (foreground: string, background: string): boolean => {
  const ratio = getContrastRatio(foreground, background)
  return ratio >= 4.5 // WCAG AA standard for normal text
}

// Check if color combination meets WCAG AAA standards
export const meetsWCAGAAA = (foreground: string, background: string): boolean => {
  const ratio = getContrastRatio(foreground, background)
  return ratio >= 7 // WCAG AAA standard for normal text
}

// Helper function to convert hex to RGB
const hexToRgb = (hex: string): { r: number; g: number; b: number } | null => {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : null
}

// ARIA live region for dynamic content updates
export const createLiveRegion = (id: string = 'live-region'): HTMLElement => {
  let liveRegion = document.getElementById(id) as HTMLElement
  
  if (!liveRegion) {
    liveRegion = document.createElement('div')
    liveRegion.id = id
    liveRegion.setAttribute('aria-live', 'polite')
    liveRegion.setAttribute('aria-atomic', 'true')
    liveRegion.className = 'sr-only'
    document.body.appendChild(liveRegion)
  }
  
  return liveRegion
}

// Announce dynamic content changes
export const announceContentChange = (message: string, regionId?: string) => {
  const liveRegion = createLiveRegion(regionId)
  liveRegion.textContent = message
}

// High contrast mode detection
export const isHighContrastMode = (): boolean => {
  return window.matchMedia('(prefers-contrast: high)').matches
}

// Reduced motion detection
export const prefersReducedMotion = (): boolean => {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches
}

// Dark mode detection
export const prefersDarkMode = (): boolean => {
  return window.matchMedia('(prefers-color-scheme: dark)').matches
}

// Screen reader detection (basic)
export const isScreenReaderActive = (): boolean => {
  return window.speechSynthesis !== undefined && 'speak' in window.speechSynthesis
}

// Focus visible polyfill for older browsers
export const setupFocusVisible = () => {
  if (!CSS.supports('selector(:focus-visible)')) {
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Tab') {
        document.body.classList.add('keyboard-navigation')
      }
    })

    document.addEventListener('mousedown', () => {
      document.body.classList.remove('keyboard-navigation')
    })
  }
}

// Initialize accessibility features
export const initializeAccessibility = () => {
  // Add skip link
  const skipLink = createSkipLink()
  document.body.insertBefore(skipLink, document.body.firstChild)

  // Setup focus visible polyfill
  setupFocusVisible()

  // Add main content landmark
  const mainContent = document.querySelector('main')
  if (mainContent && !mainContent.id) {
    mainContent.id = 'main-content'
    mainContent.setAttribute('tabindex', '-1')
  }

  // Create live region for announcements
  createLiveRegion()
}
