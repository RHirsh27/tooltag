import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import type { RequestHandler } from './$types';

/**
 * GET /api/health
 * Health check endpoint for monitoring and uptime services
 * Public endpoint (no auth required)
 */
export const GET: RequestHandler = async () => {
	const startTime = Date.now();

	try {
		// Test database connectivity
		await db.$queryRaw`SELECT 1`;

		const responseTime = Date.now() - startTime;

		return json({
			status: 'healthy',
			timestamp: new Date().toISOString(),
			uptime: process.uptime(),
			responseTime,
			database: 'connected',
			version: '1.0.0-MVP'
		});
	} catch (error) {
		const responseTime = Date.now() - startTime;

		return json(
			{
				status: 'unhealthy',
				timestamp: new Date().toISOString(),
				uptime: process.uptime(),
				responseTime,
				database: 'disconnected',
				error: error instanceof Error ? error.message : 'Unknown error',
				version: '1.0.0-MVP'
			},
			{ status: 503 }
		);
	}
};
