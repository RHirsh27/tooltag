<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';

	let item = $state<any>(null);
	let organization = $state<any>(null);
	let loading = $state(true);
	let error = $state('');

	const uid = $page.params.uid;

	// Check for success messages
	let successMessage = $state('');

	$effect(() => {
		if ($page.url.searchParams.get('checked_out') === 'true') {
			successMessage = 'Item successfully checked out!';
		} else if ($page.url.searchParams.get('checked_in') === 'true') {
			successMessage = 'Item successfully checked in!';
		}
	});

	onMount(async () => {
		await loadTag();
	});

	async function loadTag() {
		loading = true;
		try {
			const res = await fetch(`/api/tags/${uid}`);
			const data = await res.json();

			if (!res.ok) {
				error = data.error || 'Tag not found';
				return;
			}

			item = data.item;
			organization = data.organization;
		} catch (err) {
			error = 'Network error. Please try again.';
		} finally {
			loading = false;
		}
	}

	function getStatusColor(status: string) {
		switch (status) {
			case 'AVAILABLE':
				return 'bg-green-100 text-green-700 border-green-300';
			case 'CHECKED_OUT':
				return 'bg-blue-100 text-blue-700 border-blue-300';
			case 'MAINTENANCE':
				return 'bg-yellow-100 text-yellow-700 border-yellow-300';
			case 'MISSING':
				return 'bg-red-100 text-red-700 border-red-300';
			case 'RETIRED':
				return 'bg-slate-100 text-slate-700 border-slate-300';
			default:
				return 'bg-slate-100 text-slate-700 border-slate-300';
		}
	}
</script>

<div class="flex min-h-screen flex-col bg-slate-50">
	<!-- Header -->
	<div class="border-b border-slate-200 bg-white px-4 py-4">
		<div class="mx-auto max-w-2xl">
			<h1 class="text-xl font-bold text-primary-600">ToolTag</h1>
			{#if organization}
				<p class="text-sm text-slate-600">{organization.name}</p>
			{/if}
		</div>
	</div>

	<!-- Content -->
	<div class="flex-1 px-4 py-6">
		<div class="mx-auto max-w-2xl">
			{#if successMessage}
				<div class="mb-4 rounded-lg bg-green-50 p-3 text-sm text-green-700">
					{successMessage}
				</div>
			{/if}

			{#if loading}
				<div class="text-center">
					<p class="text-slate-600">Loading...</p>
				</div>
			{:else if error}
				<div class="card">
					<div class="text-center">
						<svg
							class="mx-auto h-16 w-16 text-slate-400"
							fill="none"
							stroke="currentColor"
							viewBox="0 0 24 24"
						>
							<path
								stroke-linecap="round"
								stroke-linejoin="round"
								stroke-width="2"
								d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
							/>
						</svg>
						<h2 class="mt-4 text-xl font-semibold text-slate-900">Tag Not Found</h2>
						<p class="mt-2 text-slate-600">{error}</p>
					</div>
				</div>
			{:else if item}
				<!-- Item Details -->
				<div class="card mb-4">
					<div class="mb-4 flex items-start justify-between">
						<div class="flex-1">
							<h2 class="text-2xl font-bold text-slate-900">{item.name}</h2>
							{#if item.description}
								<p class="mt-2 text-slate-600">{item.description}</p>
							{/if}
						</div>
						<span
							class="ml-4 rounded-full border-2 px-3 py-1 text-sm font-semibold {getStatusColor(
								item.status
							)}"
						>
							{item.status.replace('_', ' ')}
						</span>
					</div>

					<dl class="grid gap-3 border-t border-slate-200 pt-4 sm:grid-cols-2">
						{#if item.sku}
							<div>
								<dt class="text-sm font-medium text-slate-600">SKU</dt>
								<dd class="mt-1 text-slate-900">{item.sku}</dd>
							</div>
						{/if}
						{#if item.serialNumber}
							<div>
								<dt class="text-sm font-medium text-slate-600">Serial Number</dt>
								<dd class="mt-1 text-slate-900">{item.serialNumber}</dd>
							</div>
						{/if}
						{#if item.location}
							<div>
								<dt class="text-sm font-medium text-slate-600">Location</dt>
								<dd class="mt-1 text-slate-900">{item.location.name}</dd>
							</div>
						{/if}
						{#if item.category}
							<div>
								<dt class="text-sm font-medium text-slate-600">Category</dt>
								<dd class="mt-1 text-slate-900">{item.category.name}</dd>
							</div>
						{/if}
					</dl>
				</div>

				<!-- Current Assignment -->
				{#if item.assignments && item.assignments.length > 0}
					<div class="card mb-4 border-l-4 border-blue-500">
						<h3 class="mb-2 font-semibold text-slate-900">Currently Checked Out</h3>
						<p class="text-slate-600">
							Assigned to: {item.assignments[0].user.name || item.assignments[0].user.email}
						</p>
						<p class="text-sm text-slate-500">
							Since: {new Date(item.assignments[0].checkedOutAt).toLocaleDateString()}
						</p>
					</div>
				{/if}

				<!-- Actions -->
				<div class="card">
					<h3 class="mb-4 font-semibold text-slate-900">Quick Actions</h3>
					<div class="space-y-2">
						{#if item.status === 'AVAILABLE'}
							<a
								href="/scan/{uid}/checkout"
								class="block w-full rounded-lg bg-primary-600 px-4 py-3 text-center font-medium text-white hover:bg-primary-700"
							>
								Check Out
							</a>
						{:else if item.status === 'CHECKED_OUT'}
							<a
								href="/scan/{uid}/checkin"
								class="block w-full rounded-lg bg-green-600 px-4 py-3 text-center font-medium text-white hover:bg-green-700"
							>
								Check In
							</a>
						{/if}
						<a
							href="/dashboard/inventory/{item.id}?org={organization.id}"
							class="block w-full rounded-lg border border-slate-300 bg-white px-4 py-3 text-center font-medium text-slate-700 hover:bg-slate-50"
						>
							View Full Details
						</a>
					</div>
				</div>

				<!-- Notes -->
				{#if item.notes}
					<div class="card mt-4">
						<h3 class="mb-2 font-semibold text-slate-900">Notes</h3>
						<p class="text-slate-600">{item.notes}</p>
					</div>
				{/if}
			{/if}
		</div>
	</div>

	<!-- Footer -->
	<div class="border-t border-slate-200 bg-white px-4 py-4 text-center">
		<p class="text-sm text-slate-500">
			Powered by <a href="/" class="font-medium text-primary-600 hover:text-primary-700"
				>ToolTag</a
			>
		</p>
	</div>
</div>
