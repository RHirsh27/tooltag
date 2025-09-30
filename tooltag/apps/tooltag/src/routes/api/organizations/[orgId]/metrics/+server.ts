import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import type { RequestHandler } from './$types';

/**
 * GET /api/organizations/[orgId]/metrics
 * Get dashboard metrics
 */
export const GET: RequestHandler = async ({ params, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	try {
		// Get counts in parallel
		const [
			totalItems,
			availableItems,
			checkedOutItems,
			maintenanceItems,
			activeAssignments,
			overdueAssignments,
			totalMembers,
		] = await Promise.all([
			db.item.count({ where: { organizationId: params.orgId } }),
			db.item.count({
				where: { organizationId: params.orgId, status: 'AVAILABLE' },
			}),
			db.item.count({
				where: { organizationId: params.orgId, status: 'CHECKED_OUT' },
			}),
			db.item.count({
				where: { organizationId: params.orgId, status: 'MAINTENANCE' },
			}),
			db.assignment.count({
				where: {
					organizationId: params.orgId,
					returnedAt: null,
				},
			}),
			db.assignment.count({
				where: {
					organizationId: params.orgId,
					returnedAt: null,
					dueAt: { lt: new Date() },
				},
			}),
			db.membership.count({ where: { organizationId: params.orgId } }),
		]);

		return json({
			items: {
				total: totalItems,
				available: availableItems,
				checkedOut: checkedOutItems,
				maintenance: maintenanceItems,
			},
			assignments: {
				active: activeAssignments,
				overdue: overdueAssignments,
			},
			members: totalMembers,
		});
	} catch (error) {
		console.error('Get metrics error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
