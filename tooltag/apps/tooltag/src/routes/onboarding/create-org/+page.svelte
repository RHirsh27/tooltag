<script lang="ts">
	import { goto } from '$app/navigation';

	let name = $state('');
	let slug = $state('');
	let loading = $state(false);
	let error = $state('');

	// Auto-generate slug from name
	function handleNameInput() {
		if (!slug) {
			slug = name
				.toLowerCase()
				.replace(/[^a-z0-9]+/g, '-')
				.replace(/^-|-$/g, '');
		}
	}

	async function handleCreate() {
		loading = true;
		error = '';

		try {
			const res = await fetch('/api/organizations', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ name, slug }),
			});

			const data = await res.json();

			if (!res.ok) {
				error = data.error || 'Failed to create organization';
				return;
			}

			// Redirect to dashboard
			goto(`/dashboard?org=${data.organization.id}`);
		} catch (err) {
			error = 'Network error. Please try again.';
		} finally {
			loading = false;
		}
	}
</script>

<div class="flex min-h-screen items-center justify-center bg-slate-50 px-4">
	<div class="w-full max-w-md">
		<div class="card">
			<h1 class="mb-2 text-2xl font-bold text-slate-900">Create your organization</h1>
			<p class="mb-6 text-sm text-slate-600">
				Set up your workspace to start tracking equipment
			</p>

			{#if error}
				<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
					{error}
				</div>
			{/if}

			<form onsubmit={handleCreate} class="space-y-4">
				<div>
					<label for="name" class="mb-1 block text-sm font-medium text-slate-700">
						Organization Name
					</label>
					<input
						id="name"
						type="text"
						bind:value={name}
						oninput={handleNameInput}
						required
						class="input"
						placeholder="Acme Construction"
					/>
				</div>

				<div>
					<label for="slug" class="mb-1 block text-sm font-medium text-slate-700">
						URL Slug
					</label>
					<input
						id="slug"
						type="text"
						bind:value={slug}
						required
						pattern="[a-z0-9-]+"
						class="input"
						placeholder="acme-construction"
					/>
					<p class="mt-1 text-xs text-slate-500">
						Lowercase letters, numbers, and hyphens only
					</p>
				</div>

				<button type="submit" disabled={loading} class="btn btn-primary w-full">
					{loading ? 'Creating...' : 'Create organization'}
				</button>
			</form>
		</div>
	</div>
</div>
