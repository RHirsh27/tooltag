import { test, expect } from '@playwright/test';

/**
 * Golden Path E2E Test: Complete workflow from signup to check-in
 *
 * Flow:
 * 1. Signup new user
 * 2. Create organization
 * 3. Add location and category
 * 4. Create inventory item
 * 5. Generate QR tag
 * 6. Scan tag (public route)
 * 7. Check out item
 * 8. Check in item
 * 9. Verify audit log
 */

test.describe('Golden Path', () => {
	const timestamp = Date.now();
	const testUser = {
		name: `Test User ${timestamp}`,
		email: `test${timestamp}@tooltag.app`,
		password: 'TestPassword123!'
	};
	const testOrg = {
		name: `Test Org ${timestamp}`,
		slug: `test-org-${timestamp}`
	};
	const testLocation = `Warehouse ${timestamp}`;
	const testCategory = `Tools ${timestamp}`;
	const testItem = {
		name: `Drill ${timestamp}`,
		sku: `DRL-${timestamp}`,
		serialNumber: `SN-${timestamp}`
	};

	let orgId: string;
	let itemId: string;
	let tagUid: string;

	test('complete workflow from signup to check-in', async ({ page }) => {
		// 1. Signup
		await test.step('Sign up new user', async () => {
			await page.goto('/signup');
			await page.fill('input[name="name"]', testUser.name);
			await page.fill('input[name="email"]', testUser.email);
			await page.fill('input[name="password"]', testUser.password);
			await page.click('button[type="submit"]');

			// Should redirect to onboarding (no org yet)
			await expect(page).toHaveURL(/\/onboarding\/create-org/);
		});

		// 2. Create organization
		await test.step('Create organization', async () => {
			await page.fill('input[name="name"]', testOrg.name);
			await page.fill('input[name="slug"]', testOrg.slug);
			await page.click('button[type="submit"]');

			// Should redirect to dashboard
			await expect(page).toHaveURL(/\/dashboard/);

			// Extract orgId from URL
			const url = new URL(page.url());
			orgId = url.searchParams.get('org') || '';
			expect(orgId).toBeTruthy();
		});

		// 3. Add location
		await test.step('Add location', async () => {
			await page.goto(`/dashboard/settings/locations?org=${orgId}`);
			await page.fill('input[name="name"]', testLocation);
			await page.click('button:has-text("Add Location")');

			// Wait for location to appear in list
			await expect(page.locator(`text=${testLocation}`)).toBeVisible();
		});

		// 4. Add category
		await test.step('Add category', async () => {
			await page.goto(`/dashboard/settings/categories?org=${orgId}`);
			await page.fill('input[name="name"]', testCategory);
			await page.click('button:has-text("Add Category")');

			// Wait for category to appear in list
			await expect(page.locator(`text=${testCategory}`)).toBeVisible();
		});

		// 5. Create inventory item
		await test.step('Create inventory item', async () => {
			await page.goto(`/dashboard/inventory/new?org=${orgId}`);
			await page.fill('input[name="name"]', testItem.name);
			await page.fill('input[name="sku"]', testItem.sku);
			await page.fill('input[name="serialNumber"]', testItem.serialNumber);

			// Select location and category
			await page.selectOption('select[name="locationId"]', { label: testLocation });
			await page.selectOption('select[name="categoryId"]', { label: testCategory });

			await page.click('button[type="submit"]');

			// Should redirect to item detail page
			await expect(page).toHaveURL(/\/dashboard\/inventory\/[^/]+\?/);

			// Extract itemId from URL
			const url = new URL(page.url());
			const pathParts = url.pathname.split('/');
			itemId = pathParts[pathParts.length - 1];
			expect(itemId).toBeTruthy();
		});

		// 6. Generate QR tag
		await test.step('Generate QR tag', async () => {
			// Click "Generate QR Tag" button on item detail page
			await page.click('button:has-text("Generate QR Tag")');

			// Wait for tag to appear
			await expect(page.locator('img[alt*="QR"]')).toBeVisible({ timeout: 5000 });

			// Extract tag UID from QR image src
			const qrImg = page.locator('img[alt*="QR"]').first();
			const src = await qrImg.getAttribute('src');
			expect(src).toContain('/api/tags/');
			tagUid = src?.split('/api/tags/')[1]?.split('/')[0] || '';
			expect(tagUid).toBeTruthy();
		});

		// 7. Scan tag (public route)
		await test.step('Scan tag and verify item details', async () => {
			await page.goto(`/scan/${tagUid}`);

			// Verify item details are shown
			await expect(page.locator(`text=${testItem.name}`)).toBeVisible();
			await expect(page.locator(`text=${testItem.sku}`)).toBeVisible();
			await expect(page.locator(`text=${testOrg.name}`)).toBeVisible();

			// Should show "Check Out" button (item is AVAILABLE)
			await expect(page.locator('a:has-text("Check Out")')).toBeVisible();
		});

		// 8. Check out item
		await test.step('Check out item', async () => {
			await page.click('a:has-text("Check Out")');

			// Should be on checkout form
			await expect(page).toHaveURL(/\/scan\/.*\/checkout/);

			// Select current user (first option in dropdown)
			await page.selectOption('select[name="userId"]', { index: 0 });

			// Set due date (7 days from now)
			const dueDate = new Date();
			dueDate.setDate(dueDate.getDate() + 7);
			const dueDateStr = dueDate.toISOString().split('T')[0];
			await page.fill('input[name="dueAt"]', dueDateStr);

			// Add notes
			await page.fill('textarea[name="notes"]', 'Test checkout via E2E');

			await page.click('button[type="submit"]');

			// Should redirect back to scan page with success message
			await expect(page).toHaveURL(/\/scan\/.*\?checked_out=true/);
			await expect(page.locator('text=successfully checked out')).toBeVisible();

			// Should now show "Check In" button
			await expect(page.locator('a:has-text("Check In")')).toBeVisible();
		});

		// 9. Check in item
		await test.step('Check in item', async () => {
			await page.click('a:has-text("Check In")');

			// Should be on checkin form
			await expect(page).toHaveURL(/\/scan\/.*\/checkin/);

			// Add return notes
			await page.fill('textarea[name="notes"]', 'Test return via E2E');

			await page.click('button[type="submit"]');

			// Should redirect back to scan page with success message
			await expect(page).toHaveURL(/\/scan\/.*\?checked_in=true/);
			await expect(page.locator('text=successfully checked in')).toBeVisible();

			// Should now show "Check Out" button again (item is AVAILABLE)
			await expect(page.locator('a:has-text("Check Out")')).toBeVisible();
		});

		// 10. Verify audit log
		await test.step('Verify audit log', async () => {
			await page.goto(`/dashboard/audit?org=${orgId}`);

			// Should see checkout and checkin actions
			await expect(page.locator('text=checkout')).toBeVisible();
			await expect(page.locator('text=checkin')).toBeVisible();

			// Should see item creation
			await expect(page.locator('text=create')).toBeVisible();
		});

		// 11. Verify dashboard metrics
		await test.step('Verify dashboard metrics', async () => {
			await page.goto(`/dashboard?org=${orgId}`);

			// Should show at least 1 item
			await expect(page.locator('text=Total Items')).toBeVisible();

			// Metrics should have loaded (not "Loading...")
			await expect(page.locator('text=Loading metrics')).not.toBeVisible();
		});
	});
});
