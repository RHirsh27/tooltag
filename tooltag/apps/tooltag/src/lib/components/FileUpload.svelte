<script lang="ts">
	let {
		onUpload,
		currentImage = '',
		label = 'Photo',
	}: {
		onUpload: (url: string) => void;
		currentImage?: string;
		label?: string;
	} = $props();

	let uploading = $state(false);
	let error = $state('');
	let fileInput: HTMLInputElement;
	let previewUrl = $state(currentImage);

	async function handleFileSelect(event: Event) {
		const input = event.target as HTMLInputElement;
		const file = input.files?.[0];

		if (!file) return;

		// Validate file type
		if (!file.type.startsWith('image/')) {
			error = 'Please select an image file';
			return;
		}

		// Validate file size (5MB)
		if (file.size > 5 * 1024 * 1024) {
			error = 'File size must be less than 5MB';
			return;
		}

		error = '';
		uploading = true;

		try {
			// Create preview
			const reader = new FileReader();
			reader.onload = (e) => {
				previewUrl = e.target?.result as string;
			};
			reader.readAsDataURL(file);

			// Upload file
			const formData = new FormData();
			formData.append('file', file);

			const res = await fetch('/api/upload', {
				method: 'POST',
				body: formData,
			});

			const result = await res.json();

			if (!res.ok) {
				error = result.error || 'Upload failed';
				previewUrl = currentImage;
				return;
			}

			// Call parent callback with URL
			onUpload(result.url);
		} catch (err) {
			error = 'Failed to upload image';
			previewUrl = currentImage;
		} finally {
			uploading = false;
		}
	}

	function handleRemove() {
		previewUrl = '';
		onUpload('');
		if (fileInput) {
			fileInput.value = '';
		}
	}
</script>

<div class="file-upload">
	<label for="file-upload" class="mb-1 block text-sm font-medium text-slate-700">
		{label}
	</label>

	{#if previewUrl}
		<div class="mb-3">
			<div class="relative inline-block">
				<img
					src={previewUrl}
					alt="Preview"
					class="h-32 w-32 rounded-lg border-2 border-slate-200 object-cover"
				/>
				<button
					type="button"
					onclick={handleRemove}
					aria-label="Remove uploaded image"
					class="absolute -right-2 -top-2 rounded-full bg-red-500 p-1 text-white shadow-lg hover:bg-red-600"
				>
					<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							stroke-width="2"
							d="M6 18L18 6M6 6l12 12"
						/>
					</svg>
				</button>
			</div>
		</div>
	{/if}

	<div class="flex items-center gap-3">
		<label
			for="file-upload"
			class="btn btn-secondary cursor-pointer {uploading ? 'opacity-50' : ''}"
		>
			{#if uploading}
				<svg class="mr-2 inline-block h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
					<circle
						class="opacity-25"
						cx="12"
						cy="12"
						r="10"
						stroke="currentColor"
						stroke-width="4"
					></circle>
					<path
						class="opacity-75"
						fill="currentColor"
						d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
					></path>
				</svg>
				Uploading...
			{:else}
				<svg class="mr-2 inline-block h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"
					/>
				</svg>
				{previewUrl ? 'Change Photo' : 'Upload Photo'}
			{/if}
		</label>
		<input
			id="file-upload"
			type="file"
			accept="image/*"
			class="hidden"
			onchange={handleFileSelect}
			disabled={uploading}
			bind:this={fileInput}
		/>
		<span class="text-sm text-slate-500">JPEG, PNG, GIF, WebP (max 5MB)</span>
	</div>

	{#if error}
		<p class="mt-2 text-sm text-red-600">{error}</p>
	{/if}
</div>

