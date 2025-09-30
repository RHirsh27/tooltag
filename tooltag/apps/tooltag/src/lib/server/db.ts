import { PrismaClient } from '@prisma/client';
import { env } from '@tooltag/config/env';

/**
 * Prisma Client singleton for connection pooling.
 * Prevents too many connections in development hot-reload.
 */
declare global {
	// eslint-disable-next-line no-var
	var __prisma: PrismaClient | undefined;
}

export const db = globalThis.__prisma || new PrismaClient({
	log: env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
});

if (env.NODE_ENV !== 'production') {
	globalThis.__prisma = db;
}
