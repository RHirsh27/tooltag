<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';

	let { data } = $props();

	let logs = $state<any[]>([]);
	let loading = $state(true);
	let error = $state('');

	let actionFilter = $state('');
	let entityFilter = $state('');
	let startDate = $state('');
	let endDate = $state('');
	let currentPage = $state(1);
	let totalPages = $state(1);

	const orgId = $page.url.searchParams.get('org') || '';
	const canExport = data.currentRole !== 'TECH';

	onMount(async () => {
		await loadLogs();
	});

	async function loadLogs() {
		loading = true;
		try {
			const params = new URLSearchParams();
			if (actionFilter) params.set('action', actionFilter);
			if (entityFilter) params.set('entity', entityFilter);
			if (startDate) params.set('startDate', new Date(startDate).toISOString());
			if (endDate) params.set('endDate', new Date(endDate).toISOString());
			params.set('page', currentPage.toString());

			const res = await fetch(`/api/organizations/${orgId}/audit?${params}`);
			const result = await res.json();

			logs = result.logs;
			totalPages = result.pagination.totalPages;
		} catch (err) {
			error = 'Failed to load audit logs';
		} finally {
			loading = false;
		}
	}

	function handleFilterChange() {
		currentPage = 1;
		loadLogs();
	}

	function nextPage() {
		if (currentPage < totalPages) {
			currentPage++;
			loadLogs();
		}
	}

	function prevPage() {
		if (currentPage > 1) {
			currentPage--;
			loadLogs();
		}
	}

	function handleExport() {
		const params = new URLSearchParams();
		if (actionFilter) params.set('action', actionFilter);
		if (entityFilter) params.set('entity', entityFilter);
		if (startDate) params.set('startDate', new Date(startDate).toISOString());
		if (endDate) params.set('endDate', new Date(endDate).toISOString());
		window.open(`/api/organizations/${orgId}/audit/export?${params}`, '_blank');
	}

	function getActionColor(action: string) {
		switch (action) {
			case 'create':
				return 'bg-green-100 text-green-700';
			case 'update':
				return 'bg-blue-100 text-blue-700';
			case 'delete':
				return 'bg-red-100 text-red-700';
			case 'checkout':
				return 'bg-purple-100 text-purple-700';
			case 'checkin':
				return 'bg-slate-100 text-slate-700';
			default:
				return 'bg-slate-100 text-slate-700';
		}
	}
</script>

<div class="p-8">
	<div class="mb-6 flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold text-slate-900">Audit Log</h1>
			<p class="text-slate-600">Track all activity in your organization</p>
		</div>
		{#if canExport}
			<button onclick={handleExport} class="btn btn-secondary">Export CSV</button>
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
				<label for="action" class="mb-1 block text-sm font-medium text-slate-700">
					Action
				</label>
				<select
					id="action"
					bind:value={actionFilter}
					onchange={handleFilterChange}
					class="input"
				>
					<option value="">All Actions</option>
					<option value="create">Create</option>
					<option value="update">Update</option>
					<option value="delete">Delete</option>
					<option value="checkout">Check Out</option>
					<option value="checkin">Check In</option>
				</select>
			</div>
			<div>
				<label for="entity" class="mb-1 block text-sm font-medium text-slate-700">
					Entity
				</label>
				<select
					id="entity"
					bind:value={entityFilter}
					onchange={handleFilterChange}
					class="input"
				>
					<option value="">All Entities</option>
					<option value="Item">Item</option>
					<option value="User">User</option>
					<option value="Organization">Organization</option>
				</select>
			</div>
			<div>
				<label for="startDate" class="mb-1 block text-sm font-medium text-slate-700">
					Start Date
				</label>
				<input
					id="startDate"
					type="date"
					bind:value={startDate}
					onchange={handleFilterChange}
					class="input"
				/>
			</div>
			<div>
				<label for="endDate" class="mb-1 block text-sm font-medium text-slate-700">
					End Date
				</label>
				<input
					id="endDate"
					type="date"
					bind:value={endDate}
					onchange={handleFilterChange}
					class="input"
				/>
			</div>
		</div>
	</div>

	<!-- Audit Log Table -->
	<div class="card">
		{#if loading}
			<p class="text-slate-600">Loading...</p>
		{:else if logs.length === 0}
			<div class="py-12 text-center">
				<p class="text-slate-600">No audit logs found</p>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left text-sm">
					<thead class="border-b border-slate-200 text-xs uppercase text-slate-600">
						<tr>
							<th class="pb-3">Timestamp</th>
							<th class="pb-3">Action</th>
							<th class="pb-3">Entity</th>
							<th class="pb-3">Actor</th>
							<th class="pb-3">Details</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-slate-100">
						{#each logs as log}
							<tr>
								<td class="py-3 text-slate-600">
									{new Date(log.createdAt).toLocaleString()}
								</td>
								<td class="py-3">
									<span
										class="inline-block rounded-full px-2 py-1 text-xs font-medium {getActionColor(
											log.action
										)}"
									>
										{log.action}
									</span>
								</td>
								<td class="py-3 font-medium text-slate-900">
									{log.entity}
									<span class="block text-xs text-slate-500 font-mono">{log.entityId}</span>
								</td>
								<td class="py-3 text-slate-600">
									{log.actor.name || log.actor.email}
								</td>
								<td class="py-3">
									{#if log.diff}
										<details class="cursor-pointer">
											<summary class="text-sm text-primary-600 hover:text-primary-700">
												View
											</summary>
											<pre
												class="mt-2 max-w-md overflow-x-auto rounded bg-slate-50 p-2 text-xs">{JSON.stringify(
													log.diff,
													null,
													2
												)}</pre>
										</details>
									{:else}
										<span class="text-slate-400">-</span>
									{/if}
								</td>
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
