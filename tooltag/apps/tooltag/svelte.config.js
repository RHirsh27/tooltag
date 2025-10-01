import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	// Consult https://svelte.dev/docs/kit/integrations
	// for more information about preprocessors
	preprocess: vitePreprocess(),

	kit: {
		// Using Node.js adapter for VPS/Docker deployment
		// For Vercel, use @sveltejs/adapter-vercel instead
		adapter: adapter({
			out: 'build',
			precompress: false,
			envPrefix: ''
		})
	}
};

export default config;
