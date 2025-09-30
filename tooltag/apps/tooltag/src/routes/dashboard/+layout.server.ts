import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';

export const load: LayoutServerLoad = async ({ locals, url }) => {
	// Require authentication
	if (!locals.user) {
		throw redirect(302, `/login?redirect=${encodeURIComponent(url.pathname)}`);
	}

	// Check if user has any organizations
	if (!locals.memberships || locals.memberships.length === 0) {
		throw redirect(302, '/onboarding/create-org');
	}

	// Get current org from query param or use first
	const orgId = url.searchParams.get('org') || locals.memberships[0].organizationId;
	const currentMembership = locals.memberships.find((m) => m.organizationId === orgId);

	if (!currentMembership) {
		// Invalid org ID, use first
		throw redirect(302, `/dashboard?org=${locals.memberships[0].organizationId}`);
	}

	return {
		user: locals.user,
		memberships: locals.memberships,
		currentOrg: currentMembership.organization,
		currentRole: currentMembership.role,
	};
};
