import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import type { RequestHandler } from './$types';
import type { Prisma } from '@prisma/client';

/**
 * GET /api/organizations/[orgId]/audit
 * List audit log entries with filters
 */
export const GET: RequestHandler = async ({ params, locals, url }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	const action = url.searchParams.get('action') || '';
	const entity = url.searchParams.get('entity') || '';
	const actorUserId = url.searchParams.get('actorUserId') || '';
	const startDate = url.searchParams.get('startDate');
	const endDate = url.searchParams.get('endDate');
	const page = parseInt(url.searchParams.get('page') || '1', 10);
	const limit = parseInt(url.searchParams.get('limit') || '50', 10);

	// Build where clause
	const where: Prisma.AuditLogWhereInput = {
		organizationId: params.orgId,
	};

	if (action) {
		where.action = action;
	}

	if (entity) {
		where.entity = entity;
	}

	if (actorUserId) {
		where.actorUserId = actorUserId;
	}

	if (startDate || endDate) {
		where.createdAt = {};
		if (startDate) {
			where.createdAt.gte = new Date(startDate);
		}
		if (endDate) {
			where.createdAt.lte = new Date(endDate);
		}
	}

	try {
		const [logs, total] = await Promise.all([
			db.auditLog.findMany({
				where,
				skip: (page - 1) * limit,
				take: limit,
				orderBy: { createdAt: 'desc' },
				include: {
					actor: {
						select: {
							id: true,
							name: true,
							email: true,
						},
					},
				},
			}),
			db.auditLog.count({ where }),
		]);

		return json({
			logs,
			pagination: {
				page,
				limit,
				total,
				totalPages: Math.ceil(total / limit),
			},
		});
	} catch (error) {
		console.error('List audit logs error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
