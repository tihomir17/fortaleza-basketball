import { test, expect } from '@playwright/test'

test.describe('Application Navigation', () => {
  test('should load the application and show login page', async ({ page }) => {
    await page.goto('/')
    
    // Should show login form
    await expect(page.getByText('Login')).toBeVisible()
    await expect(page.getByLabel('Email')).toBeVisible()
    await expect(page.getByLabel('Password')).toBeVisible()
    await expect(page.getByRole('button', { name: 'Login' })).toBeVisible()
  })

  test('should navigate to dashboard after successful login', async ({ page }) => {
    await page.goto('/')
    
    // Mock successful login
    await page.route('**/api/auth/login', async route => {
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
          },
          token: 'mock-jwt-token'
        })
      })
    })

    // Fill login form
    await page.getByLabel('Email').fill('test@example.com')
    await page.getByLabel('Password').fill('password123')
    
    // Submit form
    await page.getByRole('button', { name: 'Login' }).click()
    
    // Should navigate to dashboard
    await expect(page.getByText('Dashboard')).toBeVisible()
    await expect(page.getByText('Welcome, Test User')).toBeVisible()
  })

  test('should show error message for invalid login', async ({ page }) => {
    await page.goto('/')
    
    // Mock failed login
    await page.route('**/api/auth/login', async route => {
      await route.fulfill({
        status: 401,
        contentType: 'application/json',
        body: JSON.stringify({
          message: 'Invalid credentials'
        })
      })
    })

    // Fill login form with invalid credentials
    await page.getByLabel('Email').fill('invalid@example.com')
    await page.getByLabel('Password').fill('wrongpassword')
    
    // Submit form
    await page.getByRole('button', { name: 'Login' }).click()
    
    // Should show error message
    await expect(page.getByText('Invalid credentials')).toBeVisible()
    
    // Should still be on login page
    await expect(page.getByText('Login')).toBeVisible()
  })

  test('should navigate between different pages', async ({ page }) => {
    await page.goto('/')
    
    // Mock successful login
    await page.route('**/api/auth/login', async route => {
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
          },
          token: 'mock-jwt-token'
        })
      })
    })

    // Login first
    await page.getByLabel('Email').fill('test@example.com')
    await page.getByLabel('Password').fill('password123')
    await page.getByRole('button', { name: 'Login' }).click()
    
    // Wait for dashboard to load
    await expect(page.getByText('Dashboard')).toBeVisible()
    
    // Navigate to Games page
    await page.getByRole('link', { name: 'Games' }).click()
    await expect(page.getByText('Games')).toBeVisible()
    
    // Navigate to Teams page
    await page.getByRole('link', { name: 'Teams' }).click()
    await expect(page.getByText('Teams')).toBeVisible()
    
    // Navigate to Analytics page
    await page.getByRole('link', { name: 'Analytics' }).click()
    await expect(page.getByText('Analytics')).toBeVisible()
    
    // Navigate back to Dashboard
    await page.getByRole('link', { name: 'Dashboard' }).click()
    await expect(page.getByText('Dashboard')).toBeVisible()
  })

  test('should be responsive on mobile devices', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 })
    await page.goto('/')
    
    // Should show mobile-friendly login form
    await expect(page.getByText('Login')).toBeVisible()
    await expect(page.getByLabel('Email')).toBeVisible()
    await expect(page.getByLabel('Password')).toBeVisible()
    
    // Check if mobile menu is available (if implemented)
    const mobileMenuButton = page.getByRole('button', { name: /menu/i })
    if (await mobileMenuButton.isVisible()) {
      await mobileMenuButton.click()
      await expect(page.getByRole('navigation')).toBeVisible()
    }
  })

  test('should support keyboard navigation', async ({ page }) => {
    await page.goto('/')
    
    // Tab through form elements
    await page.keyboard.press('Tab')
    await expect(page.getByLabel('Email')).toBeFocused()
    
    await page.keyboard.press('Tab')
    await expect(page.getByLabel('Password')).toBeFocused()
    
    await page.keyboard.press('Tab')
    await expect(page.getByRole('button', { name: 'Login' })).toBeFocused()
    
    // Fill form using keyboard
    await page.keyboard.type('test@example.com')
    await page.keyboard.press('Tab')
    await page.keyboard.type('password123')
    
    // Submit using Enter key
    await page.keyboard.press('Enter')
    
    // Should attempt to submit (will fail without proper mocking, but we can check the attempt)
    await expect(page.getByLabel('Email')).toHaveValue('test@example.com')
    await expect(page.getByLabel('Password')).toHaveValue('password123')
  })
})
