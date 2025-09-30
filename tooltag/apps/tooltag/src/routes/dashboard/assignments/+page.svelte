<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	let { data } = $props();

	let assignments = $state<any[]>([]);
	let loading = $state(true);
	let error = $state('');

	let statusFilter = $state('active'); // active | returned | overdue | all
	let currentPage = $state(1);
	let totalPages = $state(1);

	const orgId = $page.url.searchParams.get('org') || '';

	onMount(async () => {
		await loadAssignments();
	});

	async function loadAssignments() {
		loading = true;
		try {
			const params = new URLSearchParams();
			params.set('status', statusFilter);
			params.set('page', currentPage.toString());

			const res = await fetch(`/api/organizations/${orgId}/assignments?${params}`);
			const result = await res.json();

			assignments = result.assignments;
			totalPages = result.pagination.totalPages;
		} catch (err) {
			error = 'Failed to load assignments';
		} finally {
			loading = false;
		}
	}

	function handleFilterChange() {
		currentPage = 1;
		loadAssignments();
	}

	function nextPage() {
		if (currentPage < totalPages) {
			currentPage++;
			loadAssignments();
		}
	}

	function prevPage() {
		if (currentPage > 1) {
			currentPage--;
			loadAssignments();
		}
	}

	function isOverdue(assignment: any): boolean {
		if (!assignment.dueAt || assignment.returnedAt) return false;
		return new Date(assignment.dueAt) < new Date();
	}
</script>

<div class="p-8">
	<div class="mb-6 flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold text-slate-900">Assignments</h1>
			<p class="text-slate-600">Track check-outs and returns</p>
		</div>
	</div>

	{#if error}
		<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
			{error}
		</div>
	{/if}

	<!-- Filters -->
	<div class="card mb-6">
		<div class="flex gap-4">
			<div class="flex-1">
				<label for="status" class="mb-1 block text-sm font-medium text-slate-700">
					Status
				</label>
				<select
					id="status"
					bind:value={statusFilter}
					onchange={handleFilterChange}
					class="input"
				>
					<option value="active">Active Check-Outs</option>
					<option value="returned">Returned</option>
					<option value="overdue">Overdue</option>
					<option value="all">All</option>
				</select>
			</div>
		</div>
	</div>

	<!-- Assignments Table -->
	<div class="card">
		{#if loading}
			<p class="text-slate-600">Loading...</p>
		{:else if assignments.length === 0}
			<div class="py-12 text-center">
				<p class="text-slate-600">No assignments found</p>
			</div>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left text-sm">
					<thead class="border-b border-slate-200 text-xs uppercase text-slate-600">
						<tr>
							<th class="pb-3">Item</th>
							<th class="pb-3">User</th>
							<th class="pb-3">Checked Out</th>
							<th class="pb-3">Due Date</th>
							<th class="pb-3">Returned</th>
							<th class="pb-3">Status</th>
						</tr>
					</thead>
					<tbody class="divide-y divide-slate-100">
						{#each assignments as assignment}
							<tr
								class="cursor-pointer hover:bg-slate-50"
								onclick={() => goto(`/dashboard/inventory/${assignment.item.id}?org=${orgId}`)}
							>
								<td class="py-3">
									<p class="font-medium text-slate-900">{assignment.item.name}</p>
									{#if assignment.item.sku}
										<p class="text-xs text-slate-500">SKU: {assignment.item.sku}</p>
									{/if}
								</td>
								<td class="py-3 text-slate-600">
									{assignment.user.name || assignment.user.email}
								</td>
								<td class="py-3 text-slate-600">
									{new Date(assignment.checkedOutAt).toLocaleDateString()}
								</td>
								<td class="py-3">
									{#if assignment.dueAt}
										<span
											class:text-red-600={isOverdue(assignment)}
											class:font-semibold={isOverdue(assignment)}
										>
											{new Date(assignment.dueAt).toLocaleDateString()}
										</span>
									{:else}
										<span class="text-slate-400">-</span>
									{/if}
								</td>
								<td class="py-3 text-slate-600">
									{#if assignment.returnedAt}
										{new Date(assignment.returnedAt).toLocaleDateString()}
									{:else}
										<span class="text-slate-400">-</span>
									{/if}
								</td>
								<td class="py-3">
									{#if assignment.returnedAt}
										<span
											class="inline-block rounded-full bg-slate-100 px-2 py-1 text-xs font-medium text-slate-700"
										>
											Returned
										</span>
									{:else if isOverdue(assignment)}
										<span
											class="inline-block rounded-full bg-red-100 px-2 py-1 text-xs font-medium text-red-700"
										>
											Overdue
										</span>
									{:else}
										<span
											class="inline-block rounded-full bg-blue-100 px-2 py-1 text-xs font-medium text-blue-700"
										>
											Active
										</span>
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
