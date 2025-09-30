import { json } from '@sveltejs/kit';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { db } from '$lib/server/db';
import type { RequestHandler } from './$types';

/**
 * POST /api/organizations/[orgId]/items/import
 * Import items from CSV
 */
export const POST: RequestHandler = async ({ params, request, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	try {
		const formData = await request.formData();
		const file = formData.get('file') as File;

		if (!file) {
			return json({ error: 'No file uploaded' }, { status: 400 });
		}

		const text = await file.text();
		const lines = text.split('\n').filter((line) => line.trim());

		if (lines.length < 2) {
			return json({ error: 'CSV must contain headers and at least one row' }, { status: 400 });
		}

		// Parse CSV (simple implementation, assumes comma-separated)
		const headers = lines[0].split(',').map((h) => h.trim().replace(/"/g, ''));
		const rows = lines.slice(1).map((line) => {
			const values = line.match(/(".*?"|[^,]+)(?=\s*,|\s*$)/g) || [];
			return values.map((v) => v.trim().replace(/^"|"$/g, ''));
		});

		// Get location and category maps
		const locations = await db.location.findMany({
			where: { organizationId: params.orgId },
			select: { id: true, name: true },
		});
		const categories = await db.category.findMany({
			where: { organizationId: params.orgId },
			select: { id: true, name: true },
		});

		const locationMap = new Map(locations.map((l) => [l.name.toLowerCase(), l.id]));
		const categoryMap = new Map(categories.map((c) => [c.name.toLowerCase(), c.id]));

		// Import items
		const imported = [];
		const errors: string[] = [];

		for (let i = 0; i < rows.length; i++) {
			const row = rows[i];
			const rowNum = i + 2; // +2 for header and 0-index

			try {
				const name = row[0];
				if (!name) {
					errors.push(`Row ${rowNum}: Name is required`);
					continue;
				}

				const locationName = row[5]?.toLowerCase();
				const categoryName = row[6]?.toLowerCase();

				const item = await db.item.create({
					data: {
						organizationId: params.orgId,
						name,
						description: row[1] || null,
						sku: row[2] || null,
						serialNumber: row[3] || null,
						status: (row[4] as any) || 'AVAILABLE',
						locationId: locationName ? locationMap.get(locationName) || null : null,
						categoryId: categoryName ? categoryMap.get(categoryName) || null : null,
						notes: row[7] || null,
					},
				});

				imported.push(item);
			} catch (err: any) {
				errors.push(`Row ${rowNum}: ${err.message}`);
			}
		}

		return json({
			imported: imported.length,
			errors: errors.length > 0 ? errors : undefined,
		});
	} catch (error) {
		console.error('Import error:', error);
		return json({ error: 'Import failed' }, { status: 500 });
	}
};
