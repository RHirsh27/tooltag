import { error } from '@sveltejs/kit';
import { db } from '../db';
import type { User, Role } from '@prisma/client';

/**
 * Role hierarchy for permission checks
 */
const roleHierarchy: Record<Role, number> = {
	OWNER: 3,
	MANAGER: 2,
	TECH: 1,
};

/**
 * Check if user has at least the specified role in an organization.
 */
export function hasRole(userRole: Role, requiredRole: Role): boolean {
	return roleHierarchy[userRole] >= roleHierarchy[requiredRole];
}

/**
 * Get user's membership for an organization.
 */
export async function getMembership(userId: string, organizationId: string) {
	return db.membership.findUnique({
		where: {
			userId_organizationId: {
				userId,
				organizationId,
			},
		},
		include: {
			organization: true,
		},
	});
}

/**
 * Require authentication. Throws 401 if not logged in.
 */
export function requireAuth(user?: User): asserts user is User {
	if (!user) {
		throw error(401, 'Authentication required');
	}
}

/**
 * Require specific role in organization. Throws 403 if insufficient permissions.
 */
export async function requireRole(
	userId: string,
	organizationId: string,
	requiredRole: Role = 'TECH'
) {
	const membership = await getMembership(userId, organizationId);

	if (!membership) {
		throw error(403, 'Not a member of this organization');
	}

	if (!hasRole(membership.role, requiredRole)) {
		throw error(403, `Requires ${requiredRole} role or higher`);
	}

	return membership;
}
