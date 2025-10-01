<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import jsQR from 'jsqr';
	import { goto } from '$app/navigation';

	let { onScan }: { onScan?: (code: string) => void } = $props();

	let videoElement: HTMLVideoElement;
	let canvasElement: HTMLCanvasElement;
	let canvas2d: CanvasRenderingContext2D | null = null;
	let stream: MediaStream | null = null;
	let scanning = $state(false);
	let error = $state('');
	let animationFrame: number;

	onMount(() => {
		if (canvasElement) {
			canvas2d = canvasElement.getContext('2d', { willReadFrequently: true });
		}
	});

	onDestroy(() => {
		stopScanning();
	});

	export async function startScanning() {
		scanning = true;
		error = '';

		try {
			stream = await navigator.mediaDevices.getUserMedia({
				video: { facingMode: 'environment' }, // Use back camera on mobile
			});

			if (videoElement) {
				videoElement.srcObject = stream;
				videoElement.setAttribute('playsinline', 'true'); // iOS fix
				await videoElement.play();
				requestAnimationFrame(tick);
			}
		} catch (err: any) {
			error = 'Camera access denied. Please enable camera permissions in your browser settings.';
			scanning = false;
			console.error('Camera error:', err);
		}
	}

	export function stopScanning() {
		scanning = false;
		if (animationFrame) {
			cancelAnimationFrame(animationFrame);
		}
		if (stream) {
			stream.getTracks().forEach((track) => track.stop());
			stream = null;
		}
		if (videoElement) {
			videoElement.srcObject = null;
		}
	}

	function tick() {
		if (!scanning || !videoElement || !canvas2d || !canvasElement) {
			return;
		}

		if (videoElement.readyState === videoElement.HAVE_ENOUGH_DATA) {
			// Set canvas size to video size
			canvasElement.height = videoElement.videoHeight;
			canvasElement.width = videoElement.videoWidth;

			// Draw video frame to canvas
			canvas2d.drawImage(videoElement, 0, 0, canvasElement.width, canvasElement.height);

			// Get image data and scan for QR code
			const imageData = canvas2d.getImageData(0, 0, canvasElement.width, canvasElement.height);
			const code = jsQR(imageData.data, imageData.width, imageData.height, {
				inversionAttempts: 'dontInvert',
			});

			if (code && code.data) {
				// QR code detected!
				handleQRCodeDetected(code.data);
				return; // Stop scanning
			}
		}

		// Continue scanning
		animationFrame = requestAnimationFrame(tick);
	}

	function handleQRCodeDetected(data: string) {
		stopScanning();

		// Extract UID from URL if it's a full ToolTag URL
		let uid = data;
		if (data.includes('/scan/')) {
			const match = data.match(/\/scan\/([^/?]+)/);
			uid = match ? match[1] : data;
		}

		if (onScan) {
			onScan(uid);
		} else {
			// Default behavior: navigate to scan page
			goto(`/scan/${uid}`);
		}
	}
</script>

<div class="qr-scanner">
	{#if error}
		<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
			{error}
		</div>
	{/if}

	<div class="relative overflow-hidden rounded-lg bg-black">
		<!-- Video element (hidden but active) -->
		<!-- svelte-ignore a11y_media_has_caption -->
		<video
			bind:this={videoElement}
			class="w-full"
			style="display: {scanning ? 'block' : 'none'}"
		></video>

		<!-- Canvas for QR detection (hidden) -->
		<canvas bind:this={canvasElement} class="hidden"></canvas>

		{#if scanning}
			<!-- Scanning overlay -->
			<div class="absolute inset-0 flex items-center justify-center">
				<div class="scanning-frame">
					<div class="corner top-left"></div>
					<div class="corner top-right"></div>
					<div class="corner bottom-left"></div>
					<div class="corner bottom-right"></div>
				</div>
			</div>
			<div class="absolute bottom-4 left-0 right-0 text-center">
				<p class="text-sm font-medium text-white drop-shadow-lg">
					Position QR code within the frame
				</p>
			</div>
		{:else}
			<!-- Placeholder when not scanning -->
			<div class="flex aspect-video items-center justify-center bg-slate-800">
				<svg class="h-24 w-24 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"
					/>
				</svg>
			</div>
		{/if}
	</div>
</div>

<style>
	.scanning-frame {
		width: 250px;
		height: 250px;
		position: relative;
	}

	.corner {
		position: absolute;
		width: 40px;
		height: 40px;
		border: 3px solid #10b981;
		filter: drop-shadow(0 0 4px rgba(16, 185, 129, 0.5));
	}

	.top-left {
		top: 0;
		left: 0;
		border-right: none;
		border-bottom: none;
	}

	.top-right {
		top: 0;
		right: 0;
		border-left: none;
		border-bottom: none;
	}

	.bottom-left {
		bottom: 0;
		left: 0;
		border-right: none;
		border-top: none;
	}

	.bottom-right {
		bottom: 0;
		right: 0;
		border-left: none;
		border-top: none;
	}
</style>

