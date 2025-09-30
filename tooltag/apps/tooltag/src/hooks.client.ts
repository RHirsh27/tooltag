import * as Sentry from '@sentry/sveltekit';

/**
 * Client-side Sentry initialization
 */
Sentry.init({
	dsn: import.meta.env.PUBLIC_SENTRY_DSN,
	enabled: import.meta.env.PROD,
	environment: import.meta.env.MODE,
	tracesSampleRate: 1.0,

	// Performance monitoring
	replaysSessionSampleRate: 0.1,
	replaysOnErrorSampleRate: 1.0
});

export const handleError = Sentry.handleErrorWithSentry();
