import { json } from '@sveltejs/kit';
import { sendOverdueReminders } from '$lib/server/tasks/send-overdue-reminders';
import type { RequestHandler } from './$types';

/**
 * POST /api/tasks/send-overdue-reminders
 * Trigger overdue reminders task manually
 * 
 * This endpoint should be:
 * 1. Protected with an API key in production
 * 2. Called by a cron service (e.g., Vercel Cron, GitHub Actions, external cron job)
 * 
 * For MVP: Can be called manually or via scheduler
 */
export const POST: RequestHandler = async ({ request }) => {
	// Simple API key authentication for cron tasks
	const authHeader = request.headers.get('Authorization');
	const apiKey = process.env.CRON_SECRET || 'dev-secret-change-in-production';

	if (authHeader !== `Bearer ${apiKey}`) {
		return json({ error: 'Unauthorized' }, { status: 401 });
	}

	try {
		const results = await sendOverdueReminders();

		return json({
			success: true,
			...results,
		});
	} catch (error: any) {
		console.error('Overdue reminders task error:', error);
		return json(
			{
				success: false,
				error: error.message || 'Failed to run task',
			},
			{ status: 500 }
		);
	}
};

