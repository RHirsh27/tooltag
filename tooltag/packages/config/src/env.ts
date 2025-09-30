import { z } from 'zod';

/**
 * Shared environment variable schema for ToolTag.
 * Parse on server startup to fail fast if config is invalid.
 */
export const envSchema = z.object({
  // Node
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),

  // Database
  DATABASE_URL: z.string().url(),

  // App
  PUBLIC_APP_URL: z.string().url().default('http://localhost:5173'),

  // Auth (adjust based on chosen provider: lucia, better-auth, etc.)
  AUTH_SECRET: z.string().min(32),

  // Email (optional for MVP, stub for now)
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.coerce.number().optional(),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  SMTP_FROM: z.string().email().optional(),

  // Storage (for photos - can use local FS for MVP)
  STORAGE_TYPE: z.enum(['local', 's3']).default('local'),
  STORAGE_PATH: z.string().default('./uploads'),

  // Observability (optional)
  PUBLIC_SENTRY_DSN: z.string().url().optional(),
  POSTHOG_KEY: z.string().optional(),
  POSTHOG_HOST: z.string().url().optional(),

  // Stripe (optional for MVP)
  STRIPE_SECRET_KEY: z.string().optional(),
  STRIPE_WEBHOOK_SECRET: z.string().optional(),
  STRIPE_PUBLISHABLE_KEY: z.string().optional(),
});

export type Env = z.infer<typeof envSchema>;

/**
 * Parse and validate environment variables.
 * Call this once at app startup (e.g., in hooks.server.ts).
 */
export function validateEnv(): Env {
  const parsed = envSchema.safeParse(process.env);

  if (!parsed.success) {
    console.error('❌ Invalid environment variables:');
    console.error(JSON.stringify(parsed.error.format(), null, 2));
    process.exit(1);
  }

  return parsed.data;
}

/**
 * Type-safe env accessor (call validateEnv first).
 */
export const env = validateEnv();
