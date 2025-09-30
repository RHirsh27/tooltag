<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	let { data } = $props();

	let items = $state<any[]>([]);
	let locations = $state<any[]>([]);
	let categories = $state<any[]>([]);
	let loading = $state(true);
	let error = $state('');

	// Filters
	let search = $state('');
	let statusFilter = $state('');
	let locationFilter = $state('');
	let categoryFilter = $state('');
	let currentPage = $state(1);
	let totalPages = $state(1);

	const orgId = $page.url.searchParams.get('org') || '';
	const canManage = data.currentRole !== 'TECH';

	let fileInput: HTMLInputElement;
	let importing = $state(false);

	onMount(async () => {
		await Promise.all([loadItems(), loadLocations(), loadCategories()]);
	});

	async function loadItems() {
		loading = true;
		try {
			const params = new URLSearchParams();
			if (search) params.set('search', search);
			if (statusFilter) params.set('status', statusFilter);
			if (locationFilter) params.set('locationId', locationFilter);
			if (categoryFilter) params.set('categoryId', categoryFilter);
			params.set('page', currentPage.toString());

			const res = await fetch(`/api/organizations/${orgId}/items?${params}`);
			const result = await res.json();

			items = result.items;
			totalPages = result.pagination.totalPages;
		} catch (err) {
			error = 'Failed to load items';
		} finally {
			loading = false;
		}
	}

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

	function handleSearch() {
		currentPage = 1;
		loadItems();
	}

	function handleFilterChange() {
		currentPage = 1;
		loadItems();
	}

	function nextPage() {
		if (currentPage < totalPages) {
			currentPage++;
			loadItems();
		}
	}

	function prevPage() {
		if (currentPage > 1) {
			currentPage--;
			loadItems();
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

	async function handleExport() {
		window.open(`/api/organizations/${orgId}/items/export`, '_blank');
	}

	function triggerImport() {
		fileInput.click();
	}

	async function handleImport(e: Event) {
		const target = e.target as HTMLInputElement;
		const file = target.files?.[0];
		if (!file) return;

		importing = true;
		error = '';

		try {
			const formData = new FormData();
			formData.append('file', file);

			const res = await fetch(`/api/organizations/${orgId}/items/import`, {
				method: 'POST',
				body: formData,
			});

			const result = await res.json();

			if (!res.ok) {
				error = result.error || 'Import failed';
				return;
			}

			alert(`Imported ${result.imported} items` + (result.errors ? `\n\nErrors:\n${result.errors.join('\n')}` : ''));
			await loadItems();
		} catch (err) {
			error = 'Network error during import';
		} finally {
			importing = false;
			target.value = ''; // Reset input
		}
	}
</script>

<div class="p-8">
	<div class="mb-6 flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold text-slate-900">Inventory</h1>
			<p class="text-slate-600">{items.length} items</p>
		</div>
		{#if canManage}
			<div class="flex gap-2">
				<a href="/dashboard/inventory/new?org={orgId}" class="btn btn-primary"> Add Item </a>
				<button onclick={triggerImport} disabled={importing} class="btn btn-secondary">
					{importing ? 'Importing...' : 'Import CSV'}
				</button>
				<input
					type="file"
					accept=".csv"
					bind:this={fileInput}
					onchange={handleImport}
					class="hidden"
				/>
				<button onclick={handleExport} class="btn btn-secondary">Export CSV</button>
			</div>
		{/if}
	</div>

	{#if error}
		<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
			{error}
		</div>
	{/if}

	<!-- Filters -->
	<div class="card mb-6">
		<div class="grid gap-4 md:grid-cols-4">
			<div>
				<label for="search" class="mb-1 block text-sm font-medium text-slate-700">
					Search
				</label>
				<input
					id="search"
					type="text"
					bind:value={search}
					oninput={handleSearch}
					placeholder="Name, SKU, Serial..."
					class="input"
				/>
			</div>
			<div>
				<label for="status" class="mb-1 block text-sm font-medium text-slate-700">
					Status
				</label>
				<select
					id="status"
					bind:value={statusFilter}
					onchange={handleFilterChange}
					class="input"
				>
					<option value="">All</option>
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
				<select
					id="location"
					bind:value={locationFilter}
					onchange={handleFilterChange}
					class="input"
				>
					<option value="">All</option>
					{#each locations as location}
						<option value={location.id}>{location.name}</option>
					{/each}
				</select>
			</div>
			<div>
				<label for="category" class="mb-1 block text-sm font-medium text-slate-700">
					Category
				</label>
				<select
					id="category"
					bind:value={categoryFilter}
					onchange={handleFilterChange}
					class="input"
				>
					<option value="">All</option>
					{#each categories as category}
						<option value={category.id}>{category.name}</option>
					{/each}
				</select>
			</div>
		</div>
	</div>

	<!-- Items Table -->
	<div class="card">
		{#if loading}
			<p class="text-slate-600">Loading...</p>
		{:else if items.length === 0}
			<div class="py-12 text-center">
				<p class="text-slate-600">No items found</p>
				{#if canManage}
					<a href="/dashboard/inventory/new?org={orgId}" class="btn btn-primary mt-4">
						Add Your First Item
					</a>
				{/if}
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left text-sm">
					<thead class="border-b border-slate-200 text-xs uppercase text-slate-600">
						<tr>
							<th class="pb-3">Name</th>
							<th class="pb-3">SKU</th>
							<th class="pb-3">Location</th>
							<th class="pb-3">Category</th>
							<th class="pb-3">Status</th>
							<th class="pb-3">Tags</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-slate-100">
						{#each items as item}
							<tr
								class="cursor-pointer hover:bg-slate-50"
								onclick={() => goto(`/dashboard/inventory/${item.id}?org=${orgId}`)}
							>
								<td class="py-3 font-medium text-slate-900">{item.name}</td>
								<td class="py-3 text-slate-600">{item.sku || '-'}</td>
								<td class="py-3 text-slate-600">{item.location?.name || '-'}</td>
								<td class="py-3 text-slate-600">{item.category?.name || '-'}</td>
								<td class="py-3">
									<span
										class="inline-block rounded-full px-2 py-1 text-xs font-medium {getStatusColor(
											item.status
										)}"
									>
										{item.status.replace('_', ' ')}
									</span>
								</td>
								<td class="py-3 text-slate-600">{item.tags.length} tag(s)</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

			<!-- Pagination -->
			{#if totalPages > 1}
				<div class="mt-4 flex items-center justify-between border-t border-slate-200 pt-4">
					<p class="text-sm text-slate-600">
						Page {currentPage} of {totalPages}
					</p>
					<div class="flex gap-2">
						<button
							onclick={prevPage}
							disabled={currentPage === 1}
							class="btn btn-secondary disabled:opacity-50"
						>
							Previous
						</button>
						<button
							onclick={nextPage}
							disabled={currentPage === totalPages}
							class="btn btn-secondary disabled:opacity-50"
						>
							Next
						</button>
					</div>
				</div>
			{/if}
		{/if}
	</div>
</div>
