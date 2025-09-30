import bcrypt from 'bcrypt';

/**
 * Salt rounds for bcrypt (10 = ~10 hashes per second on 2GHz CPU)
 */
const SALT_ROUNDS = 10;

/**
 * Hash a password using bcrypt.
 */
export async function hashPassword(password: string): Promise<string> {
	return bcrypt.hash(password, SALT_ROUNDS);
}

/**
 * Verify a password against a hash.
 */
export async function verifyPassword(password: string, hash: string): Promise<boolean> {
	return bcrypt.compare(password, hash);
}

/**
 * Validate password strength (basic rules for MVP).
 */
export function validatePasswordStrength(password: string): { valid: boolean; error?: string } {
	if (password.length < 8) {
		return { valid: false, error: 'Password must be at least 8 characters' };
	}

	if (password.length > 128) {
		return { valid: false, error: 'Password must be less than 128 characters' };
	}

	// Optional: Add complexity requirements (uppercase, numbers, etc.)
	// Keeping simple for MVP

	return { valid: true };
}
