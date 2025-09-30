import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { nanoid } from 'nanoid';
import type { RequestHandler } from './$types';

/**
 * POST /api/organizations/[orgId]/items/[itemId]/tags
 * Generate a new QR tag for an item (MANAGER+)
 */
export const POST: RequestHandler = async ({ params, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	try {
		// Verify item exists in org
		const item = await db.item.findUnique({
			where: {
				id: params.itemId,
				organizationId: params.orgId,
			},
		});

		if (!item) {
			return json({ error: 'Item not found' }, { status: 404 });
		}

		// Generate unique tag UID (10 chars, URL-safe)
		const uid = nanoid(10);

		// Create tag
		const tag = await db.tag.create({
			data: {
				organizationId: params.orgId,
				itemId: params.itemId,
				uid,
			},
		});

		return json({ tag }, { status: 201 });
	} catch (error) {
		console.error('Create tag error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * DELETE /api/organizations/[orgId]/items/[itemId]/tags/[tagId]
 * Delete a tag (MANAGER+)
 */
export const DELETE: RequestHandler = async ({ params, locals, url }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	const tagId = url.searchParams.get('tagId');
	if (!tagId) {
		return json({ error: 'tagId query param required' }, { status: 400 });
	}

	try {
		await db.tag.delete({
			where: {
				id: tagId,
				organizationId: params.orgId,
			},
		});

		return json({ success: true });
	} catch (error) {
		console.error('Delete tag error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
