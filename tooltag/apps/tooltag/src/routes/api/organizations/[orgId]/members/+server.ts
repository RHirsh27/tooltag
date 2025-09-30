import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { z } from 'zod';
import type { RequestHandler } from './$types';

/**
 * GET /api/organizations/[orgId]/members
 * List all members of an organization
 */
export const GET: RequestHandler = async ({ params, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	const members = await db.membership.findMany({
		where: { organizationId: params.orgId },
		include: {
			user: {
				select: {
					id: true,
					email: true,
					name: true,
					createdAt: true,
				},
			},
		},
		orderBy: { createdAt: 'asc' },
	});

	return json({ members });
};

const updateMemberSchema = z.object({
	role: z.enum(['OWNER', 'MANAGER', 'TECH']),
});

/**
 * PATCH /api/organizations/[orgId]/members/[userId]
 * Update member role (OWNER only)
 */
export const PATCH: RequestHandler = async ({ params, request, locals, url }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'OWNER');

	const userId = url.searchParams.get('userId');
	if (!userId) {
		return json({ error: 'userId query param required' }, { status: 400 });
	}

	try {
		const body = await request.json();
		const parsed = updateMemberSchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		// Can't change own role
		if (userId === locals.user.id) {
			return json({ error: 'Cannot change your own role' }, { status: 400 });
		}

		const membership = await db.membership.update({
			where: {
				userId_organizationId: {
					userId,
					organizationId: params.orgId,
				},
			},
			data: { role: parsed.data.role },
			include: { user: true },
		});

		return json({ membership });
	} catch (error) {
		console.error('Update member error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * DELETE /api/organizations/[orgId]/members/[userId]
 * Remove member from organization (OWNER only)
 */
export const DELETE: RequestHandler = async ({ params, locals, url }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'OWNER');

	const userId = url.searchParams.get('userId');
	if (!userId) {
		return json({ error: 'userId query param required' }, { status: 400 });
	}

	// Can't remove self
	if (userId === locals.user.id) {
		return json({ error: 'Cannot remove yourself from organization' }, { status: 400 });
	}

	try {
		await db.membership.delete({
			where: {
				userId_organizationId: {
					userId,
					organizationId: params.orgId,
				},
			},
		});

		return json({ success: true });
	} catch (error) {
		console.error('Remove member error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
