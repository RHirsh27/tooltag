import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import type { Prisma } from '@prisma/client';

const checkOutSchema = z.object({
	itemId: z.string(),
	userId: z.string(),
	dueAt: z.string().datetime().optional(),
	notes: z.string().optional(),
});

/**
 * GET /api/organizations/[orgId]/assignments
 * List assignments with filters
 */
export const GET: RequestHandler = async ({ params, locals, url }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	const status = url.searchParams.get('status') || 'active'; // active | returned | overdue | all
	const userId = url.searchParams.get('userId');
	const itemId = url.searchParams.get('itemId');
	const page = parseInt(url.searchParams.get('page') || '1', 10);
	const limit = parseInt(url.searchParams.get('limit') || '50', 10);

	// Build where clause
	const where: Prisma.AssignmentWhereInput = {
		organizationId: params.orgId,
	};

	if (status === 'active') {
		where.returnedAt = null;
	} else if (status === 'returned') {
		where.returnedAt = { not: null };
	} else if (status === 'overdue') {
		where.returnedAt = null;
		where.dueAt = { lt: new Date() };
	}

	if (userId) {
		where.userId = userId;
	}

	if (itemId) {
		where.itemId = itemId;
	}

	try {
		const [assignments, total] = await Promise.all([
			db.assignment.findMany({
				where,
				skip: (page - 1) * limit,
				take: limit,
				orderBy: { checkedOutAt: 'desc' },
				include: {
					item: {
						select: {
							id: true,
							name: true,
							sku: true,
							status: true,
						},
					},
					user: {
						select: {
							id: true,
							name: true,
							email: true,
						},
					},
				},
			}),
			db.assignment.count({ where }),
		]);

		return json({
			assignments,
			pagination: {
				page,
				limit,
				total,
				totalPages: Math.ceil(total / limit),
			},
		});
	} catch (error) {
		console.error('List assignments error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * POST /api/organizations/[orgId]/assignments
 * Check out an item (TECH+)
 */
export const POST: RequestHandler = async ({ params, request, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	try {
		const body = await request.json();
		const parsed = checkOutSchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		const { itemId, userId, dueAt, notes } = parsed.data;

		// Verify item exists and is available
		const item = await db.item.findUnique({
			where: {
				id: itemId,
				organizationId: params.orgId,
			},
		});

		if (!item) {
			return json({ error: 'Item not found' }, { status: 404 });
		}

		if (item.status === 'CHECKED_OUT') {
			return json({ error: 'Item is already checked out' }, { status: 400 });
		}

		// Create assignment and update item status in transaction
		const [assignment] = await db.$transaction([
			db.assignment.create({
				data: {
					organizationId: params.orgId,
					itemId,
					userId,
					dueAt: dueAt ? new Date(dueAt) : null,
					notes: notes || null,
				},
				include: {
					item: true,
					user: true,
				},
			}),
			db.item.update({
				where: { id: itemId },
				data: { status: 'CHECKED_OUT' },
			}),
			db.auditLog.create({
				data: {
					organizationId: params.orgId,
					actorUserId: locals.user.id,
					action: 'checkout',
					entity: 'Item',
					entityId: itemId,
					diff: { userId, dueAt, notes },
				},
			}),
		]);

		return json({ assignment }, { status: 201 });
	} catch (error) {
		console.error('Check out error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
