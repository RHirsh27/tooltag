import { db } from '../db';
import { nanoid } from 'nanoid';
import type { User } from '@prisma/client';

/**
 * Session token length (URL-safe)
 */
const SESSION_TOKEN_LENGTH = 32;

/**
 * Session expiry (30 days)
 */
const SESSION_EXPIRY_MS = 30 * 24 * 60 * 60 * 1000;

export interface Session {
	id: string;
	userId: string;
	expiresAt: Date;
	user?: User;
}

/**
 * Create a new session for a user.
 */
export async function createSession(userId: string): Promise<string> {
	const token = nanoid(SESSION_TOKEN_LENGTH);
	const expiresAt = new Date(Date.now() + SESSION_EXPIRY_MS);

	// Store session metadata in User model (for MVP, using a JSON field)
	// In production, consider a separate Session table
	await db.user.update({
		where: { id: userId },
		data: {
			// For now, we'll handle sessions via cookies only
			// A proper Session table would be added in production
			updatedAt: new Date(),
		},
	});

	return token;
}

/**
 * Validate a session token and return user data.
 * For MVP, we'll use a simple token scheme. In production,
 * implement a Session table with token hashing.
 */
export async function validateSession(token: string): Promise<{ user: User } | null> {
	if (!token || token.length === 0) {
		return null;
	}

	// For MVP: decode userId from token (NOT production-ready)
	// TODO Phase 2: Add Session table with hashed tokens
	try {
		const decoded = Buffer.from(token, 'base64').toString();
		const [userId, timestamp] = decoded.split(':');

		if (!userId || !timestamp) {
			return null;
		}

		const expiresAt = parseInt(timestamp, 10);

		if (Date.now() > expiresAt) {
			return null; // Expired
		}

		const user = await db.user.findUnique({
			where: { id: userId },
		});

		if (!user) {
			return null;
		}

		return { user };
	} catch {
		return null;
	}
}

/**
 * Create a session token (MVP version - encodes userId + expiry).
 * NOT cryptographically secure - replace with DB-backed sessions in production.
 */
export function createSessionToken(userId: string): string {
	const expiresAt = Date.now() + SESSION_EXPIRY_MS;
	const payload = `${userId}:${expiresAt}`;
	return Buffer.from(payload).toString('base64');
}

/**
 * Invalidate a session (logout).
 */
export async function invalidateSession(token: string): Promise<void> {
	// For MVP with token-based sessions, we can't invalidate
	// Production: DELETE FROM sessions WHERE token = ?
	// For now, client just deletes cookie
	return;
}
