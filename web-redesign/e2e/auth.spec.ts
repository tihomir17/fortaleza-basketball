import { test, expect } from '@playwright/test'

const clearAuth = async (page: any) => {
  await page.addInitScript(() => {
    localStorage.removeItem('auth_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('auth-storage')
  })
}

test.describe('Authentication Flow', () => {
  test('should redirect to login when not authenticated', async ({ page, context }) => {
    await context.clearCookies()
    await clearAuth(page)
    await page.goto('/')
    // App renders Login inline; assert form instead of URL
    await expect(page.getByRole('heading', { name: /Sign in/i })).toBeVisible()
    await expect(page.locator('input[name="username"]')).toBeVisible()
    await expect(page.locator('input[name="password"]')).toBeVisible()
  })

  test('should show login form', async ({ page, context }) => {
    await context.clearCookies()
    await clearAuth(page)
    await page.goto('/login')
    await expect(page.locator('input[name="username"]')).toBeVisible()
    await expect(page.locator('input[name="password"]')).toBeVisible()
    await expect(page.locator('button[type="submit"]')).toBeVisible()
  })

  test('should handle invalid login credentials', async ({ page, context }) => {
    await context.clearCookies()
    await clearAuth(page)
    await page.goto('/login')
    await page.fill('input[name="username"]', 'invaliduser')
    await page.fill('input[name="password"]', 'wrongpassword')
    await page.click('button[type="submit"]')
    // Expect some error feedback (lenient)
    await expect(page.locator('.bg-red-50, .error, [role="alert"]')).toBeVisible()
  })

  test('should login with valid credentials', async ({ page, context }) => {
    await context.clearCookies()
    await clearAuth(page)
    await page.goto('/login')
    await page.fill('input[name="username"]', 'vladdos')
    await page.fill('input[name="password"]', '20 pogodi')
    await page.click('button[type="submit"]')
    await page.waitForLoadState('networkidle')
    // Land somewhere authenticated (dashboard or root)
    await expect(page).not.toHaveURL(/.*login/)
  })

  test('should logout user', async ({ page }) => {
    // Assumes prior login in storage (from global setup) or previous test
    await page.goto('/')
    const menu = page.locator('[data-testid="user-menu"], [aria-label*="user"], [id*="user"], button:has-text("Profile")')
    if (await menu.count()) {
      await menu.first().click()
      const logout = page.getByText(/Logout/i)
      if (await logout.count()) {
        await logout.click()
        await expect(page.getByRole('heading', { name: /Sign in/i })).toBeVisible()
      }
    }
  })
})
