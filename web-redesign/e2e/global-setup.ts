import { chromium, FullConfig } from '@playwright/test'

async function globalSetup(config: FullConfig) {
  console.log('🚀 Setting up global test environment...')
  
  // Start backend server if needed
  const browser = await chromium.launch()
  const page = await browser.newPage()
  
  try {
    // Test backend connectivity
    await page.goto('http://localhost:8000/api/health/', { timeout: 10000 })
    console.log('✅ Backend server is running')
  } catch (error) {
    console.log('⚠️ Backend server not accessible, tests will use mocked data')
  }
  
  await browser.close()
  console.log('✅ Global setup completed')
}

export default globalSetup
