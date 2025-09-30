import * as Sentry from '@sentry/sveltekit';
import { validateSession } from '$lib/server/auth/session';
import { db } from '$lib/server/db';
import type { Handle } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';

/**
 * Server-side Sentry initialization
 */
Sentry.init({
	dsn: process.env.PUBLIC_SENTRY_DSN,
	enabled: process.env.NODE_ENV === 'production',
	environment: process.env.NODE_ENV,
	tracesSampleRate: 1.0
});

/**
 * Auth handler that runs on every request.
 * Validates session and loads user + memberships into locals.
 */
const authHandle: Handle = async ({ event, resolve }) => {
	const sessionToken = event.cookies.get('session');

	if (sessionToken) {
		const session = await validateSession(sessionToken);

		if (session) {
			event.locals.user = session.user;

			// Set Sentry user context
			Sentry.setUser({
				id: session.user.id,
				email: session.user.email,
				username: session.user.name || undefined
			});

			// Load user's organization memberships
			const memberships = await db.membership.findMany({
				where: { userId: session.user.id },
				include: { organization: true },
			});

			event.locals.memberships = memberships;
		}
	}

	return resolve(event);
};

export const handle = sequence(Sentry.sentryHandle(), authHandle);
export const handleError = Sentry.handleErrorWithSentry();
