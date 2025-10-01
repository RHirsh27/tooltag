import { json } from '@sveltejs/kit';
import { uploadFile } from '$lib/server/storage';
import { requireAuth } from '$lib/server/auth/rbac';
import type { RequestHandler } from './$types';

/**
 * POST /api/upload
 * Upload a file (photo) and return the URL
 */
export const POST: RequestHandler = async ({ request, locals }) => {
	requireAuth(locals.user);

	try {
		const formData = await request.formData();
		const file = formData.get('file') as File;

		if (!file) {
			return json({ error: 'No file provided' }, { status: 400 });
		}

		const result = await uploadFile(file);

		return json({
			url: result.url,
			filename: result.filename,
		});
	} catch (error: any) {
		console.error('Upload error:', error);
		return json(
			{ error: error.message || 'Failed to upload file' },
			{ status: 500 }
		);
	}
};

