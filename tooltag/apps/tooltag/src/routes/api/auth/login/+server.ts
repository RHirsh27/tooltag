import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { verifyPassword } from '$lib/server/auth/password';
import { createSessionToken } from '$lib/server/auth/session';
import { z } from 'zod';
import type { RequestHandler } from './$types';

const loginSchema = z.object({
	email: z.string().email('Invalid email address'),
	password: z.string().min(1, 'Password is required'),
});

export const POST: RequestHandler = async ({ request, cookies }) => {
	try {
		const body = await request.json();
		const parsed = loginSchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		const { email, password } = parsed.data;

		// Find user
		const user = await db.user.findUnique({
			where: { email: email.toLowerCase() },
		});

		if (!user || !user.password) {
			return json({ error: 'Invalid email or password' }, { status: 401 });
		}

		// Verify password
		const isValid = await verifyPassword(password, user.password);
		if (!isValid) {
			return json({ error: 'Invalid email or password' }, { status: 401 });
		}

		// Create session token
		const sessionToken = createSessionToken(user.id);

		// Set HTTP-only cookie
		cookies.set('session', sessionToken, {
			path: '/',
			httpOnly: true,
			sameSite: 'lax',
			secure: process.env.NODE_ENV === 'production',
			maxAge: 60 * 60 * 24 * 30, // 30 days
		});

		return json({
			user: {
				id: user.id,
				email: user.email,
				name: user.name,
			},
		});
	} catch (error) {
		console.error('Login error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
