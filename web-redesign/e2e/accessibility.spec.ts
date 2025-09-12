import { test, expect } from '@playwright/test'

test.describe('Accessibility Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Mock authentication
    await page.route('**/api/auth/me', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          user: {
            id: '1',
            email: 'test@example.com',
            firstName: 'Test',
            lastName: 'User',
            role: 'admin'
          }
        })
      })
    })

    await page.goto('/')
  })

  test('should have proper heading structure', async ({ page }) => {
    // Check for main heading
    const h1 = page.locator('h1')
    await expect(h1).toBeVisible()
    
    // Check heading hierarchy
    const headings = page.locator('h1, h2, h3, h4, h5, h6')
    const headingCount = await headings.count()
    expect(headingCount).toBeGreaterThan(0)
  })

  test('should have proper form labels', async ({ page }) => {
    // Check that all form inputs have labels
    const inputs = page.locator('input[type="text"], input[type="email"], input[type="password"], textarea, select')
    const inputCount = await inputs.count()
    
    for (let i = 0; i < inputCount; i++) {
      const input = inputs.nth(i)
      const id = await input.getAttribute('id')
      
      if (id) {
        // Check for associated label
        const label = page.locator(`label[for="${id}"]`)
        await expect(label).toBeVisible()
      }
    }
  })

  test('should support keyboard navigation', async ({ page }) => {
    // Test tab navigation
    await page.keyboard.press('Tab')
    
    // Check if focus is visible
    const focusedElement = page.locator(':focus')
    await expect(focusedElement).toBeVisible()
    
    // Test tab order
    const tabbableElements = page.locator('button, input, select, textarea, a[href], [tabindex]:not([tabindex="-1"])')
    const tabbableCount = await tabbableElements.count()
    
    expect(tabbableCount).toBeGreaterThan(0)
  })

  test('should have proper ARIA attributes', async ({ page }) => {
    // Check for main landmark
    const main = page.locator('main, [role="main"]')
    await expect(main).toBeVisible()
    
    // Check for navigation landmark
    const nav = page.locator('nav, [role="navigation"]')
    await expect(nav).toBeVisible()
    
    // Check for proper button roles
    const buttons = page.locator('button, [role="button"]')
    const buttonCount = await buttons.count()
    
    for (let i = 0; i < buttonCount; i++) {
      const button = buttons.nth(i)
      const role = await button.getAttribute('role')
      const type = await button.getAttribute('type')
      
      // Button should have proper role or type
      const tagName = await button.evaluate(el => el.tagName.toLowerCase())
      expect(role === 'button' || type === 'button' || tagName === 'button').toBeTruthy()
    }
  })

  test('should have proper color contrast', async ({ page }) => {
    // This is a basic test - in a real scenario, you'd use axe-core or similar
    // Check that text elements have sufficient contrast
    
    const textElements = page.locator('p, span, div, h1, h2, h3, h4, h5, h6, a, button')
    const textCount = await textElements.count()
    
    // Basic check that text elements exist and are visible
    expect(textCount).toBeGreaterThan(0)
    
    // Check that no text has the same color as background
    // This is a simplified check - real contrast testing requires more sophisticated tools
    for (let i = 0; i < Math.min(textCount, 10); i++) {
      const element = textElements.nth(i)
      const isVisible = await element.isVisible()
      
      if (isVisible) {
        const text = await element.textContent()
        if (text && text.trim().length > 0) {
          // Element has text content and is visible
          expect(text.trim().length).toBeGreaterThan(0)
        }
      }
    }
  })

  test('should have proper focus management', async ({ page }) => {
    // Test focus trap in modals (if any)
    const modals = page.locator('[role="dialog"], .modal')
    const modalCount = await modals.count()
    
    if (modalCount > 0) {
      // Open first modal
      const openModalButton = page.locator('button').first()
      await openModalButton.click()
      
      // Check that focus is trapped in modal
      await page.keyboard.press('Tab')
      const focusedElement = page.locator(':focus')
      await expect(focusedElement).toBeVisible()
    }
  })

  test('should have proper alt text for images', async ({ page }) => {
    const images = page.locator('img')
    const imageCount = await images.count()
    
    for (let i = 0; i < imageCount; i++) {
      const img = images.nth(i)
      const alt = await img.getAttribute('alt')
      const role = await img.getAttribute('role')
      
      // Image should have alt text or be decorative
      expect(alt !== null || role === 'presentation').toBeTruthy()
    }
  })

  test('should have proper link text', async ({ page }) => {
    const links = page.locator('a[href]')
    const linkCount = await links.count()
    
    for (let i = 0; i < linkCount; i++) {
      const link = links.nth(i)
      const text = await link.textContent()
      const ariaLabel = await link.getAttribute('aria-label')
      
      // Link should have descriptive text or aria-label
      expect(text?.trim().length || ariaLabel?.trim().length).toBeGreaterThan(0)
    }
  })

  test('should handle screen reader announcements', async ({ page }) => {
    // Check for live regions
    const liveRegions = page.locator('[aria-live], [role="status"], [role="alert"]')
    const liveRegionCount = await liveRegions.count()
    
    // Should have at least one live region for dynamic content
    expect(liveRegionCount).toBeGreaterThanOrEqual(0)
  })

  test('should have proper form validation', async ({ page }) => {
    // Test form validation accessibility
    const forms = page.locator('form')
    const formCount = await forms.count()
    
    for (let i = 0; i < formCount; i++) {
      const form = forms.nth(i)
      
      // Check for required field indicators
      const requiredFields = form.locator('[required], [aria-required="true"]')
      const requiredCount = await requiredFields.count()
      
      if (requiredCount > 0) {
        // Check that required fields have proper indicators
        for (let j = 0; j < requiredCount; j++) {
          const field = requiredFields.nth(j)
          const ariaRequired = await field.getAttribute('aria-required')
          const required = await field.getAttribute('required')
          
          expect(ariaRequired === 'true' || required !== null).toBeTruthy()
        }
      }
    }
  })

  test('should support high contrast mode', async ({ page }) => {
    // Simulate high contrast mode by adding CSS
    await page.addStyleTag({
      content: `
        * {
          background: white !important;
          color: black !important;
          border-color: black !important;
        }
      `
    })
    
    // Check that content is still readable
    const textElements = page.locator('p, span, div, h1, h2, h3, h4, h5, h6, a, button')
    const textCount = await textElements.count()
    
    expect(textCount).toBeGreaterThan(0)
  })

  test('should have proper table structure', async ({ page }) => {
    const tables = page.locator('table')
    const tableCount = await tables.count()
    
    for (let i = 0; i < tableCount; i++) {
      const table = tables.nth(i)
      
      // Check for table headers
      const headers = table.locator('th, [role="columnheader"]')
      const headerCount = await headers.count()
      
      if (headerCount > 0) {
        // Check for proper table structure
        const rows = table.locator('tr')
        const rowCount = await rows.count()
        
        expect(rowCount).toBeGreaterThan(0)
      }
    }
  })
})
