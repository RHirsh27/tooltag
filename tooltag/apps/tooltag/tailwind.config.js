/** @type {import('tailwindcss').Config} */
export default {
	content: ['./src/**/*.{html,js,svelte,ts}'],
	theme: {
		extend: {
			colors: {
				// ToolTag Orange - Primary Brand Accent
				primary: {
					50: '#FFF4ED',
					100: '#FFEAD9',
					200: '#FFAA73',  // Lighter 40%
					300: '#FF8C42',  // Lighter 20%
					400: '#F26A1B',  // ToolTag Orange (Core)
					500: '#F26A1B',  // ToolTag Orange (Core)
					600: '#CC5615',  // Darker 20%
					700: '#993F10',  // Darker 40%
					800: '#662A0B',
					900: '#331507',
				},
				// Iron Black - Primary Background
				iron: {
					50: '#606060',   // Lighter 40%
					100: '#474747',  // Lighter 20%
					200: '#2D2D2D',  // Iron Black (Core)
					300: '#1A1A1A',  // Darker 20%
					400: '#0D0D0D',  // Darker 40%
				},
				// Gunmetal Gray - Secondary Backgrounds
				gunmetal: {
					50: '#6B6B6B',   // Lighter 20%
					100: '#4A4A4A',  // Gunmetal Gray (Core)
					200: '#333333',  // Darker 20%
				},
				// Forge Silver - Icons & Borders
				silver: '#BFBFBF',
				
				// Accent Extensions
				safety: '#FFD23F',    // Safety Yellow
				blueprint: '#1F4E79', // Blueprint Blue
			},
			fontFamily: {
				heading: ['Montserrat', 'sans-serif'],
				body: ['Inter', 'system-ui', 'sans-serif'],
				mono: ['JetBrains Mono', 'monospace'],
			},
		},
	},
	plugins: [],
};
