import { env } from '@tooltag/config/env';
import { writeFile, mkdir } from 'fs/promises';
import { existsSync } from 'fs';
import path from 'path';
import { nanoid } from 'nanoid';

/**
 * File storage service for handling photo uploads.
 * Supports local filesystem storage (with S3 ready for future).
 */

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

export interface UploadResult {
	url: string;
	filename: string;
}

/**
 * Validate uploaded file
 */
function validateFile(file: File): { valid: boolean; error?: string } {
	if (!ALLOWED_MIME_TYPES.includes(file.type)) {
		return { valid: false, error: 'Invalid file type. Only images (JPEG, PNG, GIF, WebP) are allowed.' };
	}

	if (file.size > MAX_FILE_SIZE) {
		return { valid: false, error: 'File too large. Maximum size is 5MB.' };
	}

	return { valid: true };
}

/**
 * Get file extension from mime type
 */
function getExtensionFromMimeType(mimeType: string): string {
	const map: Record<string, string> = {
		'image/jpeg': '.jpg',
		'image/png': '.png',
		'image/gif': '.gif',
		'image/webp': '.webp',
	};
	return map[mimeType] || '.jpg';
}

/**
 * Upload file to local storage
 */
async function uploadToLocal(file: File): Promise<UploadResult> {
	const storageDir = path.resolve(env.STORAGE_PATH || './uploads');
	
	// Create uploads directory if it doesn't exist
	if (!existsSync(storageDir)) {
		await mkdir(storageDir, { recursive: true });
	}

	// Generate unique filename
	const ext = getExtensionFromMimeType(file.type);
	const filename = `${Date.now()}-${nanoid(10)}${ext}`;
	const filepath = path.join(storageDir, filename);

	// Convert file to buffer and write
	const buffer = Buffer.from(await file.arrayBuffer());
	await writeFile(filepath, buffer);

	// Return public URL
	const url = `/uploads/${filename}`;
	return { url, filename };
}

/**
 * Upload file to S3 (placeholder for future implementation)
 */
async function uploadToS3(file: File): Promise<UploadResult> {
	// TODO: Implement S3 upload
	// For now, fall back to local storage
	console.warn('S3 upload not implemented, using local storage');
	return uploadToLocal(file);
}

/**
 * Upload a file (photo) and return the URL
 */
export async function uploadFile(file: File): Promise<UploadResult> {
	// Validate file
	const validation = validateFile(file);
	if (!validation.valid) {
		throw new Error(validation.error);
	}

	// Upload based on storage type
	if (env.STORAGE_TYPE === 's3') {
		return uploadToS3(file);
	} else {
		return uploadToLocal(file);
	}
}

/**
 * Delete a file from storage
 */
export async function deleteFile(filename: string): Promise<boolean> {
	try {
		if (env.STORAGE_TYPE === 'local') {
			const filepath = path.join(env.STORAGE_PATH || './uploads', filename);
			const { unlink } = await import('fs/promises');
			await unlink(filepath);
			return true;
		}
		// TODO: Implement S3 deletion
		return false;
	} catch (error) {
		console.error('Failed to delete file:', error);
		return false;
	}
}

