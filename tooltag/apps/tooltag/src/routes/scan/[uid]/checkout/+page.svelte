<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';

	let item = $state<any>(null);
	let organization = $state<any>(null);
	let members = $state<any[]>([]);
	let loading = $state(true);
	let submitting = $state(false);
	let error = $state('');

	let form = $state({
		userId: '',
		dueAt: '',
		notes: '',
	});

	const uid = $page.params.uid;

	onMount(async () => {
		await Promise.all([loadTag(), loadMembers()]);
	});

	async function loadTag() {
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
			error = 'Network error';
		} finally {
			loading = false;
		}
	}

	async function loadMembers() {
		if (!organization?.id) return;

		try {
			const res = await fetch(`/api/organizations/${organization.id}/members`);
			const data = await res.json();
			members = data.members || [];
		} catch (err) {
			console.error('Failed to load members');
		}
	}

	async function handleSubmit() {
		if (!form.userId) {
			error = 'Please select a user';
			return;
		}

		submitting = true;
		error = '';

		try {
			const res = await fetch(`/api/organizations/${organization.id}/assignments`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					itemId: item.id,
					userId: form.userId,
					dueAt: form.dueAt || undefined,
					notes: form.notes || undefined,
				}),
			});

			const data = await res.json();

			if (!res.ok) {
				error = data.error || 'Check-out failed';
				return;
			}

			// Redirect to scan page with success
			goto(`/scan/${uid}?checked_out=true`);
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
			<h1 class="text-xl font-bold text-primary-600">Check Out Item</h1>
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
			{:else if item}
				<!-- Item Summary -->
				<div class="card mb-4">
					<h2 class="text-lg font-semibold text-slate-900">{item.name}</h2>
					{#if item.sku}
						<p class="text-sm text-slate-600">SKU: {item.sku}</p>
					{/if}
				</div>

				{#if error}
					<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
						{error}
					</div>
				{/if}

				<!-- Check-out Form -->
				<div class="card">
					<h3 class="mb-4 font-semibold text-slate-900">Check-Out Details</h3>
					<form onsubmit={handleSubmit} class="space-y-4">
						<div>
							<label for="user" class="mb-1 block text-sm font-medium text-slate-700">
								Assign To <span class="text-red-500">*</span>
							</label>
							<select id="user" bind:value={form.userId} required class="input">
								<option value="">Select a user...</option>
								{#each members as member}
									<option value={member.userId}>
										{member.user.name || member.user.email}
									</option>
								{/each}
							</select>
						</div>

						<div>
							<label for="dueAt" class="mb-1 block text-sm font-medium text-slate-700">
								Due Date (Optional)
							</label>
							<input id="dueAt" type="datetime-local" bind:value={form.dueAt} class="input" />
						</div>

						<div>
							<label for="notes" class="mb-1 block text-sm font-medium text-slate-700">
								Notes (Optional)
							</label>
							<textarea
								id="notes"
								bind:value={form.notes}
								rows="3"
								placeholder="Add any notes about this check-out..."
								class="input"
							></textarea>
						</div>

						<div class="flex gap-2">
							<button type="submit" disabled={submitting} class="btn btn-primary flex-1">
								{submitting ? 'Checking Out...' : 'Check Out'}
							</button>
							<a href="/scan/{uid}" class="btn btn-secondary"> Cancel </a>
						</div>
					</form>
				</div>
			{/if}
		</div>
	</div>
</div>
