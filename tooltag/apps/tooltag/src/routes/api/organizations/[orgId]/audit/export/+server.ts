import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { db } from '$lib/server/db';
import type { RequestHandler } from './$types';

/**
 * GET /api/organizations/[orgId]/audit/export
 * Export audit log as CSV
 */
export const GET: RequestHandler = async ({ params, locals, url }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	// Get filters from query params (same as list endpoint)
	const action = url.searchParams.get('action') || '';
	const entity = url.searchParams.get('entity') || '';
	const startDate = url.searchParams.get('startDate');
	const endDate = url.searchParams.get('endDate');

	const where: any = {
		organizationId: params.orgId,
	};

	if (action) where.action = action;
	if (entity) where.entity = entity;
	if (startDate || endDate) {
		where.createdAt = {};
		if (startDate) where.createdAt.gte = new Date(startDate);
		if (endDate) where.createdAt.lte = new Date(endDate);
	}

	try {
		const logs = await db.auditLog.findMany({
			where,
			orderBy: { createdAt: 'desc' },
			include: {
				actor: {
					select: {
						name: true,
						email: true,
					},
				},
			},
		});

		// Generate CSV
		const headers = ['Timestamp', 'Action', 'Entity', 'Entity ID', 'Actor', 'Details'];

		const rows = logs.map((log) => [
			new Date(log.createdAt).toISOString(),
			log.action,
			log.entity,
			log.entityId,
			log.actor.name || log.actor.email,
			JSON.stringify(log.diff),
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
				'Content-Disposition': `attachment; filename="audit-log-${new Date().toISOString().split('T')[0]}.csv"`,
			},
		});
	} catch (error) {
		console.error('Export audit log error:', error);
		return new Response('Export failed', { status: 500 });
	}
};
