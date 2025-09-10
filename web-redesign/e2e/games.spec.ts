import { test, expect } from '@playwright/test'

test.describe('Games Management', () => {
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

    // Mock games API
    await page.route('**/api/games', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([
          {
            id: '1',
            home_team_name: 'Fortaleza',
            away_team_name: 'Lakers',
            date: '2024-01-15T19:00:00Z',
            location: 'Home Arena',
            status: 'SCHEDULED',
            home_score: 0,
            away_score: 0
          },
          {
            id: '2',
            home_team_name: 'Warriors',
            away_team_name: 'Celtics',
            date: '2024-01-20T19:00:00Z',
            location: 'Away Arena',
            status: 'SCHEDULED',
            home_score: 0,
            away_score: 0
          }
        ])
      })
    })

    // Navigate to games page
    await page.goto('/games')
  })

  test('should display games list', async ({ page }) => {
    // Should show games list
    await expect(page.getByText('Games')).toBeVisible()
    await expect(page.getByText('Fortaleza vs Lakers')).toBeVisible()
    await expect(page.getByText('Warriors vs Celtics')).toBeVisible()
    
    // Should show game details
    await expect(page.getByText('Home Arena')).toBeVisible()
    await expect(page.getByText('Away Arena')).toBeVisible()
  })

  test('should allow creating a new game', async ({ page }) => {
    // Mock create game API
    await page.route('**/api/games', async route => {
      if (route.request().method() === 'POST') {
        await route.fulfill({
          status: 201,
          contentType: 'application/json',
          body: JSON.stringify({
            id: '3',
            home_team_name: 'Fortaleza',
            away_team_name: 'Bulls',
            date: '2024-01-25T19:00:00Z',
            location: 'Home Arena',
            status: 'SCHEDULED',
            home_score: 0,
            away_score: 0
          })
        })
      } else {
        // Return existing games for GET requests
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([
            {
              id: '1',
              home_team_name: 'Fortaleza',
              away_team_name: 'Lakers',
              date: '2024-01-15T19:00:00Z',
              location: 'Home Arena',
              status: 'SCHEDULED',
              home_score: 0,
              away_score: 0
            },
            {
              id: '3',
              home_team_name: 'Fortaleza',
              away_team_name: 'Bulls',
              date: '2024-01-25T19:00:00Z',
              location: 'Home Arena',
              status: 'SCHEDULED',
              home_score: 0,
              away_score: 0
            }
          ])
        })
      }
    })

    // Click add game button
    await page.getByRole('button', { name: 'Add Game' }).click()
    
    // Should show create game modal
    await expect(page.getByText('Create New Game')).toBeVisible()
    
    // Fill form
    await page.getByLabel('Home Team').fill('Fortaleza')
    await page.getByLabel('Away Team').fill('Bulls')
    await page.getByLabel('Date').fill('2024-01-25T19:00')
    await page.getByLabel('Location').fill('Home Arena')
    
    // Submit form
    await page.getByRole('button', { name: 'Create' }).click()
    
    // Should show new game in list
    await expect(page.getByText('Fortaleza vs Bulls')).toBeVisible()
  })

  test('should allow editing a game', async ({ page }) => {
    // Mock update game API
    await page.route('**/api/games/1', async route => {
      if (route.request().method() === 'PUT') {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            id: '1',
            home_team_name: 'Fortaleza Updated',
            away_team_name: 'Lakers',
            date: '2024-01-15T19:00:00Z',
            location: 'Home Arena',
            status: 'SCHEDULED',
            home_score: 0,
            away_score: 0
          })
        })
      }
    })

    // Click edit button for first game
    await page.getByRole('button', { name: 'Edit' }).first().click()
    
    // Should show edit modal
    await expect(page.getByText('Edit Game')).toBeVisible()
    
    // Form should be pre-filled
    await expect(page.getByLabel('Home Team')).toHaveValue('Fortaleza')
    
    // Update the game
    await page.getByLabel('Home Team').fill('Fortaleza Updated')
    
    // Submit changes
    await page.getByRole('button', { name: 'Save' }).click()
    
    // Should show updated game name
    await expect(page.getByText('Fortaleza Updated vs Lakers')).toBeVisible()
  })

  test('should allow deleting a game', async ({ page }) => {
    // Mock delete game API
    await page.route('**/api/games/1', async route => {
      if (route.request().method() === 'DELETE') {
        await route.fulfill({
          status: 204
        })
      }
    })

    // Click delete button for first game
    await page.getByRole('button', { name: 'Delete' }).first().click()
    
    // Should show confirmation dialog
    await expect(page.getByText('Are you sure you want to delete this game?')).toBeVisible()
    
    // Confirm deletion
    await page.getByRole('button', { name: 'Yes, Delete' }).click()
    
    // Should remove game from list
    await expect(page.getByText('Fortaleza vs Lakers')).not.toBeVisible()
  })

  test('should filter games by search term', async ({ page }) => {
    // Search for "Fortaleza"
    await page.getByPlaceholder('Search games...').fill('Fortaleza')
    
    // Should show only Fortaleza games
    await expect(page.getByText('Fortaleza vs Lakers')).toBeVisible()
    await expect(page.getByText('Warriors vs Celtics')).not.toBeVisible()
    
    // Clear search
    await page.getByPlaceholder('Search games...').fill('')
    
    // Should show all games again
    await expect(page.getByText('Fortaleza vs Lakers')).toBeVisible()
    await expect(page.getByText('Warriors vs Celtics')).toBeVisible()
  })

  test('should export games data', async ({ page }) => {
    // Click export button
    await page.getByRole('button', { name: 'Export' }).click()
    
    // Should show export options
    await expect(page.getByText('Export to Excel')).toBeVisible()
    await expect(page.getByText('Export to CSV')).toBeVisible()
    await expect(page.getByText('Export to PDF')).toBeVisible()
    
    // Click Excel export
    await page.getByText('Export to Excel').click()
    
    // Should trigger download (we can't easily test the actual download in e2e)
    // But we can verify the export modal closes
    await expect(page.getByText('Export to Excel')).not.toBeVisible()
  })

  test('should handle pagination', async ({ page }) => {
    // Mock games with pagination
    await page.route('**/api/games**', async route => {
      const url = new URL(route.request().url())
      const pageParam = url.searchParams.get('page') || '1'
      
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          data: [
            {
              id: pageParam === '1' ? '1' : '2',
              home_team_name: pageParam === '1' ? 'Fortaleza' : 'Warriors',
              away_team_name: pageParam === '1' ? 'Lakers' : 'Celtics',
              date: '2024-01-15T19:00:00Z',
              location: 'Home Arena',
              status: 'SCHEDULED',
              home_score: 0,
              away_score: 0
            }
          ],
          pagination: {
            page: parseInt(pageParam),
            totalPages: 2,
            totalItems: 2,
            hasNext: pageParam === '1',
            hasPrev: pageParam === '2'
          }
        })
      })
    })

    // Should show pagination controls
    await expect(page.getByRole('button', { name: 'Next' })).toBeVisible()
    
    // Click next page
    await page.getByRole('button', { name: 'Next' }).click()
    
    // Should show different games
    await expect(page.getByText('Warriors vs Celtics')).toBeVisible()
    
    // Should show previous button
    await expect(page.getByRole('button', { name: 'Previous' })).toBeVisible()
  })
})
