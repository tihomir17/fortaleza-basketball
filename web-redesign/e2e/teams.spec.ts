import { test, expect } from '@playwright/test'

test.describe('Team Management', () => {
  test.beforeEach(async ({ page }) => {
    // Mock authentication
    await page.addInitScript(() => {
      localStorage.setItem('auth_token', 'mock-token')
    })

    // Mock API responses
    await page.route('**/api/teams/', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          results: [
            {
              id: 1,
              name: 'Test Team 1',
              description: 'A test team',
              competition: 1,
              coaches: [
                {
                  id: 1,
                  username: 'coach1',
                  email: 'coach1@example.com',
                  first_name: 'Coach',
                  last_name: 'One'
                }
              ],
              players: [
                {
                  id: 2,
                  username: 'player1',
                  email: 'player1@example.com',
                  first_name: 'Player',
                  last_name: 'One'
                },
                {
                  id: 3,
                  username: 'player2',
                  email: 'player2@example.com',
                  first_name: 'Player',
                  last_name: 'Two'
                }
              ],
              created_at: '2024-01-01T00:00:00Z',
              updated_at: '2024-01-01T00:00:00Z'
            },
            {
              id: 2,
              name: 'Test Team 2',
              description: 'Another test team',
              competition: 2,
              coaches: [],
              players: [],
              created_at: '2024-01-02T00:00:00Z',
              updated_at: '2024-01-02T00:00:00Z'
            }
          ],
          count: 2,
          next: null,
          previous: null
        })
      })
    })

    await page.route('**/api/competitions/', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          results: [
            { id: 1, name: 'Competition 1' },
            { id: 2, name: 'Competition 2' }
          ]
        })
      })
    })

    await page.goto('/teams')
  })

  test('should display teams list', async ({ page }) => {
    await expect(page.locator('text=Test Team 1')).toBeVisible()
    await expect(page.locator('text=Test Team 2')).toBeVisible()
    await expect(page.locator('text=A test team')).toBeVisible()
    await expect(page.locator('text=Another test team')).toBeVisible()
  })

  test('should show team members', async ({ page }) => {
    await expect(page.locator('text=Coach One')).toBeVisible()
    await expect(page.locator('text=Player One')).toBeVisible()
    await expect(page.locator('text=Player Two')).toBeVisible()
  })

  test('should filter teams by search term', async ({ page }) => {
    const searchInput = page.locator('input[placeholder="Search teams..."]')
    await searchInput.fill('Test Team 1')

    await expect(page.locator('text=Test Team 1')).toBeVisible()
    await expect(page.locator('text=Test Team 2')).not.toBeVisible()
  })

  test('should open create team modal', async ({ page }) => {
    const createButton = page.locator('text=Create Team')
    await createButton.click()

    await expect(page.locator('text=Create New Team')).toBeVisible()
    await expect(page.locator('input[name="name"]')).toBeVisible()
    await expect(page.locator('textarea[name="description"]')).toBeVisible()
    await expect(page.locator('select[name="competition"]')).toBeVisible()
  })

  test('should create new team', async ({ page }) => {
    // Mock create API
    await page.route('**/api/teams/', async route => {
      if (route.request().method() === 'POST') {
        await route.fulfill({
          status: 201,
          contentType: 'application/json',
          body: JSON.stringify({
            id: 3,
            name: 'New Team',
            description: 'A new team',
            competition: 1,
            coaches: [],
            players: [],
            created_at: '2024-01-03T00:00:00Z',
            updated_at: '2024-01-03T00:00:00Z'
          })
        })
      } else {
        await route.continue()
      }
    })

    const createButton = page.locator('text=Create Team')
    await createButton.click()

    await page.fill('input[name="name"]', 'New Team')
    await page.fill('textarea[name="description"]', 'A new team')
    await page.selectOption('select[name="competition"]', '1')
    await page.click('button[type="submit"]')

    await expect(page.locator('text=New Team')).toBeVisible()
  })

  test('should open edit team modal', async ({ page }) => {
    const editButton = page.locator('[aria-label*="edit team"]').first()
    await editButton.click()

    await expect(page.locator('text=Edit Team')).toBeVisible()
    await expect(page.locator('input[name="name"]')).toHaveValue('Test Team 1')
    await expect(page.locator('textarea[name="description"]')).toHaveValue('A test team')
  })

  test('should update team', async ({ page }) => {
    // Mock update API
    await page.route('**/api/teams/1/', async route => {
      if (route.request().method() === 'PATCH') {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            id: 1,
            name: 'Updated Team',
            description: 'An updated team',
            competition: 1,
            coaches: [
              {
                id: 1,
                username: 'coach1',
                email: 'coach1@example.com',
                first_name: 'Coach',
                last_name: 'One'
              }
            ],
            players: [
              {
                id: 2,
                username: 'player1',
                email: 'player1@example.com',
                first_name: 'Player',
                last_name: 'One'
              },
              {
                id: 3,
                username: 'player2',
                email: 'player2@example.com',
                first_name: 'Player',
                last_name: 'Two'
              }
            ],
            created_at: '2024-01-01T00:00:00Z',
            updated_at: '2024-01-01T00:00:00Z'
          })
        })
      } else {
        await route.continue()
      }
    })

    const editButton = page.locator('[aria-label*="edit team"]').first()
    await editButton.click()

    await page.fill('input[name="name"]', 'Updated Team')
    await page.fill('textarea[name="description"]', 'An updated team')
    await page.click('button[type="submit"]')

    await expect(page.locator('text=Updated Team')).toBeVisible()
    await expect(page.locator('text=An updated team')).toBeVisible()
  })

  test('should delete team with confirmation', async ({ page }) => {
    // Mock delete API
    await page.route('**/api/teams/1/', async route => {
      if (route.request().method() === 'DELETE') {
        await route.fulfill({
          status: 204
        })
      } else {
        await route.continue()
      }
    })

    const deleteButton = page.locator('[aria-label*="delete team"]').first()
    await deleteButton.click()

    // Should show confirmation dialog
    await expect(page.locator('text=Delete Team')).toBeVisible()
    await expect(page.locator('text=Are you sure you want to delete "Test Team 1"?')).toBeVisible()

    // Confirm deletion
    await page.click('button:has-text("Delete")')

    // Team should be removed from the list
    await expect(page.locator('text=Test Team 1')).not.toBeVisible()
  })

  test('should show empty state when no teams', async ({ page }) => {
    // Mock empty API response
    await page.route('**/api/teams/', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          results: [],
          count: 0,
          next: null,
          previous: null
        })
      })
    })

    await page.reload()

    await expect(page.locator('text=No teams found')).toBeVisible()
    await expect(page.locator('text=Create your first team to get started')).toBeVisible()
  })

  test('should handle API errors gracefully', async ({ page }) => {
    // Mock API error
    await page.route('**/api/teams/', async route => {
      await route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({
          error: 'Internal server error'
        })
      })
    })

    await page.reload()

    // Should show error message
    await expect(page.locator('.error, .alert-error, [role="alert"]')).toBeVisible()
  })

  test('should validate form fields', async ({ page }) => {
    const createButton = page.locator('text=Create Team')
    await createButton.click()

    // Try to submit without filling required fields
    await page.click('button[type="submit"]')

    // Should show validation errors
    await expect(page.locator('.error, .invalid, [aria-invalid="true"]')).toBeVisible()
  })
})
