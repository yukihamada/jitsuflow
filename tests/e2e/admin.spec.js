import { test, expect } from '@playwright/test';

const ADMIN_URL = process.env.ADMIN_URL || 'http://localhost:3001';

test.describe('Admin Dashboard', () => {
  test('should login successfully', async ({ page }) => {
    await page.goto(ADMIN_URL);
    
    // Wait for login form
    await page.waitForSelector('input[name="email"]');
    
    // Fill login form
    await page.fill('input[name="email"]', 'admin@jitsuflow.app');
    await page.fill('input[name="password"]', 'admin123');
    
    // Submit
    await page.click('button[type="submit"]');
    
    // Should redirect to dashboard
    await page.waitForSelector('text=JitsuFlow 管理ダッシュボード');
    
    // Check if logged in
    expect(await page.locator('text=管理者モード').isVisible()).toBeTruthy();
  });

  test('should display dojos correctly', async ({ page }) => {
    // Login first
    await page.goto(ADMIN_URL);
    await page.fill('input[name="email"]', 'admin@jitsuflow.app');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    
    // Navigate to dojos tab
    await page.click('text=道場管理');
    
    // Check if dojos are displayed
    await page.waitForSelector('text=YAWARA東京');
    await page.waitForSelector('text=SWEEP東京');
    await page.waitForSelector('text=OverLimit札幌');
    
    // Check websites are displayed
    expect(await page.locator('text=yawara-bjj.com').isVisible()).toBeTruthy();
    expect(await page.locator('text=sweep-bjj.com').isVisible()).toBeTruthy();
    expect(await page.locator('text=overlimit-bjj.com').isVisible()).toBeTruthy();
  });

  test('should display instructors correctly', async ({ page }) => {
    // Login first
    await page.goto(ADMIN_URL);
    await page.fill('input[name="email"]', 'admin@jitsuflow.app');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    
    // Navigate to instructors tab
    await page.click('text=インストラクター');
    
    // Check if instructors are displayed
    await page.waitForSelector('text=一木');
    await page.waitForSelector('text=村田');
    await page.waitForSelector('text=河野');
    await page.waitForSelector('text=諸澤陽斗');
  });

  test('should display products correctly', async ({ page }) => {
    // Login first
    await page.goto(ADMIN_URL);
    await page.fill('input[name="email"]', 'admin@jitsuflow.app');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    
    // Navigate to products tab
    await page.click('text=商品管理');
    
    // Check if YAWARA products are displayed
    await page.waitForSelector('text=パーソナルトレーニング セッション(一木)');
    await page.waitForSelector('text=柔術パーソナルトレーニング Personal');
    await page.waitForSelector('text=リラックスヒーリング');
  });
});