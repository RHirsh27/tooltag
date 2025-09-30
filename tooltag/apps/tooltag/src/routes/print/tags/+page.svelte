<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';

	let items = $state<any[]>([]);
	let loading = $state(true);
	let error = $state('');

	const orgId = $page.url.searchParams.get('org') || '';
	const itemIds = $page.url.searchParams.get('items')?.split(',') || [];

	onMount(async () => {
		await loadItems();

		// Auto-print after load (optional)
		// setTimeout(() => window.print(), 500);
	});

	async function loadItems() {
		if (itemIds.length === 0) {
			error = 'No items specified';
			loading = false;
			return;
		}

		try {
			// Fetch each item
			const promises = itemIds.map(async (itemId) => {
				const res = await fetch(`/api/organizations/${orgId}/items/${itemId}`);
				if (res.ok) {
					const data = await res.json();
					return data.item;
				}
				return null;
			});

			const results = await Promise.all(promises);
			items = results.filter((item) => item !== null);
		} catch (err) {
			error = 'Failed to load items';
		} finally {
			loading = false;
		}
	}
</script>

<svelte:head>
	<title>Print Tags - ToolTag</title>
	<style>
		@media print {
			body {
				margin: 0;
				padding: 0;
			}
			.no-print {
				display: none !important;
			}
			.tag-page {
				page-break-after: always;
			}
			.tag-page:last-child {
				page-break-after: auto;
			}
		}
	</style>
</svelte:head>

<div class="min-h-screen bg-white">
	{#if loading}
		<div class="flex h-screen items-center justify-center">
			<p class="text-slate-600">Loading...</p>
		</div>
	{:else if error}
		<div class="flex h-screen items-center justify-center">
			<div class="text-center">
				<p class="text-red-600">{error}</p>
				<a href="/dashboard/inventory?org={orgId}" class="mt-4 text-primary-600 hover:underline">
					Back to Inventory
				</a>
			</div>
		</div>
	{:else}
		<!-- Print Controls (hidden when printing) -->
		<div class="no-print fixed right-4 top-4 flex gap-2">
			<button onclick={() => window.print()} class="btn btn-primary"> Print Tags </button>
			<a href="/dashboard/inventory?org={orgId}" class="btn btn-secondary"> Back </a>
		</div>

		<!-- Tag Pages -->
		{#each items as item}
			{#each item.tags as tag}
				<div class="tag-page flex h-screen flex-col items-center justify-center p-8">
					<!-- QR Code -->
					<div class="mb-6">
						<img
							src="/api/tags/{tag.uid}/qr.svg"
							alt="QR Code for {item.name}"
							class="h-64 w-64"
						/>
					</div>

					<!-- Item Info -->
					<div class="text-center">
						<h1 class="mb-2 text-3xl font-bold text-slate-900">{item.name}</h1>
						{#if item.sku}
							<p class="mb-2 text-lg text-slate-600">SKU: {item.sku}</p>
						{/if}
						{#if item.serialNumber}
							<p class="mb-2 text-lg text-slate-600">Serial: {item.serialNumber}</p>
						{/if}
						{#if item.location}
							<p class="mb-4 text-slate-600">Location: {item.location.name}</p>
						{/if}
					</div>

					<!-- Tag UID -->
					<div class="mt-6 rounded-lg border-2 border-slate-300 bg-slate-50 px-6 py-3">
						<p class="font-mono text-sm text-slate-600">{tag.uid}</p>
					</div>

					<!-- Scan URL -->
					<div class="mt-8 text-center">
						<p class="text-xs text-slate-500">
							Scan to view: {window.location.origin}/scan/{tag.uid}
						</p>
					</div>
				</div>
			{/each}
		{/each}
	{/if}
</div>
