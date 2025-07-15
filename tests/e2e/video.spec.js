import { test, expect } from '@playwright/test';

test.describe('Video Library', () => {
  test.beforeEach(async ({ page }) => {
    // Login as demo user
    await page.goto('/');
    await page.click('text=一般ユーザーでログイン');
    await page.waitForTimeout(2000);
    
    // Navigate to video tab
    await page.click('text=動画');
  });

  test('should display video library', async ({ page }) => {
    // Check video library display
    await expect(page.locator('text=動画ライブラリ')).toBeVisible();
    
    // Should show video cards
    await expect(page.locator('[data-testid="video-card"]').first()).toBeVisible();
  });

  test('should search videos', async ({ page }) => {
    // Type in search box
    await page.fill('input[placeholder="動画を検索..."]', 'ガード');
    
    // Wait for search results
    await page.waitForTimeout(500);
    
    // Should show filtered results
    const videos = await page.locator('[data-testid="video-card"]').count();
    expect(videos).toBeGreaterThanOrEqual(1);
  });

  test('should filter by category', async ({ page }) => {
    // Open filter dialog
    await page.click('[aria-label="Filter list"]');
    
    // Select category
    await page.click('text=ベーシック');
    
    // Apply filter
    await page.click('text=適用');
    
    // Should show filter chip
    await expect(page.locator('text=ベーシック').nth(1)).toBeVisible();
    
    // Should show filtered videos
    const videos = await page.locator('[data-testid="video-card"]').count();
    expect(videos).toBeGreaterThanOrEqual(1);
  });

  test('should filter premium videos', async ({ page }) => {
    // Open filter dialog
    await page.click('[aria-label="Filter list"]');
    
    // Select premium filter
    await page.click('text=プレミアム');
    
    // Apply filter
    await page.click('text=適用');
    
    // Should show only premium videos
    const premiumBadges = await page.locator('text=プレミアム').count();
    expect(premiumBadges).toBeGreaterThan(1); // At least one in filter chip and one in video card
  });

  test('should play video', async ({ page }) => {
    // Mock video details API
    await page.route('**/api/videos/*', route => {
      if (route.request().method() === 'GET') {
        route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            video: {
              id: 'video-1',
              title: 'ベーシックガード',
              description: 'ガードの基本',
              uploadUrl: 'https://example.com/video.mp4',
              isPremium: false
            }
          })
        });
      }
    });
    
    // Click on video card
    await page.locator('[data-testid="video-card"]').first().click();
    
    // Should navigate to video player
    await expect(page).toHaveURL(/\/video\//);
    
    // Should show video player controls
    await expect(page.locator('video, [data-testid="video-player"]')).toBeVisible();
  });

  test('should handle premium video access', async ({ page }) => {
    // Mock user without subscription
    await page.route('**/api/payments/subscription', route => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          subscription: null,
          has_active_subscription: false
        })
      });
    });
    
    // Click on premium video
    await page.locator('[data-testid="video-card"]:has-text("プレミアム")').first().click();
    
    // Should show subscription prompt
    await expect(page.locator('text=/プレミアムプランに登録/')).toBeVisible();
  });

  test('should clear filters', async ({ page }) => {
    // Apply multiple filters
    await page.click('[aria-label="Filter list"]');
    await page.click('text=ベーシック');
    await page.click('text=無料');
    await page.click('text=適用');
    
    // Should show filter chips
    await expect(page.locator('text=ベーシック').nth(1)).toBeVisible();
    await expect(page.locator('text=無料').nth(1)).toBeVisible();
    
    // Clear filters
    await page.click('[aria-label="Filter list"]');
    await page.click('text=クリア');
    
    // Filter chips should be removed
    await expect(page.locator('[data-testid="filter-chip"]')).toHaveCount(0);
  });
});

test.describe('Video Upload (Admin)', () => {
  test.beforeEach(async ({ page }) => {
    // Login as admin
    await page.goto('/');
    await page.click('text=管理者でログイン');
    await page.waitForTimeout(2000);
    
    // Navigate to video tab
    await page.click('text=動画');
  });

  test('should show upload button for admin', async ({ page }) => {
    await expect(page.locator('button:has-text("動画をアップロード")').or(page.locator('[aria-label="Upload video"]'))).toBeVisible();
  });

  test('should open upload dialog', async ({ page }) => {
    // Click upload button
    await page.click('button:has-text("動画をアップロード"), [aria-label="Upload video"]');
    
    // Should show upload form
    await expect(page.locator('text=動画アップロード')).toBeVisible();
    await expect(page.locator('input[name="title"]')).toBeVisible();
    await expect(page.locator('textarea[name="description"]')).toBeVisible();
  });

  test('should validate upload form', async ({ page }) => {
    // Open upload dialog
    await page.click('button:has-text("動画をアップロード"), [aria-label="Upload video"]');
    
    // Try to submit without filling required fields
    await page.click('button:has-text("アップロード")');
    
    // Should show validation errors
    await expect(page.locator('text=/タイトルは必須です/')).toBeVisible();
    await expect(page.locator('text=/説明は必須です/')).toBeVisible();
  });

  test('should upload video successfully', async ({ page }) => {
    // Mock successful upload
    await page.route('**/api/videos/upload', route => {
      route.fulfill({
        status: 201,
        contentType: 'application/json',
        body: JSON.stringify({
          message: 'Video upload initialized',
          video: {
            id: 'new-video-1',
            title: 'テスト動画',
            status: 'pending'
          },
          upload_url: 'https://example.com/upload'
        })
      });
    });
    
    // Open upload dialog
    await page.click('button:has-text("動画をアップロード"), [aria-label="Upload video"]');
    
    // Fill form
    await page.fill('input[name="title"]', 'テスト動画');
    await page.fill('textarea[name="description"]', 'これはテスト動画です');
    await page.selectOption('select[name="category"]', { label: 'ベーシック' });
    await page.check('input[name="isPremium"]');
    
    // Select file
    const fileInput = await page.locator('input[type="file"]');
    await fileInput.setInputFiles({
      name: 'test-video.mp4',
      mimeType: 'video/mp4',
      buffer: Buffer.from('fake video content')
    });
    
    // Submit
    await page.click('button:has-text("アップロード")');
    
    // Should show success message
    await expect(page.locator('text=/動画のアップロードを開始しました/')).toBeVisible();
  });
});