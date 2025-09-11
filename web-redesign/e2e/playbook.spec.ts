import { test, expect } from '@playwright/test'

test.describe('Playbook Management', () => {
  test.beforeEach(async ({ page }) => {
    // Mock authentication
    await page.addInitScript(() => {
      localStorage.setItem('auth_token', 'mock-token')
    })

    // Mock API responses
    await page.route('**/api/plays/', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          results: [
            {
              id: 1,
              name: 'Test Play 1',
              description: 'A test play',
              play_type: 'OFFENSIVE',
              team: 1,
              category: { id: 1, name: 'Offense' },
              subcategory: 'Fast Break',
              action_type: 'NORMAL',
              diagram_url: '',
              video_url: '',
              tags: ['test', 'offense'],
              difficulty: 'Beginner',
              duration: 12,
              players: 5,
              success_rate: 75.5,
              last_used: '2024-01-01',
              is_favorite: false,
              created_by: 1,
              created_by_name: 'Test User',
              steps: []
            },
            {
              id: 2,
              name: 'Test Play 2',
              description: 'Another test play',
              play_type: 'DEFENSIVE',
              team: 1,
              category: { id: 2, name: 'Defense' },
              subcategory: 'Zone',
              action_type: 'NORMAL',
              diagram_url: '',
              video_url: '',
              tags: ['test', 'defense'],
              difficulty: 'Intermediate',
              duration: 15,
              players: 5,
              success_rate: 60.0,
              last_used: '2024-01-02',
              is_favorite: true,
              created_by: 1,
              created_by_name: 'Test User',
              steps: []
            }
          ],
          count: 2,
          next: null,
          previous: null
        })
      })
    })

    await page.goto('/playbook')
  })

  test('should display playbook with plays', async ({ page }) => {
    await expect(page.locator('text=Test Play 1')).toBeVisible()
    await expect(page.locator('text=Test Play 2')).toBeVisible()
    await expect(page.locator('text=A test play')).toBeVisible()
    await expect(page.locator('text=Another test play')).toBeVisible()
  })

  test('should filter plays by search term', async ({ page }) => {
    const searchInput = page.locator('input[placeholder="Search plays..."]')
    await searchInput.fill('Test Play 1')

    await expect(page.locator('text=Test Play 1')).toBeVisible()
    await expect(page.locator('text=Test Play 2')).not.toBeVisible()
  })

  test('should filter plays by difficulty', async ({ page }) => {
    const difficultyFilter = page.locator('select').first()
    await difficultyFilter.selectOption('Beginner')

    await expect(page.locator('text=Test Play 1')).toBeVisible()
    await expect(page.locator('text=Test Play 2')).not.toBeVisible()
  })

  test('should toggle favorites filter', async ({ page }) => {
    const favoritesToggle = page.locator('text=Favorites Only')
    await favoritesToggle.click()

    await expect(page.locator('text=Test Play 1')).not.toBeVisible()
    await expect(page.locator('text=Test Play 2')).toBeVisible()
  })

  test('should open edit modal when edit button is clicked', async ({ page }) => {
    // Mock update API
    await page.route('**/api/plays/1/', async route => {
      if (route.request().method() === 'PATCH') {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            id: 1,
            name: 'Updated Play',
            description: 'Updated description',
            play_type: 'OFFENSIVE',
            team: 1,
            category: { id: 1, name: 'Offense' },
            subcategory: 'Fast Break',
            action_type: 'NORMAL',
            diagram_url: '',
            video_url: '',
            tags: ['test', 'offense'],
            difficulty: 'Beginner',
            duration: 12,
            players: 5,
            success_rate: 75.5,
            last_used: '2024-01-01',
            is_favorite: false,
            created_by: 1,
            created_by_name: 'Test User',
            steps: []
          })
        })
      } else {
        await route.continue()
      }
    })

    const editButton = page.locator('[aria-label*="edit"]').first()
    await editButton.click()

    await expect(page.locator('text=Edit Play: Test Play 1')).toBeVisible()
    await expect(page.locator('input[name="name"]')).toHaveValue('Test Play 1')
    await expect(page.locator('textarea[name="description"]')).toHaveValue('A test play')
  })

  test('should update play when form is submitted', async ({ page }) => {
    // Mock update API
    await page.route('**/api/plays/1/', async route => {
      if (route.request().method() === 'PATCH') {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            id: 1,
            name: 'Updated Play',
            description: 'Updated description',
            play_type: 'OFFENSIVE',
            team: 1,
            category: { id: 1, name: 'Offense' },
            subcategory: 'Fast Break',
            action_type: 'NORMAL',
            diagram_url: '',
            video_url: '',
            tags: ['test', 'offense'],
            difficulty: 'Beginner',
            duration: 12,
            players: 5,
            success_rate: 75.5,
            last_used: '2024-01-01',
            is_favorite: false,
            created_by: 1,
            created_by_name: 'Test User',
            steps: []
          })
        })
      } else {
        await route.continue()
      }
    })

    const editButton = page.locator('[aria-label*="edit"]').first()
    await editButton.click()

    await page.fill('input[name="name"]', 'Updated Play')
    await page.fill('textarea[name="description"]', 'Updated description')
    await page.click('button[type="submit"]')

    await expect(page.locator('text=Updated Play')).toBeVisible()
    await expect(page.locator('text=Updated description')).toBeVisible()
  })

  test('should toggle favorite status', async ({ page }) => {
    // Mock favorite toggle API
    await page.route('**/api/plays/1/favorite/', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 1,
          name: 'Test Play 1',
          description: 'A test play',
          play_type: 'OFFENSIVE',
          team: 1,
          category: { id: 1, name: 'Offense' },
          subcategory: 'Fast Break',
          action_type: 'NORMAL',
          diagram_url: '',
          video_url: '',
          tags: ['test', 'offense'],
          difficulty: 'Beginner',
          duration: 12,
          players: 5,
          success_rate: 75.5,
          last_used: '2024-01-01',
          is_favorite: true, // Toggled to true
          created_by: 1,
          created_by_name: 'Test User',
          steps: []
        })
      })
    })

    const favoriteButton = page.locator('[aria-label*="favorite"]').first()
    await favoriteButton.click()

    // Should show success message or visual feedback
    await expect(page.locator('.success, .alert-success, [role="alert"]')).toBeVisible()
  })

  test('should delete play with confirmation', async ({ page }) => {
    // Mock delete API
    await page.route('**/api/plays/1/', async route => {
      if (route.request().method() === 'DELETE') {
        await route.fulfill({
          status: 204
        })
      } else {
        await route.continue()
      }
    })

    const deleteButton = page.locator('[aria-label*="delete"]').first()
    await deleteButton.click()

    // Should show confirmation dialog
    await expect(page.locator('text=Delete Play')).toBeVisible()
    await expect(page.locator('text=Are you sure')).toBeVisible()

    // Confirm deletion
    await page.click('button:has-text("Delete")')

    // Play should be removed from the list
    await expect(page.locator('text=Test Play 1')).not.toBeVisible()
  })

  test('should duplicate play', async ({ page }) => {
    // Mock duplicate API
    await page.route('**/api/plays/1/duplicate/', async route => {
      await route.fulfill({
        status: 201,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 3,
          name: 'Test Play 1 (Copy)',
          description: 'A test play',
          play_type: 'OFFENSIVE',
          team: 1,
          category: { id: 1, name: 'Offense' },
          subcategory: 'Fast Break',
          action_type: 'NORMAL',
          diagram_url: '',
          video_url: '',
          tags: ['test', 'offense'],
          difficulty: 'Beginner',
          duration: 12,
          players: 5,
          success_rate: 75.5,
          last_used: '2024-01-01',
          is_favorite: false,
          created_by: 1,
          created_by_name: 'Test User',
          steps: []
        })
      })
    })

    const duplicateButton = page.locator('[aria-label*="duplicate"]').first()
    await duplicateButton.click()

    // Should show success message
    await expect(page.locator('.success, .alert-success, [role="alert"]')).toBeVisible()
  })

  test('should handle API errors gracefully', async ({ page }) => {
    // Mock API error
    await page.route('**/api/plays/', async route => {
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
})
