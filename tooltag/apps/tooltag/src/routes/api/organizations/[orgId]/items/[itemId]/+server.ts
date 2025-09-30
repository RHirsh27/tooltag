import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { z } from 'zod';
import type { RequestHandler } from './$types';

const itemSchema = z.object({
	name: z.string().min(1, 'Name is required'),
	description: z.string().optional(),
	sku: z.string().optional(),
	serialNumber: z.string().optional(),
	status: z.enum(['AVAILABLE', 'CHECKED_OUT', 'MAINTENANCE', 'MISSING', 'RETIRED']).optional(),
	locationId: z.string().nullable().optional(),
	categoryId: z.string().nullable().optional(),
	notes: z.string().optional(),
});

/**
 * GET /api/organizations/[orgId]/items/[itemId]
 * Get item details
 */
export const GET: RequestHandler = async ({ params, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	try {
		const item = await db.item.findUnique({
			where: {
				id: params.itemId,
				organizationId: params.orgId,
			},
			include: {
				location: true,
				category: true,
				tags: true,
				assignments: {
					include: {
						user: { select: { id: true, name: true, email: true } },
					},
					orderBy: { checkedOutAt: 'desc' },
					take: 10,
				},
			},
		});

		if (!item) {
			return json({ error: 'Item not found' }, { status: 404 });
		}

		return json({ item });
	} catch (error) {
		console.error('Get item error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * PATCH /api/organizations/[orgId]/items/[itemId]
 * Update item (MANAGER+)
 */
export const PATCH: RequestHandler = async ({ params, request, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	try {
		const body = await request.json();
		const parsed = itemSchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		const item = await db.item.update({
			where: {
				id: params.itemId,
				organizationId: params.orgId,
			},
			data: parsed.data,
			include: {
				location: true,
				category: true,
				tags: true,
			},
		});

		return json({ item });
	} catch (error) {
		console.error('Update item error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * DELETE /api/organizations/[orgId]/items/[itemId]
 * Delete item (MANAGER+)
 */
export const DELETE: RequestHandler = async ({ params, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	try {
		await db.item.delete({
			where: {
				id: params.itemId,
				organizationId: params.orgId,
			},
		});

		return json({ success: true });
	} catch (error) {
		console.error('Delete item error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
