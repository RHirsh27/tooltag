import { sveltekit } from '@sveltejs/kit/vite';
import { sentrySvelteKit } from '@sentry/sveltekit';
import { defineConfig, loadEnv } from 'vite';
import * as dotenv from 'dotenv';

// Load .env file
dotenv.config();

export default defineConfig(({ mode }) => ({
	plugins: [sentrySvelteKit(), sveltekit()],
	// Make .env variables available to the app
	define: {
		'process.env': process.env
	}
}));
