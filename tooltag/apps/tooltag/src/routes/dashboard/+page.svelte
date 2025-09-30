<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';

	let { data } = $props();

	let metrics = $state<any>(null);
	let loading = $state(true);

	const orgId = $page.url.searchParams.get('org') || '';

	onMount(async () => {
		await loadMetrics();
	});

	async function loadMetrics() {
		try {
			const res = await fetch(`/api/organizations/${orgId}/metrics`);
			if (res.ok) {
				metrics = await res.json();
			}
		} catch (err) {
			console.error('Failed to load metrics');
		} finally {
			loading = false;
		}
	}
</script>

<div class="p-8">
	<div class="mb-6">
		<h1 class="text-3xl font-bold text-slate-900">Dashboard</h1>
		<p class="text-slate-600">Welcome back, {data.user.name || 'there'}!</p>
	</div>

	{#if loading}
		<p class="text-slate-600">Loading metrics...</p>
	{:else if metrics}
		<div class="grid gap-6 md:grid-cols-3">
			<div class="card">
				<h3 class="mb-2 text-sm font-medium text-slate-600">Total Items</h3>
				<p class="text-3xl font-bold text-slate-900">{metrics.items.total}</p>
				<div class="mt-2 flex gap-4 text-xs text-slate-500">
					<span>{metrics.items.available} available</span>
					<span>{metrics.items.checkedOut} checked out</span>
				</div>
			</div>

			<div class="card">
				<h3 class="mb-2 text-sm font-medium text-slate-600">Active Assignments</h3>
				<p class="text-3xl font-bold text-slate-900">{metrics.assignments.active}</p>
				{#if metrics.assignments.overdue > 0}
					<p class="mt-2 text-xs font-semibold text-red-600">
						{metrics.assignments.overdue} overdue
					</p>
				{:else}
					<p class="mt-2 text-xs text-slate-500">None overdue</p>
				{/if}
			</div>

			<div class="card">
				<h3 class="mb-2 text-sm font-medium text-slate-600">Team Members</h3>
				<p class="text-3xl font-bold text-slate-900">{metrics.members}</p>
				<p class="mt-2 text-xs text-slate-500">In your organization</p>
			</div>
		</div>
	{/if}

	<div class="card mt-6">
		<h2 class="mb-4 text-lg font-semibold text-slate-900">Quick Start</h2>
		<div class="space-y-3">
			<div class="flex items-start gap-3">
				<div class="flex h-6 w-6 items-center justify-center rounded-full bg-primary-100 text-sm font-semibold text-primary-700">
					1
				</div>
				<div>
					<p class="font-medium text-slate-900">Add your first item</p>
					<p class="text-sm text-slate-600">Create inventory items to start tracking</p>
				</div>
			</div>
			<div class="flex items-start gap-3">
				<div class="flex h-6 w-6 items-center justify-center rounded-full bg-slate-200 text-sm font-semibold text-slate-700">
					2
				</div>
				<div>
					<p class="font-medium text-slate-900">Generate QR tags</p>
					<p class="text-sm text-slate-600">Print tags for your equipment</p>
				</div>
			</div>
			<div class="flex items-start gap-3">
				<div class="flex h-6 w-6 items-center justify-center rounded-full bg-slate-200 text-sm font-semibold text-slate-700">
					3
				</div>
				<div>
					<p class="font-medium text-slate-900">Scan and check out</p>
					<p class="text-sm text-slate-600">Use mobile to scan tags and manage assignments</p>
				</div>
			</div>
		</div>
	</div>
</div>
