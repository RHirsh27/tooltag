<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';

	let { data } = $props();

	let categories = $state<any[]>([]);
	let loading = $state(true);
	let error = $state('');
	let showForm = $state(false);
	let editingId = $state<string | null>(null);

	let form = $state({
		name: '',
		description: '',
	});

	const orgId = $page.url.searchParams.get('org') || '';
	const canManage = data.currentRole !== 'TECH';

	onMount(async () => {
		await loadCategories();
	});

	async function loadCategories() {
		loading = true;
		try {
			const res = await fetch(`/api/organizations/${orgId}/categories`);
			const result = await res.json();
			categories = result.categories;
		} catch (err) {
			error = 'Failed to load categories';
		} finally {
			loading = false;
		}
	}

	async function handleSubmit() {
		error = '';

		try {
			const url = editingId
				? `/api/organizations/${orgId}/categories?id=${editingId}`
				: `/api/organizations/${orgId}/categories`;

			const res = await fetch(url, {
				method: editingId ? 'PATCH' : 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify(form),
			});

			if (!res.ok) {
				const result = await res.json();
				error = result.error || 'Failed to save';
				return;
			}

			form = { name: '', description: '' };
			showForm = false;
			editingId = null;
			await loadCategories();
		} catch (err) {
			error = 'Network error';
		}
	}

	function startEdit(category: any) {
		form = { name: category.name, description: category.description || '' };
		editingId = category.id;
		showForm = true;
	}

	async function handleDelete(id: string) {
		if (!confirm('Delete this category?')) return;

		try {
			const res = await fetch(`/api/organizations/${orgId}/categories?id=${id}`, {
				method: 'DELETE',
			});

			if (res.ok) {
				await loadCategories();
			}
		} catch (err) {
			error = 'Failed to delete';
		}
	}
</script>

<div class="p-8">
	<div class="mb-6 flex items-center justify-between">
		<h1 class="text-3xl font-bold text-slate-900">Categories</h1>
		{#if canManage}
			<button
				onclick={() => {
					showForm = !showForm;
					if (!showForm) {
						form = { name: '', description: '' };
						editingId = null;
					}
				}}
				class="btn btn-primary"
			>
				{showForm ? 'Cancel' : 'Add Category'}
			</button>
		{/if}
	</div>

	{#if error}
		<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
			{error}
		</div>
	{/if}

	{#if showForm}
		<div class="card mb-6 max-w-2xl">
			<h2 class="mb-4 text-lg font-semibold text-slate-900">
				{editingId ? 'Edit' : 'New'} Category
			</h2>
			<form onsubmit={handleSubmit} class="space-y-4">
				<div>
					<label for="name" class="mb-1 block text-sm font-medium text-slate-700">Name</label>
					<input id="name" type="text" bind:value={form.name} required class="input" />
				</div>
				<div>
					<label for="description" class="mb-1 block text-sm font-medium text-slate-700">
						Description
					</label>
					<textarea id="description" bind:value={form.description} rows="2" class="input"
					></textarea>
				</div>
				<button type="submit" class="btn btn-primary">
					{editingId ? 'Update' : 'Create'}
				</button>
			</form>
		</div>
	{/if}

	<div class="card">
		{#if loading}
			<p class="text-slate-600">Loading...</p>
		{:else if categories.length === 0}
			<p class="text-slate-600">No categories yet</p>
		{:else}
			<div class="space-y-2">
				{#each categories as category}
					<div class="rounded-lg border border-slate-200 p-4">
						<div class="flex items-start justify-between">
							<div class="flex-1">
								<h3 class="font-medium text-slate-900">{category.name}</h3>
								{#if category.description}
									<p class="text-sm text-slate-600">{category.description}</p>
								{/if}
								<p class="mt-1 text-xs text-slate-500">
									{category._count.items} item(s)
								</p>
							</div>
							{#if canManage}
								<div class="flex gap-2">
									<button
										onclick={() => startEdit(category)}
										class="text-sm text-primary-600 hover:text-primary-700"
									>
										Edit
									</button>
									<button
										onclick={() => handleDelete(category.id)}
										class="text-sm text-red-600 hover:text-red-700"
									>
										Delete
									</button>
								</div>
							{/if}
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</div>
</div>
