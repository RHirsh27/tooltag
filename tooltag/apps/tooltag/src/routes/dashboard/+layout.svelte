<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';

	let { data, children } = $props();

	let showOrgMenu = $state(false);

	async function handleLogout() {
		await fetch('/api/auth/logout', { method: 'POST' });
		goto('/login');
	}

	function switchOrg(orgId: string) {
		goto(`/dashboard?org=${orgId}`);
		showOrgMenu = false;
	}
</script>

<div class="flex min-h-screen bg-slate-50">
	<!-- Sidebar -->
	<aside class="w-64 border-r border-slate-200 bg-white">
		<div class="flex h-16 items-center border-b border-slate-200 px-4">
			<h1 class="text-xl font-bold text-primary-600">ToolTag</h1>
		</div>

		<!-- Org Switcher -->
		<div class="border-b border-slate-200 p-4">
			<button
				onclick={() => (showOrgMenu = !showOrgMenu)}
				class="flex w-full items-center justify-between rounded-lg border border-slate-200 bg-white px-3 py-2 text-left hover:bg-slate-50"
			>
				<div>
					<p class="text-sm font-medium text-slate-900">{data.currentOrg.name}</p>
					<p class="text-xs text-slate-500 capitalize">{data.currentRole.toLowerCase()}</p>
				</div>
				<svg
					class="h-5 w-5 text-slate-400"
					fill="none"
					stroke="currentColor"
					viewBox="0 0 24 24"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M19 9l-7 7-7-7"
					/>
				</svg>
			</button>

			{#if showOrgMenu && data.memberships.length > 1}
				<div class="mt-2 rounded-lg border border-slate-200 bg-white shadow-lg">
					{#each data.memberships as membership}
						{#if membership.organizationId !== data.currentOrg.id}
							<button
								onclick={() => switchOrg(membership.organizationId)}
								class="block w-full px-3 py-2 text-left text-sm hover:bg-slate-50"
							>
								{membership.organization.name}
							</button>
						{/if}
					{/each}
				</div>
			{/if}
		</div>

		<!-- Navigation -->
		<nav class="p-4">
			<a
				href="/dashboard?org={data.currentOrg.id}"
				class="block rounded-lg px-3 py-2 text-sm font-medium {$page.url.pathname === '/dashboard'
					? 'bg-primary-50 text-primary-700'
					: 'text-slate-700 hover:bg-slate-50'}"
			>
				Dashboard
			</a>
			<a
				href="/dashboard/inventory?org={data.currentOrg.id}"
				class="block rounded-lg px-3 py-2 text-sm font-medium {$page.url.pathname.startsWith(
					'/dashboard/inventory'
				)
					? 'bg-primary-50 text-primary-700'
					: 'text-slate-700 hover:bg-slate-50'}"
			>
				Inventory
			</a>
			<a
				href="/dashboard/assignments?org={data.currentOrg.id}"
				class="block rounded-lg px-3 py-2 text-sm font-medium {$page.url.pathname.startsWith(
					'/dashboard/assignments'
				)
					? 'bg-primary-50 text-primary-700'
					: 'text-slate-700 hover:bg-slate-50'}"
			>
				Assignments
			</a>
			<a
				href="/dashboard/audit?org={data.currentOrg.id}"
				class="block rounded-lg px-3 py-2 text-sm font-medium {$page.url.pathname.startsWith(
					'/dashboard/audit'
				)
					? 'bg-primary-50 text-primary-700'
					: 'text-slate-700 hover:bg-slate-50'}"
			>
				Audit Log
			</a>

			{#if data.currentRole !== 'TECH'}
				<div class="my-4 border-t border-slate-200 pt-4">
					<p class="mb-2 px-3 text-xs font-semibold uppercase text-slate-500">Manage</p>
					<a
						href="/dashboard/settings/locations?org={data.currentOrg.id}"
						class="block rounded-lg px-3 py-2 text-sm font-medium {$page.url.pathname.startsWith(
							'/dashboard/settings/locations'
						)
							? 'bg-primary-50 text-primary-700'
							: 'text-slate-700 hover:bg-slate-50'}"
					>
						Locations
					</a>
					<a
						href="/dashboard/settings/categories?org={data.currentOrg.id}"
						class="block rounded-lg px-3 py-2 text-sm font-medium {$page.url.pathname.startsWith(
							'/dashboard/settings/categories'
						)
							? 'bg-primary-50 text-primary-700'
							: 'text-slate-700 hover:bg-slate-50'}"
					>
						Categories
					</a>
					<a
						href="/dashboard/settings?org={data.currentOrg.id}"
						class="block rounded-lg px-3 py-2 text-sm font-medium {$page.url.pathname ===
						'/dashboard/settings'
							? 'bg-primary-50 text-primary-700'
							: 'text-slate-700 hover:bg-slate-50'}"
					>
						Settings
					</a>
				</div>
			{/if}
		</nav>

		<!-- User Menu -->
		<div class="absolute bottom-0 w-64 border-t border-slate-200 p-4">
			<div class="flex items-center justify-between">
				<div class="min-w-0 flex-1">
					<p class="truncate text-sm font-medium text-slate-900">{data.user.name}</p>
					<p class="truncate text-xs text-slate-500">{data.user.email}</p>
				</div>
				<button
					onclick={handleLogout}
					class="ml-2 rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-600"
					title="Logout"
				>
					<svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
						/>
					</svg>
				</button>
			</div>
		</div>
	</aside>

	<!-- Main Content -->
	<main class="flex-1 overflow-auto">
		{@render children?.()}
	</main>
</div>
