<script lang="ts">
	import { goto } from '$app/navigation';

	let name = $state('');
	let email = $state('');
	let password = $state('');
	let loading = $state(false);
	let error = $state('');

	async function handleSignup(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		try {
			const res = await fetch('/api/auth/signup', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ name, email, password }),
			});

			const data = await res.json();

			if (!res.ok) {
				error = data.error || 'Signup failed';
				return;
			}

			// Redirect to org creation
			goto('/onboarding/create-org');
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
			<h1 class="mb-2 text-2xl font-bold text-slate-900">Create your account</h1>
			<p class="mb-6 text-sm text-slate-600">Get started with ToolTag</p>

			{#if error}
				<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
					{error}
				</div>
			{/if}

			<form onsubmit={handleSignup} class="space-y-4">
				<div>
					<label for="name" class="mb-1 block text-sm font-medium text-slate-700">
						Full Name
					</label>
					<input
						id="name"
						type="text"
						bind:value={name}
						class="input"
						placeholder="John Doe"
					/>
				</div>

				<div>
					<label for="email" class="mb-1 block text-sm font-medium text-slate-700">
						Email
					</label>
					<input
						id="email"
						type="email"
						bind:value={email}
						required
						class="input"
						placeholder="you@example.com"
					/>
				</div>

				<div>
					<label for="password" class="mb-1 block text-sm font-medium text-slate-700">
						Password
					</label>
					<input
						id="password"
						type="password"
						bind:value={password}
						required
						minlength="8"
						class="input"
						placeholder="••••••••"
					/>
					<p class="mt-1 text-xs text-slate-500">At least 8 characters</p>
				</div>

				<button type="submit" disabled={loading} class="btn btn-primary w-full">
					{loading ? 'Creating account...' : 'Create account'}
				</button>
			</form>

			<div class="mt-6 text-center text-sm text-slate-600">
				Already have an account?
				<a href="/login" class="font-medium text-primary-600 hover:text-primary-700">
					Sign in
				</a>
			</div>
		</div>
	</div>
</div>
