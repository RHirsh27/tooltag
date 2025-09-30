import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth } from '$lib/server/auth/rbac';
import { z } from 'zod';
import type { RequestHandler } from './$types';

const createOrgSchema = z.object({
	name: z.string().min(1, 'Organization name is required'),
	slug: z
		.string()
		.min(3, 'Slug must be at least 3 characters')
		.regex(/^[a-z0-9-]+$/, 'Slug must be lowercase letters, numbers, and hyphens only'),
});

/**
 * GET /api/organizations
 * List all organizations the user is a member of
 */
export const GET: RequestHandler = async ({ locals }) => {
	requireAuth(locals.user);

	const memberships = await db.membership.findMany({
		where: { userId: locals.user.id },
		include: {
			organization: true,
		},
	});

	return json({
		organizations: memberships.map((m) => ({
			...m.organization,
			role: m.role,
		})),
	});
};

/**
 * POST /api/organizations
 * Create a new organization (user becomes OWNER)
 */
export const POST: RequestHandler = async ({ request, locals }) => {
	requireAuth(locals.user);

	try {
		const body = await request.json();
		const parsed = createOrgSchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		const { name, slug } = parsed.data;

		// Check if slug is taken
		const existing = await db.organization.findUnique({
			where: { slug },
		});

		if (existing) {
			return json({ error: 'Slug already taken' }, { status: 409 });
		}

		// Create organization and membership in a transaction
		const organization = await db.organization.create({
			data: {
				name,
				slug,
				memberships: {
					create: {
						userId: locals.user.id,
						role: 'OWNER',
					},
				},
			},
		});

		return json({ organization }, { status: 201 });
	} catch (error) {
		console.error('Create organization error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
