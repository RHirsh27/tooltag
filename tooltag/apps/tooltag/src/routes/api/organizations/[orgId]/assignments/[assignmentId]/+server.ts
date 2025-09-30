import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { requireAuth, requireRole } from '$lib/server/auth/rbac';
import { z } from 'zod';
import type { RequestHandler } from './$types';

const checkInSchema = z.object({
	notes: z.string().optional(),
});

/**
 * GET /api/organizations/[orgId]/assignments/[assignmentId]
 * Get assignment details
 */
export const GET: RequestHandler = async ({ params, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	try {
		const assignment = await db.assignment.findUnique({
			where: {
				id: params.assignmentId,
				organizationId: params.orgId,
			},
			include: {
				item: {
					include: {
						location: true,
						category: true,
					},
				},
				user: true,
			},
		});

		if (!assignment) {
			return json({ error: 'Assignment not found' }, { status: 404 });
		}

		return json({ assignment });
	} catch (error) {
		console.error('Get assignment error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};

/**
 * PATCH /api/organizations/[orgId]/assignments/[assignmentId]/checkin
 * Check in an item (TECH+)
 */
export const PATCH: RequestHandler = async ({ params, request, locals }) => {
	requireAuth(locals.user);
	await requireRole(locals.user.id, params.orgId, 'TECH');

	try {
		const body = await request.json();
		const parsed = checkInSchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		// Get assignment
		const assignment = await db.assignment.findUnique({
			where: {
				id: params.assignmentId,
				organizationId: params.orgId,
			},
		});

		if (!assignment) {
			return json({ error: 'Assignment not found' }, { status: 404 });
		}

		if (assignment.returnedAt) {
			return json({ error: 'Item already checked in' }, { status: 400 });
		}

		// Update assignment and item status in transaction
		const [updatedAssignment] = await db.$transaction([
			db.assignment.update({
				where: { id: params.assignmentId },
				data: {
					returnedAt: new Date(),
					notes: parsed.data.notes
						? `${assignment.notes || ''}\n\nReturn: ${parsed.data.notes}`.trim()
						: assignment.notes,
				},
				include: {
					item: true,
					user: true,
				},
			}),
			db.item.update({
				where: { id: assignment.itemId },
				data: { status: 'AVAILABLE' },
			}),
			db.auditLog.create({
				data: {
					organizationId: params.orgId,
					actorUserId: locals.user.id,
					action: 'checkin',
					entity: 'Item',
					entityId: assignment.itemId,
					diff: { assignmentId: assignment.id, notes: parsed.data.notes },
				},
			}),
		]);

		return json({ assignment: updatedAssignment });
	} catch (error) {
		console.error('Check in error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
