import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { db } from '$lib/server/db';
import type { RequestHandler } from './$types';

/**
 * GET /api/organizations/[orgId]/items/export
 * Export items as CSV
 */
export const GET: RequestHandler = async ({ params, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	try {
		const items = await db.item.findMany({
			where: { organizationId: params.orgId },
			include: {
				location: { select: { name: true } },
				category: { select: { name: true } },
			},
			orderBy: { name: 'asc' },
		});

		// Generate CSV
		const headers = [
			'Name',
			'Description',
			'SKU',
			'Serial Number',
			'Status',
			'Location',
			'Category',
			'Notes',
		];

		const rows = items.map((item) => [
			item.name,
			item.description || '',
			item.sku || '',
			item.serialNumber || '',
			item.status,
			item.location?.name || '',
			item.category?.name || '',
			item.notes || '',
		]);

		const csv = [
			headers.join(','),
			...rows.map((row) =>
				row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(',')
			),
		].join('\n');

		return new Response(csv, {
			headers: {
				'Content-Type': 'text/csv',
				'Content-Disposition': `attachment; filename="inventory-${new Date().toISOString().split('T')[0]}.csv"`,
			},
		});
	} catch (error) {
		console.error('Export error:', error);
		return new Response('Export failed', { status: 500 });
	}
};
