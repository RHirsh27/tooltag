import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { z } from 'zod';
import type { RequestHandler } from './$types';

const updateOrgSchema = z.object({
	name: z.string().min(1, 'Organization name is required').optional(),
	slug: z
		.string()
		.min(3, 'Slug must be at least 3 characters')
		.regex(/^[a-z0-9-]+$/, 'Slug must be lowercase letters, numbers, and hyphens only')
		.optional(),
});

/**
 * GET /api/organizations/[orgId]
 * Get organization details
 */
export const GET: RequestHandler = async ({ params, locals }) => {
	requireAuth(locals.user);

	const membership = await requireRole(locals.user.id, params.orgId, 'TECH');

	return json({
		organization: membership.organization,
		role: membership.role,
	});
};

/**
 * PATCH /api/organizations/[orgId]
 * Update organization (MANAGER+ only)
 */
export const PATCH: RequestHandler = async ({ params, request, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'MANAGER');

	try {
		const body = await request.json();
		const parsed = updateOrgSchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		const updateData = parsed.data;

		// If changing slug, check availability
		if (updateData.slug) {
			const existing = await db.organization.findUnique({
				where: { slug: updateData.slug },
			});

			if (existing && existing.id !== params.orgId) {
				return json({ error: 'Slug already taken' }, { status: 409 });
			}
		}

		const organization = await db.organization.update({
			where: { id: params.orgId },
			data: updateData,
		});

		return json({ organization });
	} catch (error) {
		console.error('Update organization error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * DELETE /api/organizations/[orgId]
 * Delete organization (OWNER only)
 */
export const DELETE: RequestHandler = async ({ params, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'OWNER');

	try {
		await db.organization.delete({
			where: { id: params.orgId },
		});

		return json({ success: true });
	} catch (error) {
		console.error('Delete organization error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
