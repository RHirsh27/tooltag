import { error } from '@sveltejs/kit';
import { readFile } from 'fs/promises';
import { existsSync } from 'fs';
import path from 'path';
import { env } from '@tooltag/config/env';
import type { RequestHandler } from './$types';

/**
 * GET /uploads/[filename]
 * Serve uploaded files from local storage
 */
export const GET: RequestHandler = async ({ params }) => {
	try {
		const storageDir = path.resolve(env.STORAGE_PATH || './uploads');
		const filepath = path.join(storageDir, params.filename);

		// Security: Prevent directory traversal
		if (!filepath.startsWith(storageDir)) {
			throw error(403, 'Forbidden');
		}

		// Check if file exists
		if (!existsSync(filepath)) {
			throw error(404, 'File not found');
		}

		// Read file
		const file = await readFile(filepath);

		// Determine content type
		const ext = path.extname(params.filename).toLowerCase();
		const contentTypes: Record<string, string> = {
			'.jpg': 'image/jpeg',
			'.jpeg': 'image/jpeg',
			'.png': 'image/png',
			'.gif': 'image/gif',
			'.webp': 'image/webp',
		};
		const contentType = contentTypes[ext] || 'application/octet-stream';

		return new Response(file, {
			headers: {
				'Content-Type': contentType,
				'Cache-Control': 'public, max-age=31536000, immutable',
			},
		});
	} catch (err: any) {
		console.error('File serve error:', err);
		throw error(err.status || 500, err.message || 'Failed to serve file');
	}
};

