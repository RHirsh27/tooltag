<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	let { data } = $props();

	let item = $state<any>(null);
	let loading = $state(true);
	let error = $state('');

	const orgId = $page.url.searchParams.get('org') || '';
	const itemId = $page.params.itemId;
	const canManage = data.currentRole !== 'TECH';

	onMount(async () => {
		await loadItem();
	});

	async function loadItem() {
		loading = true;
		try {
			const res = await fetch(`/api/organizations/${orgId}/items/${itemId}`);
			const result = await res.json();

			if (!res.ok) {
				error = result.error || 'Failed to load item';
				return;
			}

			item = result.item;
		} catch (err) {
			error = 'Network error. Please try again.';
		} finally {
			loading = false;
		}
	}

	async function handleDelete() {
		if (!confirm('Delete this item? This action cannot be undone.')) return;

		try {
			const res = await fetch(`/api/organizations/${orgId}/items/${itemId}`, {
				method: 'DELETE',
			});

			if (res.ok) {
				goto(`/dashboard/inventory?org=${orgId}`);
			}
		} catch (err) {
			error = 'Failed to delete item';
		}
	}

	async function generateTag() {
		try {
			const res = await fetch(`/api/organizations/${orgId}/items/${itemId}/tags`, {
				method: 'POST',
			});

			if (res.ok) {
				await loadItem();
			} else {
				error = 'Failed to generate tag';
			}
		} catch (err) {
			error = 'Network error';
		}
	}

	async function deleteTag(tagId: string) {
		if (!confirm('Delete this tag?')) return;

		try {
			const res = await fetch(`/api/organizations/${orgId}/items/${itemId}/tags?tagId=${tagId}`, {
				method: 'DELETE',
			});

			if (res.ok) {
				await loadItem();
			}
		} catch (err) {
			error = 'Failed to delete tag';
		}
	}

	function getStatusColor(status: string) {
		switch (status) {
			case 'AVAILABLE':
				return 'bg-green-100 text-green-700';
			case 'CHECKED_OUT':
				return 'bg-blue-100 text-blue-700';
			case 'MAINTENANCE':
				return 'bg-yellow-100 text-yellow-700';
			case 'MISSING':
				return 'bg-red-100 text-red-700';
			case 'RETIRED':
				return 'bg-slate-100 text-slate-700';
			default:
				return 'bg-slate-100 text-slate-700';
		}
	}
</script>

<div class="p-8">
	{#if loading}
		<p class="text-slate-600">Loading...</p>
	{:else if error}
		<div class="rounded-lg bg-red-50 p-3 text-sm text-red-700">
			{error}
		</div>
	{:else if item}
		<div class="mb-6 flex items-start justify-between">
			<div>
				<h1 class="text-3xl font-bold text-slate-900">{item.name}</h1>
				<span
					class="mt-2 inline-block rounded-full px-3 py-1 text-sm font-medium {getStatusColor(
						item.status
					)}"
				>
					{item.status.replace('_', ' ')}
				</span>
			</div>
			{#if canManage}
				<div class="flex gap-2">
					<a href="/dashboard/inventory/{itemId}/edit?org={orgId}" class="btn btn-secondary">
						Edit
					</a>
					<button onclick={handleDelete} class="btn bg-red-600 text-white hover:bg-red-700">
						Delete
					</button>
				</div>
			{/if}
		</div>

		<div class="grid gap-6 md:grid-cols-2">
			<!-- Details -->
			<div class="card">
				<h2 class="mb-4 text-lg font-semibold text-slate-900">Details</h2>
				<dl class="space-y-3">
					<div>
						<dt class="text-sm font-medium text-slate-600">Description</dt>
						<dd class="mt-1 text-slate-900">{item.description || '-'}</dd>
					</div>
					<div>
						<dt class="text-sm font-medium text-slate-600">SKU</dt>
						<dd class="mt-1 text-slate-900">{item.sku || '-'}</dd>
					</div>
					<div>
						<dt class="text-sm font-medium text-slate-600">Serial Number</dt>
						<dd class="mt-1 text-slate-900">{item.serialNumber || '-'}</dd>
					</div>
					<div>
						<dt class="text-sm font-medium text-slate-600">Location</dt>
						<dd class="mt-1 text-slate-900">{item.location?.name || '-'}</dd>
					</div>
					<div>
						<dt class="text-sm font-medium text-slate-600">Category</dt>
						<dd class="mt-1 text-slate-900">{item.category?.name || '-'}</dd>
					</div>
					{#if item.notes}
						<div>
							<dt class="text-sm font-medium text-slate-600">Notes</dt>
							<dd class="mt-1 text-slate-900">{item.notes}</dd>
						</div>
					{/if}
				</dl>
			</div>

			<!-- QR Tags -->
			<div class="card">
				<h2 class="mb-4 text-lg font-semibold text-slate-900">QR Tags</h2>
				{#if item.tags.length === 0}
					<p class="text-slate-600">No tags generated yet</p>
					{#if canManage}
						<button onclick={generateTag} class="btn btn-primary mt-4">Generate Tag</button>
					{/if}
				{:else}
					<div class="space-y-2">
						{#each item.tags as tag}
							<div class="rounded-lg border border-slate-200 p-3">
								<div class="flex items-start justify-between">
									<div class="flex-1">
										<p class="font-mono text-sm font-medium text-slate-900">{tag.uid}</p>
										<p class="mt-1 text-xs text-slate-500">
											Scan URL: {window.location.origin}/scan/{tag.uid}
										</p>
									</div>
									{#if canManage}
										<button
											onclick={() => deleteTag(tag.id)}
											class="text-sm text-red-600 hover:text-red-700"
										>
											Delete
										</button>
									{/if}
								</div>
								<div class="mt-3 flex gap-2">
									<a
										href="/api/tags/{tag.uid}/qr.svg"
										target="_blank"
										class="text-sm text-primary-600 hover:text-primary-700"
									>
										View QR
									</a>
									<a
										href="/print/tags?items={itemId}&org={orgId}"
										target="_blank"
										class="text-sm text-primary-600 hover:text-primary-700"
									>
										Print Sheet
									</a>
								</div>
							</div>
						{/each}
					</div>
					{#if canManage}
						<button onclick={generateTag} class="btn btn-secondary mt-4">
							Generate Another Tag
						</button>
					{/if}
				{/if}
			</div>
		</div>

		<!-- Assignment History -->
		{#if item.assignments.length > 0}
			<div class="card mt-6">
				<h2 class="mb-4 text-lg font-semibold text-slate-900">Assignment History</h2>
				<div class="space-y-3">
					{#each item.assignments as assignment}
						<div class="rounded-lg border border-slate-200 p-3">
							<div class="flex items-start justify-between">
								<div>
									<p class="font-medium text-slate-900">{assignment.user.name}</p>
									<p class="text-sm text-slate-600">{assignment.user.email}</p>
								</div>
								<span
									class="rounded-full px-2 py-1 text-xs font-medium {assignment.returnedAt
										? 'bg-slate-100 text-slate-700'
										: 'bg-blue-100 text-blue-700'}"
								>
									{assignment.returnedAt ? 'Returned' : 'Active'}
								</span>
							</div>
							<p class="mt-2 text-sm text-slate-600">
								Checked out: {new Date(assignment.checkedOutAt).toLocaleDateString()}
							</p>
							{#if assignment.returnedAt}
								<p class="text-sm text-slate-600">
									Returned: {new Date(assignment.returnedAt).toLocaleDateString()}
								</p>
							{/if}
						</div>
					{/each}
				</div>
			</div>
		{/if}
	{/if}
</div>
