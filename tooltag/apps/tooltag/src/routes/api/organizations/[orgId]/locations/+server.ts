import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { z } from 'zod';
import type { RequestHandler } from './$types';

const locationSchema = z.object({
	name: z.string().min(1, 'Name is required'),
	description: z.string().optional(),
});

/**
 * GET /api/organizations/[orgId]/locations
 * List all locations
 */
export const GET: RequestHandler = async ({ params, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	const locations = await db.location.findMany({
		where: { organizationId: params.orgId },
		orderBy: { name: 'asc' },
		include: {
			_count: {
				select: { items: true },
			},
		},
	});

	return json({ locations });
};

/**
 * POST /api/organizations/[orgId]/locations
 * Create location (MANAGER+)
 */
export const POST: RequestHandler = async ({ params, request, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	try {
		const body = await request.json();
		const parsed = locationSchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		const location = await db.location.create({
			data: {
				organizationId: params.orgId,
				...parsed.data,
			},
		});

		return json({ location }, { status: 201 });
	} catch (error) {
		console.error('Create location error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * PATCH /api/organizations/[orgId]/locations/[id]
 * Update location (MANAGER+)
 */
export const PATCH: RequestHandler = async ({ params, request, locals, url }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	const locationId = url.searchParams.get('id');
	if (!locationId) {
		return json({ error: 'id query param required' }, { status: 400 });
	}

	try {
		const body = await request.json();
		const parsed = locationSchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		const location = await db.location.update({
			where: {
				id: locationId,
				organizationId: params.orgId,
			},
			data: parsed.data,
		});

		return json({ location });
	} catch (error) {
		console.error('Update location error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * DELETE /api/organizations/[orgId]/locations/[id]
 * Delete location (MANAGER+)
 */
export const DELETE: RequestHandler = async ({ params, locals, url }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	const locationId = url.searchParams.get('id');
	if (!locationId) {
		return json({ error: 'id query param required' }, { status: 400 });
	}

	try {
		await db.location.delete({
			where: {
				id: locationId,
				organizationId: params.orgId,
			},
		});

		return json({ success: true });
	} catch (error) {
		console.error('Delete location error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
