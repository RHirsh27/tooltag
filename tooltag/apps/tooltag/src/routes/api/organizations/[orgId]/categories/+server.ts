import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { z } from 'zod';
import type { RequestHandler } from './$types';

const categorySchema = z.object({
	name: z.string().min(1, 'Name is required'),
	description: z.string().optional(),
});

/**
 * GET /api/organizations/[orgId]/categories
 * List all categories
 */
export const GET: RequestHandler = async ({ params, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	const categories = await db.category.findMany({
		where: { organizationId: params.orgId },
		orderBy: { name: 'asc' },
		include: {
			_count: {
				select: { items: true },
			},
		},
	});

	return json({ categories });
};

/**
 * POST /api/organizations/[orgId]/categories
 * Create category (MANAGER+)
 */
export const POST: RequestHandler = async ({ params, request, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	try {
		const body = await request.json();
		const parsed = categorySchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		const category = await db.category.create({
			data: {
				organizationId: params.orgId,
				...parsed.data,
			},
		});

		return json({ category }, { status: 201 });
	} catch (error) {
		console.error('Create category error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * PATCH /api/organizations/[orgId]/categories/[id]
 * Update category (MANAGER+)
 */
export const PATCH: RequestHandler = async ({ params, request, locals, url }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	const categoryId = url.searchParams.get('id');
	if (!categoryId) {
		return json({ error: 'id query param required' }, { status: 400 });
	}

	try {
		const body = await request.json();
		const parsed = categorySchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		const category = await db.category.update({
			where: {
				id: categoryId,
				organizationId: params.orgId,
			},
			data: parsed.data,
		});

		return json({ category });
	} catch (error) {
		console.error('Update category error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * DELETE /api/organizations/[orgId]/categories/[id]
 * Delete category (MANAGER+)
 */
export const DELETE: RequestHandler = async ({ params, locals, url }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	const categoryId = url.searchParams.get('id');
	if (!categoryId) {
		return json({ error: 'id query param required' }, { status: 400 });
	}

	try {
		await db.category.delete({
			where: {
				id: categoryId,
				organizationId: params.orgId,
			},
		});

		return json({ success: true });
	} catch (error) {
		console.error('Delete category error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
