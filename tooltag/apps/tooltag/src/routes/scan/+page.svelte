<script lang="ts">
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	let scanning = $state(false);
	let manualCode = $state('');
	let error = $state('');
	let stream: MediaStream | null = null;
	let videoElement: HTMLVideoElement;

	onMount(() => {
		return () => {
			stopCamera();
		};
	});

	async function startCamera() {
		scanning = true;
		error = '';

		try {
			stream = await navigator.mediaDevices.getUserMedia({
				video: { facingMode: 'environment' },
			});

			if (videoElement) {
				videoElement.srcObject = stream;
			}
		} catch (err: any) {
			error = 'Camera access denied. Please enable camera permissions.';
			scanning = false;
		}
	}

	function stopCamera() {
		if (stream) {
			stream.getTracks().forEach((track) => track.stop());
			stream = null;
		}
		scanning = false;
	}

	function handleManualScan() {
		if (!manualCode.trim()) {
			error = 'Please enter a tag code';
			return;
		}

		// Extract UID from full URL or use as-is
		let uid = manualCode.trim();
		if (uid.includes('/scan/')) {
			uid = uid.split('/scan/')[1].split('?')[0];
		}

		goto(`/scan/${uid}`);
	}
</script>

<svelte:head>
	<title>Scan Tag - ToolTag</title>
</svelte:head>

<div class="flex min-h-screen flex-col bg-slate-50">
	<!-- Header -->
	<div class="border-b border-slate-200 bg-white px-4 py-4">
		<div class="mx-auto max-w-2xl">
			<h1 class="text-xl font-bold text-primary-600">ToolTag Scanner</h1>
			<p class="text-sm text-slate-600">Scan or enter a tag code</p>
		</div>
	</div>

	<!-- Content -->
	<div class="flex-1 px-4 py-6">
		<div class="mx-auto max-w-2xl">
			{#if error}
				<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
					{error}
				</div>
			{/if}

			<!-- Camera Scanner -->
			<div class="card mb-6">
				<h2 class="mb-4 text-lg font-semibold text-slate-900">Camera Scanner</h2>

				{#if !scanning}
					<button onclick={startCamera} class="btn btn-primary w-full">
						Start Camera Scanner
					</button>
					<p class="mt-2 text-center text-xs text-slate-500">
						Note: QR code scanning requires additional library (coming soon)
					</p>
				{:else}
					<div class="mb-4">
						<!-- svelte-ignore a11y_media_has_caption -->
						<video
							bind:this={videoElement}
							autoplay
							playsinline
							class="w-full rounded-lg bg-black"
						></video>
					</div>
					<button onclick={stopCamera} class="btn btn-secondary w-full"> Stop Scanner </button>
				{/if}
			</div>

			<!-- Manual Entry -->
			<div class="card">
				<h2 class="mb-4 text-lg font-semibold text-slate-900">Manual Entry</h2>
				<form onsubmit={handleManualScan} class="space-y-4">
					<div>
						<label for="code" class="mb-1 block text-sm font-medium text-slate-700">
							Tag Code or URL
						</label>
						<input
							id="code"
							type="text"
							bind:value={manualCode}
							placeholder="Enter tag code or scan URL"
							class="input"
						/>
						<p class="mt-1 text-xs text-slate-500">
							Example: ABC123XYZ or https://tooltag.app/scan/ABC123XYZ
						</p>
					</div>
					<button type="submit" class="btn btn-primary w-full"> Go to Item </button>
				</form>
			</div>

			<!-- Help -->
			<div class="mt-6 rounded-lg border border-slate-200 bg-slate-50 p-4">
				<h3 class="mb-2 text-sm font-semibold text-slate-900">How to Use</h3>
				<ul class="space-y-1 text-sm text-slate-600">
					<li>• Scan a QR code using your device camera</li>
					<li>• Or manually enter the tag code from the label</li>
					<li>• View item details and perform quick actions</li>
				</ul>
			</div>
		</div>
	</div>

	<!-- Footer -->
	<div class="border-t border-slate-200 bg-white px-4 py-4 text-center">
		<a href="/dashboard" class="text-sm text-primary-600 hover:text-primary-700">
			Back to Dashboard
		</a>
	</div>
</div>
