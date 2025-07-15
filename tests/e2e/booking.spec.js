import { test, expect } from '@playwright/test';

test.describe('Booking System', () => {
  test.beforeEach(async ({ page }) => {
    // Login as demo user
    await page.goto('/');
    await page.click('text=一般ユーザーでログイン');
    await page.waitForTimeout(2000);
    
    // Navigate to booking tab
    await page.click('text=予約');
  });

  test('should display class schedule', async ({ page }) => {
    // Check schedule display
    await expect(page.locator('text=今週のクラススケジュール')).toBeVisible();
    
    // Should show at least one schedule item
    await expect(page.locator('[data-testid="schedule-item"]').first()).toBeVisible();
  });

  test('should filter schedules by dojo', async ({ page }) => {
    // Open dojo filter
    await page.click('text=全ての道場');
    
    // Select specific dojo
    await page.click('text=YAWARA (原宿)');
    
    // Wait for filter to apply
    await page.waitForTimeout(500);
    
    // Check filtered results
    const schedules = await page.locator('[data-testid="schedule-item"]').count();
    expect(schedules).toBeGreaterThan(0);
  });

  test('should enable multiple selection mode', async ({ page }) => {
    // Click multiple selection button
    await page.click('[aria-label="複数選択"]');
    
    // Should show checkboxes
    await expect(page.locator('input[type="checkbox"]').first()).toBeVisible();
    
    // Select multiple schedules
    await page.locator('input[type="checkbox"]').nth(0).check();
    await page.locator('input[type="checkbox"]').nth(1).check();
    
    // Should show selection count
    await expect(page.locator('text=/2件選択/')).toBeVisible();
    
    // Should enable batch booking button
    await expect(page.locator('text=まとめて予約')).toBeEnabled();
  });

  test('should book a single class', async ({ page }) => {
    // Mock successful booking API
    await page.route('**/api/bookings', route => {
      if (route.request().method() === 'POST') {
        route.fulfill({
          status: 201,
          contentType: 'application/json',
          body: JSON.stringify({
            success: true,
            booking: { id: 1, status: 'confirmed' }
          })
        });
      }
    });
    
    // Click book button on first available class
    await page.locator('button:has-text("予約する")').first().click();
    
    // Should show confirmation dialog
    await page.click('text=確認');
    
    // Should show success message
    await expect(page.locator('text=/予約が完了しました/')).toBeVisible();
  });

  test('should handle booking conflicts', async ({ page }) => {
    // Mock booking conflict
    await page.route('**/api/bookings', route => {
      if (route.request().method() === 'POST') {
        route.fulfill({
          status: 409,
          contentType: 'application/json',
          body: JSON.stringify({
            error: 'Booking conflict',
            message: 'この時間帯は既に予約されています'
          })
        });
      }
    });
    
    // Try to book
    await page.locator('button:has-text("予約する")').first().click();
    await page.click('text=確認');
    
    // Should show error message
    await expect(page.locator('text=/この時間帯は既に予約されています/')).toBeVisible();
  });

  test('should search for specific instructor', async ({ page }) => {
    // Click search button
    await page.click('[aria-label="Search"]');
    
    // Enter instructor name
    await page.fill('input[placeholder="インストラクター名を検索"]', '村田');
    
    // Apply search
    await page.click('text=検索');
    
    // Should show filtered results
    await expect(page.locator('text=/村田/')).toBeVisible();
  });
});

test.describe('Admin Booking Features', () => {
  test.beforeEach(async ({ page }) => {
    // Login as admin
    await page.goto('/');
    await page.click('text=管理者でログイン');
    await page.waitForTimeout(2000);
    
    // Navigate to booking tab
    await page.click('text=予約');
  });

  test('should show admin-only features', async ({ page }) => {
    // Should show add schedule button
    await expect(page.locator('[aria-label="Add schedule"]')).toBeVisible();
  });

  test('should add new class schedule', async ({ page }) => {
    // Mock successful schedule creation
    await page.route('**/api/schedules', route => {
      if (route.request().method() === 'POST') {
        route.fulfill({
          status: 201,
          contentType: 'application/json',
          body: JSON.stringify({
            success: true,
            schedule: { id: 100, className: 'テストクラス' }
          })
        });
      }
    });
    
    // Click add schedule button
    await page.click('[aria-label="Add schedule"]');
    
    // Fill form
    await page.selectOption('select[name="dojo"]', { label: 'YAWARA (原宿)' });
    await page.fill('input[name="className"]', 'テストクラス');
    await page.selectOption('select[name="dayOfWeek"]', { label: '月曜日' });
    await page.fill('input[name="startTime"]', '19:00');
    await page.fill('input[name="endTime"]', '20:30');
    await page.selectOption('select[name="level"]', { label: '初級' });
    await page.fill('input[name="instructor"]', 'テストインストラクター');
    await page.fill('input[name="capacity"]', '20');
    
    // Submit
    await page.click('button:has-text("作成")');
    
    // Should show success message
    await expect(page.locator('text=/スケジュールを作成しました/')).toBeVisible();
  });
});