import { chromium, FullConfig } from '@playwright/test'
import path from 'path'
import { fileURLToPath } from 'url'

async function globalSetup(config: FullConfig) {
  console.log('🚀 Setting up global test environment...')
  const baseURL = (config.projects?.[0]?.use as any)?.baseURL || 'http://localhost:5173'
  const __filename = fileURLToPath(import.meta.url)
  const __dirname = path.dirname(__filename)
  const storagePath = path.resolve(__dirname, './.auth.json')

  const browser = await chromium.launch()
  const context = await browser.newContext()
  const page = await context.newPage()

  try {
    // Go to login and perform real authentication
    await page.goto(`${baseURL}/login`, { waitUntil: 'domcontentloaded' })
    await page.fill('input[name="username"]', 'vladdos')
    await page.fill('input[name="password"]', '20 pogodi')
    await page.click('button[type="submit"]')

    // Wait for post-login landing page
    await page.waitForLoadState('networkidle', { timeout: 20000 })

    // Persist authenticated storage state
    await context.storageState({ path: storagePath })
    console.log('✅ Auth storage state saved:', storagePath)
  } catch (error) {
    console.error('❌ Failed to complete real login in global setup:', error)
    throw error
  } finally {
    await browser.close()
  }

  console.log('✅ Global setup completed')
}

export default globalSetup
