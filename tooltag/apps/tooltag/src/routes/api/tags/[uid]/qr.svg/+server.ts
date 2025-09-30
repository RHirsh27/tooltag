import QRCode from 'qrcode';
import { env } from '@tooltag/config/env';
import type { RequestHandler } from './$types';

/**
 * GET /api/tags/[uid]/qr.svg
 * Generate QR code SVG for a tag (PUBLIC - no auth required)
 */
export const GET: RequestHandler = async ({ params, url }) => {
	try {
		const { uid } = params;

		// Generate scan URL (points to public scan page)
		const scanUrl = `${env.PUBLIC_APP_URL}/scan/${uid}`;

		// Generate QR code as SVG
		const svg = await QRCode.toString(scanUrl, {
			type: 'svg',
			width: 300,
			margin: 2,
			color: {
				dark: '#000000',
				light: '#ffffff',
			},
		});

		return new Response(svg, {
			headers: {
				'Content-Type': 'image/svg+xml',
				'Cache-Control': 'public, max-age=31536000, immutable', // Cache for 1 year
			},
		});
	} catch (error) {
		console.error('Generate QR error:', error);
		return new Response('QR generation failed', { status: 500 });
	}
};
