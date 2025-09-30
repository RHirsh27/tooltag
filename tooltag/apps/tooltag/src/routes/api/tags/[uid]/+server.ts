import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import type { RequestHandler } from './$types';

/**
 * GET /api/tags/[uid]
 * Resolve a tag UID to item details (PUBLIC - for mobile scanning)
 */
export const GET: RequestHandler = async ({ params }) => {
	try {
		const { uid } = params;

		const tag = await db.tag.findUnique({
			where: { uid },
			include: {
				item: {
					include: {
						location: { select: { id: true, name: true } },
						category: { select: { id: true, name: true } },
						assignments: {
							where: { returnedAt: null },
							include: {
								user: { select: { id: true, name: true, email: true } },
							},
							take: 1,
						},
					},
				},
				organization: { select: { id: true, name: true } },
			},
		});

		if (!tag) {
			return json({ error: 'Tag not found' }, { status: 404 });
		}

		if (!tag.item) {
			return json(
				{
					error: 'Tag exists but is not assigned to an item',
					tag: { uid: tag.uid, organizationId: tag.organizationId },
				},
				{ status: 404 }
			);
		}

		return json({
			tag: {
				uid: tag.uid,
				itemId: tag.itemId,
			},
			item: tag.item,
			organization: tag.organization,
		});
	} catch (error) {
		console.error('Resolve tag error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
