<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	let item = $state<any>(null);
	let organization = $state<any>(null);
	let activeAssignment = $state<any>(null);
	let loading = $state(true);
	let submitting = $state(false);
	let error = $state('');

	let form = $state({
		notes: '',
	});

	const uid = $page.params.uid;

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

			// Get active assignment
			if (item.assignments && item.assignments.length > 0) {
				activeAssignment = item.assignments[0];
			} else {
				error = 'No active check-out found';
			}
		} catch (err) {
			error = 'Network error';
		} finally {
			loading = false;
		}
	}

	async function handleSubmit() {
		if (!activeAssignment) {
			error = 'No active assignment';
			return;
		}

		submitting = true;
		error = '';

		try {
			const res = await fetch(
				`/api/organizations/${organization.id}/assignments/${activeAssignment.id}/checkin`,
				{
					method: 'PATCH',
					headers: { 'Content-Type': 'application/json' },
					body: JSON.stringify({
						notes: form.notes || undefined,
					}),
				}
			);

			const data = await res.json();

			if (!res.ok) {
				error = data.error || 'Check-in failed';
				return;
			}

			// Redirect to scan page with success
			goto(`/scan/${uid}?checked_in=true`);
		} catch (err) {
			error = 'Network error. Please try again.';
		} finally {
			submitting = false;
		}
	}
</script>

<div class="flex min-h-screen flex-col bg-slate-50">
	<!-- Header -->
	<div class="border-b border-slate-200 bg-white px-4 py-4">
		<div class="mx-auto max-w-2xl">
			<h1 class="text-xl font-bold text-primary-600">Check In Item</h1>
			{#if organization}
				<p class="text-sm text-slate-600">{organization.name}</p>
			{/if}
		</div>
	</div>

	<!-- Content -->
	<div class="flex-1 px-4 py-6">
		<div class="mx-auto max-w-2xl">
			{#if loading}
				<p class="text-slate-600">Loading...</p>
			{:else if error && !item}
				<div class="card">
					<p class="text-red-600">{error}</p>
					<a href="/scan/{uid}" class="mt-4 text-primary-600 hover:underline">Back</a>
				</div>
			{:else if item && activeAssignment}
				<!-- Item Summary -->
				<div class="card mb-4">
					<h2 class="text-lg font-semibold text-slate-900">{item.name}</h2>
					{#if item.sku}
						<p class="text-sm text-slate-600">SKU: {item.sku}</p>
					{/if}
				</div>

				<!-- Assignment Info -->
				<div class="card mb-4 border-l-4 border-blue-500">
					<h3 class="mb-2 font-semibold text-slate-900">Current Assignment</h3>
					<p class="text-slate-600">
						Checked out to: {activeAssignment.user.name || activeAssignment.user.email}
					</p>
					<p class="text-sm text-slate-500">
						Since: {new Date(activeAssignment.checkedOutAt).toLocaleDateString()}
					</p>
					{#if activeAssignment.dueAt}
						<p class="text-sm text-slate-500">
							Due: {new Date(activeAssignment.dueAt).toLocaleDateString()}
							{#if new Date(activeAssignment.dueAt) < new Date()}
								<span class="font-semibold text-red-600">(Overdue)</span>
							{/if}
						</p>
					{/if}
				</div>

				{#if error}
					<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
						{error}
					</div>
				{/if}

				<!-- Check-in Form -->
				<div class="card">
					<h3 class="mb-4 font-semibold text-slate-900">Check-In Details</h3>
					<form onsubmit={handleSubmit} class="space-y-4">
						<div>
							<label for="notes" class="mb-1 block text-sm font-medium text-slate-700">
								Return Notes (Optional)
							</label>
							<textarea
								id="notes"
								bind:value={form.notes}
								rows="3"
								placeholder="Add any notes about the item condition or return..."
								class="input"
							></textarea>
						</div>

						<div class="flex gap-2">
							<button type="submit" disabled={submitting} class="btn btn-primary flex-1">
								{submitting ? 'Checking In...' : 'Check In'}
							</button>
							<a href="/scan/{uid}" class="btn btn-secondary"> Cancel </a>
						</div>
					</form>
				</div>
			{:else}
				<div class="card">
					<p class="text-slate-600">No active check-out found</p>
					<a href="/scan/{uid}" class="mt-4 text-primary-600 hover:underline">Back</a>
				</div>
			{/if}
		</div>
	</div>
</div>
