<script lang="ts">
	import { goto } from '$app/navigation';
	import QRScanner from '$lib/components/QRScanner.svelte';

	let scanner: QRScanner;
	let scanning = $state(false);
	let manualCode = $state('');
	let error = $state('');

	function handleStartScanner() {
		scanning = true;
		error = '';
		scanner?.startScanning();
	}

	function handleStopScanner() {
		scanning = false;
		scanner?.stopScanning();
	}

	function handleQRCodeScanned(code: string) {
		scanning = false;
		goto(`/scan/${code}`);
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

				<QRScanner bind:this={scanner} onScan={handleQRCodeScanned} />

				<div class="mt-4">
					{#if !scanning}
						<button onclick={handleStartScanner} class="btn btn-primary w-full">
							<svg class="mr-2 inline-block h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
								<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
							</svg>
							Start QR Scanner
						</button>
						<p class="mt-2 text-center text-xs text-slate-500">
							Point your camera at a QR code to scan automatically
						</p>
					{:else}
						<button onclick={handleStopScanner} class="btn btn-secondary w-full">
							Stop Scanner
						</button>
					{/if}
				</div>
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
