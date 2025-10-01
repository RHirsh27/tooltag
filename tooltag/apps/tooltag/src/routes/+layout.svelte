<script lang="ts">
	import '../app.css';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" type="image/svg+xml" href="/favicon.svg" />
	<link rel="icon" type="image/x-icon" href="/favicon.svg" />
	<title>ToolTag - Equipment Tracking</title>
</svelte:head>

{@render children?.()}
