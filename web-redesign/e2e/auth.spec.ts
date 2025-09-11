import { test, expect } from '@playwright/test'

test.describe('Authentication Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the app
    await page.goto('/')
  })

  test('should redirect to login when not authenticated', async ({ page }) => {
    // Should be redirected to login page
    await expect(page).toHaveURL(/.*login/)
    await expect(page.locator('h1')).toContainText('Login')
  })

  test('should show login form', async ({ page }) => {
    await expect(page.locator('input[name="username"]')).toBeVisible()
    await expect(page.locator('input[name="password"]')).toBeVisible()
    await expect(page.locator('button[type="submit"]')).toBeVisible()
  })

  test('should handle invalid login credentials', async ({ page }) => {
    await page.fill('input[name="username"]', 'invaliduser')
    await page.fill('input[name="password"]', 'wrongpassword')
    await page.click('button[type="submit"]')

    // Should show error message
    await expect(page.locator('.error, .alert-error, [role="alert"]')).toBeVisible()
  })

  test('should login with valid credentials', async ({ page }) => {
    // Mock successful login
    await page.route('**/auth/login/', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          access: 'mock-access-token',
          refresh: 'mock-refresh-token',
          user: {
            id: 1,
            username: 'testuser',
            email: 'test@example.com',
            first_name: 'Test',
            last_name: 'User'
          }
        })
      })
    })

    await page.fill('input[name="username"]', 'testuser')
    await page.fill('input[name="password"]', 'password123')
    await page.click('button[type="submit"]')

    // Should redirect to dashboard
    await expect(page).toHaveURL('/')
    await expect(page.locator('text=Dashboard')).toBeVisible()
  })

  test('should logout user', async ({ page }) => {
    // First login
    await page.route('**/auth/login/', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          access: 'mock-access-token',
          refresh: 'mock-refresh-token',
          user: {
            id: 1,
            username: 'testuser',
            email: 'test@example.com',
            first_name: 'Test',
            last_name: 'User'
          }
        })
      })
    })

    await page.fill('input[name="username"]', 'testuser')
    await page.fill('input[name="password"]', 'password123')
    await page.click('button[type="submit"]')

    await expect(page).toHaveURL('/')

    // Click logout
    await page.click('[data-testid="user-menu"]')
    await page.click('text=Logout')

    // Should redirect to login
    await expect(page).toHaveURL(/.*login/)
  })
})
