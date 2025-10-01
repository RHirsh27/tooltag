<script lang="ts">
	import { goto } from '$app/navigation';

	let email = $state('');
	let password = $state('');
	let loading = $state(false);
	let error = $state('');

	async function handleLogin(e: Event) {
		e.preventDefault();
		loading = true;
		error = '';

		try {
			const res = await fetch('/api/auth/login', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ email, password }),
			});

			const data = await res.json();

			if (!res.ok) {
				error = data.error || 'Login failed';
				loading = false;
				return;
			}

			// Redirect to dashboard - using window.location for full page reload
			window.location.href = '/dashboard';
		} catch (err) {
			console.error('Login error:', err);
			error = 'Network error. Please try again.';
			loading = false;
		}
	}
</script>

<div class="flex min-h-screen items-center justify-center bg-slate-50 px-4">
	<div class="w-full max-w-md">
		<div class="card">
			<h1 class="mb-2 text-2xl font-bold text-slate-900">Welcome back</h1>
			<p class="mb-6 text-sm text-slate-600">Sign in to your ToolTag account</p>

			{#if error}
				<div class="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-700">
					{error}
				</div>
			{/if}

			<form onsubmit={handleLogin} class="space-y-4">
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
						class="input"
						placeholder="••••••••"
					/>
				</div>

				<button type="submit" disabled={loading} class="btn btn-primary w-full">
					{loading ? 'Signing in...' : 'Sign in'}
				</button>
			</form>

			<div class="mt-6 text-center text-sm text-slate-600">
				Don't have an account?
				<a href="/signup" class="font-medium text-primary-600 hover:text-primary-700">
					Sign up
				</a>
			</div>
		</div>
	</div>
</div>
