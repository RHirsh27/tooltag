import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import type { Prisma } from '@prisma/client';

const itemSchema = z.object({
	name: z.string().min(1, 'Name is required'),
	description: z.string().optional(),
	sku: z.string().optional(),
	serialNumber: z.string().optional(),
	status: z.enum(['AVAILABLE', 'CHECKED_OUT', 'MAINTENANCE', 'MISSING', 'RETIRED']).optional(),
	locationId: z.string().optional(),
	categoryId: z.string().optional(),
	notes: z.string().optional(),
});

/**
 * GET /api/organizations/[orgId]/items
 * List items with search/filter/pagination
 */
export const GET: RequestHandler = async ({ params, locals, url }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	// Parse query params
	const search = url.searchParams.get('search') || '';
	const status = url.searchParams.get('status') || '';
	const locationId = url.searchParams.get('locationId') || '';
	const categoryId = url.searchParams.get('categoryId') || '';
	const page = parseInt(url.searchParams.get('page') || '1', 10);
	const limit = parseInt(url.searchParams.get('limit') || '50', 10);

	// Build where clause
	const where: Prisma.ItemWhereInput = {
		organizationId: params.orgId,
	};

	if (search) {
		where.OR = [
			{ name: { contains: search, mode: 'insensitive' } },
			{ sku: { contains: search, mode: 'insensitive' } },
			{ serialNumber: { contains: search, mode: 'insensitive' } },
		];
	}

	if (status) {
		where.status = status as any;
	}

	if (locationId) {
		where.locationId = locationId;
	}

	if (categoryId) {
		where.categoryId = categoryId;
	}

	try {
		const [items, total] = await Promise.all([
			db.item.findMany({
				where,
				skip: (page - 1) * limit,
				take: limit,
				orderBy: { createdAt: 'desc' },
				include: {
					location: { select: { id: true, name: true } },
					category: { select: { id: true, name: true } },
					tags: { select: { id: true, uid: true } },
					_count: {
						select: { assignments: true },
					},
				},
			}),
			db.item.count({ where }),
		]);

		return json({
			items,
			pagination: {
				page,
				limit,
				total,
				totalPages: Math.ceil(total / limit),
			},
		});
	} catch (error) {
		console.error('List items error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * POST /api/organizations/[orgId]/items
 * Create item (MANAGER+)
 */
export const POST: RequestHandler = async ({ params, request, locals }) => {
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

		const item = await db.item.create({
			data: {
				organizationId: params.orgId,
				...parsed.data,
			},
			include: {
				location: true,
				category: true,
			},
		});

		return json({ item }, { status: 201 });
	} catch (error) {
		console.error('Create item error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
