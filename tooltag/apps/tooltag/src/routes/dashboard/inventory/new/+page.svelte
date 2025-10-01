<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import FileUpload from '$lib/components/FileUpload.svelte';

	let { data } = $props();

	let locations = $state<any[]>([]);
	let categories = $state<any[]>([]);
	let loading = $state(false);
	let error = $state('');

	let form = $state({
		name: '',
		description: '',
		sku: '',
		serialNumber: '',
		status: 'AVAILABLE',
		locationId: '',
		categoryId: '',
		imageUrl: '',
		notes: '',
	});

	const orgId = $page.url.searchParams.get('org') || '';

	onMount(async () => {
		await Promise.all([loadLocations(), loadCategories()]);
	});

	async function loadLocations() {
		try {
			const res = await fetch(`/api/organizations/${orgId}/locations`);
			const result = await res.json();
			locations = result.locations;
		} catch (err) {
			console.error('Failed to load locations');
		}
	}

	async function loadCategories() {
		try {
			const res = await fetch(`/api/organizations/${orgId}/categories`);
			const result = await res.json();
			categories = result.categories;
		} catch (err) {
			console.error('Failed to load categories');
		}
	}

	async function handleSubmit() {
		loading = true;
		error = '';

		try {
			const payload = {
				...form,
				locationId: form.locationId || undefined,
				categoryId: form.categoryId || undefined,
			};

			const res = await fetch(`/api/organizations/${orgId}/items`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify(payload),
			});

			const result = await res.json();

			if (!res.ok) {
				error = result.error || 'Failed to create item';
				return;
			}

			goto(`/dashboard/inventory/${result.item.id}?org=${orgId}`);
		} catch (err) {
			error = 'Network error. Please try again.';
		} finally {
			loading = false;
		}
	}
</script>

<div class="p-8">
	<div class="mb-6">
		<h1 class="text-3xl font-bold text-slate-900">Add Item</h1>
		<p class="text-slate-600">Create a new inventory item</p>
	</div>

	{#if error}
		<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
			{error}
		</div>
	{/if}

	<div class="card max-w-2xl">
		<form onsubmit={handleSubmit} class="space-y-4">
			<div>
				<label for="name" class="mb-1 block text-sm font-medium text-slate-700">
					Name <span class="text-red-500">*</span>
				</label>
				<input id="name" type="text" bind:value={form.name} required class="input" />
			</div>

			<div>
				<label for="description" class="mb-1 block text-sm font-medium text-slate-700">
					Description
				</label>
				<textarea
					id="description"
					bind:value={form.description}
					rows="3"
					class="input"
				></textarea>
			</div>

			<div class="grid gap-4 md:grid-cols-2">
				<div>
					<label for="sku" class="mb-1 block text-sm font-medium text-slate-700"> SKU </label>
					<input id="sku" type="text" bind:value={form.sku} class="input" />
				</div>
				<div>
					<label for="serial" class="mb-1 block text-sm font-medium text-slate-700">
						Serial Number
					</label>
					<input id="serial" type="text" bind:value={form.serialNumber} class="input" />
				</div>
			</div>

			<div class="grid gap-4 md:grid-cols-3">
				<div>
					<label for="status" class="mb-1 block text-sm font-medium text-slate-700">
						Status
					</label>
					<select id="status" bind:value={form.status} class="input">
						<option value="AVAILABLE">Available</option>
						<option value="CHECKED_OUT">Checked Out</option>
						<option value="MAINTENANCE">Maintenance</option>
						<option value="MISSING">Missing</option>
						<option value="RETIRED">Retired</option>
					</select>
				</div>
				<div>
					<label for="location" class="mb-1 block text-sm font-medium text-slate-700">
						Location
					</label>
					<select id="location" bind:value={form.locationId} class="input">
						<option value="">None</option>
						{#each locations as location}
							<option value={location.id}>{location.name}</option>
						{/each}
					</select>
				</div>
				<div>
					<label for="category" class="mb-1 block text-sm font-medium text-slate-700">
						Category
					</label>
					<select id="category" bind:value={form.categoryId} class="input">
						<option value="">None</option>
						{#each categories as category}
							<option value={category.id}>{category.name}</option>
						{/each}
					</select>
				</div>
			</div>

			<div>
				<FileUpload
					currentImage={form.imageUrl}
					onUpload={(url) => {
						form.imageUrl = url;
					}}
				/>
			</div>

			<div>
				<label for="notes" class="mb-1 block text-sm font-medium text-slate-700"> Notes </label>
				<textarea id="notes" bind:value={form.notes} rows="3" class="input"></textarea>
			</div>

			<div class="flex gap-2">
				<button type="submit" disabled={loading} class="btn btn-primary">
					{loading ? 'Creating...' : 'Create Item'}
				</button>
				<a href="/dashboard/inventory?org={orgId}" class="btn btn-secondary"> Cancel </a>
			</div>
		</form>
	</div>
</div>
