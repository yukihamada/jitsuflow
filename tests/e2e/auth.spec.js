import { test, expect } from '@playwright/test';

test.describe('Authentication Flow', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should display login screen', async ({ page }) => {
    await expect(page).toHaveTitle(/JitsuFlow/);
    await expect(page.locator('text=JitsuFlow')).toBeVisible();
    await expect(page.locator('text=ブラジリアン柔術トレーニング')).toBeVisible();
  });

  test('should login as demo user', async ({ page }) => {
    // Click demo user login button
    await page.click('text=一般ユーザーでログイン');
    
    // Wait for loading to complete
    await page.waitForTimeout(2000);
    
    // Should redirect to home page
    await expect(page).toHaveURL(/\/home/);
    
    // Should show welcome message
    await expect(page.locator('text=/おかえりなさい.*さん/')).toBeVisible();
  });

  test('should login as admin', async ({ page }) => {
    // Click admin login button
    await page.click('text=管理者でログイン');
    
    // Wait for loading to complete
    await page.waitForTimeout(2000);
    
    // Should redirect to home page
    await expect(page).toHaveURL(/\/home/);
    
    // Should show admin-specific elements
    await expect(page.locator('text=/おかえりなさい.*管理者.*さん/')).toBeVisible();
  });

  test('should handle login errors gracefully', async ({ page }) => {
    // Intercept API calls to simulate error
    await page.route('**/api/users/login', route => {
      route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Server error' })
      });
    });
    
    // Click login button
    await page.click('text=一般ユーザーでログイン');
    
    // Should show error message
    await expect(page.locator('text=/ログインエラー/')).toBeVisible();
  });
});

test.describe('Protected Routes', () => {
  test('should redirect to login when accessing protected route', async ({ page }) => {
    // Try to access home directly
    await page.goto('/home');
    
    // Should redirect to login
    await expect(page).toHaveURL(/\/login/);
  });

  test('should maintain session after login', async ({ page }) => {
    // Login first
    await page.goto('/');
    await page.click('text=一般ユーザーでログイン');
    await page.waitForTimeout(2000);
    
    // Navigate to different tabs
    await page.click('text=予約');
    await expect(page.locator('text=予約')).toBeVisible();
    
    await page.click('text=動画');
    await expect(page.locator('text=動画ライブラリ')).toBeVisible();
    
    // Should still be logged in
    await page.click('text=ホーム');
    await expect(page.locator('text=/おかえりなさい.*さん/')).toBeVisible();
  });
});