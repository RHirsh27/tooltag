import { db } from '../db';
import { sendOverdueReminder } from '../email';

/**
 * Task: Send overdue item reminders
 * 
 * This should be run daily (e.g., via cron job or scheduled task).
 * Can be triggered via API endpoint or external scheduler.
 */
export async function sendOverdueReminders(): Promise<{
	sent: number;
	failed: number;
	errors: string[];
}> {
	const results = {
		sent: 0,
		failed: 0,
		errors: [] as string[],
	};

	try {
		// Find all overdue assignments (not returned, past due date)
		const overdueAssignments = await db.assignment.findMany({
			where: {
				returnedAt: null,
				dueAt: {
					lt: new Date(),
				},
			},
			include: {
				item: true,
				user: true,
				organization: true,
			},
		});

		console.log(`[Overdue Reminders] Found ${overdueAssignments.length} overdue assignments`);

		// Send reminder for each overdue assignment
		for (const assignment of overdueAssignments) {
			// Skip if no due date (shouldn't happen, but just in case)
			if (!assignment.dueAt) continue;

			// Calculate days overdue
			const daysOverdue = Math.ceil(
				(Date.now() - assignment.dueAt.getTime()) / (1000 * 60 * 60 * 24)
			);

			// Only send reminder if overdue (skip if sent today already - would need a separate tracking table in production)
			try {
				const sent = await sendOverdueReminder({
					userEmail: assignment.user.email,
					userName: assignment.user.name || assignment.user.email,
					itemName: assignment.item.name,
					dueDate: assignment.dueAt,
					organizationName: assignment.organization.name,
					daysOverdue,
				});

				if (sent) {
					results.sent++;
					console.log(
						`[Overdue Reminders] Sent to ${assignment.user.email} for item ${assignment.item.name}`
					);
				} else {
					results.failed++;
					results.errors.push(`Failed to send to ${assignment.user.email} (SMTP not configured)`);
				}
			} catch (error: any) {
				results.failed++;
				results.errors.push(`Error sending to ${assignment.user.email}: ${error.message}`);
				console.error('[Overdue Reminders] Send error:', error);
			}

			// Add small delay to avoid rate limiting
			await new Promise((resolve) => setTimeout(resolve, 100));
		}

		console.log(
			`[Overdue Reminders] Complete - Sent: ${results.sent}, Failed: ${results.failed}`
		);
	} catch (error) {
		console.error('[Overdue Reminders] Task error:', error);
		results.errors.push(`Task error: ${error}`);
	}

	return results;
}

