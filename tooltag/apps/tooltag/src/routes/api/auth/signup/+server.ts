import { json } from '@sveltejs/kit';
import { db } from '$lib/server/db';
import { hashPassword, validatePasswordStrength } from '$lib/server/auth/password';
import { createSessionToken } from '$lib/server/auth/session';
import { z } from 'zod';
import type { RequestHandler } from './$types';

const signupSchema = z.object({
	email: z.string().email('Invalid email address'),
	password: z.string().min(8, 'Password must be at least 8 characters'),
	name: z.string().min(1, 'Name is required').optional(),
});

export const POST: RequestHandler = async ({ request, cookies }) => {
	try {
		const body = await request.json();
		const parsed = signupSchema.safeParse(body);

		if (!parsed.success) {
			return json(
				{ error: 'Validation failed', issues: parsed.error.issues },
				{ status: 400 }
			);
		}

		const { email, password, name } = parsed.data;

		// Validate password strength
		const passwordCheck = validatePasswordStrength(password);
		if (!passwordCheck.valid) {
			return json({ error: passwordCheck.error }, { status: 400 });
		}

		// Check if user already exists
		const existingUser = await db.user.findUnique({
			where: { email: email.toLowerCase() },
		});

		if (existingUser) {
			return json({ error: 'Email already registered' }, { status: 409 });
		}

		// Hash password and create user
		const passwordHash = await hashPassword(password);
		const user = await db.user.create({
			data: {
				email: email.toLowerCase(),
				password: passwordHash,
				name: name || null,
			},
		});

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
		console.error('Signup error:', error);
		return json({ error: 'Internal server error' }, { status: 500 });
	}
};
