<script lang="ts">
	import { page } from '$app/stores';
	import { onMount } from 'svelte';

	let { data } = $props();

	let members = $state<any[]>([]);
	let loading = $state(true);
	let error = $state('');

	// Organization settings
	let orgName = $state(data.currentOrg.name);
	let orgSlug = $state(data.currentOrg.slug);
	let saving = $state(false);

	const orgId = $page.url.searchParams.get('org') || '';
	const isOwner = data.currentRole === 'OWNER';

	onMount(async () => {
		await loadMembers();
	});

	async function loadMembers() {
		try {
			const res = await fetch(`/api/organizations/${orgId}/members`);
			const result = await res.json();
			members = result.members;
		} catch (err) {
			error = 'Failed to load members';
		} finally {
			loading = false;
		}
	}

	async function saveOrgSettings() {
		saving = true;
		error = '';

		try {
			const res = await fetch(`/api/organizations/${orgId}`, {
				method: 'PATCH',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ name: orgName, slug: orgSlug }),
			});

			if (!res.ok) {
				const data = await res.json();
				error = data.error || 'Failed to save';
				return;
			}

			window.location.reload();
		} catch (err) {
			error = 'Network error';
		} finally {
			saving = false;
		}
	}

	async function updateMemberRole(userId: string, newRole: string) {
		try {
			const res = await fetch(`/api/organizations/${orgId}/members?userId=${userId}`, {
				method: 'PATCH',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ role: newRole }),
			});

			if (res.ok) {
				await loadMembers();
			}
		} catch (err) {
			error = 'Failed to update role';
		}
	}

	async function removeMember(userId: string) {
		if (!confirm('Remove this member from the organization?')) return;

		try {
			const res = await fetch(`/api/organizations/${orgId}/members?userId=${userId}`, {
				method: 'DELETE',
			});

			if (res.ok) {
				await loadMembers();
			}
		} catch (err) {
			error = 'Failed to remove member';
		}
	}
</script>

<div class="p-8">
	<h1 class="mb-6 text-3xl font-bold text-slate-900">Settings</h1>

	{#if error}
		<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
			{error}
		</div>
	{/if}

	<!-- Organization Settings -->
	{#if data.currentRole !== 'TECH'}
		<div class="card mb-6">
			<h2 class="mb-4 text-lg font-semibold text-slate-900">Organization</h2>
			<div class="space-y-4">
				<div>
					<label for="orgName" class="mb-1 block text-sm font-medium text-slate-700">
						Name
					</label>
					<input
						id="orgName"
						type="text"
						bind:value={orgName}
						disabled={!isOwner}
						class="input"
					/>
				</div>
				<div>
					<label for="orgSlug" class="mb-1 block text-sm font-medium text-slate-700">
						URL Slug
					</label>
					<input
						id="orgSlug"
						type="text"
						bind:value={orgSlug}
						disabled={!isOwner}
						pattern="[a-z0-9-]+"
						class="input"
					/>
				</div>
				{#if isOwner}
					<button onclick={saveOrgSettings} disabled={saving} class="btn btn-primary">
						{saving ? 'Saving...' : 'Save Changes'}
					</button>
				{/if}
			</div>
		</div>
	{/if}

	<!-- Team Members -->
	<div class="card">
		<h2 class="mb-4 text-lg font-semibold text-slate-900">Team Members</h2>

		{#if loading}
			<p class="text-slate-600">Loading...</p>
		{:else if members.length === 0}
			<p class="text-slate-600">No members found</p>
		{:else}
			<div class="overflow-x-auto">
				<table class="w-full text-left text-sm">
					<thead class="border-b border-slate-200 text-xs uppercase text-slate-600">
						<tr>
							<th class="pb-3">Name</th>
							<th class="pb-3">Email</th>
							<th class="pb-3">Role</th>
							{#if isOwner}
								<th class="pb-3">Actions</th>
							{/if}
						</tr>
					</thead>
					<tbody class="divide-y divide-slate-100">
						{#each members as member}
							<tr>
								<td class="py-3">{member.user.name || '-'}</td>
								<td class="py-3">{member.user.email}</td>
								<td class="py-3">
									{#if isOwner && member.userId !== data.user.id}
										<select
											value={member.role}
											onchange={(e) => updateMemberRole(member.userId, e.currentTarget.value)}
											class="rounded border border-slate-300 px-2 py-1 text-sm"
										>
											<option value="OWNER">Owner</option>
											<option value="MANAGER">Manager</option>
											<option value="TECH">Tech</option>
										</select>
									{:else}
										<span
											class="inline-block rounded-full px-2 py-1 text-xs font-medium {member.role ===
											'OWNER'
												? 'bg-purple-100 text-purple-700'
												: member.role === 'MANAGER'
													? 'bg-blue-100 text-blue-700'
													: 'bg-slate-100 text-slate-700'}"
										>
											{member.role}
										</span>
									{/if}
								</td>
								{#if isOwner}
									<td class="py-3">
										{#if member.userId !== data.user.id}
											<button
												onclick={() => removeMember(member.userId)}
												class="text-red-600 hover:text-red-700"
											>
												Remove
											</button>
										{/if}
									</td>
								{/if}
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}

		{#if isOwner}
			<div class="mt-4 border-t border-slate-200 pt-4">
				<p class="text-sm text-slate-600">
					Invite new members: Phase 1 - Email invitations coming soon
				</p>
			</div>
		{/if}
	</div>
</div>
